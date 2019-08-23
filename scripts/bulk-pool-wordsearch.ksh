#!/usr/bin/env bash
#
# script to issue a series of searches.
#

# source helpers
SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <configuration file> <iterations>"
}

# ensure correct usage
if [ $# -ne 2 ]; then
   help_and_exit
fi

# we need to check for our operating environment
if [[ "$OSTYPE" =~ "darwin" ]]; then
   SHUF=gshuf
else
   SHUF=shuf
fi

# input parameters for clarity
CONFIG_FILE=$1
ITERATIONS=$2

# ensure the config file exists
if [ ! -f $CONFIG_FILE ]; then
   error_and_exit "$CONFIG_FILE does not exist or is not readable"
fi

# our temp wordlist file
WORDLIST_FILE=/tmp/words.$$
rm $WORDLIST_FILE >/dev/null 2>&1

# ensure we have the tools available
SED_TOOL=sed
ensure_tool_available $SED_TOOL
SHUF_TOOL=$SHUF
ensure_tool_available $SHUF_TOOL

# get our parameters
endpoint=$(get_config "endpoint" $CONFIG_FILE required)
payload=$(get_config "payload" $CONFIG_FILE required)
wordlist=$(get_config "wordlist" $CONFIG_FILE required)
rewrite=$(get_config "rewrite" $CONFIG_FILE required)
walkresults=$(get_config "walkresults" $CONFIG_FILE required)

# ensure payload template exists
if [ ! -f $payload ]; then
   error_and_exit "$payload does not exist or is not readable"
   exit 1
fi

# ensure wordlist source exists
if [ ! -f $wordlist ]; then
   error_and_exit "$wordlist does not exist or is not readable"
   exit 1
fi

# generate the test wordlist file we will use
log "Generating test words..."
cat $wordlist | $SHUF_TOOL | head -$ITERATIONS > $WORDLIST_FILE

# temp files
PAYLOAD_FILE=/tmp/payload.$$
RESPONSE_FILE=/tmp/response.$$

# our progress counter
COUNTER=0

# test start time
STIME=$(python -c 'import time; print time.time()')

# go through the word list and issue a new search for each one
for word in $(<$WORDLIST_FILE); do

   COUNTER=$((COUNTER + 1 ))

   # generate the search from the template
   cat $payload | $SED_TOOL -e "s/$rewrite/$word/g" > $PAYLOAD_FILE

   log "Search $COUNTER of $ITERATIONS: ($word)"

   # issue the search
   $SCRIPT_DIR/issue-search.ksh $endpoint $PAYLOAD_FILE $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$res issuing search, aborting"
   fi

   # summerize the results
   if [ "$walkresults" == "no" ]; then
      $SCRIPT_DIR/summerize-pool-response.ksh $RESPONSE_FILE
      res=$?
   else
      $SCRIPT_DIR/walk-pool-response.ksh $RESPONSE_FILE $PAYLOAD_FILE
      res=$?
   fi
   if [ $res -ne 0 ]; then
      error_and_exit "$res processing results, aborting"
   fi
   
done

# test end time
ETIME=$(python -c 'import time; print time.time()')

# remove the working files
rm $PAYLOAD_FILE > /dev/null 2>&1
rm $RESPONSE_FILE > /dev/null 2>&1
rm $WORDLIST_FILE > /dev/null 2>&1

# calculate and show total time
ELAPSED=$(echo "$ETIME - $STIME" | bc)
log "Total test time $ELAPSED seconds"

log "Exiting normally"
exit 0

#
# end of file
#
