#!/bin/sh
#

git remote add local-common ../common
git merge -s subtree -Xtheirs -Xsubtree=common local-common/main
