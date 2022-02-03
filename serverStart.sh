#!/bin/bash

# Copyright (c) 2022 Synopsys, Inc. All rights reserved worldwide.

for i in "$@"; do
    case "$i" in
        --startCmd=*) startCmd="${i#*=}" ;;
        --startedString=*) startedString="${i#*=}" ;;
        --project=*) project="${i#*=}" ;;
        --workingDir=*) workingDir="${i#*=}" ;;
    esac
done

if [ -z "$startCmd" ]; then
    echo "You must specify startCmd"
    echo "Usage: serverStart.sh --startCmd=COMMAND_TO_START_SERVER --startedString=SERVER_STARTED_MESSAGE --project=PROJECT --workingDir=WORKING_DIR"
    exit 1
fi

if [ -z "$startedString" ]; then
    echo "You must specify startedString"
    echo "Usage: serverStart.sh --startCmd=COMMAND_TO_START_SERVER --startedString=SERVER_STARTED_MESSAGE --project=PROJECT --workingDir=WORKING_DIR"
    exit 1
fi

if [ -z "$project" ]; then
    echo "You must specify project"
    echo "Usage: serverStart.sh --startCmd=COMMAND_TO_START_SERVER --startedString=SERVER_STARTED_MESSAGE --project=PROJECT --workingDir=WORKING_DIR"
    exit 1
fi

if [ $workingDir ]; then
    cd $workingDir
fi

output=$(mktemp /tmp/$project.XXX)
sh -c "$startCmd" &>$output &
serverPID=$!

wait_server "$output" "$startedString" 1m && \
echo -e "\n-------------------------- Server READY --------------------------\n"

if [ $workingDir ]; then
    cd -
fi

echo $serverPID

wait_str() {
    local file="$1"; shift
    local search_term="$1"; shift
    local wait_time="${1:-5m}"; shift # 5 minutes as default timeout

    (timeout $wait_time tail -F -n0 "$file" &) | grep -q "$search_term" && return 0

    echo "Timeout of $wait_time reached. Unable to find '$search_term' in '$file'"
    return 1
}

wait_server() {
    echo "Waiting for server..."
    local server_log="$1"; shift
    local started_text="$1"; shift
    local wait_time="$1"; shift

    wait_file "$server_log" 10 || { echo "Server log file missing: '$server_log'"; return 1; }

    wait_str "$server_log" "[INFO] Started Jetty Server" "$wait_time"
}

wait_file() {
    local file="$1"; shift
    local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout

    until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done

    ((++wait_seconds))
}

exit 0
