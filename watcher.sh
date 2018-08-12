#!/bin/sh
#
# Version 1.1
# Copyright Heroes Share
# https://heroesshare.net
#

trap cleanup 1 2 3 6
cleanup() {
  echo "[`date`] Caught termination signal... shutting down" | tee -a "$logfile"
  rm -f "$pidfile"
  exit 0
}

appdir="/Library/Application Support/Heroes Share"
parser="$appdir/heroprotocol/rejoinprotocol.py"
pidfile="$appdir/watcher.pid"
logfile="$appdir/watcher.log"

tmpdir="/private/var/folders"
replayfile=""
rejoinfile=""

randid=`/usr/bin/openssl rand -hex 12`

# make sure application directory exists
if [ ! -d "$appdir" ]; then
	echo "[`date`] Application directory missing: '$appdir'. Quitting." | tee -a "$logfile"
	exit 1
fi
# make sure parser exists
if [ ! -f "$parser" ]; then
	echo "[`date`] Parsing protocol missing: '$parser'. Quitting." | tee -a "$logfile"
	exit 2
fi
# make sure parser is executable
if [ ! -x "$parser" ]; then
	echo "[`date`] Parsing protocol invalid: '$parser'. Quitting." | tee -a "$logfile"
	exit 3
fi

# record the process ID
echo $$ > "$pidfile"
echo "[`date`] Launching with process ID $$..." | tee -a "$logfile"

# check for lastmatch file
if [ ! -f "$appdir/lastmatch" ]; then
	echo "[`date`] Last match file missing; creating a fresh copy" | tee -a "$logfile"
	/usr/bin/touch "$appdir/lastmatch"
fi

# main process loop
while true; do
	# look for any new BattleLobby files and grab the latest one
	replayfile=`/usr/bin/find "$tmpdir" -name replay.server.battlelobby -newer "$appdir/lastmatch" 2> /dev/null | sort -n | tail -n 1`

	# if there was a match, cURL it to the server
	if [ "$replayfile" ]; then
		echo "[`date`] Detected new battle lobby file: $replayfile" | tee -a "$logfile"

		# update status
		/usr/bin/touch "$appdir/lastmatch"
	
		# get hash to check if it has been uploaded
		hash=`/sbin/md5 -q "$replayfile"`
		result=`/usr/bin/curl --silent https://heroesshare.net/lives/check/$hash`
		if [ ! "$result" ]; then
			printf "[`date`] Uploading replay file with hash $hash... " | tee -a "$logfile"
			/usr/bin/curl --form "randid=$randid" --form "upload=@$replayfile" https://heroesshare.net/lives/battlelobby  | tee -a "$logfile"

			# audible notification when complete
			/usr/bin/afplay "/System/Library/Sounds/Hero.aiff"
			
			# get username from file owner
			username=`/usr/bin/stat -f %Su "$replayfile"`
			userhome=`eval echo ~$username`
			targetdir="$userhome/Library/Application Support/Blizzard/Heroes of the Storm/Accounts"
			
			# watch for new rejoin file - should be about 1 minute but wait up to 5
			i=0
			while [ $i -lt 60 ]; do
				rejoinfile=`/usr/bin/find "$targetdir" -name *.StormSave -newer "$appdir/lastrun" 2> /dev/null | sort -n | tail -n 1`

				# if there was a match, cURL it to the server
				if [ "$rejoinfile" ]; then
					echo "[`date`] Detected new rejoin file: $rejoinfile" | tee -a "$logfile"
					
					# grab a temp file
					tmpfile=`mktemp`
					parseflag=""
					
					# parse details from the file
					"$parser" --details --json "$rejoinfile" > "$tmpfile"
					if [ $? -eq 0 ]; then
						printf "[`date`] Uploading details file... " | tee -a "$logfile"		
						/usr/bin/curl --form "randid=$randid" --form "upload=@$tmpfile" https://heroesshare.net/lives/details  | tee -a "$logfile"
						
					else
						echo "[`date`] Unable to parse details from rejoin file" | tee -a "$logfile"	
						parseflag=1
					fi
					
					# parse attribute events from the file
					"$parser" --attributeevents --json "$rejoinfile" > "$tmpfile"
					if [ $? -eq 0 ]; then
						printf "[`date`] Uploading attributes file... " | tee -a "$logfile"		
						/usr/bin/curl --form "randid=$randid" --form "upload=@$tmpfile" https://heroesshare.net/lives/events  | tee -a "$logfile"
					
					else
						echo "[`date`] Unable to parse events from rejoin file" | tee -a "$logfile"	

						# audible notification of failure
						/usr/bin/afplay "/System/Library/Sounds/Purr.aiff"
					fi
					
					# parse init data from the file
					"$parser" --initdata --json "$rejoinfile" > "$tmpfile"
					if [ $? -eq 0 ]; then
						printf "[`date`] Uploading init data file... " | tee -a "$logfile"		
						/usr/bin/curl --form "randid=$randid" --form "upload=@$tmpfile" https://heroesshare.net/lives/initdata  | tee -a "$logfile"
					
					else
						echo "[`date`] Unable to parse init data from rejoin file" | tee -a "$logfile"	

						# audible notification of failure
						/usr/bin/afplay "/System/Library/Sounds/Purr.aiff"
					fi
					
					if [ "$parseflag" ]; then
						# audible notification of failure
						/usr/bin/afplay "/System/Library/Sounds/Purr.aiff"
					else
						# audible notification when all complete
						/usr/bin/afplay "/System/Library/Sounds/Hero.aiff"
					fi
					
					rm "$tmpfile"
					break;
				fi
				
				i=`expr $i + 1`
				sleep 5
			done
			
			# check if this was a match or a timeout
			if [ ! "$rejoinfile" ]; then
				echo "[`date`] No rejoin file found for additional upload: $targetdir" | tee -a "$logfile"	

				# audible notification of failure
				/usr/bin/afplay "/System/Library/Sounds/Purr.aiff"
			fi
			rejoinfile=""
		else
			echo "[`date`] $result" | tee -a "$logfile"
			
			# audible notification of failure
			/usr/bin/afplay "/System/Library/Sounds/Purr.aiff"
		fi
		replayfile=""
	fi
	
	# note this cycle
	/usr/bin/touch "$appdir/lastrun"
	sleep 3
done
