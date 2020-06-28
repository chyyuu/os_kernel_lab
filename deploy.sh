#!/bin/sh
# 下面的 DEPLOY_DIR 目录需要关联到 https://github.com/rcore-os/rCore-Tutorial-deploy 远程仓库
# 随后可以通过 https://rcore-os.github.io/rCore-Tutorial-deploy 来访问
DEPLOY_DIR=../rCore-Tutorial-deploy/

# Build and copy
gitbook build
cp -r _book/* $DEPLOY_DIR
cd $DEPLOY_DIR || exit

CURRENT_TIME=$(date +"%Y-%m-%d %H:%m:%S")
# Commit and push
git add *
git commit -m "[Auto-deploy] Build $CURRENT_TIME"
git push origin master

cd - || exit