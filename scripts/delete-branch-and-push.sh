#!/bin/sh

usage() {
  printf "$0 -b <BRANCH-NAME>\n"
  exit 1
}

while getopts "b:" opt
do
    case $opt in
	(b) if [[ "$OPTARG" == *","* ]]; then
	      BRANCHNAME=$(echo $* | sed "s|-b||g" ) # option to list multiple clusters e.g. cluster1, cluster2,cluster3
	    else
	      BRANCHNAME=$OPTARG
	    fi
	    ;;
	(*) printf "Illegal option '-%s'\n" "$opt" 
	    usage
	    ;;
    esac
done

if [ "$BRANCHNAME." == "." ]; then
	usage
	exit
fi

BRANCHNAMES=$(echo $BRANCHNAME | tr -d ' ' | grep ',')

if [ ".$BRANCHNAMES" == "." ]; then
  echo "Verifying branches ..."
  
  GITBRANCHES=$(git branch)
  for gitbranch in ${GITBRANCHES[@]}; do
    if [[ "$gitbranch" == "$BRANCHNAME" ]]; then
	    RC=$(git branch -D $BRANCHNAME > /dev/null 2>&1;echo $?)
	    if [ $RC -eq 0 ]; then
              echo  "Branch [$BRANCHNAME] deleted locally"
	    fi
	    RC=$(git push origin -d $BRANCHNAME > /dev/null 2>&1;echo $?)
	    if [ $RC -eq 0 ]; then
              echo  "Branch [$BRANCHNAME] deleted in origin"
	    fi
    fi
  done
else 
  BRANCHNAMES=$(echo $BRANCHNAMES | sed "s/,/ /g")
  for branch in ${BRANCHNAMES[@]}; do
    GITBRANCHES=$(git branch)
    for gitbranch in ${GITBRANCHES[@]}; do
      if [[ "$gitbranch" == "$branch" ]]; then
	    RC=$(git branch -D $branch > /dev/null 2>&1;echo $?)
	    if [ $RC -eq 0 ]; then
              echo  "Branch [$branch] deleted locally"
	    fi
	    RC=$(git push origin -d $branch > /dev/null 2>&1;echo $?)
	    if [ $RC -eq 0 ]; then
              echo  "Branch [$branch] deleted in origin"
	    fi
      fi
    done 
  done
fi
