#!/usr/bin/env bash
#
# common helpers used by the scripting
#

# print a message and exit
function report_and_exit {

   local MESSAGE=$1
   echo $MESSAGE >&2
   exit 1
}

# print an error message and exit
function error_and_exit {

   local MESSAGE="ERROR: $1"
   report_and_exit "$MESSAGE"
}

# ensure the specific tool is available
function ensure_tool_file_available {

   local TOOL_NAME=$1
   if [ ! -x $TOOL_NAME ]; then
      error_and_exit "$TOOL_NAME is not available in this environment"
   fi
}

# ensure the specific tool is available
function ensure_tool_available {

   local TOOL_NAME=$1
   which $TOOL_NAME > /dev/null 2>&1
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$TOOL_NAME is not available in this environment"
   fi
}

# ensure the specific tool is available
function ensure_value_defined {
   
   local value_name=$1
   local value=$2
   if [ -z "$value" ]; then
      error_and_exit "value $value_name is not defined"
   fi
}

# extract a config value from the specified file
function get_config {

   local config_name=$1
   local file_name=$2
   local required=$3

   # extract the value from the file
   value=$(grep "^$config_name" $file_name | awk '{print $2}')

   if [ "$required" == "required" ]; then
      ensure_value_defined $config_name $value
   fi

   echo $value
}

# log message with a timestamp
function log {

   DS=$(date "+%Y-%m-%d% %H:%M:%S")
   echo "$DS: $*"
}

#
# end of file
#
