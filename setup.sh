#!/bin/bash

HISTFILE_LINENUM=`cat "$HISTFILE" | wc -l`

# maximum number of lines in the external log file
export EnhancedHistory_LOGLINENUM=5000

function __prompt_command(){
	# get the exit code of the last executed command
	local status="$?"
	# get current directory name
	local currentdir=`basename "\`pwd\`"`

	# retreat the setting before 'history'
	local _HISTTIMEFORMAT="$HISTTIMEFORMAT"
	# newline immediately after a timestamp
	HISTTIMEFORMAT='%F %T
'   # <= don't remove

	local historyresult=`history 1 |
							sed -r '1s/^ *[0-9]+ *//'` # remove the serial number part of the history
	local datetime=`echo "$historyresult" | head -n 1`
	local lastcmd=`echo "$historyresult" | sed -e 1d`

	# share the history with other terminals (history -a ; history -c ; history -r)
	history -a # update .bash_history
	# record
	NEW_HISTFILE_LINENUM=`cat "$HISTFILE" | wc -l`
	if [ ! "$NEW_HISTFILE_LINENUM" = "$HISTFILE_LINENUM" ]; then
		# if changed, record the history in an external file
		"${EnhancedHistory}"/record_history.sh "$status" "$currentdir" "$datetime" "$lastcmd"
	fi
	history -c # clear history of this terminal
	history -r # update this history

	HISTFILE_LINENUM="$NEW_HISTFILE_LINENUM"

	# restore the setting
	HISTTIMEFORMAT="$_HISTTIMEFORMAT"
}

# change the command to be executed every time you execute some command
PROMPT_COMMAND=__prompt_command

# we will edit the HISTFILE, so turn off writing.
shopt -u histappend

# readonly and export
if [ ! -v EnhancedHistory_LOGDIR ]; then
	# if undefined
	declare -r EnhancedHistory_LOGDIR="$EnhancedHistory/log/"
fi
export EnhancedHistory_LOGDIR
