#!/usr/bin/perl

use lib "./lib";
use lib "./blib/lib";

BEGIN { $| = 1; print "1..4\n"; }

######################################################################

print "test 1: using the module and tie this.\n";

use Tie::Cfg;
tie %cfg, 'Tie::Cfg', READ => "conf.cfg", WRITE => "conf.cfg", LOCK => 1, MODE => 0600;

print "ok 1\n";

######################################################################

print "test 2: getting.\n";

for (1..10) {
  if (exists $cfg{$_}) {
    print $cfg{$_}," - ";
  }
  else {
    print "U - ";
  }
}
print "\n";
print "ok 2\n";

######################################################################

print "test 3: setting.\n";

for (1..10) {
  $cfg{$_}=$_**2;
}

for (1..10) {
  print $cfg{$_}," - ";
}
print "\n";

print "ok 3\n";

######################################################################

print "test 4: closing.\n";

untie %cfg;

tie %cfg,'Tie::Cfg', READ => "/etc/passwd";
$user=$ENV{USER};
if (not $user) {
  $user=$ENV{$USERNAME};
  if (not $user) {
    open IN,"< whoami |";
    $user=<IN>;
    chop $user;
    close IN;
  }
}

print "/etc/passwd entry for $user\n";
print $cfg{$user},"\n";

print "ok 4\n";

exit;
