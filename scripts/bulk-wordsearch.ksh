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

# input parameters for clarity
CONFIG_FILE=$1
ITERATIONS=$2

# ensure the config file exists
if [ ! -f $CONFIG_FILE ]; then
   echo "ERROR: $CONFIG_FILE does not exist or is not readable" >&2
   exit 1
fi

# our temp wordlist file
WORDLIST_FILE=/tmp/words.$$
rm $WORDLIST_FILE >/dev/null 2>&1

# ensure we have the tools available
SED_TOOL=sed
ensure_tool_available $SED_TOOL

# get our parameters
endpoint=$(get_config "endpoint" $CONFIG_FILE required)
payload=$(get_config "payload" $CONFIG_FILE required)
wordlist=$(get_config "wordlist" $CONFIG_FILE required)
rewrite=$(get_config "rewrite" $CONFIG_FILE required)

# ensure payload template exists
if [ ! -f $payload ]; then
   echo "ERROR: $payload does not exist or is not readable" >&2
   exit 1
fi

# ensure wordlist source exists
if [ ! -f $wordlist ]; then
   echo "ERROR: $wordlist does not exist or is not readable" >&2
   exit 1
fi

# generate the test wordlist file we will use
echo "Generating test words..."
cat $wordlist | sort -R | head -$ITERATIONS > $WORDLIST_FILE

# temp files
PAYLOAD_FILE=/tmp/payload.$$
RESPONSE_FILE=/tmp/response.$$

# our progress counter
COUNTER=0

# go through the word list and issue a new search for each one
for word in $(<$WORDLIST_FILE); do

   COUNTER=$((COUNTER + 1 ))

   # generate the search from the template
   cat $payload | $SED_TOOL -e "s/$rewrite/$word/g" > $PAYLOAD_FILE

   echo -n "Search $COUNTER of $ITERATIONS: "

   # issue the search
   $SCRIPT_DIR/issue-search.ksh $endpoint $PAYLOAD_FILE $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$res issuing search, aborting test"
   fi

   # summerize the results
   $SCRIPT_DIR/summerize-master-response.ksh $RESPONSE_FILE
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$res processing results, aborting test"
   fi
   
done

# remove the working files
rm $PAYLOAD_FILE
rm $RESPONSE_FILE
rm $WORDLIST_FILE

echo "Existing normally"
exit 0

#
# end of file
#
