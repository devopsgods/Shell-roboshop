#!/bin/bash

SG_ID="sg-059bc57f32dfd1979" #replace with our ID
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z015439937GBQIS91RBN2"
DOMAIN_ID="karegowdra.com"

for instance  in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].INSTANCEID' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId, PrivateIpAddress, PublicIpAddress]' --output table 
        )
        RECORD_NAME=."$DOMAIN_ID"
    else
        IP=$(
            aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId, PrivateIpAddress, PublicIpAddress]' --output table 
        )
        RECORD_NAME=$instance."$DOMAIN_ID" #mongobd.karegowdra.com
    fi
    
    echo "IP Address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating the A record for my app",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
     }
    '
    
     echo "record updated for $instance "
done