#!/bin/sh

cd /tmp
# Download the binary
curl -sSL -o ~/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x ~/bin/argocd

# Test installation
argocd version
