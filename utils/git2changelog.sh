#!/bin/bash

if test -z "$1" ; then
  echo "Usage $0 TAG"
  exit
fi

DATE=`date +%y-%m-%d`
echo "$1  ($DATE)"
echo ""
git log "$1"..HEAD --no-merges  --format="    %B"

