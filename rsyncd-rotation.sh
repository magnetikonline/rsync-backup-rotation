#!/bin/bash -e

REVISION_COUNT=25


function exitError {

	echo "Error: $1" >&2
	exit 1
}

function padRevisionDirPart {

	printf "%03d" "$1"
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

revisionDir="$RSYNC_MODULE_PATH/$(padRevisionDirPart "$REVISION_COUNT")"
if [[ -d $revisionDir ]]; then
	# drop the oldest backup directory, outside revision range
	chmod --recursive u+w "$revisionDir"
	rm --force --recursive "$revisionDir"
fi

revision=$REVISION_COUNT
while [[ $revision -gt 0 ]]; do
	((revision--))
	revisionDir="$RSYNC_MODULE_PATH/$(padRevisionDirPart "$revision")"

	if [[ -d $revisionDir ]]; then
		mv \
			"$revisionDir" \
			"$RSYNC_MODULE_PATH/$(padRevisionDirPart "$(($revision + 1))")"
	fi
done
