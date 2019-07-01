#!/usr/bin/env bash
#
# issue a search against the search API given the parameters provided
#

# source helpers
SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <endpoint> <payload file> <results file>"
}

# ensure correct usage
if [ $# -ne 3 ]; then
   help_and_exit
fi

# input parameters for clarity
ENDPOINT=$1
PAYLOAD_FILE=$2
RESULTS_FILE=$3

# verify the payload file exists
if [ ! -f $PAYLOAD_FILE ]; then
   echo "ERROR: $PAYLOAD_FILE does not exist or is not readable" >&2
   exit 1
fi

# remove the results file if it exists
rm $RESULTS_FILE >/dev/null 2>&1

# ensure we have the tools available
CURL_TOOL=curl
ensure_tool_available $CURL_TOOL

# define our basic options
TOOL_OPTIONS="-X POST -H \"Content-Type: application/json\" -H \"Accept: application/json\" -H \"Authorization: Bearer bkb4notbo1bc80d2uucg\""

# temp files
RUNNER=/tmp/runner.$$

# add the payload file
TOOL_OPTIONS="$TOOL_OPTIONS -d @$PAYLOAD_FILE"

# call the tool
echo $CURL_TOOL $TOOL_DEFAULTS $TOOL_OPTIONS $ENDPOINT > $RUNNER
#cat $RUNNER
chmod +x $RUNNER
$RUNNER > $RESULTS_FILE 2>/dev/null
res=$?
rm $RUNNER
if [ $res -ne 0 ]; then
   error_and_exit "$res issuing search"
fi

exit 0

#
# end of file
#
