#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0672a218cab9ebbb0"
INSTANCES=("mongodb" "catalogue" "user" "cart" "shipping" "dispatch" "redis" "mysql" "rabbitmq" "payment" "frontend")
ZONE_ID="Z02370613NFA2YD1CKRZ2"
DOMAIN_NAME="sreeja.site"


instance_id=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0672a218cab9ebbb0 --subnet-id subnet-00af09fb15e458af9 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE[@]}]' --query 'Instances[0].InstanceId' --output text)

if (instance -ne frontend)
then 
    IP=$(aws ec2 describe-instances --instance-ids i-0abcdef1234567890 --query 'Reservations[*].Instances[*].PricateIpAddress' --output text)
else
    IP=$(aws ec2 describe-instances --instance-ids i-0abcdef1234567890 --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

fi
