#!/bin/bash

if [ "$1." == "." ]; then
    echo "Listing all users ... "
    aws iam list-users | jq ".Users[].UserName"
    exit
else 
   aws iam list-users | jq ".Users[].UserName" | grep $1
fi

