package Tk::Pretty::SelfRef;
my $version
  = q$Id: SelfRef.pm,v 1.2.2.1 1998/11/17 14:12:16 hkoba Exp $;
require Exporter;
@ISA=qw(Exporter);
@EXPORT = qw(Pretty PrintArgs);
@EXPORT_OK = qw(Pretty PrintArgs _type _stringify _is_overloaded _is_blessed);
$Limit ||= 1000;

use strict;
sub Limit {
  shift;
  return $Tk::Pretty::SelfRef::Limit if ! @_; # fetch
  $Tk::Pretty::SelfRef::Limit = shift;        # store
}
sub Pretty {
  my $total = 0;
  my $result = join(",", &pretty_list({}, \$total, @_));
  my $limit = $Tk::Pretty::SelfRef::Limit;
  return $result unless defined $limit and length($result) > $limit;
  substr($result, 0, $limit) . "...";
}
sub PrintArgs {
 my $name = (caller(1))[3];
 my ($pack, $fun) = $name =~ m/^(.*?)::([^:]+)$/;
 print "--$fun $pack(",Pretty(@_),")\n";
}
sub pretty_list {
  my ($dict, $total) = (shift, shift);
  my @all;
  my $limit = $Tk::Pretty::SelfRef::Limit;
  my $push = sub {
    push @all, @_;
    $$total += length(shift) while @_;
  };
  while (@_ and (!defined $limit or $$total <= $limit) ) {
    my $obj = shift;

    if (!defined $obj) {
      &$push('undef');

    } elsif ( ref $obj ) {
      my $result = _stringify($obj);
      my $type = _type($obj);
      if (_is_blessed($obj) and
	  $type eq "HASH" and exists $obj->{"_Tcl_CmdInfo_\0"}) {
	&$push( $result );
	next;
      }

      unless (exists $dict->{$result}) {
	$dict->{$result} = 1;    # or $obj
	$result = "";
	my $class;               # re-init per each.
	if ( _is_blessed($obj) ) {
	  $result .= "bless(";
	  $class = ref($obj);
	}
	if ($type eq 'ARRAY') {
	  $result .= '[';
	  $result .= join ",", &pretty_list($dict, $total, @$obj);
	  $result .= ']';
	} elsif ($type eq 'HASH') {
	  $result .= '{';
	  if (%$obj) {
	    my ($key, $val);
	    while ( ($key, $val) = each %$obj and
		    (!defined $limit or
		     length($result) + $$total <= $limit) ) {
	      $result .= "$key => " .
		join(', ', &pretty_list($dict, $total, $val)). ", ";
	    }
	    $result =~ s/, $//;
	  }
	  $result .= '}';
	} elsif ($type eq 'SCALAR') {
	  $result .= &pretty_list($dict, $total, $$obj);
	} elsif ($type eq 'REF') {
	  $result .= "\\" . &pretty_list($dict, $total, $$obj);
	} else{
	  $result .= _stringify($obj);
	}
	$result .= ",$class)" if defined $class;
      }
      &$push( $result );
    } else {
      if ($obj =~ /^-?[0-9]+(.[0-9]*(e[+-][0-9]+)?)?$/ ||
	  $obj =~ /^[A-Z_][A-Za-z_0-9]*$/ ||
	  $obj =~ /^[a-z_][A-Za-z_0-9]*[A-Z_][A-Za-z_0-9]*$/)
	{
	  &$push($obj);
	} else {
	  &$push("'" . $obj . "'");
	}
    }
  }
  push @all, " ... " if defined $limit and $$total > $limit;
  @all;
}

##### 
sub _type {
  # careful version of overload::AddrRef
  my $obj = shift;
  my $type;
  # to avoid corruption of %PKG::
  if(_is_overloaded($obj)){
    # overloaded.
    my $package = ref $obj;
    bless $obj, 'Overload::Fake'; # Non-overloaded package
    my $str = "$obj";
    bless $obj, $package;         # Back
    ($type) = $str =~ m/(\w+)\(/g;
  } else {
    # Not overloaded.
    ($type) = $obj =~ m/(\w+)\(/g;
  }
  return $type;
}
sub _stringify {
  my $obj = shift;
  my $str;
  if(_is_overloaded($obj)){
    # overloaded.
    my $package = ref $obj;
    bless $obj, 'Overload::Fake'; # Non-overloaded package
    $str = "$package=" .("$obj" =~ /Overload::Fake=(.*)/g)[0];
    bless $obj, $package;         # Back
  } else {
    # Not overloaded.
    $str = "$obj";
  }
  return $str;
}
my $types = {qw(ARRAY 1 SCALAR 1 HASH 1 REF 1 GLOB 1 CODE 1)};
sub _is_blessed {
  my $obj = shift;
  return 0 if exists $types->{ref($obj)};
  return 1;
}
sub globref {
  my ($class, $name) = @_;
  no strict 'refs';
  \*{join("::", ref $class || $class, $name)};
}
sub _is_overloaded {
  my $obj = shift;

  return 0 if ref($obj) eq "Overload::Fake";

  my $ns = globref($obj, '');
  my $symtab = *{$ns}{HASH};

  $symtab->{'OVERLOAD'} && *{globref($obj, 'OVERLOAD')}{HASH}
}
%Overload::Fake::OVERLOAD = qw(fallback 1); # Why!!!

1;
