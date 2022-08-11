#!/usr/bin/env bash
#
# script to issue a series of item searches.
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

# our temp item file
ITEMLIST_FILE=/tmp/words.$$
rm $ITEMLIST_FILE >/dev/null 2>&1

# ensure we have the tools available
SED_TOOL=sed
ensure_tool_available $SED_TOOL
SHUF_TOOL=$SHUF
ensure_tool_available $SHUF_TOOL

# get our parameters
endpoint=$(get_config "endpoint" $CONFIG_FILE required)
auth=$(get_config "auth" $CONFIG_FILE required)
idlist=$(get_config "idlist" $CONFIG_FILE required)

# ensure id list source exists
if [ ! -f $idlist ]; then
   error_and_exit "$idlist does not exist or is not readable"
   exit 1
fi

# generate the test id file we will use
log "Generating ids..."
cat $idlist | $SHUF_TOOL | head -$ITERATIONS > $ITEMLIST_FILE
IFS=$'\n' read -d '' -r -a items < $ITEMLIST_FILE
rm $ITEMLIST_FILE > /dev/null 2>&1

# generate the authentication token
log "Getting authentication token..."
authtoken=$($SCRIPT_DIR/get-auth-token.ksh $auth)

# temp files
RESPONSE_FILE=/tmp/response.$$

# our progress counter
COUNTER=0

# test start time
TSTART=$($SCRIPT_DIR/get-timestamp.ksh)

# go through the word list and issue a new search for each one
while [ $COUNTER -lt $ITERATIONS ]; do

   COUNTER=$(($COUNTER + 1 ))

   IX=$(($RANDOM % $ITERATIONS))
   ID=${items[$IX]}

   log "Request $COUNTER of $ITERATIONS: (id: $ID)"

   # issue the search
   $SCRIPT_DIR/issue-api-item.ksh $endpoint $authtoken $ID $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$res issuing search, aborting"
   fi

   # summerize the results
   #if [ "$walkresults" == "no" ]; then
   #   $SCRIPT_DIR/summerize-pool-response.ksh $RESPONSE_FILE
   #   res=$?
   #else
   #   $SCRIPT_DIR/walk-pool-response.ksh $RESPONSE_FILE $PAYLOAD_FILE
   #   res=$?
   #fi
   #cat $RESPONSE_FILE

   #cp $RESPONSE_FILE tmp/$ID.json

   #if [ $res -ne 0 ]; then
   #   error_and_exit "$res processing results, aborting"
   #fi
   
done

# test end time
TEND=$($SCRIPT_DIR/get-timestamp.ksh)

# remove the working files
rm $RESPONSE_FILE > /dev/null 2>&1

# calculate and show total time
ELAPSED=$(echo "$TEND - $TSTART" | bc)
log "Total test time $ELAPSED seconds"

log "Exiting normally"
exit 0

#
# end of file
#
