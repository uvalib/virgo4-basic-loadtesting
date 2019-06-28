#!/usr/bin/env bash
#
# basic scripting to drive curl for some search testing
#

# source helpers
SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/common.ksh

function help_and_exit {
   report_and_exit "use: $(basename $0) <scenario file>"
}

# ensure correct usage
if [ $# -ne 1 ]; then
   help_and_exit
fi

# common definitions
TOOL_DEFAULTS=""

# input parameters for clarity
SCENARIO_FILE=$1

if [ ! -f $SCENARIO_FILE ]; then
   echo "ERROR: $SCENARIO_FILE does not exist or is not readable" >&2
   exit 1
fi

RESULTS_FILE=$(basename $SCENARIO_FILE).results
rm $RESULTS_FILE >/dev/null 2>&1

WORDLIST_FILE=/tmp/words.$$
rm $WORDLIST_FILE >/dev/null 2>&1

# ensure we have the tools available
CURL_TOOL=curl
ensure_tool_available $CURL_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# get our parameters
endpoint=$(get_config "endpoint" $SCENARIO_FILE required)
payload=$(get_config "payload" $SCENARIO_FILE required)
wordlist=$(get_config "wordlist" $SCENARIO_FILE required)
rewrite=$(get_config "rewrite" $SCENARIO_FILE required)
iterations=$(get_config "iterations" $SCENARIO_FILE required)

# ensure payload template exists
if [ ! -f $payload ]; then
   echo "ERROR: $payload does not exist or is not readable" >&2
   exit 1
fi

# ensure wordlist exists
if [ ! -f $wordlist ]; then
   echo "ERROR: $wordlist does not exist or is not readable" >&2
   exit 1
fi

# generate the wordlist file we will test with
echo "extracting sample test words..."
cat $wordlist | sort -R | head -$iterations > $WORDLIST_FILE

TOOL_OPTIONS="-X POST -H \"Content-Type: application/json\" -H \"Accept: application/json\" -H \"Authorization: Bearer bkb4notbo1bc80d2uucg\""

# temp files
PAYLOAD_FILE=/tmp/payload.$$
RESPONSE_FILE=/tmp/response.$$
RUNNER=/tmp/runner.$$

# add the payload file
TOOL_OPTIONS="$TOOL_OPTIONS -d @$PAYLOAD_FILE"

# out progress counter
COUNTER=0

# go through the word list and issue a new search for each one
for word in $(<$WORDLIST_FILE); do

   COUNTER=$((COUNTER + 1 ))

   # generate the search from the template
   cat $payload | sed -e "s/$rewrite/$word/g" > $PAYLOAD_FILE

   # call the tool
   echo $CURL_TOOL $TOOL_DEFAULTS $TOOL_OPTIONS $endpoint > $RUNNER
   #cat $RUNNER
   chmod +x $RUNNER
   $RUNNER > $RESPONSE_FILE 2>/dev/null
   res=$?
   rm $RUNNER
   if [ $res -ne 0 ]; then
      error_and_exit "$res running $CURL_TOOL"
   fi

   QUERY=$(cat $RESPONSE_FILE | $JQ_TOOL ".request.query")
   HITS=$(cat $RESPONSE_FILE | $JQ_TOOL ".total_hits")
   TIME_MS=$(cat $RESPONSE_FILE | $JQ_TOOL ".total_time_ms")

   echo "$COUNTER of $iterations: hits=$HITS, ms=$TIME_MS, q=$QUERY"
   echo "$COUNTER of $iterations: hits=$HITS, ms=$TIME_MS, q=$QUERY" >> $RESULTS_FILE
   
done

# remove the working files
rm $PAYLOAD_FILE
rm $RESPONSE_FILE

echo "Results available in $RESULTS_FILE"
exit 0

#
# end of file
#
