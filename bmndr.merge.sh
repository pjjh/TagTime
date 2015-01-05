#!/bin/sh 

# USAGE: bmndr.merge.pl logfile1 logfile2
#        merges log files and submits the aggregate to beeminder.
#        defaults to *.log.txt
#
# AUTHOR:  Philip Hellyer 
# HOME:    http://www.hellyer.net/
# URL:     https://github.com/pjjh/TagTime
# FILE:    bmndr.merge.pl
# LICENSE: Licensed on the same terms as TagTime itself
#          Copyright 2014 Philip Hellyer

# DEPENDENCIES & LIMITATIONS
# - BACKUP your TagTime logs until you're sure this works
# - COPY bmndr.settings.pl.template to bmndr.settings.pl
# - MOVE your Beeminder settings out of settings.pl into that
# TODO check that this works cross-platform. Works on my Mac.

# CONFIG

# output file name
MLOG=merged.log

# END CONFIG

if [ ! -f tagtimed.pl ] ; then
  echo "Must be run from the TagTime directory"
  exit 1
fi

if [ ! -f bmndr.settings.pl ] ; then
  echo "Beeminder goals must be in bmndr.settings.pl"
  exit 1
fi

# default argument
if [ -z "$1" ]; then
  $0 *.log.txt
  exit
fi

echo "Merging log files"

# preprocess all files
for f in "$@"
do
	if [ ! -s "$f" ] ; then /bin/echo "Can't open file '$f'" ; exit 1 ; fi

	# eliminate non-ping lines, fix misordered pings
	/usr/bin/grep -E '^\d{10}\s' "$f" | /usr/bin/grep -v 'MISSING' | /usr/bin/sort > "$f.$$"

	if [ ! -s "$f.$$" ] ; then /bin/echo "Can't open file '$f.$$'" ; exit 1 ; fi

	if /usr/bin/cmp --quiet "$f" "$f.$$" 
	then 
		# sorting made no change to file $f... 
		/bin/rm "$f.$$" 
	else 
		# numbered backups of the individual file
		for i in 4 3 2 1 ""
		do
			if [ -f "$f.bak$i" ] 
			then
				/bin/mv -f "$f.bak$i" "$f.bak$(( $i + 1 ))"
			fi
		done
		/bin/mv "$f" "$f.bak"

		# the real operation, replace $f with the sanitised version
		/bin/mv -f "$f.$$" "$f"
	fi
done

# numbered backups of the merged file
for i in 4 3 2 1 ""
do
	if [ -f "$MLOG.bak$i" ] 
	then
		/bin/mv -f "$MLOG.bak$i" "$MLOG.bak$(( $i + 1 ))"
	fi
done
if [ -f "$MLOG" ] ; then /bin/mv -f "$MLOG" "$MLOG.bak" ; fi

# merge the files
./merge.pl "$@" > "$MLOG"

if [ $? -eq 0 ] ; then
  # send to beeminder if the merge succeeded
  echo "Updating Beeminder graphs"
  /usr/bin/perl -e 'require "${path}bmndr.settings.pl"; print join "\n", keys %beeminder;' | /usr/bin/xargs -n 1 ./beeminder.pl "$MLOG"

  # warn about any MISSING or merged pings
  /usr/bin/grep -w MISSING "$MLOG"
  /usr/bin/tail -1000 "$MLOG" | /usr/bin/grep \+
fi

