#!/bin/bash

stack_name=$1

fun deploy --use-ros --stack-name ${stack_name} --assume-yes | tee ${stack_name}-deploy.log
cat ${stack_name}-deploy.log | grep '^url:' | sed -e "s/^url: //" | sed -e 's/^/DEPLOYED_URL=/' > .env
cat .env
rm ${stack_name}-deploy.log
sleep 2