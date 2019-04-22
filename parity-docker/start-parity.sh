#!/bin/bash

mkdir -p /root/.local
aws s3 sync --delete --region $region s3://$bucket/$s3key/.local/ /root/.local/
/usr/bin/parity $*
