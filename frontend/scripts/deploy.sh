#!/usr/bin/env bash

CWD=`basename $PWD`

# try to make sure this runs from the right place
if [ $CWD == 'scripts' ]
    then
        cd ../..
elif [ $CWD == 'frontend' ]
    then
        cd ..
fi

rsync -vre ssh frontend pi@doorbot.local:doorbot/ --exclude *.db --exclude .git --exclude .env
