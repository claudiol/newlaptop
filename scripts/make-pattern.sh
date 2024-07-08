#!/bin/bash
#

podman login quay.io

if [ "$1." == "." ]; then
IMAGE_TAG_BASE=quay.io/claudiol/patterns-operator VERSION=0.0.40 IMG=quay.io/claudiol/patterns-operator:"${VERSION}" CHANNELS=fast make generate bundle docker-build bundle-build catalog-build
else
IMAGE_TAG_BASE=quay.io/claudiol/patterns-operator VERSION=6.6.67 IMG=quay.io/claudiol/patterns-operator:"${VERSION}" CHANNELS=fast make generate bundle docker-build docker-push bundle-build bundle-push catalog-build catalog-push catalog-install
fi
