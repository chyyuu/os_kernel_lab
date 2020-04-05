#!/bin/sh
DEPLOY_DIR=../rCore-Tutorial-deploy/

# Build and copy
gitbook build
cp -r _book/* $DEPLOY_DIR
cd $DEPLOY_DIR

CURRENT_TIME=$(date +"%Y-%m-%d %H:%m:%S")
# Commit and push
git add *
git commit -m "[Auto-deploy] Build $CURRENT_TIME"
git push origin master