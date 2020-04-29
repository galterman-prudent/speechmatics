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
# Get completed jobs
# ------------------------------------------------------------------------------

echo ">>>> Begin processing all available jobs."

JOBSTATUS=""

# Get the first job from the "in-progress" area

cd ${IN_PROGRESS_DIR}
for JOBID in `find . -name \*.done | awk -F'[.]' '{print $2}' | sed "s/\///g"`
do
	# get the name of the file from the job file
	FILE=`cat ${IN_PROGRESS_DIR}/${JOBID}.done`

	echo "Checking for job [ " $JOBID " ] to be completed....."
	JOBSTATUS=$(curl -s -X GET "$STATUSURL/$JOBID/" | /bin/jq -r .job.job_status)

	# Exit if the job is not done
	if [ "$JOBSTATUS" != "done" ]
	then
		exit 1
	fi

	# The job is ready to process
	echo "The job [ " $JOBID " ] is ready to fetch. Fetching the data....."

	# ------------------------------------------------------------------------------
	# Get the completed transcription
	# ------------------------------------------------------------------------------

	curl -s -L -X GET "$STATUSURL/$JOBID/transcript?format=txt" \
	    > $OUTPUTDIR/$FILE-$JOBID.txt
	
	curl -s -L -X GET "$STATUSURL/$JOBID/transcript?format=json-v2" \
	    > $OUTPUTDIR/$FILE-$JOBID.json
	
	echo "Your transcription has been downloaded for job [ " $JOBID " ]. Moving media file to Done folder"

	# ------------------------------------------------------------------------------
	# Move the processed files to location to be picked up by monitor
	# ------------------------------------------------------------------------------

	mv ${IN_PROGRESS_DIR}/${FILE} ${DONEDIR}/${FILE}
	rm ${IN_PROGRESS_DIR}/${JOBID}.done

	# Exit for now after processing this job
	echo ">>>> Done processing all available jobs."
	exit 0
done





