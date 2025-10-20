#!/bin/bash
# usage: bash bash/make_csv.sh <start_date> <start_time> <end_date> <end_time> <path/of/output/file>

#------------------------NOTE--------------------------
# POSIX compliant character classes ([[:alnum:]], [[:space:]], etc.)
# are used because for cross compatibility between operating systems
# Also, an attempt has been made to keep the regular expressions specific,
# so they are a bit hard to read

FILE_IN="uploads/input_file"
FILE_OUT="$5"

APACHE_AWK="bash/apache.awk"
ANDROID_AWK="bash/android.awk"
ANDROID_EVENTS="bash/android.events"
SYSTEM_AWK="bash/system.awk"
SYSTEM_EVENTS="bash/system.events"

SDATE="$1"
STIME="$2"
EDATE="$3"
ETIME="$4"

# preprocessing: remove return carriage and empty lines
sed -E '
s/\r//g
/^[[:space:]]*$/N;s/\n//
' "$FILE_IN" > "${FILE_OUT}tmp"

# APACHE
# check if all lines are of the required format
if gawk '!/^\[([^]]+)\][[:space:]]+\[([^]]+)\][[:space:]]+(.+)$/{exit 1}' "${FILE_OUT}tmp";then
    echo "apache"
    sed -E '
    s/^\[([^]]+)\][[:space:]]+\[([^]]+)\][[:space:]]+(.+)$/\1,\2,\3/
    ' "${FILE_OUT}tmp" > "$FILE_OUT"

    gawk -v SDATE="$SDATE" -v STIME="$STIME" -v EDATE="$EDATE" -v ETIME="$ETIME" -f "$APACHE_AWK" "$FILE_OUT" > "${FILE_OUT}tmp"
    mv "${FILE_OUT}tmp" "$FILE_OUT"

# ANDROID
# check if all lines are of the required format
elif gawk '!/^([0-9]{2}-[0-9]{2})[[:space:]]+([0-9:\.]*)[[:space:]]+([0-9]*)[[:space:]]+([0-9]*)[[:space:]]+([A-Z])[[:space:]]+([^:]*):[[:space:]]+(.*)$/{exit 1}' "${FILE_OUT}tmp";then
    echo "android"

    # '%' is not a character in the log file, so is used as a temporary
    # field separator before passing the file to AWK
    sed -E '
    s/^([0-9]{2}-[0-9]{2})[[:space:]]+([0-9:\.]*)[[:space:]]+([0-9]*)[[:space:]]+([0-9]*)[[:space:]]+([A-Z])[[:space:]]+([^:]*):[[:space:]]+(.*)$/\1%\2%\3%\4%\5%\6%\7/
    ' "${FILE_OUT}tmp" > "$FILE_OUT"
    
    gawk -v SDATE="$SDATE" -v STIME="$STIME" -v EDATE="$EDATE" -v ETIME="$ETIME" -f "$ANDROID_AWK" "$ANDROID_EVENTS" "$FILE_OUT" > "${FILE_OUT}tmp"

    mv "${FILE_OUT}tmp" "$FILE_OUT"

# SYSTEM
# check if all lines are of the required format
elif gawk '!/^([[:alnum:]]{3})[[:space:]]+([[:digit:]]+)[[:space:]]+(.{8})[[:space:]]+([[:alnum:]]+)[[:space:]]+([^:]+):[[:space:]]+(.*)$/{exit 1}' "${FILE_OUT}tmp";then
    echo "system"

    # '%' is not a character in the log file, so is used as a temporary
    # field separator before passing the file to AWK
    # Second and third lines in this SED command parse the component and the PID
    # which in the format - "component[PID]:", where [PID] may be present or not
    sed -E '
    s/^([[:alnum:]]{3})[[:space:]]+([[:digit:]]+)[[:space:]]+(.{8})[[:space:]]+([[:alnum:]]+)[[:space:]]+([^:]+:)[[:space:]]+(.*[[:graph:]])[[:space:]]*$/\1%\2%\3%\4%\5%\6/
    /\[.*\]:/!s/([^%]+)%([^%]+)%([^%]+)%([^%]+)%([^%:]+):%([^%]+)/\1%\2%\3%\4%\5%%\6/
    /\[.*\]:/s/([^%]+)%([^%]+)%([^%]+)%([^%]+)%([^[%]+)\[(.*)\]:%([^%]+)/\1%\2%\3%\4%\5%\6%\7/
    ' "${FILE_OUT}tmp" > "$FILE_OUT"
    
    gawk -v SDATE="$SDATE" -v STIME="$STIME" -v EDATE="$EDATE" -v ETIME="$ETIME" -f "$SYSTEM_AWK" "$SYSTEM_EVENTS" "$FILE_OUT" > "${FILE_OUT}tmp"

    mv "${FILE_OUT}tmp" "$FILE_OUT"

else
    echo "Error"

fi
