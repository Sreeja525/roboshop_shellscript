#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0672a218cab9ebbb0"
INSTANCES=("mongodb" "catalogue" "frontend")
ZONE_ID="Z02370613NFA2YD1CKRZ2"
DOMAIN_NAME="sreeja.site"

for instance in ${INSTANCES[@]}
do
    instance_id=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0672a218cab9ebbb0 --subnet-id subnet-00af09fb15e458af9 --network-interfaces "DeviceIndex=0,SubnetId=$SUBNET_ID,AssociatePublicIpAddress=true,Groups=$SG_ID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId" --output text)

    echo "Waiting for $instance to enter running state..."
    aws ec2 wait instance-running --instance-ids "$instance_id"

    if [ $instance != "frontend" ]
    then 
        IP=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        
    else
        IP=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

    fi
    echo "$instance ip address is: $IP"
done
