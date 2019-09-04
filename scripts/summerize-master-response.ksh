#!/usr/bin/env bash
#
# script to summerize the standard response from a master search
#

# source helpers
SCRIPT_DIR=$(dirname $0)
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

# debugging
#cat $RESULTS_FILE | $JQ_TOOL "."

QUERY=$(cat $RESULTS_FILE | $JQ_TOOL ".request.query")
HITS=$(cat $RESULTS_FILE | $JQ_TOOL ".total_hits")
POOLS=$(cat $RESULTS_FILE | $JQ_TOOL "[.pool_results[] | select( .pagination.total > 0) ] | length" )
TIME_MS=$(cat $RESULTS_FILE | $JQ_TOOL ".total_time_ms")

echo " ==> hits: $HITS, pools: $POOLS, ms: $TIME_MS, q: $QUERY"
   
exit 0

#
# end of file
#
