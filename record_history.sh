#!/bin/bash

function trapFunc(){
	# delete a lock file even if this script suddenly exits with an error
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
	local cmdindex=1
	local logfile=`head -n 1 "$cachefile" 2> /dev/null` # 'head' is redundant proc.
	if [ ! -f "$logfile" ]; then
		# empty, or not found log file
		logfile=`getNewLogFilePath`
	else
		# log file exists

		# get index of the command which will be recorded.
		# records are arranged in the log file as follows.
		# 153   2 DESKTOP-**** tty4 2022-06-23 18:51:12 EnhancedHistory$ ls huga
		# therefore, get the last line, extract the last index, and add 1
		cmdindex=`tail -n 1 "$logfile"`
		cmdindex="$((${cmdindex%% *} + 1))" # it can be calculated with 'expr', but it is slow, so this is adopted.
		# if '+ 1' is failed, cmdindex == 1

		# get the number of lines
		local numline=`wc -l "$logfile"`
		if [ "${numline%% *}" -ge "$EnhancedHistory_LOGLINENUM" ]; then
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
######################## directory & file path settings ##############################

set -u
trap 'trapFunc' 2 3 9 15

# check the export destination directory
# readonly
declare -r logdir="$EnhancedHistory/log/"
if [ ! -d "$logdir" ]; then
	# not found directory
	mkdir -p "$logdir"
fi

# change directory
# all subsequent processing is completed in this directory.
cd "$logdir"

# setting the file path required for processing
# readonly
declare -r lockfile=".lock"
declare -r cachefile=".cache"


############################### data settings ########################################
# get data from arguments
exitstatus=`printf "%3d" "$1"`	 # exit status
executeddir="$2"				 # the directory where the command was executed
datetime="$3"					 # time stamp
lastcmd="$4"					 # the command

# get additional data
#host="$HOSTNAME"				 # hostname (-> $HOSTNAME)
term=`tty` 						 # virtual terminal number
term="${term#/dev/}"			 # remove '/dev/'

################################# write data #########################################
# get lock
getLock
	set `getLogFilePath`
	cmdindex="$1"
	logfile="$2"

	# set dat
	# if lastcmd is multiple lines
	# add cmdindex to the second and subsequent lines
	dat="$cmdindex $exitstatus $HOSTNAME $term $datetime ${executeddir%/}\$ $lastcmd"
	# since sed is slow, we will deal with it by expanding variables.
	dat="${dat//
/
$cmdindex }"

	# append
	echo "$dat" >> "$logfile"

# release lock
releaseLock


