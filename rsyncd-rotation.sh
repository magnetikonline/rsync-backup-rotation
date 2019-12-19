#!/bin/bash -e

REVISION_COUNT_DEFAULT=25
REVISION_DIR_DIGITS=3


function exitError {
	echo "Error: $1" >&2
	exit 1
}

function writeWarning {
	echo "Warning: $1" >&2
}

function writeLog {
	# only write to log file if log path defined
	if [[ -n $logFilePath ]]; then
		echo "$(date "+%Y-%m-%d %H:%M:%S"): $1" >>"$logFilePath"
	fi
}

function padRevisionDirPart {
	printf "%0${REVISION_DIR_DIGITS}d" "$1"
}

function removeExpiredRevision {
	local revisionDirRegexp="^[0-9]{${REVISION_DIR_DIGITS}}$"
	local moduleBaseDir

	local IFS=$'\n'
	for moduleBaseDir in $(ls -1 "$RSYNC_MODULE_PATH/."); do
		local revisionDir="$RSYNC_MODULE_PATH/$moduleBaseDir"

		# skip anything not a directory or not exactly $REVISION_DIR_DIGITS digits in length
		if [[
			(! -d $revisionDir) ||
			(! $moduleBaseDir =~ $revisionDirRegexp)
		]]; then
			continue
		fi

		# convert revision to integer
		local revision=$((10#$moduleBaseDir))

		# above revision retention count?
		if [[ $revision -ge $1 ]]; then
			# drop revision outside range
			chmod --recursive u+w "$revisionDir"
			rm --force --recursive "$revisionDir"

			writeLog "Removed revision [$revisionDir]"
		fi
	done
}

# read script arguments
logFilePath=""
revisionCount=$REVISION_COUNT_DEFAULT

while getopts ":l:r:" optKey; do
	case "$optKey" in
		l)
			# log key script events to file
			logFilePath=$OPTARG

			# ensure parent directory exists
			parentDir=$(dirname "$logFilePath")
			if [[ ! -d $parentDir ]]; then
				writeWarning "Invalid log file directory of [$parentDir], logging disabled."
				logFilePath=""
			fi
			;;
		r)
			# set revision count
			revisionCount=$OPTARG

			# validate count is an integer in sensible bounds
			if [[
				(! $revisionCount =~ ^[1-9][0-9]?$) ||
				($revisionCount -lt 2)
			]]; then
				writeWarning "Revision count must be a value between 2-99, falling back to default of [$REVISION_COUNT_DEFAULT]"
				revisionCount=$REVISION_COUNT_DEFAULT
			fi
			;;
	esac
done

# confirm module path given & Rsync transfer a success
if [[ -z $RSYNC_MODULE_PATH ]]; then
	exitError "No \$RSYNC_MODULE_PATH found."
fi

if [[ $RSYNC_EXIT_STATUS -ne 0 ]]; then
	exitError "Returned \$RSYNC_EXIT_STATUS not successful, skipping rotate."
fi

# only rotate if zeroed directory exists
zeroBackupDirPart=$(padRevisionDirPart 0)
if [[ ! -d "$RSYNC_MODULE_PATH/$zeroBackupDirPart" ]]; then
	exitError "Unable to locate upload directory, ensure Rsync target in the form [TARGET_HOST::MODULE_NAME/$zeroBackupDirPart]."
fi

# log environment
writeLog "Rsync module path [$RSYNC_MODULE_PATH]"
writeLog "Revision keep count [$revisionCount]"

# remove expired directories after [$revisionCount]
removeExpiredRevision $revisionCount

# increment each revision directory
revision=$revisionCount
while [[ $revision -gt 0 ]]; do
	((revision--))
	revisionDir="$RSYNC_MODULE_PATH/$(padRevisionDirPart $revision)"

	if [[ -d $revisionDir ]]; then
		revisionDirNext="$RSYNC_MODULE_PATH/$(padRevisionDirPart $((revision + 1)))"
		mv "$revisionDir" "$revisionDirNext"

		writeLog "Moved [$revisionDir] -> [$revisionDirNext]"
	fi
done
