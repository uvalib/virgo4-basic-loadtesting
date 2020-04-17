#!/usr/bin/env bash
#
# script to get an authentication token from the auth API
#

# source helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <authentication endpoint>"
}

# ensure correct usage
if [ $# -ne 1 ]; then
   help_and_exit
fi

# input parameters for clarity
AUTH_ENDPOINT=$1

# ensure we have the tools available
CURL_TOOL=curl
ensure_tool_available $CURL_TOOL

# temp files
RUNNER=/tmp/runner.$$

# define the tool defaults
TOOL_DEFAULTS="--fail"

# define our basic options
TOOL_OPTIONS="-X POST -H \"Content-Type: application/json\" -H \"Accept: application/json\""

# call the tool
#echo "$ENDPOINT"
echo $CURL_TOOL $TOOL_DEFAULTS $TOOL_OPTIONS $AUTH_ENDPOINT > $RUNNER
echo "exit \$?" >> $RUNNER

chmod +x $RUNNER
$RUNNER 2>/dev/null
res=$?
rm $RUNNER > /dev/null 2>&1
if [ $res -ne 0 ]; then
   error_and_exit "$res issuing auth token request"
fi

exit 0

#
# end of file
#
