#!/usr/bin/env bash
#
# issue a search against the digital content API given the parameters provided
#

# source helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <endpoint> <auth token> <id> <results file>"
}

# ensure correct usage
if [ $# -ne 4 ]; then
   help_and_exit
fi

# input parameters for clarity
ENDPOINT=$1
AUTHTOKEN=$2
ID=$3
RESULTS_FILE=$4

# remove the results file if it exists
rm $RESULTS_FILE >/dev/null 2>&1

# ensure we have the tools available
CURL_TOOL=curl
ensure_tool_available $CURL_TOOL

# define the tool defaults
TOOL_DEFAULTS="--fail -s -S"

# define our basic options
TOOL_OPTIONS="-H \"Accept: application/json\" -H \"Authorization: Bearer $AUTHTOKEN\""

# temp files
RUNNER=/tmp/runner.$$

# add the payload file
TOOL_OPTIONS="$TOOL_OPTIONS"

# call the tool
#echo "$ENDPOINT"
echo $CURL_TOOL $TOOL_DEFAULTS $TOOL_OPTIONS ${ENDPOINT}/${ID} > $RUNNER
echo "exit \$?" >> $RUNNER

# for debugging
#cat $RUNNER

chmod +x $RUNNER
TSTART=$($SCRIPT_DIR/get-timestamp.ksh)
$RUNNER > $RESULTS_FILE
res=$?
TEND=$($SCRIPT_DIR/get-timestamp.ksh)
rm $RUNNER > /dev/null 2>&1
if [ $res -ne 0 ]; then
   #cat $RESULTS_FILE
   exit $res
fi

ELAPSED=$(echo "$TEND - $TSTART" | bc)
echo " ==> elapsed $ELAPSED seconds"

# for debugging
#cat $RESULTS_FILE

exit 0

#
# end of file
#
