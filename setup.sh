#!/bin/bash

HISTFILE_LINENUM=`cat "$HISTFILE" | wc -l`

# maximum number of lines in the external log file
export EnhancedHistory_LOGLINENUM=5000

function __prompt_command(){
	# get the exit code of the last executed command
	local status="$?"

	local lastcmd=`history 1`

	# share the history with other terminals (history -a ; history -c ; history -r)
	history -a # update .bash_history
	NEW_HISTFILE_LINENUM=`cat "$HISTFILE" | wc -l`
	if [ ! "$NEW_HISTFILE_LINENUM" = "$HISTFILE_LINENUM" ]; then
		# if changed, record the history in an external file
		"${EnhancedHistory}"/record_history.sh "$status" "$lastcmd"
	fi
	history -c # clear history of this terminal
	history -r # update this history

	HISTFILE_LINENUM="$NEW_HISTFILE_LINENUM"
}

# change the command to be executed every time you execute some command
PROMPT_COMMAND=__prompt_command

# we will edit the HISTFILE, so turn off writing.
shopt -u histappend

