#!/usr/bin/env perl
# edit your ping log file
# handy if you were typing when the ping window opened and fubar'd it
#
# opens the local file if you're using host-specific log file names
# also, if $ED is configured rightly, should open on the last line
#
# $logf is defined in settings.pl
# $ED is defined in settings.pl

require "$ENV{HOME}/.tagtimerc";

exec "$ED $logf"

