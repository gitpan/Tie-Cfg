
package Tie::Cfg;
require 5.6.0;
use strict;

use Fcntl qw(:DEFAULT :flock);

use vars qw($VERSION %cnf);

$VERSION="0.14";

sub TIEHASH {
  my $class = shift;
  my $args  = { READ      => undef,
                WRITE     => undef,
                MODE      => 0640,
                LOCK      => undef,
                INIMODE   => undef,
                SEP       => undef,
                SPLITSEP  => undef,
                @_
              };
  my $file    = $args->{READ};
  my $outfile = $args->{WRITE};
  my $lock    = $args->{LOCK};
  my $mode    = $args->{MODE};
  my $inimode = $args->{INIMODE};
  my $separator;
  my $fsep;
  
  $separator=":" if not $inimode;
  $separator="=" if $inimode;
  if ($args->{SEP}) { $separator=$args->{SEP}; }
  
  my %cnf = ();
  my $fh;
  my $val;
  my $key;

  $outfile="" if (not $outfile);

  my $node = {
     CNF  => {},
     FILE => $outfile,
     MODE => $mode,
     LOCK => undef,
     SEPARATOR => $separator,
     INIMODE => $inimode
  };

  if (-e $file) {
    if ($lock and $outfile) {
      my $lck=$outfile.".lock";

      sysopen $node->{LOCK},$lck, O_RDONLY | O_CREAT
             or die "Cannot create or open $lck";

      flock($node->{LOCK}, LOCK_EX)
        or die "Cannot lock $lck";
    }

    #chmod $mode,$file;  # Don't change the in file
    
    my $section="";
    my $fsep="[:=]";
    $fsep="=" if ($inimode);
    $fsep=$args->{SEP} if ($args->{SEP});
    $fsep=$args->{SPLITSEP} if ($args->{SPLITSEP});
    
    open $fh, $file;
    while (<$fh>) {
      next if /^\s*$/;
      next if /^\s*#/ and not $inimode;
      next if /^\s*;/ and $inimode;
      if (/^\s*\[.*\]\s*$/ and $inimode) {
	      $section=$_;
	      $section=~s/^\s*\[//;
	      $section=~s/\]\s*$//;
	      $section=~s/^\s+//;
	      $section=~s/\s+$//;
	      $section.=".";
	      next;
      }
      ($key,$val) = split /$fsep/,$_,2;
      $key=~s/^\s+//;$key=~s/\s+$//;
      $val=~s/^\s+//;$val=~s/\s+$//;
      if ($inimode and $section) { 
	      $key=$section.$key; 
      }
      
      if ($key=~/([\[][0-9]+[\]])$/) {
	      my $index;
	      $index=$key;
	      
	      $key=~s/([\[][0-9]+[\]])$//;
	      
	      $index=substr($index,length($key));
	      $index=~s/[\[]//;
	      $index=~s/[\]]//;
	      
	      print $key, " - ",$index,"\n";
	      
	      $node->{CNF}{$key}[$index]=$val;
      }
      else {
        $node->{CNF}{$key}=$val;
      }
    }
    close $fh;
  }
  return bless $node, $class;
}

sub FETCH {
  my $self = shift;
  my $key  = shift;
  return $self->{CNF}->{$key};
}

sub STORE {
  my $self = shift;
  my $key  = shift;
  my $val  = shift;
  $self->{CNF}->{$key}=$val;
return $val;
}

sub DELETE {
  my $self = shift;
  my $key  = shift;
  delete $self->{CNF}->{$key};
}

sub EXISTS {
  my $self = shift;
  my $key  = shift;
  return exists $self->{CNF}->{$key};
}

sub FIRSTKEY {
  my $self = shift;
  my $temp = keys %{$self->{CNF}};
  return scalar each %{$self->{CNF}};
}

sub NEXTKEY {
  my $self = shift;
  return scalar each %{$self->{CNF}};
}

sub DESTROY {
  my $self = shift;
  my $fh;
  my $key;
  my $value;
  
  my $inimode=$self->{INIMODE};
  my $sep=$self->{SEPARATOR};

  if ($self->{FILE}) {
    open $fh,">",$self->{FILE};
    
    if ($inimode) {
	    print $fh ";";
    }
    else {
	    print $fh "#";
    }
    print $fh "Tie::Cfg version $VERSION (c) H. Oesterholt-Dijkema, sep=$sep, inimode=$inimode\n";
    print $fh "\n";
    
    my @values;
    while (($key,$value) = each %{$self->{CNF}}) {
	    
	    print "key: ",$key," - ",$value,"\n";
	    
	    my ($s,$k)=split /\./,$key,2;
	    if (not $k) {
		    $key=' '.$key;
	    }
	    
	    if (ref($value) eq "ARRAY") {
		    my $idx=0;
		    for my $val (@{$value}) {
			    push @values,$key."[".$idx."]".$sep.$val;
			    $idx+=1;
		    }
	    }
	    else {
		    push @values,$key.$sep.$value;
	    }
	    
    }
    
    @values=sort @values;
    my $section="";
    
    for my $line (@values) {
	    $line=~s/^[ ]//;
	    if ($inimode) {
		    my ($key,$value)=split /$sep/,$line,2;
		    my ($newsection,$key)=split /\./,$key,2;
		    if (not $key) {
			    print $fh "$line\n";
		    }
		    else {
			    if ($newsection ne $section) {
				    print $fh "[$newsection]\n";
				    print $fh $key.$sep.$value,"\n";
				    $section=$newsection;
			    }
			    else {
				    print $fh $key.$sep.$value,"\n";
			    }
		    }
	    }
	    else {
  	      print $fh "$line\n";
  	    }
    }
    close $fh;
    chmod $self->{MODE},$self->{FILE};
    if ($self->{LOCK}) {
      close $self->{LOCK};
    }
  }
}

=pod

=head1 NAME

Tie::Cfg - Ties simple configuration files to hashes.

=head1 SYNOPSIS

  use Tie::Cfg;
  
  ### Sample 1

  tie my %conf, 'Tie::Cfg',
    READ   => "/etc/connect.cfg",
    WRITE  => "/etc/connect.cfg",
    MODE   => 0600,
    LOCK   => 1;

  $conf{test}="this is a test";

  untie %conf;
  
  ### Sample 2

  my $limit="10000k";

  tie my %files, 'Tie::Cfg',
    READ  => "find $dirs -xdev -type f -size +$limit -printf \"%h/%f:%k\\n\" |";

  if (exists $files{"/etc/passwd"}) {
    print "You've got a /etc/passwd file!\n";
  }

  while (($file,$size) = each %newdb) {
    print "Wow! Another file bigger than $limit ($size)\n";
  }
  
  untie %files;
  
  ### Reading and writing an INI file
  
  tie my %ini, 'Tie::Cfg', READ => "config.ini", WRITE => "config.ini", INIMODE => 1;
  
  my $counter=$ini{"section1.counter1"};
  $counter+=1;
  $ini{"section1.counter1"}=$counter;

  untie %ini;

  ### Reading an INI file with user separator
  
  tie my %ini, 'Tie::Cfg', READ => "config.ini", INIMODE => 1, SEP => "\t\t", SPLITSEP => "\s+";
  
  my $counter=$ini{"section1.counter1"};
  $counter+=1;
  $ini{"section1.counter1"}=$counter;

  untie %ini;
  
=head1 DESCRIPTION

This module reads in a configuration file at 'tie' and writes it at 'untie'.

You can use file locking to prevent others from accessing the configuration file,
but this should only be used if the configuration file is used as a small data file 
to hold a few entries that can be concurrently accessed.
Note! In this case a persistent ".lock" file will be created.

Mode is used to set access permissions; defaults to 0640. It's only set
if a file should be written (i.e. using the WRITE keyword).

INIMODE lets you choose between Windows alike .ini configuration files and simple 
key[:=]value entried files.

Keys that end on [\[][0-9]+[\]] will be interpreted as arrays and will show up
in the tied hash as an array element. For example:

  [array-section]
  var[0]=1
  var[1]=2
  var[2]=3

will show up in a tied %cfg hash like:

  for (0..2) {
    print $cfg{array-section.var}[$_],"\n";
  }


=head1 PREREQUISITE

Perl's Version >= 5.6.0! Please don't test this module with
anything earlier. 

=head1 AUTHOR

Hans Oesterholt-Dijkema <hans@oesterholt-dijkema.emailt.nl>

=head1 BUGS

Probably.

=head1 LICENCE

Perl.

=end


