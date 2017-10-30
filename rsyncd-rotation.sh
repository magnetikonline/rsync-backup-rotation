#!/bin/bash -e

REVISION_COUNT=25
REVISION_DIR_DIGITS=3


function exitError {

	echo "Error: $1" >&2
	exit 1
}

function padRevisionDirPart {

	printf "%0${REVISION_DIR_DIGITS}d" "$1"
}

# confirm module path given & rsync transfer a success?
if [[ -z $RSYNC_MODULE_PATH ]]; then
	exitError "No \$RSYNC_MODULE_PATH found."
fi

if [[ $RSYNC_EXIT_STATUS -ne 0 ]]; then
	exitError "Returned \$RSYNC_EXIT_STATUS not successful, skipping rotate."
fi

# only rotate if zeroed (/000) directory exists
zeroBackupDirPart=$(padRevisionDirPart 0)
if [[ ! -d "$RSYNC_MODULE_PATH/$zeroBackupDirPart" ]]; then
	exitError "Unable to locate upload directory, ensure Rsync target is in the form [TARGET_HOST::MODULE_NAME/$zeroBackupDirPart]."
fi

# remove all directories outside [REVISION_COUNT] limit
revisionDirRegexp="^[0-9]{${REVISION_DIR_DIGITS}}$"
IFS=$'\n'
for moduleBaseDir in $(ls -1 "$RSYNC_MODULE_PATH/."); do
	revisionDir="$RSYNC_MODULE_PATH/$moduleBaseDir"

	# skip anything not a directory or not exactly three digits
	if [[
		(! -d $revisionDir) ||
		(! $moduleBaseDir =~ $revisionDirRegexp)
	]]; then
		continue
	fi

	# convert to revision integer
	revision=$((10#$moduleBaseDir))

	# above revision retention count?
	if [[ $revision -ge $REVISION_COUNT ]]; then
		# drop revision outside range
		chmod --recursive u+w "$revisionDir"
		rm --force --recursive "$revisionDir"
	fi
done

unset IFS

revision=$REVISION_COUNT
while [[ $revision -gt 0 ]]; do
	((revision--))
	revisionDir="$RSYNC_MODULE_PATH/$(padRevisionDirPart $revision)"

	if [[ -d $revisionDir ]]; then
		mv \
			"$revisionDir" \
			"$RSYNC_MODULE_PATH/$(padRevisionDirPart $(($revision + 1)))"
	fi
done
