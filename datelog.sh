#!/bin/sh

# USAGE: datelog.sh [today|yesterday|date]
#        prints pings for the specified date in all log files
#        defaults to today
#        greps *.log.txt
#        date format can be any of 2014-12-31, 2014.12.31, 2014/12/31
#
# AUTHOR:  Philip Hellyer 
# HOME:    http://www.hellyer.net/
# URL:     https://github.com/pjjh/TagTime
# FILE:    datelog.sh
# LICENSE: Licensed on the same terms as TagTime itself
#          Copyright 2015 Philip Hellyer

# DEPENDENCIES & LIMITATIONS
# - Hardcoded *.log.txt
# TODO check that this works cross-platform. Works on my Mac.

if [ 'yesterday' == "$1" ]; then
  DATE=$(date -v -1d +%Y.%m.%d)
elif [ -n "$1" ] ; then
  DATE=$(echo "$1" | tr '/-' '..')
elif [ 'today' == "$1" ]; then
  DATE=$(date +%Y.%m.%d)
else
  DATE=$(date +%Y.%m.%d)
fi

echo "$0 $DATE"
grep "$DATE" *.log.txt | sort -t: -k2n | perl -ne 's/\s+/ /g; /(\S+):(\d+) ([^\[]*).*(\[.*])/ and print "$2\t$4\t$1\t$3\n" or print'

