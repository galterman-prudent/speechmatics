#!/bin/sh

# This script POSTS files to the local Batch VA
# and will check the job status until done.
# It will then fetch the transcription files.

# Define variables
SPLUNK_HOME=/opt/splunk
URL="http://18.208.2.242:8082/v1/user/1/jobs/"
STATUSURL="http://18.208.2.242:8082/v1/user/1/jobs"
WATCHDIR=$SPLUNK_HOME/etc/apps/TA-prudent_speechmatics/data/Watchfolder
SOURCEDIR=$SPLUNK_HOME/etc/apps/TA-prudent_speechmatics/data/ToDo
DONEDIR=$SPLUNK_HOME/etc/apps/TA-prudent_speechmatics/data/Done
OUTPUTDIR=$SPLUNK_HOME/etc/apps/TA-prudent_speechmatics/data/Output
USER=splunk

# ------------------------------------------------------------------------------
# Perform the transcription
# ------------------------------------------------------------------------------
echo "Taking the top file from the source directory"

FILE=$(find $SOURCEDIR -maxdepth 1 -iregex '.*\.\(mp3\|wav\|mp4\|mov\)' -printf '%f\n' | head -1)

if [ -z "$FILE" ] ; then
    echo "No more files found, this script will now terminate."
    exit
fi

JOBID=$(curl -L -X POST $URL \
   -F data_file="@$SOURCEDIR/$FILE" \
   -F config="$(cat $WATCHDIR/Config/config.json)" \
        | /bin/jq -r .id )


# ------------------------------------------------------------------------------
# Get completed job
# ------------------------------------------------------------------------------

echo "File received. The job ID is $JOBID. Now checking job status"

JOBSTATUS=""

while [ "$JOBSTATUS" != "done" ];
do
        JOBSTATUS=$(curl -s -X GET "$STATUSURL/$JOBID/" \
                | /bin/jq -r .job.job_status)
        sleep 10
done

echo "The job is done. Fetching Transcript"



# ------------------------------------------------------------------------------
# Get the completed transcription
# ------------------------------------------------------------------------------

curl -s -L -X GET "$STATUSURL/$JOBID/transcript?format=txt" \
    > $OUTPUTDIR/$FILE-$JOBID.txt
	
curl -s -L -X GET "$STATUSURL/$JOBID/transcript?format=json-v2" \
    > $OUTPUTDIR/$FILE-$JOBID.json
	
echo "Your transcription has been downloaded as txt and json. Moving media file to Done folder"


# ------------------------------------------------------------------------------
# Move the processed files to location to be picked up by monitor
# ------------------------------------------------------------------------------

mv "$SOURCEDIR/$FILE" "$DONEDIR"

echo "File moved, looking for next job"


