#!/usr/bin/env bash
#
# script to issue a series of searches.
#

# source helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
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
query=$(get_config "query" $CONFIG_FILE required)
wordlist=$(get_config "wordlist" $CONFIG_FILE required)
walkresults=$(get_config "walkresults" $CONFIG_FILE required)

# ensure query template exists
if [ ! -f $query ]; then
   error_and_exit "$query does not exist or is not readable"
   exit 1
fi

# ensure wordlist source exists
if [ ! -f $wordlist ]; then
   error_and_exit "$wordlist does not exist or is not readable"
   exit 1
fi

# generate the test wordlist file we will use
log "Generating test words..."
WORD_COUNT=$(($ITERATIONS * 3 ))
cat $wordlist | $SHUF_TOOL | head -$WORD_COUNT > $WORDLIST_FILE
IFS=$'\n' read -d '' -r -a words < $WORDLIST_FILE
rm $WORDLIST_FILE > /dev/null 2>&1

# temp files
QUERY_FILE=/tmp/query.$$
RESPONSE_FILE=/tmp/response.$$

# our progress counter
COUNTER=0

# test start time
STIME=$(python -c 'import time; print time.time()')

# go through the word list and issue a new search for each one
while [ $COUNTER -lt $ITERATIONS ]; do

   COUNTER=$(($COUNTER + 1 ))

   # support up to 3 terms
   IX=$(($RANDOM % $WORD_COUNT))
   TERM1=${words[$IX]}
   IX=$(($RANDOM % $WORD_COUNT))
   TERM2=${words[$IX]}
   IX=$(($RANDOM % $WORD_COUNT))
   TERM3=${words[$IX]}

   # generate the search from the template
   cat $query | $SED_TOOL -e "s/_TERM1_/$TERM1/g" | $SED_TOOL -e "s/_TERM2_/$TERM2/g" | $SED_TOOL -e "s/_TERM3_/$TERM3/g" > $QUERY_FILE

   log "Request $COUNTER of $ITERATIONS: ($(cat $QUERY_FILE))"

   # issue the search
   $SCRIPT_DIR/issue-solr-search.ksh $endpoint $QUERY_FILE $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$res issuing search, aborting"
   fi

   # summerize the results
   #if [ "$walkresults" == "no" ]; then
      $SCRIPT_DIR/summerize-solr-response.ksh $RESPONSE_FILE
      res=$?
   #else
   #   $SCRIPT_DIR/walk-solr-response.ksh $RESPONSE_FILE $QUERY_FILE
   #   res=$?
   #fi
   if [ $res -ne 0 ]; then
      error_and_exit "$res processing results, aborting"
   fi
   
done

# test end time
ETIME=$(python -c 'import time; print time.time()')

# remove the working files
rm $QUERY_FILE > /dev/null 2>&1
rm $RESPONSE_FILE > /dev/null 2>&1

# calculate and show total time
ELAPSED=$(echo "$ETIME - $STIME" | bc)
log "Total test time $ELAPSED seconds"

log "Exiting normally"
exit 0

#
# end of file
#
