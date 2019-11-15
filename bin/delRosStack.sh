#!/bin/bash

stack_name=$1

stack_id=`aliyun --access-key-id ${ACCESS_KEY_ID} --access-key-secret ${ACCESS_KEY_SECRET} ros ListStacks --RegionId ${REGION} --StackName.1 ${stack_name} | jq -r '.Stacks[0].StackId'`
aliyun --access-key-id ${ACCESS_KEY_ID} --access-key-secret ${ACCESS_KEY_SECRET} ros DeleteStack  --RegionId ${REGION} --StackId ${stack_id} --RetainAllResources true