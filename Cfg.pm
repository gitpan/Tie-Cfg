
package Tie::Cfg;
require 5.6.0;
use strict;

use Fcntl qw(:DEFAULT :flock);

use vars qw($VERSION %cnf);

$VERSION="0.11";

sub TIEHASH {
  my $class = shift;
  my $args  = { READ  => undef,
                WRITE => undef,
                MODE  => 0640,
                LOCK  => undef,
                @_
              };
  my $file    = $args->{READ};
  my $outfile = $args->{WRITE};
  my $lock    = $args->{LOCK};
  my $mode    = $args->{MODE};

  my %cnf = ();
  my $fh;
  my $val;
  my $key;

  $outfile="" if (not $outfile);

  my $node = {
     CNF  => {},
     FILE => $outfile,
     MODE => $mode,
     LOCK => undef
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

    open $fh, $file;
    while (<$fh>) {
      next if /^\s*#/;
      next if /^\s*$/;
      ($key,$val) = split /[:=]/,$_,2;
      $key=~s/^\s+//;$key=~s/\s+$//;
      $val=~s/^\s+//;$val=~s/\s+$//;
      $node->{CNF}{$key}=$val;
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

  if ($self->{FILE}) {
    open $fh,">",$self->{FILE};
    while (($key,$value) = each %{$self->{CNF}}) {
      print $fh $key,":",$value,"\n";
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

  tie my %conf, 'Tie::Cfg',
    READ   => "/etc/connect.cfg",
    WRITE  => "/etc/connect.cfg",
    MODE   => 0600,
    LOCK   => 1;

  $conf{test}="this is a test";

  untie %conf;

  my $limit="10000k";

  tie my %files, 'Tie::Cfg',
    READ  => "find $dirs -xdev -type f -size +$limit -printf \"%h/%f:%k\\n\" |";

  $conf{test}="this is a test";

  if (exists $files{"/etc/passwd"}) {
    print "You've got a /etc/passwd file!\n";
  }

  while (($file,$size) = each %newdb) {
    print "Wow! Another file bigger than $limit ($size)\n";
  }


  untie %files;

=head1 DESCRIPTION

This module reads in a configuration file at 'tie' and writes it at 'untie'.
You can use file locking to prevent others from accessing the configuration file,
but this should only be used if the configuration file is used as a kind of
a database to hold a few entries that can be concurrently accessed.

Mode is used to set access permissions; defaults to 0640. It's only set
if a file can be written (i.e. using the WRITE keyword).

=head1 AUTHOR

Hans Oesterholt-Dijkema <hans@oesterholt-dijkema.emailt.nl>

=head1 BUGS

Possibly.

=head1 LICENCE

Perl.

=end


