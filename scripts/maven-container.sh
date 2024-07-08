#!/bin/bash
#
podman run -it --entrypoint /bin/bash -v /home/claudiol/work/gitrepos/spring-petclinic:/workspace/source/spring-petclinic --security-opt label=disable gcr.io/cloud-builders/mvn:3.8-jdk-8
