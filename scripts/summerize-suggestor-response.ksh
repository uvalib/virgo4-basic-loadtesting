#!/usr/bin/env bash
#
# script to summerize the standard response from the suggestor
#

# source helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <results file>"
}

# ensure correct usage
if [ $# -ne 1 ]; then
   help_and_exit
fi

# input parameters for clarity
RESULTS_FILE=$1

if [ ! -f $RESULTS_FILE ]; then
   error_and_exit "$RESULTS_FILE does not exist or is not readable"
fi

# ensure we have the tools available
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

SUGGESTIONS=$(cat $RESULTS_FILE | $JQ_TOOL ".suggestions | length")
echo " ==> suggestions: $SUGGESTIONS"

exit 0

#
# end of file
#
