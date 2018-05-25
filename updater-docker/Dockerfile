FROM parity/parity:stable

RUN apt-get update -y && apt-get install -y python-pip && pip install awscli && rm -rf /var/lib/apt/lists/*
 
COPY ./start-parity.sh /root/start-parity.sh

EXPOSE 8080 8545 8180
ENTRYPOINT ["/root/start-parity.sh"]
