#!/bin/bash -x

mkdir -p /root/.local
aws s3 sync --delete --region $region s3://$bucket/$s3key/.local/ /root/.local/
/parity/parity $* &
sleep 1800
pid=`ps -ef |grep parity/parity|grep -v grep|awk '{print $2}'`
kill $pid
sleep 30
aws s3 sync --delete --region $region /root/.local/ s3://$bucket/$s3key/.local/
