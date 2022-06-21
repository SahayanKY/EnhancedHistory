#!/bin/bash

# set history options
# The root user will be logged in by 'su' or 'su -'
# They differ in whether they load .bashrc or .bash_profile.
# Add to .bashrc so that the settings are overwritten in either case
# https://qiita.com/incep/items/7e5760de0c2c748296aa
export HISTFILE="${HOME}/.bash_history"
export HISTSIZE=20000
export HISTFILESIZE=$HISTSIZE
export HISTTIMEFORMAT='%F %T '
export HISTCONTROL=
HISTFILE_LINENUM=`cat "$HISTFILE" | wc -l`

export hist2_dir="${HOME}/hist2/"
export hist2_linenum=5000

function __prompt_command(){
	# get the exit code of the last executed command
	local status="$?"

	local lastcmd=`history 1`

	# share the history with other terminals (history -a ; history -c ; history -r)
	history -a # update .bash_history
	NEW_HISTFILE_LINENUM=`cat "$HISTFILE" | wc -l`
	if [ ! "$NEW_HISTFILE_LINENUM" = "$HISTFILE_LINENUM" ]; then
		# if changed, record the history in an external file
		"${hist2_dir}"/record_history.sh "$status" "$lastcmd"
	fi
	history -c # clear history of this terminal
	history -r # update this history

	HISTFILE_LINENUM="$NEW_HISTFILE_LINENUM"
}

# change the command to be executed every time you execute some command
PROMPT_COMMAND=__prompt_command

# we will edit the HISTFILE, so turn off writing.
shopt -u histappend

