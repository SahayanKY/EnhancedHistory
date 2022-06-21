#!/bin/bash

set -u
trap 'trapfunc' 2 15

function trapfunc(){
	# don't leave a lock file even if this script suddenly exits with an error
	[ -L "$lockfile" ] && rm -f "$lockfile" # if exists, the lock file will be deleted.
	echo "hist2: record_history.sh trap signal." >&2
}


function get_logfile(){
	while :
	do
		# get lock
		if ln -s $$ "$lockfile" 2>/dev/null; then
			break
		fi
	done

	local cmdindex=0
	local newlogfile=false
	local logfile=`/usr/bin/ls -1 "$logdir"/*.log 2>/dev/null | tail -n 1`
	if [ ! "$logfile" ]; then
		# not found log file
		newlogfile=true
	else
		# log file exists

		# get index of the command which will be recorded. 
		cmdindex=`cat "$logfile" | tail -n 1 | sed -r 's/ .+/ + 1/' | xargs expr 2>/dev/null`
		if [ ! "$?" = 0 ]; then
			cmdindex=0
		fi
		if [ "`cat "$logfile" | wc -l`" -ge "$hist2_linenum" ]; then
			# the log file contains "hist2_linenum" lines already
			# "hist2_linenum" is defined at setup.sh
			(
				cd "$logdir"
				logfile=`basename "$logfile"`
				tar -zcvf "${logfile}.tar.gz" "$logfile" >/dev/null 2>&1
				rm -f "$logfile"
			)
			newlogfile=true
		fi
	fi
	if "$newlogfile"; then
		# create new log file
		logfile="$logdir/`date +%Y%m%d%H%M%S`.log"
	fi
	echo "$cmdindex" "$logfile"

	# release lock
	rm -f "$lockfile"

}

logdir="$hist2_dir/log/"
lockfile="$logdir/.lock"
# check the export destination directory
if [ ! -d "$logdir" ]; then
	# not found directory
	mkdir -p "$logdir"
fi

# record history in an external file
# data processing
exitStatus=`printf "%3d" "$1"`
lastcmd=`echo "$2" | sed -r 's/^ *[0-9]+ *//'`
set `get_logfile`
cmdindex="$1"
logfile="$2"
dat="$cmdindex exit:$exitStatus $lastcmd"
if [ `echo "$dat" | wc -l` -gt 1 ]; then
	# if lastcmd is multiple lines
	# add cmdindex to the second and subsequent lines
	dat=`echo "$dat" | sed -r '2,$s/^/'"$cmdindex"' /'`
fi

# append
echo "$dat" >> "$logfile"




