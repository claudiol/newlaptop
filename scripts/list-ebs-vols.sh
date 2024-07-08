#!/bin/sh
for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text)
do 
  for volumeId in $(aws ec2 describe-volumes --region "$region" --filters Name=status,Values=available --query 'Volumes[].[VolumeId]' --output text)
  do 
	  for clusterId in $(aws ec2 describe-volumes --volume-ids "$volumeId" --filters Name=status,Values=available --query "Volumes[].Tags[].Value" --output text)
	  do
	    if [[ "$clusterId" == *"claudiol"* ]]; then
              echo "Deleting Volume Region: $region VolumeId $volumeId clusterId $clusterId"
	      #aws ec2 delete-volume --volume-id $volumeId
	    fi
          done 
  done 
done
