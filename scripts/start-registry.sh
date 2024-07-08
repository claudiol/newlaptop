#!/bin/sh

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Function log
# Arguments:
#   $1 are for the options for echo
#   $2 is for the message
function log {
    if [ -z "$2" ]; then
	echo -e "\033[1;36m$1\033[0m"
    else
	echo -e $1 "\033[1;36m$2\033[0m"
    fi
}

function checkImageExists {

  log -n "Checking to see if registry image exists ... "

  podman images  > /dev/null

  if [ $? -eq 0 ]; then
    log  "PASS"
  else
    log  "FAIL"
    log  "Please ensure that you loaded httpd-24 image using podman"
    exit
  fi
}

function checkRegistryStatus {
  log -n "Checking if registry is already running ... "
  podman ps | grep ocp-disc-registry > /dev/null
 
  if [ $? -eq 0 ]; then
    log  "Running"
    exit
  else
    log  "Stopped."
  fi
}

function setRegistryEnvironment {
  log -n "Checking registry environment ... "
  if [ -d /opt/registry/auth ] && [ -d /opt/registry/certs ] && [ -d /opt/registry/data ]; then
     log  "ok."
  else
    mkdir -p /opt/registry/{auth,certs,data}
  fi
  log  "done"

}

function createTLSCertificate {
  log -n "Checking for existing registry certificates ... "
  if [ -f /opt/registry/certs/domain.key ] && [ -f /opt/registry/certs/domain.crt ]; then
    log  "ok. Using certificates under /opt/registry/certs"
  else  
    log -n "Creating registry certificate ... "
    # create a TLS certificate
    /usr/bin/openssl req \
      -newkey rsa:4096  \
      -nodes -sha256 \
      -keyout /opt/registry/certs/domain.key \
      -subj "/C=US/ST=North Carolina/L=Raleigh/O=Red Hat Inc/OU=Consulting Department/CN=$HOSTNAME" \
      -addext "subjectAltName = DNS:$HOSTNAME" \
      -x509 \
      -days 365 \
      -out /opt/registry/certs/domain.crt
  fi 

  cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
  update-ca-trust
  trust list | grep -i "<hostname>"
}

function runRegistry {
  log  "Running the podman ocp-disc-registry"
  export REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/home/claudiol/work/storage
  podman run \
    --name ocp-disc-registry \
    -p 5000:5000 \
    -v /opt/registry/auth:/auth:Z \
    -e "REGISTRY_AUTH=htpasswd" \
    -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
    -v /opt/registry/certs:/certs:z \
    -v /home/claudiol/work/storage:/data:z \
    -e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt" \
    -e "REGISTRY_HTTP_TLS_KEY=/certs/domain.key" \
    -e REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true \
	-e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data \
    -d \
    docker.io/library/registry:2

  log  "done"
}

checkImageExists
checkRegistryStatus
setRegistryEnvironment
createTLSCertificate
runRegistry
