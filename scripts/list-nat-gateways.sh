#!/bin/sh
#aws ec2 describe-nat-gateways --query NatGateways[].State  --query NatGateways[].Tags[].Value

for natId in $(aws ec2 describe-nat-gateways --region us-west-1 --query NatGateways[].NatGatewayId --output text)
do
  for valueId in $(aws ec2 describe-nat-gateways --nat-gateway-ids $natId --query NatGateways[].Tags[].Value --output text)
  do
    if [[ "$valueId" == *"claudiol"* ]]; then
      echo "ID = $natId Value = $valueId"
      #aws ec2 delete-nat-gateway --nat-gateway-id $natId
    fi
  done
done
