STDOUT_CAPTURE=$(mktemp)
STDERR_CAPTURE=$(mktemp)


function exitError {
	echo "Error: $1" >&2
	exit 1
}

function execScript {
	set +e
	$1 \
		>"$STDOUT_CAPTURE" \
		2>"$STDERR_CAPTURE"

	retVal=$?
	set -e

	scriptStdout=$(cat "$STDOUT_CAPTURE")
	scriptStderr=$(cat "$STDERR_CAPTURE")
}

function retValIs0 {
	if [[ $retVal -ne 0 ]]; then
		exitError "Expected exit code 0"
	fi
}

function retValIs1 {
	if [[ $retVal -ne 1 ]]; then
		exitError "Expected exit code 1"
	fi
}

function stderrMatch {
	if [[ ! $scriptStderr =~ $1 ]]; then
		exitError "Unexpected error message [$scriptStderr]"
	fi
}

function dirExist {
	if [[ ! -d $1 ]]; then
		exitError "Expected to find directory [$1]"
	fi
}

function dirNotExist {
	if [[ -d $1 ]]; then
		exitError "Expected not to find directory [$1]"
	fi
}

function fileExist {
	if [[ ! -f $1 ]]; then
		exitError "Expected to find file [$1]"
	fi
}

function cleanup {
	rm --force "$STDOUT_CAPTURE"
	rm --force "$STDERR_CAPTURE"
}
