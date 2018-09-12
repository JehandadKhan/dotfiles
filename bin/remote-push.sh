#!/bin/bash

source $DOTFILES/bin/remote-setup.sh

rsync --verbose --recursive --times --compress --progress \
    --exclude ".hg" \
    --exclude ".git" \
        $CURR_DIR/ $HOST:$DEST_DIR