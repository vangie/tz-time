#!/bin/bash

url=$1

until $(curl --output /dev/null --silent --head --fail $url); do
    printf '.'
    sleep 0.1
done