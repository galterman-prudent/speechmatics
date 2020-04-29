#!/bin/sh

# This script POSTS files to the local Batch VA
# and will check the job status until done.
# It will then fetch the transcription files.

# Define variables
SPLUNK_HOME="/opt/splunk"
URL="http://18.208.2.242:8082/v1/user/1/jobs/"
STATUSURL="http://18.208.2.242:8082/v1/user/1/jobs"
WATCHDIR="${SPLUNK_HOME}/etc/apps/TA-prudent_speechmatics/data/Watchfolder"
SOURCEDIR="${SPLUNK_HOME}/etc/apps/TA-prudent_speechmatics/data/ToDo"
IN_PROGRESS_DIR="${SPLUNK_HOME}/etc/apps/TA-prudent_speechmatics/data/InProgress"
DONEDIR="${SPLUNK_HOME}/etc/apps/TA-prudent_speechmatics/data/Done"
OUTPUTDIR="${SPLUNK_HOME}/etc/apps/TA-prudent_speechmatics/data/Output"
USER=splunk

# ------------------------------------------------------------------------------
# Perform the transcription
# ------------------------------------------------------------------------------
echo "Taking the top file from the source directory"

FILE=$(find ${SOURCEDIR} -maxdepth 1 -iregex '.*\.\(mp3\|wav\|mp4\|mov\)' -printf '%f\n' | head -1)

if [ -z "${FILE}" ] ; then
    echo "No more files found, this script will now terminate."
    exit
fi

# Move the audio file to the "in-progress" folder
mv ${SOURCEDIR}/${FILE} ${IN_PROGRESS_DIR}/${FILE}

JOBID=$(curl -L -X POST $URL \
   -F data_file="@${IN_PROGRESS_DIR}/${FILE}" \
   -F config="$(cat ${WATCHDIR}/Config/config.json)" \
        | /bin/jq -r .id )

echo ${FILE} > ${IN_PROGRESS_DIR}/${JOBID}.done




