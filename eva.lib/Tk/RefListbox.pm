package Tk::RefListbox;
use strict;
use Carp;

=head1 NAME

RefListbox (Reference Listbox) - Modified version of ScrlListbox. 
Suit for 'Reference' listing.

=head1 SYNOPSIS

  use Tk::RefListbox;

  $list = $top->RefListbox
         (-stringify   => \&Tk::Pretty::Pretty
	 ,-opencommand => [$text, "Load"]
	 );

=head2 Motivation:

In raw Listbox, if you do 

   use strict;
   
   my $list  = MainWindow->new->Listbox->pack;

   $list->insert(0 => [0..3], [4..7]);

   print @{ $list->get(0) }, "\n";

then you get I<error> like:

  Can't use string ("ARRAY(0x134bec)") as an ARRAY ref
      while "strict refs" in use at ...

Yes, Listbox can contain only 'string'. This is uncomfortable,
especially to store 'reference'. Since 'reference' is the largest
progress of perl5, we frequently need to store it in Listbox.

In RefListbox, 

   use strict;
   require Tk::RefListbox;
   
   my $rlist = MainWindow->new->RefListbox->pack;

   $rlist->insert(0 => [0..3], [4..7]);

   print @{ $rlist->get(0) }, "\n";

then you get '0123'.  RefListbox has a hidden array to store
B<insert>ed value. RefListbox catches B<insert>, B<delete>,
B<get>,... and operate it on both of underlying listbox and 
hidden array.

=head1 DESCRIPTION

=cut 

require Tk;
require Tk::Frame;
@Tk::RefListbox::ISA = qw(Tk::Frame);
$Tk::RefListbox::ver
  = q$Id: RefListbox.pm,v 1.2.2.1 1998/11/17 14:12:15 hkoba Exp $;
Tk::Widget->Construct('RefListbox');
require Tk::IO;
BEGIN {
  if($] < 5.002){
    require Tk::Compatibility::BeforeB9; # to emulate b9-script in b8
    import  Tk::Compatibility::BeforeB9;
  }
}

sub Populate{
  my ($cw,$args) = @_;
  $cw->SUPER::Populate($args);

  my $list = $cw->Listbox;
  $cw->AddScrollbars($list);
  $cw->Advertise(listbox=> $list);

=head1 Configure option:

Same option of Listbox can be used. And following options are
provided.

=over 2

=item  B<-variable>

Reference to the hidden array,
that holds real entity of RefListbox.

=item  B<-opencommand>

Tk::Callback, that is invoked via B<Double-1> and applied to current
selection.

=item  B<-stringify>

Formatter function. CODE REF (sub {...}) , used to convert refs to
string viewed in raw Listbox.

=item B<-scrollbarwidth>

Specify width of 'scrollbars'.

=back

=cut

 $cw->ConfigSpecs
   ( -scrollbars       => ['METHOD','scrollbars','Scrollbars','e']
    ,'-scrollbarwidth' => ['METHOD', 'scrollbarwidth', 'Scrollbarwidth', [] ]
    ,-variable         => ['PASSIVE', undef, undef, [] ]
    ,-stringify        => ['PASSIVE', undef, undef, sub {"$_[0]"}]
    ,-update           => ['PASSIVE', undef, undef, 3 ]
    ,-opencommand      => ['CALLBACK',undef, undef, undef]
    ,-io               => ['PASSIVE', undef, undef, undef ]
   );
 $list->bindtags( [$list->bindtags, $cw] );
 $cw->bind($cw, '<Double-1>', [$cw, 'DoCallback', -opencommand]);
 return $cw->Default(listbox => $list);
}

sub DoCallback {
  my($self, $attrib, @rest) = @_;
  my $callback = $self->cget($attrib);

  if(defined ref $callback and ref $callback eq 'Tk::Callback' ){
    $callback->Call(@rest, $self->Getselected);
    
  } elsif( !defined $callback) {
    return; # nop
    
  } else {
    
    croak "invalid callback($callback)\n";
  }
}
#   $list->configure(
#     -opencommand => [sub { print "<@_>\n"; }, 3] );
#                                   <3  7>
#                                       ^^ selected elem.

sub scrollbarwidth {
  my ($cw, $width) = @_;
  my ($x, $y);
  if( defined ref $width and ref $width eq 'ARRAY') {
    ($x, $y) = @$width;
  } else {
    ($x, $y) = ($width, $width);
  }
  $cw->Subwidget('yscrollbar')->configure(-width => $x) if defined $x;
  $cw->Subwidget('xscrollbar')->configure(-width => $y) if defined $y;
  $cw;
}

=head1 COMMAND

=over 2

=cut

sub Getselected {

=item B<Getselected>

This returns not viewed items, but contents of the hidden variable.
If you want to get indices, use B<curselection>.

Note: In B<older> version, this method is called as B<curselection>.

=cut

  my $cw    = shift;
  my @indices = $cw->Subwidget('listbox')->curselection;
  #
  my $var  = $cw->cget(-variable);
  return wantarray ? () : undef if ! @indices;
  return wantarray ? @{$var}[@indices] : $var->[$indices[0]];
}

sub get {

=item B<get>

This returns not viewed one, but contents of the hidden variable.

Note: Even if nothing is selected, $reflist->get('active') returns
first (or last?) element.  That is same spec of Listbox. To get
selected element only if selection exists, use 'Getselected',
instead.

=cut

  my $cw    = shift;
  my $list  = $cw->Subwidget('listbox');
  my $first = $list->index( shift );
  my $last  = $first;
  $last = $list->index(shift) if @_;
  #
  my $var = $cw->cget(-variable);
  $last = $last > $#$var ? $#$var : $last; # if index eq 'end'
  return wantarray ? @{$var}[$first .. $last] : $var->[$first];
}
sub insert {
  my $cw  = shift;

=item B<insert>

Insert given elements to both of raw listbox and hidden array.

=cut

  my $list  = $cw->Subwidget('listbox');
  my $code  = $cw->cget(-stringify);
  my $index = shift;
  #
  my $var = $cw->cget(-variable);
  if($index eq "end"){
    push(@$var, @_);
  } elsif( $index == 0 ){
    unshift(@$var, @_);
  } else {
    $index = $list->index('active') if ($index eq 'active');
    splice(@$var, $index, 0, @_);
  }
  #
  $index = $list->index($index); # numerize.
  my $update = $cw->cget(-update);
  while ( @_ ) {
    $list->insert($index, map { &$code($_) } splice @_, 0, $update);
    $list->update;
    $index += $update; # care-less.
  }
  #
  return $cw;
}
sub delete {
  my $cw  = shift;

=item B<delete>

Delete elements specified by indices from both of raw listbox and
hidden array.

=cut

  my $list  = $cw->Subwidget('listbox');
  #
  my @indices = @_;
  my $first = $list->index(shift); 
  my $len  = 1;
  $len = $list->index(shift) - $first + 1 if @_;
  splice @{ $cw->cget(-variable) }, $first, $len;
  #
  $list->delete(@indices);
  
  return $cw;
}
sub deleteSelection {

=item B<deleteSelection>

Short hand method to delete selected elements.

=cut

  shift->deleteSelectionOrIndex;
}
sub deleteSelectionOrIndex {
# If selection exists, delete them.
# If not, delete items specified by index.

  my $cw   = shift;
  my $list = $cw->Subwidget('listbox');
  #
  my @indices = $list->curselection;
  if (@indices) {
    while(@indices){
      $cw->delete(pop @indices);  # to avoid $obj->method while 0;
    }
  } else {
    $cw->delete(@_) if @_;
  }
  return $cw;
}
sub Clear {

=item B<Clear>

Short hand of '->delete(0 => "end")'

=cut

  shift->delete(0 => 'end');
}

=item Refresh(begin, end)

Re-format specified range. If no range is specified, all range is
re-formated. If you need complex operation (like B<sort>, tsort, ...) 
on the RefListbox, do like below.

  $aryref  = $reflist->cget(-variable);
                                        # get hidden array.
  @$aryref = sort BY_YOUR_FUNC @$aryref; 
                                        # overwrite them.
  $reflist->Refresh;                    # refresh view.

=cut

sub Refresh {
  my $cw = shift;
  my $prog = $cw->cget(-stringify);
  my $var  = $cw->cget(-variable);
  my $list = $cw->Subwidget('listbox');
  if (@_) {
    my($begin, $end) = @_;
    $end ||= $begin;
    $begin = $list->index($begin);

    if($begin < $list->index('end')){
      $list->delete($begin, $list->index($end));
      #                     #^^^^ 
    }

    # Does not treat when $begin eq 'active'

    $end = $end eq 'end' ? $#$var : $end; # if index eq 'end'
    $list->insert($begin, map { &$prog($_) } @{$var}[$begin .. $end]);
  } else {
    # If '->Refresh($begin, $end)' is buggy, try '->Refresh'.

    $list->delete("0", "end");
    $list->insert("end", map { &$prog($_) } @$var);
  }
  $cw->update;
  $cw;
}
sub AppendSilently {
  my ($cw) = shift;
  my $var = $cw->cget(-variable);
  push @$var, @_;
  #
  unless( $cw->{"Update"}-- ){
    $cw->{"Update"} = $cw->cget(-update);
    $cw->RefreshGrowth;
    $cw->update;
  }
  #
  $cw->DoWhenIdle([$cw, 'RefreshGrowth']);
  $cw;
}
sub RefreshGrowth {
  my ($cw) = shift;
  my $var = $cw->cget(-variable);
  my $list = $cw->Subwidget('listbox');
  my $end = $list->index('end');
  if( @$var > $end ){
    $cw->Refresh( $end, $#$var );
  }
  $cw;
}

sub Read {
  my($cw, $file, $func) = @_;
# ...($cw, $func, @files) would be better...
# If I change argument spec of 'Read', do you complain?

=item B<Read>

Short hand method to read a file.

  $reflist->Read('/etc/passwd');

This method works under Non-blocking mode. Try:

  $reflist->Read('cat |');

Optional CODE argument is applied to each line.
See L<EXAMPLE>

=cut

  my ($fh, $line);
  if($] < 5.002){
    $fh = Tk::IO->open($file);
    croak "$!: '$file'" if !defined $fh;
  } else {
    $fh = Tk::IO->new;
    open($fh, $file) or croak "$!: '$file'";
    # print "<$pid>\n";
    # $file =~ /|\s*$/ and $fh->configure(-pid => $pid);
  }
  $cw->configure( -io => $fh ); # save the fh.
  while( !  exists $cw->{"Close"}
	 && defined($line = $fh->readline) ){
    $line = &$func($line) if defined $func ;
    $cw->AppendSilently( $line );
  }
  $fh->close;
  $cw->configure(-io => undef);

  delete $cw->{"Close"};
  $cw->RefreshGrowth;
  $cw;
}
sub Close {
  my $cw = shift;

=item B<Close>

Request 'close' to the running B<Read> session.

=cut

  my $fh = $cw->cget(-io);
  if( defined $fh ){
    $fh->cget(-pid) and $fh->kill(9);
    $cw->{"Close"} ++;
  }
  $cw;
}

sub Exec {
# under construction. untested.
  my ($cw, $file, $func) = @_;

  my $var = $cw->cget(-variable);
  my $fh;
  $fh = Tk::IO->new
    (-widget => $cw
     ,-errorcommand=> sub {croak "RefList->Exec error:'$!'";}
     ,-linecommand => [$cw, 'insert', 'end']);
  # $func ... 
  $cw->configure(-io => $fh,   # -update => 1
		);
  $fh->exec($file);
  return $cw;
}

1;

=back

=head1 EXAMPLE

=head2 Hidden Element

Listbox with B<Hidden Element>. Below reads F</etc/passwd>, split 
each record and store them as ref to ARRAY in RefListbox.

  use Tk;
  require Tk::RefListbox;

  $l = MainWindow->new->RefListbox
     (-stringify   => sub { shift->[1] }
     ,-opencommand => sub { printf("%8d %12s\t%s\n", @{ shift; })}
     );
  $l->pack(-fill => "both", -expand => 1);

  $l->Read("/etc/passwd", sub {[ ( split(":", shift) )[2,0,4] ]} );

  MainLoop;

=head2 Non blocking Read

Simple MH interface, using lazy "scan" via B<Read> command.

  $folder = shift || "+inbox";
  chop($folderpath = `mhpath $folder`);

  use Tk;
  #require Tk::TextUndo;
  require Tk::RefListbox;
  $mw = MainWindow->new;  $mw ->title("MH scan");
  $mw2= MainWindow->new;  $mw2->title("MH show");
  
  map( $_->pack(-fill => "both", -expand => 1)
  ,( $l    = $mw ->RefListbox(-width => 80, -update => 3) )
  ,( $mw->Button(-text => "Stop", -command => [$l, "Close"]))
  ,( $text = $mw2->Scrolled('Text')         )
  );
  ## for Japanese.
  $mw->kanjicode("jis") if exists $Tk::{"Kinput::"};
  
  $l->configure(-opencommand => sub {
   my($num) = shift =~ m/(\d+)/  ;  # need paren.
   my $file = "$folderpath/$num";
   $text->delete("1.0", "end");
   $text->Load($file);

   $text->search("Subject: ", "1.0") =~ m/(\d+)\./;
   $text->yview($1 - 1);

  });

  $l->Read("scan $folder -reverse |");

  MainLoop;

  sub Tk::Text::Load {
    my ($text, $filename) = @_;
    use Carp;
    if( -r $filename ){
      local(*FH);
      open(FH, $filename) or croak "$0: $! '$filename'";
      while(<FH>){
        $text->insert('end', $_);
      }
      close(FH);
    } else {
      print STDERR "Can't read $filename\n";
    }
  }

=head1 AUTHOR

KOBAYASI Hiroaki -- hkoba@t3.rim.or.jp --

   in Japanese, 小林 弘明 -- h小林＠第3東京.リムネット --
     これが私の_『ほとばしる熱いパトス』ってやつです

=cut

__END__
