BEGIN{
    print "LineId,Month,Date,Time,Level,Component,PID,Content,EventId,EventTemplate"
    FS = "%"
    OFS = ","

    month["Jan"] = "01"
    month["Feb"] = "02"
    month["Mar"] = "03"
    month["Apr"] = "04"
    month["May"] = "05"
    month["Jun"] = "06"
    month["Jul"] = "07"
    month["Aug"] = "08"
    month["Sep"] = "09"
    month["Oct"] = "10"
    month["Nov"] = "11"
    month["Dec"] = "12"

    # when year is not required, use 2020 as the default year
    # for using mktime() (2020 is a leap year so Feb 29 will
    # be handled)
    YEAR_EPOCH = mktime("2020 01 01 00 00 00") # start of year

    split(SDATE, sdate, "-")
    split(STIME, STIME_, ".")
    split(STIME_[1], stime, ":")

    # time from start of year
    START_TIME = mktime("2020 " sdate[2] " " sdate[3] " " stime[1] " " stime[2] " " stime[3]) - YEAR_EPOCH

    split(EDATE, edate, "-")
    split(ETIME, ETIME_, ".")
    split(ETIME_[1], etime, ":")

    # time from start of year
    END_TIME = mktime("2020 " edate[2] " " edate[3] " " etime[1] " " etime[2] " " etime[3]) - YEAR_EPOCH
}

# Process the .events file first
FNR == NR{
    match($0, /([^%]*)%([^%]*)%(.*)/, arr)
    regex[arr[1]] = arr[3]
    templates[arr[1]] = arr[2]
}

# custom comparator for array traversal
function cmp(index_1, value_1, index_2, value_2){
    # Normally, to compare bw E_i, E_j;
    # check i, j; except (79, 80) & (16, 17-19)
    number_1 = substr(index_1, 2)
    number_2 = substr(index_2, 2)
    if (number_1 == 79 && number_2 == 80) {
        return 1
    }
    else if (number_1 == 80 && number_2 == 79) {
        return -1
    }
    else if (number_1 == 16 && 17 <= number_2 && number_2 <= 19) {
        return 1
    }
    else if (17 <= number_1 && number_1 <= 19 && number_2 == 16) {
        return -1
    }
    return (number_1 - number_2)
}

# Process the logs now
FNR != NR{
    # Indicator if field matched to an event
    unmatched = 1

    # setting comparator for array (regex) traversal
    PROCINFO["sorted_in"] = "cmp"
    for (event in regex){
        match($7, regex[event], matched_str)

        # if there is a match
        if(matched_str[0] != "" ){
            # parse dates
            date_parts[1] = month[$1] # %m
            date_parts[2] = $2 # %d
            if (length($2) == 1) date_parts[1] = "0" date_parts[1]
            split($3, time_clock, ":") # [%H, %M, %S]

            EPOCH = mktime("2020 " date_parts[1] " " date_parts[2] " " time_clock[1] " " time_clock[2] " " time_clock[3])

            EPOCH -= YEAR_EPOCH # time from start of the year

            if(START_TIME <= EPOCH && EPOCH <= END_TIME){
                # handle CSV if comma is in between a field 
                gsub(/"/, "\"\"", $7)
                if ($7 ~ /,|"/) {
                    $7 = "\"" $7 "\""
                }

                event_template = templates[event]
                gsub(/"/, "\"\"", event_template)
                if (event_template ~ /,|"/){
                    event_template = "\"" event_template "\""
                }

                print FNR "," $1,$2,$3,$4,$5,$6,$7 "," event "," event_template
            }
            unmatched = 0
            break
        }
    }

    # if no event was mapped to the entry, 
    # leave the EventId and EventTemplate fields blank
    if(unmatched){
        gsub(/"/, "\"\"", $7)
        if ($7 ~ /,|"/) {
            $7 = "\"" $7 "\""
        }
        print FNR "," $1,$2,$3,$4,$5,$6,$7 ",,"
    }
}


