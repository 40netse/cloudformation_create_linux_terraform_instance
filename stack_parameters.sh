#!/usr/bin/env bash

stack_prefix=terraform-linux-dev
stack1=$stack_prefix-base
stack2=$stack_prefix-linux

region=us-east-1
aws_az=us-east-1a

vpc_cidr="10.0.0.0/16"
subnet_cidr="10.0.0.0/24"
linux_instance_type=c4.large
key=mdw-poc-common
access="0.0.0.0/0"
management_cidr1="208.91.115.30/32"
management_cidr2="76.184.215.100/32"
management_cidr3="159.48.172.13/32"
