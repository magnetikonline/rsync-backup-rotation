#!/bin/bash

REVISION=25


# module path given & rsync transfer a success?
[ -z "$RSYNC_MODULE_PATH" ] && exit
[ "$RSYNC_EXIT_STATUS" -ne 0 ] && exit

# only rotate if /000 dir exists
[ ! -d "$RSYNC_MODULE_PATH/000" ] && exit

REVISIONPAD=`printf %03d $REVISION`
if [ -d "$RSYNC_MODULE_PATH/$REVISIONPAD" ]; then
	# drop the oldest backup, outside revision range
	chmod -R u+w "$RSYNC_MODULE_PATH/$REVISIONPAD"
	rm -rf "$RSYNC_MODULE_PATH/$REVISIONPAD"
fi

while [ $REVISION -gt 0 ]; do
	REVISION=$((REVISION - 1))
	REVISIONPAD=`printf %03d $REVISION`

	if [ -d "$RSYNC_MODULE_PATH/$REVISIONPAD" ]; then
		REVISIONNEXTPAD=`printf %03d $((REVISION + 1))`
		mv "$RSYNC_MODULE_PATH/$REVISIONPAD" "$RSYNC_MODULE_PATH/$REVISIONNEXTPAD"
	fi
done
