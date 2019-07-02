#!/usr/bin/env bash
#
# script to walk through the standard response from a master search
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
TR_TOOL=tr
ensure_tool_available $TR_TOOL

#cat $RESULTS_FILE

TOTAL_HITS=$(cat $RESULTS_FILE | $JQ_TOOL ".total_hits")
if [ $TOTAL_HITS -eq 0 ]; then
   log "no search results"
   exit 0
fi

POOLS=$(cat $RESULTS_FILE | $JQ_TOOL ".pool_results[].service_url" | $TR_TOOL -d "\"")

for pool in $POOLS; do

   log "** pool url: $pool **"

   $SCRIPT_DIR/walk-pool-response.ksh $RESULTS_FILE $pool
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$res walking pool response, aborting"
   fi

done

exit 0

#
# end of file
#
