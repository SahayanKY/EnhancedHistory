#!/bin/bash

set -u
trap 'trapFunc' 2 15

function trapFunc(){
	# don't leave a lock file even if this script suddenly exits with an error
	releaseLock
	echo "EnhancedHistory: record_history.sh trap signal." >&2
}

function getLockFilePath(){
	# return path to lock file
	echo "${EnhancedHistory_LOGDIR}/.lock"
}

function getLock(){
	# get lock
	local lockfile=`getLockFilePath`
	while :
	do
		# loop until get the lock
		if ln -s $$ "$lockfile" 2>/dev/null; then
			break
		fi
	done
}

function releaseLock(){
	# release lock
	local lockfile=`getLockFilePath`

	# if exists, the lock file will be deleted.
	[ -L "$lockfile" ] && rm -f "$lockfile"
}

function getLogFilePath(){
	local cmdindex=0
	local logfile=`cat "${EnhancedHistory_CACHE}" 2> /dev/null |
						head -n 1` # 'head' is redundant proc.
	if [ ! "$logfile" ] || [ ! -f "$logfile" ]; then
		# not found log file
		logfile=`getNewLogFilePath`
	else
		# log file exists

		# get index of the command which will be recorded.
		cmdindex=`cat "$logfile" |
					tail -n 1 |
					sed -r 's/ .+/ + 1/' |
					xargs expr 2>/dev/null`
		if [ ! "$?" = 0 ]; then
			cmdindex=0
		fi
		if [ "`cat "$logfile" | wc -l`" -ge "$EnhancedHistory_LOGLINENUM" ]; then
			# the log file contains "EnhancedHistory_LOGLINENUM" lines already
			# "EnhancedHistory_LOGLINENUM" is defined at setup.sh
			(
				cd "${EnhancedHistory_LOGDIR}"
				logfile=`basename "$logfile"`
				# change to readonly because don't need to write anymore
				chmod a-w "$logfile"
				tar -zcvf "${logfile}.tar.gz" "$logfile" >/dev/null 2>&1
				rm -f "$logfile"
			)
			# get new log file path
			logfile=`getNewLogFilePath`
		fi
	fi

	echo "$cmdindex" "$logfile"
}

function getNewLogFilePath(){
	local newlogfile="${EnhancedHistory_LOGDIR}/`date +%Y%m%d%H%M%S`.log"
	echo "$newlogfile" > "${EnhancedHistory_CACHE}"
	echo "$newlogfile"
}

# check the export destination directory
if [ ! -d "${EnhancedHistory_LOGDIR}" ]; then
	# not found directory
	mkdir -p "${EnhancedHistory_LOGDIR}"
fi

# record history in an external file
# data processing
exitstatus=`printf "%3d" "$1"`
lastcmd=`echo "$2" | sed -r 's/^ *[0-9]+ *//'`

# get lock
getLock
	set `getLogFilePath`
	cmdindex="$1"
	logfile="$2"
	# set dat
	# if lastcmd is multiple lines
	# add cmdindex to the second and subsequent lines
	dat=`echo "$cmdindex exit:$exitstatus $lastcmd" |
			sed -r '2,$s/^/'"$cmdindex"' /'`

	# append
	echo "$dat" >> "$logfile"

# release lock
releaseLock


