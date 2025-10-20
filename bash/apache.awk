BEGIN{
    print "LineId,Time,Level,Content,EventId,EventTemplate"
    FS = ","
    OFS = ","
    e1 = "jk2_init() Found child <*> in scoreboard slot <*>"
    e2 = "workerEnv.init() ok <*>"
    e3 = "mod_jk child workerEnv in error state <*>"
    e4 = "[client <*>] Directory index forbidden by rule: <*>"
    e5 = "jk2_init() Can't find child <*> in scoreboard"
    e6 = "mod_jk child init <*> <*>"

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

    # Indicator if field matched to an event
    unmatched = 1

    split(SDATE, sdate, "-")
    split(STIME, STIME_, ".")
    split(STIME_[1], stime, ":")

    # User input
    START_TIME = mktime(sdate[1] " " sdate[2] " " sdate[3] " " stime[1] " " stime[2] " " stime[3])

    split(EDATE, edate, "-")
    split(ETIME, ETIME_, ".")
    split(ETIME_[1], etime, ":")

    # User input
    END_TIME = mktime(edate[1] " " edate[2] " " edate[3] " " etime[1] " " etime[2] " " etime[3])
}

/^.*,.*,jk2_init\(\) Found child .* in scoreboard slot .*$/{
    unmatched = 0
    split($1, arr, " ")
    split(arr[4], hms, ":")
    EPOCH = mktime(arr[5] " " month[arr[2]] " " arr[3] " " hms[1] " " hms[2] " " hms[3])

    if(START_TIME <= EPOCH && EPOCH <= END_TIME){
        printf("%d,%s,E1,%s\n", NR, $0, e1)
    }
} 

/^.*,.*,workerEnv\.init\(\) ok .*$/{
    unmatched = 0
    split($1, arr, " ")
    split(arr[4], hms, ":")
    EPOCH = mktime(arr[5] " " month[arr[2]] " " arr[3] " " hms[1] " " hms[2] " " hms[3])
    
    if(START_TIME <= EPOCH && EPOCH <= END_TIME){
        printf("%d,%s,E2,%s\n", NR, $0, e2)
    }
} 

/^.*,.*,mod_jk child workerEnv in error state .*$/{
    unmatched = 0
    split($1, arr, " ")
    split(arr[4], hms, ":")
    EPOCH = mktime(arr[5] " " month[arr[2]] " " arr[3] " " hms[1] " " hms[2] " " hms[3])

    if(START_TIME <= EPOCH && EPOCH <= END_TIME){
        printf("%d,%s,E3,%s\n", NR, $0, e3)
    }
} 

/^.*,.*,\[client .*\] Directory index forbidden by rule: .*$/{
    unmatched = 0
    split($1, arr, " ")
    split(arr[4], hms, ":")
    EPOCH = mktime(arr[5] " " month[arr[2]] " " arr[3] " " hms[1] " " hms[2] " " hms[3])

    if(START_TIME <= EPOCH && EPOCH <= END_TIME){
        printf("%d,%s,E4,%s\n", NR, $0, e4)
    }
}

/^.*,.*,jk2_init\(\) Can't find child .* in scoreboard$/{
    unmatched = 0
    split($1, arr, " ")
    split(arr[4], hms, ":")
    EPOCH = mktime(arr[5] " " month[arr[2]] " " arr[3] " " hms[1] " " hms[2] " " hms[3])

    if(START_TIME <= EPOCH && EPOCH <= END_TIME){
        printf("%d,%s,E5,%s\n", NR, $0, e5)
    }
}

/^.*,.*,mod_jk child init .* .*$/{
    unmatched = 0
    split($1, arr, " ")
    split(arr[4], hms, ":")
    EPOCH = mktime(arr[5] " " month[arr[2]] " " arr[3] " " hms[1] " " hms[2] " " hms[3])

    if(START_TIME <= EPOCH && EPOCH <= END_TIME){
        printf("%d,%s,E6,%s\n", NR, $0, e6)
    }
}

{
    # if no event was mapped to the entry, 
    # leave the EventId and EventTemplate fields blank
    if(unmatched){
        printf("%d,%s,,\n", NR, $0)
    }
}
