#!/bin/bash

REVISION_COUNT=25


# module path given & rsync transfer a success?
[ -z "$RSYNC_MODULE_PATH" ] && exit
[ "$RSYNC_EXIT_STATUS" -ne 0 ] && exit

# only rotate if /000 directory exists
[ ! -d "$RSYNC_MODULE_PATH/000" ] && exit

revisionPad=`printf %03d $REVISION_COUNT`
if [ -d "$RSYNC_MODULE_PATH/$revisionPad" ]; then
	# drop the oldest backup directory, outside revision range
	chmod -R u+w "$RSYNC_MODULE_PATH/$revisionPad"
	rm -rf "$RSYNC_MODULE_PATH/$revisionPad"
fi

revision=$REVISION_COUNT
while [ $revision -gt 0 ]; do
	revision=$((revision - 1))
	revisionPad=`printf %03d $revision`

	if [ -d "$RSYNC_MODULE_PATH/$revisionPad" ]; then
		revisionNextPad=`printf %03d $((revision + 1))`
		mv "$RSYNC_MODULE_PATH/$revisionPad" "$RSYNC_MODULE_PATH/$revisionNextPad"
	fi
done
