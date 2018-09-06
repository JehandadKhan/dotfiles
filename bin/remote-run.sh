#!/bin/bash

source $DOTFILES/bin/remote-setup.sh

ssh $HOST "cd $DEST_DIR && $*"
