#!/usr/bin/env bash
#
# script to issue a series of api requests.
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

# our temp user file
USERLIST_FILE1=/tmp/users1.$$
rm $USERLIST_FILE1 >/dev/null 2>&1
USERLIST_FILE2=/tmp/users2.$$
rm $USERLIST_FILE2 >/dev/null 2>&1

# ensure we have the tools available
SED_TOOL=sed
ensure_tool_available $SED_TOOL
SHUF_TOOL=$SHUF
ensure_tool_available $SHUF_TOOL

# get our parameters
endpoint=$(get_config "endpoint" $CONFIG_FILE required)
auth=$(get_config "auth" $CONFIG_FILE required)
template=$(get_config "template" $CONFIG_FILE required)
userlist=$(get_config "userlist" $CONFIG_FILE required)

# ensure userlist source exists
if [ ! -f $userlist ]; then
   error_and_exit "$userlist does not exist or is not readable"
   exit 1
fi

# generate the test userlist file we will use
log "Generating userlist..."
USERCOUNT=$(wc -l $userlist | awk '{print $1}')
TIMES=$(( ($ITERATIONS / $USERCOUNT) + 1))
echo $TIMES
for i in $(seq $TIMES); do
   cat $userlist >> $USERLIST_FILE1
done
cat $USERLIST_FILE1 | $SHUF_TOOL | head -$ITERATIONS > $USERLIST_FILE2
IFS=$'\n' read -d '' -r -a users < $USERLIST_FILE2
rm $USERLIST_FILE1 > /dev/null 2>&1
rm $USERLIST_FILE2 > /dev/null 2>&1

# generate the authentication token
log "Getting authentication token..."
authtoken=$($SCRIPT_DIR/get-auth-token.ksh $auth)

# temp files
RESPONSE_FILE=/tmp/response.$$

# our progress counter
COUNTER=0

# test start time
STIME=$(python3 -c 'import time; print( time.time())')

# go through the word list and issue a new search for each one
while [ $COUNTER -lt $ITERATIONS ]; do

   COUNTER=$(($COUNTER + 1 ))

   IX=$(($RANDOM % $ITERATIONS))
   USER=${users[$IX]}

   # generate the search from the template
   TEMPLATE=$(echo $template | $SED_TOOL -e "s/_USER_/$USER/g")

   API=$endpoint/$TEMPLATE
   log "Call $COUNTER of $ITERATIONS: ($(echo $API))"

   # issue the search
   $SCRIPT_DIR/issue-api-call.ksh $API $authtoken $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$res issuing call, aborting"
   fi

   # summerize the results
   #if [ "$walkresults" == "no" ]; then
   #   $SCRIPT_DIR/summerize-master-response.ksh $RESPONSE_FILE
   #   res=$?
   #else
   #   $SCRIPT_DIR/walk-master-response.ksh $RESPONSE_FILE
   #   res=$?
   #fi
   #if [ $res -ne 0 ]; then
   #   error_and_exit "$res processing results, aborting"
   #fi
   
done

# test end time
ETIME=$(python3 -c 'import time; print( time.time())')

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
