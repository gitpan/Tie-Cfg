ö#!/usr/bin/perl

use lib "./lib";
use lib "./blib/lib";

require 5.6.0;

BEGIN { $| = 1; print "1..10\n"; }

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

print "test 4: Checking if we have to run this test again.\n";

$again=0;
if (not exists $cfg{AGAIN}) {
  $cfg{AGAIN}="yes";
  $again=1;
}

print "ok 4\n";

######################################################################

print "test 5: closing.\n";

untie %cfg;

print "ok 5\n";

######################################################################

print "test 6: reading /etc/passwd.\n";

  $user=$ENV{USER};
  if ($user eq "") {
    $user=$ENV{USERNAME};
    if ($user eq "") {
      print "Trying whoami...\n";
      open IN,"whoami |";
      $user=<IN>;
      close IN;
      $user=~s/\s+$//;
    }
  }

  print "found user $user\n";

  if (not $user) {
    print "skipping 6\n";
  }
  else {
    tie %cfg,'Tie::Cfg', READ => "/etc/passwd", SEP => ':', COMMENT => '#';
    print "/etc/passwd entry for $user\n";
    print $cfg{$user},"\n";
    untie %cfg;

    print "ok 6\n";
  }

######################################################################

print "test 7: Using ini mode and sections\n";

tie %cfg,'Tie::Cfg', READ => "sect.ini", WRITE => "sect.ini";

print "counter section1.par1=",$cfg{"section1.par1"},"\n";
my $counter=$cfg{"section1"}{"par1"};
$counter+=1;
$cfg{"section"}{"par1"}=$counter;
$cfg{"section1"}{"par1"}=$counter;

print "section.par1=",$cfg{"section"}{"par1"},"\n";
print "section1.par1=",$cfg{"section1"}{"par1"},"\n";

$cfg{"somekey"}=rand;
$cfg{"somesect"}{"somekey"}="jeo";

for my $v (@{$cfg{"array"}{"a"}}) {
	print "get a ",$v,"\n";
}


for (0..10) {
  $cfg{"array"}{"a"}[$_]=$cfg{"array"}{"a"}[$_]+$_;
}

for (0..10) {
	print "array[$_]=",$cfg{"array"}{"a"}[$_],"\n";
}

print "untie...\n";
untie %cfg;
print "untie done.\n";

print "ok 7\n";
#exit;

######################################################################

print "test 8: Using ini mode with user separator\n";

tie %cfg, 'Tie::Cfg', READ => "usersect.ini", WRITE => "usersect.ini", SEP => ":", COMMENT => "#", REGSEP => "[:]", REGCOMMENT => "[#]";

print "counter section1.par1",$cfg{"par1"},"\n";
my $counter=$cfg{"par1"};
$counter+=1;
$cfg{"par1"}=$counter;


untie %cfg;
print "ok 8\n";

######################################################################

print "test 9: read and write sect.ini\n";

tie %cfg, 'Tie::Cfg', READ => "sect.ini", WRITE => "sect.ini";
untie %cfg;


######################################################################

print "test 10: recursive hashes in Cfg\n";

tie %cfg, 'Tie::Cfg', READ => "sect.ini", WRITE => "sect.ini";

my $counter=$cfg{"counter"};
$counter+=1;

for my $i (1..10) {
	print "array[$i]=$i, ";
}
print "\n";

for my $i (1..2) {
	for my $j (1..2) {
		for my $k (1..2) {
			for my $l (1..2) {
				print "section$i.subsec$j.ssubsec$k.par$l=",$cfg{"section$i"}{"subsec$j"}{"ssubsec$k"}{"par$l"},"\n";
			}
			print "section$i.subsec$j.par$k=",$cfg{"section$i"}{"subsec$j"}{"par$k"},"\n";
		}
	}
}

for my $i (1..2) {
	for my $j (1..2) {
		for my $k (1..2) {
			for my $l (1..2) {
				$cfg{"section$i"}{"subsec$j"}{"ssubsec$k"}{"par$l"}=$counter;
			}
			$cfg{"section$i"}{"subsec$j"}{"par$k"}=$counter;
		}
	}
}


$counter+=1;
$cfg{"counter"}=$counter;

untie %cfg;
print "ok 10\n";



######################################################################

if ($again) {
  print "\nPLEASE run this test again (make test for the second time).\n"
}
else {
  print "\nYou're done.\n";
}

exit;
