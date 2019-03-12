#!/bin/bash

##This script loops through running containers and sends you an email when security updates are required.##

function needsUpdates() {
        RESULT=$(docker exec ${1} bash -c ' \
                if [[ -f /etc/apt/sources.list ]]; then \
                grep security /etc/apt/sources.list > /tmp/security.list; \
                apt-get update > /dev/null; \
                apt-get upgrade -oDir::Etc::Sourcelist=/tmp/security.list -s; \
                fi; \
                ')
        RESULT=$(echo $RESULT)
        GOODRESULT="Reading package lists... Building dependency tree... Reading state information... Calculating upgrade... 0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded."
        if [[ "${RESULT}" != "" ]] && [[ "${RESULT}" != "${GOODRESULT}" ]]; then
                return 0
        else
                return 1
        fi
}

function sendEmail() {
        echo "Container ${1} needs security updates";
        H=`hostname`
        ssh -i /data/keys/<KEYFILE> <USRER>@<REMOTEHOST>.com "{ echo \"MAIL FROM: root@${H}\"; echo \"RCPT TO: <USER>@<EMAILHOST>.com\"; echo \"DATA\"; echo \"Subject: ${H} - ${1} container needs security update\"; echo \"\"; echo -e \"\n${1} container needs update.\n\n\"; echo -e \"docker exec ${1} bash -c 'grep security /etc/apt/sources.list > /tmp/security.list; apt-get update > /dev/null; apt-get upgrade -oDir::Etc::Sourcelist=/tmp/security.list -s'\n\n\"; echo \"Remove the -s to run the update\"; echo \"\"; echo \".\"; echo \"quit\"; sleep 1; } | telnet <SMTPHOST> 25"
}

CONTAINERS=$(docker ps --format "{{.Names}}")
for CONTAINER in $CONTAINERS; do
        echo "Checking ${CONTAINER}"
        if needsUpdates $CONTAINER; then
                sendEmail $CONTAINER
        fi
done
