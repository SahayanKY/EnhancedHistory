#!/bin/bash

function trapFunc(){
	# don't leave a lock file even if this script suddenly exits with an error
	releaseLock
	echo "EnhancedHistory: record_history.sh trap signal." >&2
}

function getLock(){
	# get lock
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

	# if exists, the lock file will be deleted.
	[ -L "$lockfile" ] && rm -f "$lockfile"
}

function getLogFilePath(){
	local cmdindex=0
	local logfile=`head -n 1 "$cachefile" 2> /dev/null` # 'head' is redundant proc.
	if [ ! "$logfile" ] || [ ! -f "$logfile" ]; then
		# not found log file
		logfile=`getNewLogFilePath`
	else
		# log file exists

		# get index of the command which will be recorded.
		cmdindex=`tail -n 1 "$logfile" |
					sed -r 's/ .+/ + 1/' |
					xargs expr 2>/dev/null`
		if [ ! "$?" = 0 ]; then
			cmdindex=0
		fi
		if [ "`cat "$logfile" | wc -l`" -ge "$EnhancedHistory_LOGLINENUM" ]; then
			# the log file contains "EnhancedHistory_LOGLINENUM" lines already
			# "EnhancedHistory_LOGLINENUM" is defined at setup.sh

			# change to readonly because don't need to write anymore
			chmod a-w "$logfile"
			# compress
			tar -zcvf "${logfile}.tar.gz" "$logfile" >/dev/null 2>&1
			rm -f "$logfile"
			# get new log file path
			logfile=`getNewLogFilePath`
		fi
	fi

	echo "$cmdindex" "$logfile"
}

function getNewLogFilePath(){
	# generate path to new log file.
	# save the result in cache and return.
	local newlogfile="`date +%Y%m%d%H%M%S`.log"
	echo "$newlogfile" > "$cachefile"
	echo "$newlogfile"
}

############################### basic settings #######################################

set -u
trap 'trapFunc' 2 3 9 15

# check the export destination directory
if [ ! -d "${EnhancedHistory_LOGDIR}" ]; then
	# not found directory
	mkdir -p "${EnhancedHistory_LOGDIR}"
fi

############################### data settings ########################################
# get data from arguments
exitstatus=`printf "%3d" "$1"`
datetime="$2"
lastcmd="$3"

# get additional data
# hostname
host=`hostname`
# the directory where the command was executed
executeddir=`basename "\`pwd\`"`
# virtual terminal number
term=`basename "\`tty\`"`

######################## directory & file path settings ##############################
# change directory
# all subsequent processing is completed in this directory.
cd "${EnhancedHistory_LOGDIR}"

# setting the file path required for processing
declare -r lockfile=".lock"
declare -r cachefile=".cache"

################################# write data #########################################
# get lock
getLock
	set `getLogFilePath`
	cmdindex="$1"
	logfile="$2"
	# set dat
	# if lastcmd is multiple lines
	# add cmdindex to the second and subsequent lines
	dat=`echo "$cmdindex $exitstatus $host $term $datetime ${executeddir%/}\$ $lastcmd" |
			sed -r '2,$s/^/'"$cmdindex"' /'`

	# append
	echo "$dat" >> "$logfile"

# release lock
releaseLock


