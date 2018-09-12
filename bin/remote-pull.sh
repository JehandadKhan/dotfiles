#!/bin/bash

source $DOTFILES/bin/remote-setup.sh

RSYNC_EXCLUDE_OPTS=(--exclude "install.dir" --exclude ".hg" --exclude ".git" --exclude "*build" --exclude "build*" --exclude ".tox" --exclude "*.deb" --exclude "*.rpm")

for i in "$@"
do
case $i in
    -a|--all)
    RSYNC_EXCLUDE_OPTS=()
    shift # past argument=value
    ;;
    -d|--delete)
    RSYNC_OPTS+=(--delete --delete-excluded)
    shift # past argument=value
    ;;
    *)
            # unknown option
    ;;
esac
done

echo "rsync --verbose --recursive --times --compress --progress ${RSYNC_OPTS[@]} ${RSYNC_EXCLUDE_OPTS[@]} $HOST:$DEST_DIR/ $CURR_DIR"
rsync --verbose --recursive --times --compress --progress "${RSYNC_OPTS[@]}" "${RSYNC_EXCLUDE_OPTS[@]}" $HOST:$DEST_DIR/ $CURR_DIR
