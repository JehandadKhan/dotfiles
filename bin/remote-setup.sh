#!/bin/bash

REMOTE_DIR=`cd ~/remote/ && pwd`
CURR_DIR=`pwd`
if [[ $CURR_DIR != $REMOTE_DIR/* ]] ; then
    echo "`basename $0`: not under $REMOTE_DIR, won't sync"
    exit 1
fi

REMOTE_HOST_DIR=${CURR_DIR#"$REMOTE_DIR/"}

HOST=`echo $REMOTE_HOST_DIR | grep -o -E '^[^/]*' | head -1`
# HOST=${REMOTE_HOST_DIR##*/}
HOST_DIR="$REMOTE_DIR/$HOST"

DEST_DIR=`echo $CURR_DIR | sed -e "s,$HOST_DIR,,"`

echo "$HOST: $CURR_DIR -> $DEST_DIR"
