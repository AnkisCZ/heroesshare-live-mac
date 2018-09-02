#!/bin/sh
#
# Build 1.2
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
lobbyfile=""
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

# get version
version=`cat "$appdir/version.txt"`

# record the process ID
echo $$ > "$pidfile"
echo "[`date`] Launching version $version with process ID $$..." | tee -a "$logfile"

# check for lastmatch file
if [ ! -f "$appdir/lastmatch" ]; then
	echo "[`date`] Last match file missing; creating a fresh copy" | tee -a "$logfile"
	/usr/bin/touch "$appdir/lastmatch"
	/usr/bin/touch "$appdir/lastrun"
fi

# main process loop
while true; do
	# look for any new BattleLobby files and grab the latest one
	lobbyfile=`/usr/bin/find "$tmpdir" -name replay.server.battlelobby -newer "$appdir/lastmatch" 2> /dev/null | sort -n | tail -n 1`

	# if there was a match, cURL it to the server
	if [ "$lobbyfile" ]; then
		echo "[`date`] Detected new battle lobby file: $lobbyfile" | tee -a "$logfile"

		# update status
		/usr/bin/touch "$appdir/lastmatch"
		# update search directory to be more specific
		tmpdir=`awk -F "/TempWriteReplay" '{print $1}' <<< "$lobbyfile"`

		# get hash to check if it has been uploaded
		uploadhash=`/sbin/md5 -q "$lobbyfile"`
		result=`/usr/bin/curl --silent https://heroesshare.net/lives/check/$uploadhash`
		if [ ! "$result" ]; then
			printf "[`date`] Uploading lobby file with hash $uploadhash... " | tee -a "$logfile"
			/usr/bin/curl --form "randid=$randid" --form "upload=@$lobbyfile" https://heroesshare.net/lives/battlelobby  | tee -a "$logfile"

			# audible notification when complete
			/usr/bin/afplay "/System/Library/Sounds/Hero.aiff"
			
			# get username from file owner
			username=`/usr/bin/stat -f %Su "$lobbyfile"`
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
						printf "[`date`] Uploading attribute events file... " | tee -a "$logfile"
						/usr/bin/curl --form "randid=$randid" --form "upload=@$tmpfile" https://heroesshare.net/lives/attributeevents  | tee -a "$logfile"
					
					else
						echo "[`date`] Unable to parse attribute events from rejoin file" | tee -a "$logfile"
						parseflag=1
					fi
					
					# parse init data from the file
					"$parser" --initdata --json "$rejoinfile" > "$tmpfile"
					if [ $? -eq 0 ]; then
						printf "[`date`] Uploading init data file... " | tee -a "$logfile"		
						/usr/bin/curl --form "randid=$randid" --form "upload=@$tmpfile" https://heroesshare.net/lives/initdata  | tee -a "$logfile"
					
					else
						echo "[`date`] Unable to parse init data from rejoin file" | tee -a "$logfile"
						parseflag=1
					fi
					
					if [ "$parseflag" ]; then
						# audible notification of failure
						/usr/bin/afplay "/System/Library/Sounds/Purr.aiff"
					else
						# audible notification when all complete
						/usr/bin/afplay "/System/Library/Sounds/Hero.aiff"
					fi
					
					# start watching for completion
					rejoinhash=""
					talentshash=""
					gameover=0
					while [ $gameover -ne 1 ]; do
						
						echo "[`date`] Begin watching for talents" | tee -a "$logfile"
						
						# if file is gone, game is over
						if [ ! -f "$rejoinfile"]; then					
							echo "[`date`] Rejoin file no longer available; completing." | tee -a "$logfile"

							gameover=1
							break
						else
							# get updated hash of rejoin file
							tmphash=`/sbin/md5 "$rejoinfile"`

							# if file didn't change, game is over
							if [ "$tmphash" != "$rejoinhash"]; then
								gameover=1
								break

							# game still going
							else
								# update last hash
								rejoinhash="$tmphash"
								
								# check for new talents
								"$parser" --gameevents --json "$rejoinfile" | grep SHeroTalentTreeSelectedEvent > "$tmpfile"
								tmphash=`/sbin/md5 "$tmpfile"`
								
								# if file changed, upload it
								if [ "$tmphash" != "$talentshash"]; then
									# update last hash
									rejoinhash="$tmphash"

									printf "[`date`] Uploading game events file... " | tee -a "$logfile"
									/usr/bin/curl --form "randid=$randid" --form "upload=@$tmpfile" https://heroesshare.net/lives/gameevents  | tee -a "$logfile"
								
								# no changes; wait a while and try again
								else
									sleep 30
								fi

							fi
						fi
					done
					
					# wait for post-game cleanup
					sleep 10
					
					# check for a new replay file
					replayfile=`/usr/bin/find "$targetdir" -name *.StormReplay -newer "$appdir/lastmatch" 2> /dev/null | sort -n | tail -n 1`

					# if there was a match, cURL it to the server
					if [ "$replayfile" ]; then
						echo "[`date`] Detected new replay file: $replayfile" | tee -a "$logfile"
						printf "[`date`] Uploading replay file to HotsApi and HotsLogs... " | tee -a "$logfile"
						/usr/bin/curl --form "file=@$replayfile" http://hotsapi.net/api/v1/upload?uploadToHotslogs=1  | tee -a "$logfile"
						
						# audible notification when complete
						/usr/bin/afplay "/System/Library/Sounds/Hero.aiff"
					else
						echo "[`date`] Unable to locate replay file for recent live game!" | tee -a "$logfile"
						/usr/bin/afplay "/System/Library/Sounds/Purr.aiff"
					fi
					
					# notify of completion
					/usr/bin/curl --silent https://heroesshare.net/lives/complete/$randid
		
					# clean up and pass back to main watch loop
					rm "$tmpfile"
					replayfile=""
					
					break
				fi
				
				i=`expr $i + 1`
				sleep 5
			done
			
			# check if stage 2 uploads succeeded or timed out
			if [ ! "$rejoinfile" ]; then
				echo "[`date`] No rejoin file found for additional upload: $targetdir" | tee -a "$logfile"	

				# audible notification of failure
				/usr/bin/afplay "/System/Library/Sounds/Purr.aiff"
			fi
			rejoinfile=""
		
		# hash check failed - probably a duplicate
		else
			echo "[`date`] $result" | tee -a "$logfile"
			
			# audible notification of failure
			/usr/bin/afplay "/System/Library/Sounds/Purr.aiff"
		fi
		lobbyfile=""
	fi
	
	# note this cycle
	/usr/bin/touch "$appdir/lastrun"
	sleep 5
done
