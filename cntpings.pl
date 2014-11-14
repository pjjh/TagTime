#!/usr/bin/env perl
# Count the number of a pings with given tags in the given time period.

BEGIN { require "$ENV{HOME}/.tagtimerc"; }
use lib $path, "$path/lib";

require "util.pl";
use Getopt::Long qw(:config bundling);
use TagTime qw(match); # should be in util.pl (or util.pl should all be here)

my $start = -1;
my $end = -1; # ts(time());
my $verbose = 0;
GetOptions("start|s=s"=>\$start, "end|e=s"=>\$end, "verbose|v"=>\$verbose);
$start = pd($start) unless isnum($start);
$end = pd($end) unless isnum($end);
# We might want to include shortcuts for specifying special time ranges like
# "since last saturday night at midnight" or "the last n weeks" or "last week 
# (previous saturday night to last saturday night)".  showpie.pl and frask.pl
# have options like that.

$help = <<"EOF";
USAGE: $0 logfile [boolean expression with pings]
  Available options:
    -s or --start DATE: only include pings on or after DATE
    -e or --end DATE: only include pings strictly before DATE 
    -v or --verbose: include interesting stats and tag breakdown
  where DATE is a string in YMDHMS order with any delimiters you want.
  Eg: cntpings -s2010.07.10 alice.log '(wrk | job) & !slp'
  If more than one boolean expression is given they are OR'd together, so
    cntpings alice.log foo bar
  is the same as 
    cntpings alice.log 'foo|bar'
  which means: count the pings in alice.log that are tagged foo or bar.
EOF
die $help if @ARGV < 1;

#die "DEBUG: [", ts($start), "][", ts($end), "]\n";

my %tc;            # tag counts -- hashes from tag to count.
my $first = -1;    # timestamp of the first matching ping in time range.
my $last  = -1;    # timestamp of the last  matching ping in time range.
my $m = 0;         # number of pings in time range that match.
my $n = 0;         # number of pings in time range that don't match.
my $e = 0;         # number of lines with parse errors.
my $toosoon = 0;   # number of pings before $start.
my $toolate = 0;   # number of pings after $end.
my $maybelate = 0; # number of pings since last match
my $errstr = "";   # concatenation of bad lines from log file.

my $logfile = shift;
my $expr = '( ' . join(' )|( ', @ARGV) . ' )';
open(LOG, $logfile) or die qq{Cannot open logfile "$logfile" - $!\n};
while(<LOG>) {
  if(!parsable($_)) {
    $e++;
    $errstr .= $_;
    next;
  }
  my $line = strip($_);

  my @tags = split(/\s+/, $line);
  my $ts = shift(@tags);
  if   ($ts < $start) { $toosoon++; }
  elsif($ts > $end && $end != -1)   { $toolate++; }
  elsif(match($expr, $line)) {
    if($first == -1 || $ts < $first) { $first = $ts; }
    if($last  == -1 || $ts > $last ) { $last =  $ts; }
    if($ts > $pingend) { $pingend = $ts; }
    $m++;
    $maybelate = 0;
    for(@tags) { $tc{$_}++; }
  } else { 
    $n++; 
    $maybelate++; 
    if($first == -1) { $toosoon++; }
  }
}
$start = $first if $start == -1;
$end   = $last  if $end   == -1;
$toolate += $maybelate;

if($e>0) { 
  print "Errors in log file: $e. ", 
        "They have to be fixed before pings can be counted:\n";
  print "\n$errstr";
  exit(1);
}
print "$m (", ss($m*$gap), ") / ", $m+$n, 
        " (", ss2(($m+$n)*$gap), " ~ ", 
              ss2($last-$first), ") = ",
        ($m+$n==0 ? "NaN" : round1(100*$m/($m+$n))), "%",
        #" [rate: ", ss(($last-$first)/($m+1)). "]",
        "\n";
  #"NomGap = ". ss2($gap) 
if($verbose and $end ne $start) {

  my @pie = ();

  my @pieline = ();
  push @pieline, '*ALL*', $m, "100%";
  push @pieline, ss($m*$gap),
                 ss2($m*$gap/(($end-$start)/(24*3600))),
                 ss2($m*$gap/(($end-$start)/(24*3600*7)));
   push @pie, \@pieline;

  print "Start: ". ts($start). "  (pings before this: $toosoon)".
  "\n  End: ". ts($end).   "  (pings after this:  $toolate)\n";
  print lrjust("PIE:", "\n");
  for(sort {$tc{$b} <=> $tc{$a}} keys %tc) {

   my @pieline = ();

# FIXME something horrible happens if 100% of the lines match

   push @pieline, $_, $tc{$_}, round1(100*$tc{$_}/$m)."%";
   if($n==0) {
      push @pieline, ss($tc{$_}/$m*($end-$start)),
                     ss2($tc{$_}/$m*24*3600),
                     ss2($tc{$_}/$m*24*3600*7);
    } else {
      push @pieline, ss($tc{$_}*$gap),
                     ss2($tc{$_}*$gap/(($end-$start)/(24*3600))),
		     ss2($tc{$_}*$gap/(($end-$start)/(24*3600*7)));
    }
   push @pie, \@pieline;

#    print "  $_ $tc{$_} = ". round1(100*$tc{$_}/$m). "% = ~";
#    if($n==0) {
#      print ss2($tc{$_}/$m*($last-$first)). " = ".
#            ss2($tc{$_}/$m*24*3600). "/day = ",
#            ss2($tc{$_}/$m*24*3600*7). "/week",
#            "\n";
#    } else {
#      print ss($tc{$_}*$gap). " = ".
#            ss2($tc{$_}*$gap/(($last-$first)/(24*3600))). "/day = ",
#            ss2($tc{$_}*$gap/(($last-$first)/(24*3600*7))). "/week",
#            "\n";
#    }


  }

  format HEADER =
  tag         pings  pct   total time  time/day  time/week
.
  $^ = 'HEADER';
  for my $pieline (@pie) {
    format STDOUT =
  @<<<<<<<<<< ^#### @>>> @>>>>>>>>>>> @>>>>>>>> @>>>>>>>>> 
          @$pieline
.
    write;
    $- = 10000000; # only one header please
  }
}
close(LOG);
