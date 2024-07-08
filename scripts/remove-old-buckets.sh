#!/bin/sh
#

# This script removes the nb.* buckets that are 30 days old

function log {
    if [ -z "$2" ]; then
        echo -e "\033[0K\r\033[1;36m$1\033[0m"
    else
        echo -e $1 "\033[0K\r\033[1;36m$2\033[0m"
    fi
}

DELETEFLAG=0

if [ ".$1" == "." ]; then
   log -n "Retieving S3 bucket info ... "
   BUCKETS=($(aws s3 ls | awk '{ printf "%s ", $3}' ))
   FILEDATES=($(aws s3 ls | awk '{ printf "%s ", $1}' | tr -d '-'))
else
   FILTER=$1
   log -n "Retieving S3 bucket info with filter [ $FILTER ]... "
   BUCKETS=($(aws s3 ls | grep $1 | awk '{ printf "%s ", $3}' ))
   FILEDATES=($(aws s3 ls | grep $1 | awk '{ printf "%s ", $1}' | tr -d '-'))
fi
log "Retrieving S3 bucket info ... ok"

TIMETODAY=$(date +%s)

echo $BUCKETS
for i in ${!BUCKETS[@]}
do
    FILEDATE=`date -d "${FILEDATES[$i]}" +%s`
    CALC=$(expr $TIMETODAY \- 60 \* 60 \* 24 \* 30)
    CHECK=$(expr $FILEDATE \< $CALC)
    if [ $CHECK -gt 0 ] && [ "$ans" != "A" ]; then
	  DELETEFLAG=1
	  log -n "Are you sure you want to remove ${BUCKETS[$i]} [Y/N/A]? "
	  read ans
	  if [ "$ans" == "y" ] || [ "$ans" == "Y" ]; then
	    log -n " $CHECK REMOVING ${BUCKETS[$i]} OLDER THAN 30 DAYS ... "
	    RC=$(aws s3 rb s3://${BUCKETS[$i]} --force > /dev/null 2>&1)
	    log " $CHECK REMOVING ${BUCKETS[$i]} OLDER THAN 30 DAYS ... DONE"
          fi
    elif [ $CHECK -gt 0 ]; then 
          log -n " $CHECK REMOVING ${BUCKETS[$i]} OLDER THAN 30 DAYS ... "
	  RC=$(aws s3 rb s3://${BUCKETS[$i]} --force > /dev/null 2>&1;echo $?)
	  if [ $RC -eq 0 ]; then
	    log " $CHECK REMOVING ${BUCKETS[$i]} OLDER THAN 30 DAYS ... DONE"
	  else
	    log " $CHECK REMOVING ${BUCKETS[$i]} OLDER THAN 30 DAYS ... FAILED"
	  fi
    fi
done

if [ $DELETEFLAG == 0 ]; then
    log "No files to delete"
fi
