#!/bin/sh

PROJROOT=$(cat ./project_path.txt)
eval "cd $PROJROOT"
pwd
yt build
