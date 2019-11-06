#!/usr/bin/env bash
#
# script to walk through the pool portion of a standard response from a master search
#

# source helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <results file> <pool url>"
}

# ensure correct usage
if [ $# -ne 2 ]; then
   help_and_exit
fi

# input parameters for clarity
RESULTS_FILE=$1
POOL_URL=$2

if [ ! -f $RESULTS_FILE ]; then
   error_and_exit "$RESULTS_FILE does not exist or is not readable"
fi

# ensure we have the tools available
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL
SED_TOOL=sed
ensure_tool_available $SED_TOOL

# basic definitions
SEARCH_URL=$POOL_URL/api/search

# extract the needed info from the results file
REQUEST=$(cat $RESULTS_FILE | $JQ_TOOL ".request")
POOL_RESULTS=$(cat $RESULTS_FILE | $JQ_TOOL ".pool_results[] | select(.service_url==\"$POOL_URL\")")
PAGINATION=$(echo $POOL_RESULTS | $JQ_TOOL ".pagination")

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

# temp files
REQUEST_FILE=/tmp/request.$$
RESPONSE_FILE=/tmp/response.$$

# our current query count in the pager
COUNT=$ROWS

# page through until we are done
while true; do

   if [ $COUNT -ge $TOTAL ]; then
      log "$SEARCH_URL done"
      break
   fi

   # prepare the request payload
   echo $REQUEST | $SED_TOOL -e "s/\"start\": 0,/\"start\": $COUNT,/g" > $REQUEST_FILE

   #cat $REQUEST_FILE
   log "$SEARCH_URL (start: $COUNT of $TOTAL)"

   # issue the search
   $SCRIPT_DIR/issue-search.ksh $SEARCH_URL $REQUEST_FILE $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      cat $REQUEST_FILE
      cat $RESPONSE_FILE
      error_and_exit "$res issuing pool search, aborting"
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
