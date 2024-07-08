#!/bin/bash

DELETE_ALLUSERS=0

function delete_user {
	USER=$1
	echo "Getting User policy ..."
	POLICY=$(aws iam list-user-policies --user-name $USER | jq '.PolicyNames[]' | tr -d '"')

	if [ "$POLICY." != "." ]; then
		echo "Deleting user policy first ... [$POLICY]"
		aws iam delete-user-policy --user-name $USER --policy-name $POLICY 
	fi
	KEYS=$(aws iam list-access-keys --user-name $USER | jq '.AccessKeyMetadata[].AccessKeyId' | tr -d '"')

	if [ ".$KEYS" != "." ]; then
		echo "Deleting access key"
		aws iam delete-access-key --user-name $USER --access-key-id $KEYS
	fi

	echo "Deleting user"
	aws iam delete-user --user-name $USER
}

while getopts "ahf:" opt
do
    case $opt in
	(f) USERFILTER=$OPTARG
	    ;;
	(a) DELETE_ALLUSERS=1
	    ;;
	(h) usage
	    ;;
	(*) printf "Illegal option '-%s'\n" "$opt" && exit 1
	    ;;
    esac
done

if [ "$USERFILTER." == "." ]; then
    echo "Need a user filter to delete"
    exit
fi
USERS=$(aws iam list-users | jq ".Users[].UserName" | grep $USERFILTER)

if [ "$USERS." == "." ]; then
    echo "No users matched for [$1]"
    exit
fi

EXISTS=0
for i in $USERS;
do
	USER=$(echo $i | tr -d '"')
	echo $USER
	RC=$(aws iam get-user --user-name $USER > /dev/null 2>&1; echo $?)
	if [ $RC -eq 0 ]; then
		if [ $DELETE_ALLUSERS -eq 1 ]; then
			delete_user $USER
		else
		        echo -n "Do you want to delete this user [$USER]? "
		        read ans
		        if [ "$ans" == "Y" ] || [ "$ans" == "y" ]; then
				delete_user $USER
			fi
		fi
	else 
		echo "Could not find user [$USER]"
	fi
done

