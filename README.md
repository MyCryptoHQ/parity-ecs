# parity-ecs - A parity backend that runs in AWS Elastic Container Service

## Installation Instructions

### Pre-Installation AWS Account Configuration
Prior to installation, you should do the following things in your AWS account:
1. Create a keypair and save the private key (PEM file) to your workstation so you can ssh to the instances in your ECS cluster.
2. Create two repositories in ECR, or in the Docker registry of your choice.  The first is called parity, and the second one is called parity-updater.
  * Note the location of each of the repositories, which will be similar to this: *AWS_account_ID*.dkr.ecr.us-east-1.amazonaws.com/parity:latest
3. Place a copy of your parity .local directory with a completely up to date blockchain in an S3 bucket by using the ```aws s3 sync``` command.

### Build Parity node Docker container
The following steps will allow you to build the Parity node docker container:
1. Clone the git repository.
2. Run the following commands to build and push the Docker container:
```
aws ecr get-login --no-include-email --region us-east-1
cd docker-parity/
docker build -t parity .
docker tag parity:latest <AWS_account_ID>.dkr.ecr.us-east-1.amazonaws.com/parity:latest
docker push <AWS_account_ID>.dkr.ecr.us-east-1.amazonaws.com/parity:latest
```

### Build the Parity Updater Docker container
The following steps will allow you to build the Parity updater docker container:
```
cd ../docker-updater/
docker build -t parity-updater .
docker tag parity-updater:latest <AWS_account_ID>.dkr.ecr.us-east-1.amazonaws.com/parity-updater:latest
docker push <AWS_account_ID>.dkr.ecr.us-east-1.amazonaws.com/parity-updater:latest
```

### Launch the ECS Cluster
The following steps will allow you to launch the ECS cluster:
1. Open the CloudFormation console, and select Create stack.
2. Browse to the file *parity-ecs.yaml* that is located in the root of the git repository.
3. Select the right instance type (only the i3 family is currently supported).
4. Select the amount of instances you would like to launch.
5. Assign a unique name to the environment and stack.  I used "parity-ecs".
6. Select the subnets you would like to launch instances in.
  * I recommend you use the Default VPC in your AWS account, and select all subnets in the VPC.
7. Select the VPC that matches the subnets you chose earlier.
8. If you are using the Default VPC, you can keep the CIDR range as 172.31.0.0/16, but if you are using a different VPC, please modify the CIDR range to match your VPC.  The CloudFormation template creates a security group that allows JSON RPC traffic from this CIDR range, to prevent it from being reachable to the public Internet.
8. Wait until the CloudFormation stack is completely created before proceeding to the next step.

### Launch the Parity Service
The following steps will allow you to launch the Parity service that will run in the ECS cluster:
1. Open the CloudFormation console, and select Create stack.
2. Browse to the file *parity-service.yaml* that is located in the root of the git repository.
3. Select the right number of parity nodes you would like to run.  Current testing indicates the following ratios provide suitable performance:
  * i3.large - 4 parity nodes per instance.
  * i3.xlarge - 8 parity nodes per instance.
  * i3.2xlarge - 16 parity nodes per instance.
  * i3.4xlarge - 32 parity nodes per instance (and so on).
4. Modify the Docker registry location to point to the ECR registry you created earlier.
5. Select the same subnets and VPC that you selected when launching the ECS cluster.
6. Launch the CloudFormation stack.  You'll need to watch it closely as it deploys, and as soon as the parity ECS service is created, you'll need to manually modify that service to set the Health Check Grace Period to 1800 seconds.  This parameter isn't currently available in CloudFormation.  Without this parameter, ECS will terminate your parity tasks before the JSON RPC listener starts.
7. Verify that all of the parity tasks have started properly, and watch CloudWatch logs to ensure that they are able to download the blockchain from S3.
  * After the blockchain is downloaded, and parity starts, verify that your load balancer has healthy targets in the target group through the EC2 console.

### Launch the Parity Updater Service
The following steps will allow you to launch the Parity updater service that keeps the stored blockchain copy in S3 up to date.
1. Open the CloudFormation console, and select Creat stack.
2. Browse to the file *parity-updater.yaml* that is locaated in the root of the git repository.
3. Modify the Docker registry location to point to the ECR registry you created earlier.
4. Launch the CloudFormation stack.
5. After the task starts, watch the CloudWatch logs to ensure that it works properly and is able to do the following:
  1. Downloads the parity blockchain data from S3.
  2. Starts parity, and catches up to the current block.
  3. 30 minutes after parity starts, shuts down parity cleanly.
  4. Copies newly downloaded blocks back to the S3 bucket to update the stored blockchain.