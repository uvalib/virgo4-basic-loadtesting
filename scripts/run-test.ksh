#!/usr/bin/env bash
#
# basic scripting to drive Apache Bench for some load testing
#

# source helpers
SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <scenario file>"
}

# ensure correct usage
if [ $# -ne 1 ]; then
   help_and_exit
fi

# common definitions
USER_AGENT="Mozilla/5.0 (X11; CrOS x86_64 8172.45.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.64 Safari/537.36"
TOOL_DEFAULTS="-h2"

# input parameters for clarity
SCENARIO_FILE=$1

if [ ! -f $SCENARIO_FILE ]; then
   echo "ERROR: $SCENARIO_FILE does not exist or is not readable" >&2
   exit 1
fi

# ensure we have the tool available
LOAD_TOOL=tools/bin/hey
ensure_tool_available $LOAD_TOOL

# get our parameters
endpoint=$(get_config "endpoint" $SCENARIO_FILE required)
method=$(get_config "method" $SCENARIO_FILE required)
concurency=$(get_config "concurency" $SCENARIO_FILE required)
qsec=$(get_config "qsec" $SCENARIO_FILE required)
duration=$(get_config "duration" $SCENARIO_FILE required)
payload=$(get_config "payload" $SCENARIO_FILE optional)

TOOL_OPTIONS="-c $concurency -q $qsec -m $method -z $duration"

# do some basic validation
if [ "$method" == "POST" ]; then
   ensure_value_defined "payload" $payload
   TOOL_OPTIONS="$TOOL_OPTIONS -H \"Content-Type: application/json\" -H \"Accept: application/json\" -D $payload"
fi

# call the tool
RUNNER=/tmp/runner.$$
echo $LOAD_TOOL $TOOL_DEFAULTS $TOOL_OPTIONS $endpoint > $RUNNER
cat $RUNNER
chmod +x $RUNNER
$RUNNER
res=$?
rm $RUNNER
if [ $res -ne 0 ]; then
   error_and_exit "$res running $LOAD_TOOL"
fi

exit 0

#
# end of file
#
