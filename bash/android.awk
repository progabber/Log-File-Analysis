BEGIN{
    print "LineId,Date,Time,Pid,Tid,Level,Component,Content,EventId,EventTemplate"
    FS = "%"
    OFS = ","

    # when year is not required, use 2020 as the default year
    # for using mktime() (2020 is a leap year so Feb 29 will
    # be handled)
    YEAR_EPOCH = mktime("2020 01 01 00 00 00") # start of year

    split(SDATE, sdate, "-")
    split(STIME, STIME_, ".")
    split(STIME_[1], stime, ":")

    # time from start of year
    START_TIME = 1000*(mktime("2020 " sdate[2] " " sdate[3] " " stime[1] " " stime[2] " " stime[3]) - YEAR_EPOCH) + STIME_[2]

    split(EDATE, edate, "-")
    split(ETIME, ETIME_, ".")
    split(ETIME_[1], etime, ":")

    # time from start of year
    END_TIME = 1000*(mktime("2020 " edate[2] " " edate[3] " " etime[1] " " etime[2] " " etime[3]) - YEAR_EPOCH) + ETIME_[2]
}


# Process the .events file first
FNR == NR{
    match($0, /([^']*)'([^']*)'(.*)/, arr)
    regex[arr[1]] = arr[2]
    templates[arr[1]] = arr[3]
}

# Custom comparator for array traversal
function cmp(index_1, value_1, index_2, value_2){
    # Normally, to compare bw E_i, E_j;
    # check i, j; except (132, 133) and (165, 166)
    number_1 = substr(index_1, 2)
    number_2 = substr(index_2, 2)
    if (number_1 == 165 && number_2 == 166) {
        return 1
    }
    else if (number_1 == 166 && number_2 == 165) {
        return -1
    }
    else if (number_1 == 132 && number_2 == 133) {
        return 1
    }
    else if (number_1 == 133 && number_2 == 132) {
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
            split($1, date_parts, "-") # [%m, %d]
            split($2, time_parts, ".") # [%H:%M:%S, %s]
            split(time_parts[1], time_clock, ":") # [%H, %M, %S]

            EPOCH = mktime("2020 " date_parts[1] " " date_parts[2] " " time_clock[1] " " time_clock[2] " " time_clock[3])

            EPOCH -= YEAR_EPOCH # time from start of the year
            EPOCH = EPOCH*1000 + time_parts[2] # add milliseconds too

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


