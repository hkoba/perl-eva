# $Id: AddMenu.pm,v 1.2.2.1 1998/11/17 14:12:17 hkoba Exp $

# This routine is now obsolete from main stream of perl/Tk.
# In normal case, you should use -menuitems config option of Tk::Menu.

## Of course, I shall return in this issue;-)

use Carp;
use strict;
sub Tk::Widget::AddMenu {
  my $cw   = shift;
  my $arg  = shift;
  local $| = 1;
  print "addm for $cw\n" if $ENV{VERBOSE};
  my $checker;
  if($] < 5.002) {
    # older
    $checker = sub { defined(ref($_[0])); };
  } else {
    # current.
    $checker = sub { ref($_[0]); };
  }
  my $menu;
  if ( $arg =~ m/-menu/ ) {
    #
    # trick for 'cascading'. use existing menu.
    $menu = shift;

  } else {
    #
    # Prepare a menubutton & menu.
    if (!ref $arg) {
	$arg = [$arg];
    }

    croak "Invalid button spec: '$arg'" if ref $arg ne 'ARRAY';

    my ($text, %bargs) = @$arg;
    $bargs{"-pack"} ||= [ -side => 'left', -fill => 'y' ];

    unless ( exists $bargs{-underline}) {
      if ( $text =~ s/(.*)~/$1/ ) {
	$bargs{-underline} = length $1;
      }
    }
    my $button;
    $button = $cw->Subwidget($text);
    if (!defined $button) {
      $button = $cw->Component(Menubutton => $text, -text => $text, %bargs);
    }
    if ($button->isa("Tk::Widget") and exists $bargs{-underline}) {
      # short-cuts.
      my $key = "<Alt-" . lc( substr($text, $bargs{-underline}, 1) ) . ">";
      my $code = sub { my($w, $but) = @_;$but->Post;Tk->break};
      $button->bind('traverse', $key => [$code ,$button] );
      $button->bind('all', $key => [$code ,$button] );
    }

    #
    # then create a menu.
    print "creating menu for $button\n" if $ENV{VERBOSE};
    $menu = $button->cget(-menu);
    if(!defined $menu) {
      $menu = $button->Menu;
      $button->configure(-menu => $menu);
    }
  }
  my $type = "command";
  my %dict;
  my $desc; # each descriptor.
  my $curindex = 1;
  my $invokeflag=0;
  # Because %translates and %defaults are not corrupted,
  # I want to declare these IN while block. (From clarity point.)
  #  .. but, It affects execution time. For example,
  # while($i++< 10000){ $x = $defaults{"-label"}; $y = $translates{"bitmap"};}
  #  6 secs ( 5.42 usr  0.00 sys =  5.42 cpu)  # Declare them in inner block.
  #  0 secs ( 0.33 usr  0.00 sys =  0.33 cpu)  # Declare them in outer block.
  my %translates = (bitmap => "command", button  => "command");
  my %defaults   = (bitmap      => ['-bitmap','-command' ],
		    'command'   => ['-label', '-command' ],
		    radiobutton => ['-label', '-value'   ],
		    checkbutton => ['-label', '-variable']);
  while( $desc = shift ){
    if ( &$checker($desc) ) {
      if (ref $desc eq "ARRAY") {
	if( exists $defaults{ $type } ) {
	  #
	  # Known type. (one of command/radio/check)

	  my %bargs = @{$desc}[2..$#$desc];
	  my ($first, $second)
	    = @{ $defaults{ $type } || $defaults{ $translates{ $type } } };
	  unless (exists $bargs{-underline}) {
	    if ($first eq '-label' and $desc->[0] =~ s/(.*)~/$1/) {
	      # print "default translation\n";
	      $bargs{-underline} = length $1;
	    }
	  }
	  #
	  @bargs{$first, $second}= @{$desc}[0,1];
	  #
	  # print "$type, @{[%dict]}, @{[%bargs]}\n";
	  $menu->add($translates{ $type } || $type , %dict, %bargs);
	  #
	  if( exists $bargs{-accelerator} ) {
	    # Short-cuts.
	    $bargs{-accelerator} =~ tr/+/-/;
	    my $command = [sub {
	      my ($w, $i) = @_;
	      $menu->invoke($i);
	      $menu->Unpost;
	      Tk->break;
	    }, $curindex];
	    # $command = $bargs{-command} if exists $bargs{-command};
	    # ... incorrect.
	    # print "<$bargs{-accelerator}>\n";
	    $menu->bind("<$bargs{-accelerator}>" => $command);
	    $menu->bind('traverse', "<$bargs{-accelerator}>" => $command);
	  }

	} else {
	  #
	  # User defined method.
	  my %user_args = ( %dict, @$desc );
	  $menu->$type( %user_args );

	}
	if($invokeflag) {
	  $menu->invoke($curindex);
	  $invokeflag = 0;
	}
	$curindex++;
      } else {
	# use Tk::Pretty;
	# croak "Unknown descriptor: '", &Pretty($desc),"'";
	croak "Unknown descriptor: '$desc'";
      }
    } else {
      #
      # == !defined ref $desc
      # to change button-type

      if( $desc =~ m/^cascade$/ or $desc =~ m/^[<>]+/) {
	#
	# cascading.
	
	my @desc = @{ shift; };
	my ($label, %args) = @{ shift @desc; };
	# $label =~ m/\.+\s*$/ or $label .= " ...";
	unless (exists $args{-underline}) {
	  if ($label =~ s/(.*)~/$1/) {
	    $args{-underline} = length $1;
	  }
	}
	$menu->add("cascade", -label => $label, %args);
	my $cascade = $menu->Menu;
	$menu->entryconfigure( $label, -menu => $cascade);
	$cascade->AddMenu(-menu => $cascade,  @desc );
	$curindex ++;

      } elsif( $desc =~ m/^separator/ or $desc =~ m/^\W{2,}/ ) {
	#
	# separator

	$menu->separator;
	$curindex ++;

      } elsif( $desc =~ m/^(:)*invoke(:)*$/ ) {
	#
	# invoke
	
	if(defined $1) {
	  $menu->invoke( $curindex );
	} elsif(defined $2) {
	  $invokeflag = 1;
	} else {
	  croak "Which? ':invoke/invoke:'\n",
	}

      } elsif( $desc =~ m/^(\w|::)+$/ ) {
	#
	# normal case

	$type = $desc;
	%dict = ();
	
      } elsif( $desc =~ m/^(-\w+)$/ ) {
	#
	# option settings. like: -variable => \$cw->{"FOO"}
	$dict{$1} = shift;
	
      } else {
	croak "Invalid descriptor: '$desc'";
      }
    }
  }
  # To enable $menubar->AddMenu()->AddMenu()->...
  return $cw;
}
1;

__END__

sub Tk::Menubar::CreateMenu {
  my $self = shift;
  croak "Odd number of menu descriptors given to CreateMenu" if @_ % 2;
  my ($head, $elts);
  use Benchmark;
  my $t1 = new Benchmark;
  my $converter = sub {
    my @res;
    while(@_){
      my $key = shift;
      $key = ref($key) ? $key : [$key];
      push @res, [ $key , @{ shift; } ];
    }
    @res;
  };

  use Tk::Pretty;
  PrintArgs( &$converter(@_) );
  # まだ使えない… なぜなら, 
  $self->AddMenu( &$converter(@_) );
  print &timediff(new Benchmark, $t1)->timestr,"\n";
  # 

}

