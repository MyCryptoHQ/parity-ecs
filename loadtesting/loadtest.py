import bees
import json

sOptions = '{"post_file":"data.json","contenttype":"application/json"}'
options = json.loads(sOptions)

bees.up(4,'beeswithmachineguns','us-east-1b')
bees.attack('parity-service-20ccef1ff1cf7cbd.elb.us-east-1.amazonaws.com:8545',2,2,**options)
bees.down()
