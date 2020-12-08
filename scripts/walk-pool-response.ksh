#!/usr/bin/env bash
#
# script to walk through the standard response from a pool search
#

# source helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <results file> <request file>"
}

# ensure correct usage
if [ $# -ne 2 ]; then
   help_and_exit
fi

# input parameters for clarity
RESULTS_FILE=$1
REQUEST_FILE=$2

if [ ! -f $RESULTS_FILE ]; then
   error_and_exit "$RESULTS_FILE does not exist or is not readable"
fi

if [ ! -f $REQUEST_FILE ]; then
   error_and_exit "$REQUEST_FILE does not exist or is not readable"
fi

# ensure we have the tools available
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL
SED_TOOL=sed
ensure_tool_available $SED_TOOL
TR_TOOL=tr
ensure_tool_available $TR_TOOL

# basic definitions

# extract the needed info from the results file
REQUEST=$(cat $REQUEST_FILE)
ENDPOINT=$(cat $RESULTS_FILE | $JQ_TOOL ".service_url" | $TR_TOOL -d "\"")
PAGINATION=$(cat $RESULTS_FILE | $JQ_TOOL ".pagination")

# values for the paging
START=$(echo $PAGINATION | $JQ_TOOL ".start")
ROWS=$(echo $PAGINATION | $JQ_TOOL ".rows")
TOTAL=$(echo $PAGINATION | $JQ_TOOL ".total")

# special case
if [ $TOTAL -eq 0 ]; then
   log "no pool results"
   exit 0
fi

# limit the total page count
ROW_LIMIT=1000
if [ $TOTAL -gt $ROW_LIMIT ]; then
   log "$TOTAL results, limiting to $ROW_LIMIT"
   TOTAL=$ROW_LIMIT
fi

#echo "PAGINATION: $PAGINATION, START: $START, ROWS: $ROWS, TOTAL: $TOTAL"

# pool endpoint
SEARCH_URL=$ENDPOINT/api/search

# temp files
REQUEST_FILE=/tmp/request-pool.$$
RESPONSE_FILE=/tmp/response-pool.$$

# our current query count in the pager
COUNT=$ROWS

# page through until we are done
while true; do

   if [ $COUNT -ge $TOTAL ]; then
      log "$SEARCH_URL done"
      break
   fi

   # prepare the request payload
   echo $REQUEST | $SED_TOOL -e "s/\"start\":0,/\"start\":$COUNT,/g" > $REQUEST_FILE

   #cat $REQUEST_FILE
   log "$SEARCH_URL (start: $COUNT of $TOTAL)"

   # issue the search
   $SCRIPT_DIR/issue-api-search.ksh $SEARCH_URL $REQUEST_FILE $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      echo "ERROR: issuing request (error shown above)"
      continue
   fi

   #cat $RESPONSE_FILE

    # update the count
    COUNT=$(( COUNT + ROWS ))
done

# remove the temp files
rm $REQUEST_FILE > /dev/null 2>&1
rm $RESPONSE_FILE > /dev/null 2>&1

exit 0

#
# end of file
#
