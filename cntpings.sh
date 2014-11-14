#!/bin/sh 

# USAGE: cntpings.sh --help
#        Additional wrapper around cntpings.pl
#
# AUTHOR:  Philip Hellyer 
# URL:     https://github.com/pjjh/TagTime
# FILE:    cntpings.sh
# LICENSE: Licensed on the same terms as TagTime itself
#          Copyright 2014 Philip Hellyer

# DEPENDENCIES & LIMITATIONS
# Relies on newstyle formatted output from cntpings.pl
# Parameters intended for the .sh must appear before ones for the .pl
# --help tails the output from cntpings.pl, to include relevant usage
# TagTime :)

## CONFIG ##

# Default tagtime log file
# N.B. If you're merging files, any unmerged pings won't be reflected
LOG='merged.log'

# Exclude these tags unless --all
FILTER='afk|off|RETRO|prowl'

# A predefined tag set, e.g. for notionally productive time
# TODO somehow reuse bmndr tags defined in settings.pl
NWO='(nnj|gc|profdev|bmndr|ntwk|tock|mit|conf|fv|dj) & !(social|idle|avoid)'
# Exclude these percentages by default 
SHARE='01234'

### END CONFIG ###


if [ "$1" = '--help' ] ; then
  echo "USAGE: $0 [logfile] [--timeline] [options] [boolean expression]"
  echo "    (automatically filters $FILTER unless --all)"
  echo "Available options:"
  echo "    --help: this text"
  echo "    --nwo:  report on my predefined tag set"
  echo "    --all:  report on all tags regardless of % share"
  echo "    --zero: only include tags with at least 0% share (i.e. --all)"
  echo "    --one:  only include tags with at least 1% share"
  echo "    --two:  only include tags with at least 2% share"
  echo "    --five: only include tags with at least 5% share (DEFAULT)"
  echo "    --today:     report on today's pings"
  echo "    --yesterday: report on yesterday's pings"
  echo "    --week:      report on the last week"
  echo "    --month:     report on the last month"
  echo "    --timeline:  report on multiple periods"
  echo "                 (reveals all --time-period options)"
  cntpings.pl 2>&1 | tail
  exit 0
fi


# Start date, if specified by --week --month --quarter --year
START=''

# Predefined Tag sets. TODO move to user defined variable in .profile
TAGS=''

# Logfile specified on command line
if [ -f "$1" ] ; then
  LOG="$1"
  shift
fi

# Timeline mode to show history of pings
if [ "$1" = '--timeline' ] ; then
  shift
  # headers
  $0 --today "$@" | grep 'time/day' | sed 's/tag   /period/'
  # periods
  for period in 'week' 'fortnight' 'month' 'quarter' 'halfyear' 'year'; do
    # SED magic adjusts the spacing in the output depending on the length of $period
    $0 "--$period" "$@" | grep '*ALL*' | sed "s/ALL/$period/" | sed "s/\* \{$((${#period}-3))\}/*/"
  done
  # epoch - all available data
  $0 "$@" | grep '*ALL*' 
  exit 0
fi


# Order-Independent Parameter Processing

while true ; do
  if [ "$1" = '--nwo' ] ; then
    TAGS="$NWO"
    shift
  elif [ "$1" = '--all' -o "$1" = '--zero' ] ; then
    SHARE=''
    FILTER=''
    shift
  elif [ "$1" = '--one' ] ; then
    SHARE='0'
    shift
  elif [ "$1" = '--two' ] ; then
    SHARE='01'
    shift
  elif [ "$1" = '--three' ] ; then
    SHARE='012'
    shift
  elif [ "$1" = '--four' ] ; then
    SHARE='0123'
    shift
  elif [ "$1" = '--five' ] ; then
    SHARE='01234'
    shift
  elif [ "$1" = '--today' ] ; then
    START="-s $(date +%C%y-%m-%d)"
    shift
  elif [ "$1" = '--yesterday' ] ; then
    START="-s $(date -v-1d +%C%y-%m-%d) -e $(date +%C%y-%m-%d)"
    shift
  elif [ "$1" = '--week' ] ; then
    START="-s $(date -v-7d +%C%y-%m-%d)"
    shift
  elif [ "$1" = '--fortnight' ] ; then
    START="-s $(date -v-14d +%C%y-%m-%d)"
    shift
  elif [ "$1" = '--month' ] ; then
    START="-s $(date -v-1m +%C%y-%m-%d)"
    shift
  elif [ "$1" = '--quarter' ] ; then
    START="-s $(date -v-3m +%C%y-%m-%d)"
    shift
  elif [ "$1" = '--halfyear' ] ; then
    START="-s $(date -v-6m +%C%y-%m-%d)"
    shift
  elif [ "$1" = '--year' ] ; then
    START="-s $(date -v-1y +%C%y-%m-%d)"
    shift
  else
    break
  fi
done


if   [ -n "$SHARE" -a -n "$FILTER" ] ; then
  cntpings.pl -v "$LOG" $START "$TAGS" "$@" | grep -vE " [$SHARE]% " | grep -vE "$FILTER"
elif [ -z "$SHARE" -a -n "$FILTER" ] ; then
  cntpings.pl -v "$LOG" $START "$TAGS" "$@" |                          grep -vE "$FILTER"
elif [ -n "$SHARE" -a -z "$FILTER" ] ; then
  cntpings.pl -v "$LOG" $START "$TAGS" "$@" | grep -vE " [$SHARE]% " 
else
  cntpings.pl -v "$LOG" $START "$TAGS" "$@"
fi

exit


if [ "$1" = '--all' ] ; then
  shift
  cntpings.pl -v "$LOG" "$@" 
elif [ "$1" = '--zero' ] ; then
  shift
  SHARE='0'
  cntpings.pl -v "$LOG" "$@" | grep -vE ' 0% ' | grep -vE "$FILTER"
elif [ "$1" = '--one' ] ; then
  shift
  SHARE='01'
  cntpings.pl -v "$LOG" "$@" | grep -vE ' [01]% ' | grep -vE "$FILTER"
elif [ "$1" = '--week' ] ; then
  shift
  START="-s $(date -v-7d +%C%y-%m-%d)"
  cntpings.pl -v "$LOG" -s $(date -v-7d +%C%y-%m-%d) "$@" | grep -vE ' [01234]% ' | grep -vE "$FILTER"
elif [ "$1" = '--month' ] ; then
  shift
  cntpings.pl -v "$LOG" -s $(date -v-30d +%C%y-%m-%d) "$@" | grep -vE ' [01234]% ' | grep -vE "$FILTER"
elif [ "$1" = '--quarter' ] ; then
  shift
  cntpings.pl -v "$LOG" -s $(date -v-90d +%C%y-%m-%d) "$@" | grep -vE ' [01234]% ' | grep -vE "$FILTER"
else
  cntpings.pl -v "$LOG" "$@" | grep -vE ' [01234]% ' | grep -vE "$FILTER"
fi


# This finds all tags registered in the last week...
# cntpings.sh --all -s $(date -v-7d +%C%y-%m-%d) | awk '{print $1}' | grep -v '[:*+]' | sort

# The harder question is what to do with this, and how to see changes.

# Taxonomy demainds monitoring for:
# - tags never seen before
# - tags not seen for some time
# - tags with the wrong year(?)

# man comm



