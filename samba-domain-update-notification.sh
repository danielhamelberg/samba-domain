#!/bin/bash
##And the following script keeps track of when new images are posted to hub.docker.com.##

DATAPATH='/data/docker/updater/data'

if [ ! -d "${DATAPATH}" ]; then
        mkdir "${DATAPATH}";
fi
IMAGES=$(docker ps --format "{{.Image}}")
for IMAGE in $IMAGES; do
        ORIGIMAGE=${IMAGE}
        if [[ "$IMAGE" != *\/* ]]; then
                IMAGE=library/${IMAGE}
        fi
        IMAGE=${IMAGE%%:*}
        echo "Checking ${IMAGE}"
        PARSED=${IMAGE//\//.}
        if [ ! -f "${DATAPATH}/${PARSED}" ]; then
                # File doesn't exist yet, make baseline
                echo "Setting baseline for ${IMAGE}"
                curl -s "https://registry.hub.docker.com/v2/repositories/${IMAGE}/tags/" > "${DATAPATH}/${PARSED}"
        else
                # File does exist, do a compare
                NEW=$(curl -s "https://registry.hub.docker.com/v2/repositories/${IMAGE}/tags/")
                OLD=$(cat "${DATAPATH}/${PARSED}")
                if [[ "${OLD}" == "${NEW}" ]]; then
                        echo "Image ${IMAGE} is up to date";
                else
                        echo ${NEW} > "${DATAPATH}/${PARSED}"
                        echo "Image ${IMAGE} needs to be updated";
                        H=`hostname`
                        ssh -i /data/keys/<KEYFILE> <USER>@<REMOTEHOST>.com "{ echo \"MAIL FROM: root@${H}\"; echo \"RCPT TO: <USER>@<EMAILHOST>.com\"; echo \"DATA\"; echo \"Subject: ${H} - ${IMAGE} needs update\"; echo \"\"; echo -e \"\n${IMAGE} needs update.\n\ndocker pull ${ORIGIMAGE}\"; echo \"\"; echo \".\"; echo \"quit\"; sleep 1; } | telnet <SMTPHOST> 25"
                fi

        fi
done;
