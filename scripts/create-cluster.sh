#!/bin/sh

CLUSTERDIR=/home/claudiol/work/clusters
FIPS=0
REGIONCOUNT=0
USEREGION=0
PARALLEL=0
INSTALL_CONFIG_FILE=datacenter-blueprints-install-config.yaml

# Function log
# Arguments:
#   $1 are for the options for echo
#   $2 is for the message
#   \033[0K\r - Trailing escape sequence to leave output on the same line
function log {
    if [ -z "$2" ]; then
        echo -e "\033[0K\r\033[1;36m$1\033[0m"
    else
        echo -e $1 "\033[0K\r\033[1;36m$2\033[0m"
    fi
}

function usage () {
  printf "$0 -n <NUMBER OF CLUSTERS> -c <CLUSTER-NAME> -v <OCPVERSION>\n"
  printf "\n"
  printf "$0 -n 2 -c npss-tnc -v 4.11\n"
  printf "\n"
  printf "The above command will create 2 clusters (npss-tnc-{1,2}) using the installer in ~/bin/ocp4.11\n"
  exit 1
}

while getopts "v:c:n:r:i:pfh" opt
do
    case $opt in
	(n) CLUSTERCOUNT=$OPTARG
	    ;;
	(r) REGION=$OPTARG
	    USEREGION=1
	    REGIONCOUNT=$(echo $REGION | cut -d '-' -f 3)
	    ;;
	(c) CLUSTERNAME=$OPTARG
	    ;;
	(f) FIPS=1
            ;;
	(p) PARALLEL=1
	    ;;
	(i) INSTALL_CONFIG_FILE=$OPTARG
	    ;;
	(v) VERSION=$OPTARG
	    ;;
	(h) usage
	    ;;
	(*) printf "Illegal option '-%s'\n" "$opt" && exit 1
	    ;;
    esac
done

cd $CLUSTERDIR

if [ -z $REGION ]; then
  REGION="us-west"
fi

if [ -z $CLUSTERNAME ]; then
	echo "Need a cluster name"
	usage
fi
if [ -z $VERSION ]; then
	echo "Need a OCP version"
	exit
fi

if [ -z $CLUSTERCOUNT ]; then
	echo "Creating 1 OpenShift cluster"
	CLUSTERCOUNT=1
fi

let COUNT=1
if [ $REGIONCOUNT -eq 0 ]; then
    let REGIONCOUNT=1
fi

INITIALCLUSTERNAME=$CLUSTERNAME

while [ $COUNT -le $CLUSTERCOUNT ]
do
   UUID=$(uuidgen | cut -d '-' -f 2)
   CLUSTERNAME=$(echo $CLUSTERNAME-$UUID)
   if [ $USEREGION -eq 0 ]; then
     region=$REGION-$REGIONCOUNT
     if [ ! -d $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT ]; then
       mkdir -p $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT
     else
      echo "Existing $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT directory. Run openshift-install destroy cluster --dir $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT"
      echo "If you have already destroyed the cluster just remove the directory."
	  let COUNT++
      continue
     fi
   else
     region=$REGION
     if [ ! -d $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT ]; then
       mkdir -p $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT
     else
      echo "Existing $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT directory. Run openshift-install destroy cluster --dir $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT"
      echo "If you have already destroyed the cluster just remove the directory."
	  let COUNT++
      continue
     fi
   fi 
     

   echo -n "Copying install config for [$CLUSTERNAME-$COUNT]  Region: [$REGION]..."
   if [ $USEREGION -eq 0 ]; then
     cp $INSTALL_CONFIG_FILE $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT/install-config.yaml
     sed -i "s|CLUSTERNAME|$CLUSTERNAME-$COUNT|g" $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT/install-config.yaml
     sed -i "s|REGION|$region|g" $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT/install-config.yaml 
   else
     cp $INSTALL_CONFIG_FILE $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT/install-config.yaml
     sed -i "s|CLUSTERNAME|$CLUSTERNAME-$COUNT|g" $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT/install-config.yaml
     sed -i "s|REGION|$region|g" $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT/install-config.yaml 
   fi
   echo "done"

   if [ $FIPS -eq 1 ]; then
     echo -n "Enabling FIPS ..."
	 if [ $USEREGION != 1 ]; then
	     sed -i "s|FIPS|true|g" $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT/install-config.yaml 
	 else
	     sed -i "s|FIPS|true|g" $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT/install-config.yaml 
	 fi
     echo "done"
   else
	 if [ $USEREGION -eq 0 ]; then
	     sed -i "s|FIPS|false|g" $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT/install-config.yaml 
	 else
	     sed -i "s|FIPS|false|g" $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT/install-config.yaml 
	 fi
   fi

   if [ -d ~/bin/ocp$VERSION ]; then
     OCPVERSION=$(~/bin/ocp$VERSION/openshift-install version | grep openshift-install)
     echo "Using openshift-install to create the cluster [$OCPVERSION]"
     if [ $USEREGION -eq 0 ]; then
	   if [ $PARALLEL -eq 1 ]; then
	     ~/bin/ocp$VERSION/openshift-install create cluster --dir $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT > $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT.log 2>&1 &
	     sleep 5
	   else
	     ~/bin/ocp$VERSION/openshift-install create cluster --dir $CLUSTERDIR/$REGION-$REGIONCOUNT-$CLUSTERNAME-$COUNT
	   fi
     else
	   if [ $PARALLEL -eq 1 ]; then
		 ~/bin/ocp$VERSION/openshift-install create cluster --dir $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT > $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT/$REGION-$CLUSTERNAME-$COUNT.log 2>&1 &
		 sleep 5
	   else
	     ~/bin/ocp$VERSION/openshift-install create cluster --dir $CLUSTERDIR/$REGION-$CLUSTERNAME-$COUNT
	   fi
	 fi
   fi

   if [ $USEREGION -eq 0 ]; then
       if [ $REGIONCOUNT -eq 2 ]; then
	   REGIONCOUNT=1
	   if [ "$REGION" == "us-west" ]; then
	       REGION="us-east"
	   else
	       REGION="us-west"
	   fi
       else
	   let REGIONCOUNT++
       fi
       let COUNT++
   else
     let COUNT++
   fi
   # RESET CLUSTERNAME
   CLUSTERNAME=$INITIALCLUSTERNAME
done

if [ -f ~/bin/oc ]; then
  rm -f ~/bin/oc
  ln -s ~/bin/ocp$VERSION/oc ~/bin
fi
if [ -f ~/bin/openshift-install ]; then
  rm -f ~/bin/openshift-install
  ln -s ~/bin/ocp$VERSION/openshift-install ~/bin
fi

HASHES=1
if [ $PARALLEL -eq 1 ]; then
        PIDS=$(ps -eaf | grep "openshift-install create cluster" | grep -v grep | awk '{print $2}')
        while [ "$PIDS." != "." ]; do
                PIDS=$(ps -eaf | grep "openshift-install create cluster" | grep -v grep | awk '{print $2}')    
                if [ $HASHES -eq 1 ]; then
                        log -n "Waiting for clusters to be created #  " 
                        let HASHES++
						sleep 2
                elif [ $HASHES -eq 2 ]; then   
                        log -n "Waiting for clusters to be created ## "  
                        let HASHES++
						sleep 2
                else                                                       
                        log -n "Waiting for clusters to be created ###"
                        HASHES=1 
                fi
        done
fi 

echo "OCP VERSION INFO"
OCVERSION=$(~/bin/ocp$VERSION/oc version | grep Client)
INSTALLVER=$(~/bin/ocp$VERSION/openshift-install version | grep openshift-install)
echo "OC Version: $OCVERSION"
echo "Installer Version: $INSTALLVER"
cd -
