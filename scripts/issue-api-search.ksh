#!/usr/bin/env bash
#
# issue a search against the search API given the parameters provided
#

# source helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <endpoint> <auth token> <payload file> <results file>"
}

# ensure correct usage
if [ $# -ne 4 ]; then
   help_and_exit
fi

# input parameters for clarity
ENDPOINT=$1
AUTHTOKEN=$2
PAYLOAD_FILE=$3
RESULTS_FILE=$4

# verify the payload file exists
if [ ! -f $PAYLOAD_FILE ]; then
   error_and_exit "$PAYLOAD_FILE does not exist or is not readable"
fi

# remove the results file if it exists
rm $RESULTS_FILE >/dev/null 2>&1

# ensure we have the tools available
CURL_TOOL=curl
ensure_tool_available $CURL_TOOL

# define the tool defaults
TOOL_DEFAULTS="--fail -s -S"

# define our basic options
TOOL_OPTIONS="-X POST -H \"Content-Type: application/json\" -H \"Accept: application/json\" -H \"Authorization: Bearer $AUTHTOKEN\""

# temp files
RUNNER=/tmp/runner.$$

# add the payload file
TOOL_OPTIONS="$TOOL_OPTIONS -d @$PAYLOAD_FILE"

# call the tool
#echo "$ENDPOINT"
echo $CURL_TOOL $TOOL_DEFAULTS $TOOL_OPTIONS $ENDPOINT > $RUNNER
echo "exit \$?" >> $RUNNER

# for debugging
#cat $RUNNER
#cat $PAYLOAD_FILE

chmod +x $RUNNER
STIME=$(python -c 'import time; print time.time()')
$RUNNER > $RESULTS_FILE
res=$?
ETIME=$(python -c 'import time; print time.time()')
rm $RUNNER > /dev/null 2>&1
if [ $res -ne 0 ]; then
   #cat $RESULTS_FILE
   exit $res
fi

ELAPSED=$(echo "$ETIME - $STIME" | bc)
echo " ==> elapsed $ELAPSED seconds"

# for debugging
#cat $RESULTS_FILE

exit 0

#
# end of file
#
