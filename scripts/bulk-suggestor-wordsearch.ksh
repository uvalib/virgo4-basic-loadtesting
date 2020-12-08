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
auth=$(get_config "auth" $CONFIG_FILE required)
payload=$(get_config "payload" $CONFIG_FILE required)
wordlist=$(get_config "wordlist" $CONFIG_FILE required)

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
WORD_COUNT=$(($ITERATIONS * 3 ))
cat $wordlist | $SHUF_TOOL | head -$WORD_COUNT > $WORDLIST_FILE
IFS=$'\n' read -d '' -r -a words < $WORDLIST_FILE
rm $WORDLIST_FILE > /dev/null 2>&1

# generate the authentication token
log "Getting authentication token..."
authtoken=$($SCRIPT_DIR/get-auth-token.ksh $auth)

# temp files
PAYLOAD_FILE=/tmp/payload.$$
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
   cat $payload | $SED_TOOL -e "s/_TERM1_/$TERM1/g" | $SED_TOOL -e "s/_TERM2_/$TERM2/g" | $SED_TOOL -e "s/_TERM3_/$TERM3/g" > $PAYLOAD_FILE

   log "Request $COUNTER of $ITERATIONS: ($(cat $PAYLOAD_FILE))"

   # issue the search
   $SCRIPT_DIR/issue-api-search.ksh $endpoint $authtoken $PAYLOAD_FILE $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      echo "ERROR: issuing request (error shown above)"
      continue
   fi

   # debugging
   #cat $RESPONSE_FILE

   # summerize the results
   $SCRIPT_DIR/summerize-suggestor-response.ksh $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$res processing results, aborting"
   fi
   
done

# test end time
ETIME=$(python -c 'import time; print time.time()')

# remove the working files
rm $PAYLOAD_FILE > /dev/null 2>&1
rm $RESPONSE_FILE > /dev/null 2>&1

# calculate and show total time
ELAPSED=$(echo "$ETIME - $STIME" | bc)
log "Total test time $ELAPSED seconds"

log "Exiting normally"
exit 0

#
# end of file
#