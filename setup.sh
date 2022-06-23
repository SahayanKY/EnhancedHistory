#!/bin/bash

function __enhancedhistory_prompt_command(){
	# get the exit code of the last executed command
	local status="$?"

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
	# get the number of lines in HISTFILE before and after appending
	local HISTFILE_LINENUM=`cat "$HISTFILE" | wc -l`
	history -a # update .bash_history
	local NEW_HISTFILE_LINENUM=`cat "$HISTFILE" | wc -l`

	# record
	if [ ! "$NEW_HISTFILE_LINENUM" = "$HISTFILE_LINENUM" ]; then
		# if changed, new command executed.
		# record the history in an external file
		"${EnhancedHistory}"/record_history.sh "$status" "$__enhancedhistory_execDir" "$datetime" "$lastcmd"
	fi
	# load others' history
	history -c # clear history of this terminal
	history -r # update this history

	# update current directory
	__enhancedhistory_execDir=`basename "\`pwd\`"`

	# restore the setting
	HISTTIMEFORMAT="$_HISTTIMEFORMAT"
}

function __enhancedhistory_add_prompt_command(){
	local alreadySet=`echo "$PROMPT_COMMAND" | grep __enhancedhistory_prompt_command`
	if [ ! "$alreadySet" ]; then
		# if not added yet
		PROMPT_COMMAND="__enhancedhistory_prompt_command ; $PROMPT_COMMAND"
	fi
}

function __enhancedhistory_add_trap(){
	# $ trap "echo 'trap detect exit'" 0
	# $ trap -p 0
	#trap -- 'echo '\''trap detect exit'\''' EXIT
	#
	# so get the value already set and replace '\'' with '.
	local oldtrapcommand=`trap -p 0 |
							sed -r '1s/^([^ ]+ +){2}//' | # remove leading string ("trap -- ")
							sed -r "1s/^'//" |			# remove leading quotation
							sed -r '$s/ +[^ ]+$//' |	# remove trailing string (" EXIT")
							sed -r '$s/'\''$//'`		# remove trailing quotation
	oldtrapcommand="${oldtrapcommand//\''\'\'/}"		# replace '\'' with '
	local alreadySet=`echo "$oldtrapcommand" | grep __enhancedhistory_prompt_command`
	if [ ! "$alreadySet" ]; then
		# if not added yet
		# add prompt_command to 0 (EXIT)
		trap "__enhancedhistory_prompt_command; ${oldtrapcommand}" 0
	fi
}


if ! test `printenv EnhancedHistory` ; then
	echo "environment variable 'EnhancedHistory' is undefined."
	return 1
fi

# maximum number of lines in the external log file
export EnhancedHistory_LOGLINENUM=5000

# change the command to be executed every time you execute some command
__enhancedhistory_add_prompt_command
# add trap to detect 'exit'
__enhancedhistory_add_trap

# we will edit the HISTFILE, so turn off writing.
shopt -u histappend

# readonly and export
if [ ! -v EnhancedHistory_LOGDIR ]; then
	# if undefined
	declare -r EnhancedHistory_LOGDIR="$EnhancedHistory/log/"
fi
export EnhancedHistory_LOGDIR

# directory in which the command is executed
__enhancedhistory_execDir=`basename "\`pwd\`"`


