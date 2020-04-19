#!/bin/bash -e

DIRNAME=$(dirname "$0")
ROTATE_SCRIPT="$DIRNAME/../rsyncd-rotation.sh"

. "$DIRNAME/util.sh"


# test: no $RSYNC_MODULE_PATH given should return error
execScript "$ROTATE_SCRIPT"
retValIs1
stderrMatch 'Error:\ No\ \$RSYNC_MODULE_PATH\ found\.'


# test: invalid log path should return warning and disable logging
execScript "$ROTATE_SCRIPT -l /dead/path/log.log"
retValIs1
stderrMatch 'Warning:\ Invalid\ log\ file\ directory\ of\ \[/dead/path\]\ -\ logging\ disabled\.'


# test: invalid rotation count should return warning and keep default
execScript "$ROTATE_SCRIPT -r INVALID"
retValIs1
stderrMatch 'Warning:\ Revision\ count\ must\ be\ between\ 2-99\ -\ falling\ back\ to\ default\ of\ \[25\]\.'


tmpModulePath=$(mktemp --directory)
export RSYNC_MODULE_PATH=$tmpModulePath


# test: non-zero Rsync exit status should return error
export RSYNC_EXIT_STATUS=1

execScript "$ROTATE_SCRIPT"
retValIs1
stderrMatch 'Error:\ Returned\ \$RSYNC_EXIT_STATUS\ not\ successful,\ skipping\ rotate\.'

export RSYNC_EXIT_STATUS=0


# test: non-exist zero directory (/000) should return error
execScript "$ROTATE_SCRIPT"
retValIs1
stderrMatch 'Error:\ Unable\ to\ locate\ upload\ directory,\ ensure\ Rsync\ target\ in\ the\ form\ \[TARGET_HOST::MODULE_NAME/000\]\.'


# test: zero directory should move to -> 001
mkdir --parents "$tmpModulePath/000"

execScript "$ROTATE_SCRIPT"
retValIs0

dirNotExist "$tmpModulePath/000"
dirExist "$tmpModulePath/001"

rm --force --recursive "$tmpModulePath/"*


# test: rotation of a few directories, removal of some beyond the rotation limit, won't touch files - even if in '000' form
mkdir --parents "$tmpModulePath/000"
mkdir --parents "$tmpModulePath/001"
mkdir --parents "$tmpModulePath/002"
mkdir --parents "$tmpModulePath/003"
mkdir --parents "$tmpModulePath/004"
mkdir --parents "$tmpModulePath/005"
touch "$tmpModulePath/006"

execScript "$ROTATE_SCRIPT -r 3"
retValIs0

dirNotExist "$tmpModulePath/000"
dirExist "$tmpModulePath/001"
dirExist "$tmpModulePath/002"
dirExist "$tmpModulePath/003"
dirNotExist "$tmpModulePath/004"
dirNotExist "$tmpModulePath/005"
dirNotExist "$tmpModulePath/006"
fileExist "$tmpModulePath/006"


# clean up
rm --force --recursive "$tmpModulePath"
cleanup
echo "Passed!"
