#!/bin/bash -e

REVISION_COUNT=25


function exitError {

	echo "Error: $1" >&2
	exit 1
}

# confirm module path given & rsync transfer a success?
if [[ -z $RSYNC_MODULE_PATH ]]; then
	exitError "No \$RSYNC_MODULE_PATH found."
fi

if [[ $RSYNC_EXIT_STATUS -ne 0 ]]; then
	exitError "Returned \$RSYNC_EXIT_STATUS not successful, skipping rotate."
fi

# only rotate if /000 directory exists
if [[ ! -d "$RSYNC_MODULE_PATH/000" ]]; then
	exitError "Unable to locate upload directory, ensure Rsync target is in the form [TARGET_HOST::MODULE_NAME/000]."
fi

revisionPad=$(printf %03d $REVISION_COUNT)
if [[ -d "$RSYNC_MODULE_PATH/$revisionPad" ]]; then
	# drop the oldest backup directory, outside revision range
	chmod -R u+w "$RSYNC_MODULE_PATH/$revisionPad"
	rm -rf "$RSYNC_MODULE_PATH/$revisionPad"
fi

revision=$REVISION_COUNT
while [[ $revision -gt 0 ]]; do
	revision=$((revision - 1))
	revisionPad=$(printf %03d $revision)

	if [[ -d "$RSYNC_MODULE_PATH/$revisionPad" ]]; then
		revisionNextPad=$(printf %03d $((revision + 1)))
		mv "$RSYNC_MODULE_PATH/$revisionPad" "$RSYNC_MODULE_PATH/$revisionNextPad"
	fi
done
