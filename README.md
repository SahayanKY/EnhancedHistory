# EnhancedHistory

extended history for bash

## what is this?

In bash, the `history` is too simple:
it often misses a lot of information when checking it later.
(eg., exit status, virtual terminal, very old history, ...)

This script solves these problems and helps you.

This script logs command execution histories in the following format:
```
324   0 DESKTOP tty1 2022-06-24 10:10:29 home$ ls
325   0 DESKTOP tty1 2022-06-24 10:10:34 home$ cd workspace
326   0 DESKTOP tty1 2022-06-24 10:10:42 workspace$ cd /
327   0 DESKTOP tty1 2022-06-24 10:10:46 $ cd -
328   2 DESKTOP tty1 2022-06-24 10:11:00 workspace$ ls hogahogahoga
329 130 DESKTOP tty1 2022-06-24 10:11:07 workspace$ sleep 60
330   0 DESKTOP tty3 2022-06-24 10:11:37 home$ echo tty3
331   0 DESKTOP tty3 2022-06-24 10:11:56 home$ echo "huuu
331 hooo
331 haaa"
332   0 DESKTOP tty3 2022-06-24 10:12:06 home$ exit
333   0 DESKTOP tty1 2022-06-24 10:12:12 workspace$ exit
```

- 1st column: serial number
- 2nd column: exit status
- 3rd column: hostname
- 4th column: virtual terminal
- 5th column: timestamp (date)
- 6th column: timestamp (time)
- 7th column: directory in which the command was executed
- 8th column: executed command

In addition,
when log file becomes large to some extent,
it is automatically compressed to targz,
and the history will remain unless you delete it yourself.
(not overwrite)


## install
Please do `git clone` and add some codes to .bashrc
```
*** $ git clone https://github.com/SahayanKY/EnhancedHistory
*** $ vi ~/.bashrc
export HISTFILE="${HOME}/.bash_history"			# depends on your preference
export HISTSIZE=20000					# depends on your preference
export HISTFILESIZE="$HISTSIZE"				# depends on your preference
export HISTTIMEFORMAT='%F %T '				# this value doesn't affect this script
export HISTCONTROL=					# all command will be recorded (depends on your preference)

export EnhancedHistory="${HOME}/EnhancedHistory"	# must
source "$EnhancedHistory/setup.sh"			# must
```


## uninstall
We provide the function, `__enhancedhistory_unload`, which is to disable EnhancedHistory.

```
*** $ __enhancedhistory_unload
EnhancedHistory: unloaded
*** $ rm -r $EnhancedHistory
```


