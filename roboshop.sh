#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0672a218cab9ebbb0"
INSTANCES=("mongodb" "catalogue" "frontend" "redis" "user" "cart" "shipping" "payment" "mysql" "dispatch" "rabbitmq")
ZONE_ID="Z02370613NFA2YD1CKRZ2"
DOMAIN_NAME="sreeja.site"
SUBNET_ID="$subnet-00af09fb15e458af9"

#for instance in ${INSTANCES[@]}
for instance in $@
do
    instance_id=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0672a218cab9ebbb0 --subnet-id subnet-00af09fb15e458af9 --network-interfaces "DeviceIndex=0,SubnetId=$SUBNET_ID,AssociatePublicIpAddress=true,Groups=$SG_ID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId" --output text)

    echo "Waiting for $instance to enter running state..."
    aws ec2 wait instance-running --instance-ids "$instance_id"

    if [ $instance != "frontend" ]
    then 
        IP=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi
    echo "$instance ip address is: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'


done
