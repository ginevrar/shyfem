#!/usr/bin/perl
#
# changes color, line thickness, etc in ps files created by gnuplot
#
#------------------------------------------------------------

$size_old = 140;		# original text size in ps
$size_new_general = 160;	# desired general text size (axis, title, etc..)
$size_new_plot = 180;		# desired text size of plot labels
$width = 2;			# line width (original is 1)
$change_color = 1;		# change line from black to color

#------------------------------------------------------------

$plot = 0;
$debug = 0;

while(<>) {

  if( /^% Begin plot #(\w+)/ ) {
    $plot = $1;
    print STDERR "starting reading plot $plot\n";
  }

  if( /^% End plot #(\w+)/ ) {
    die "error in numbering of plots: $1 $plot\n" if( $1 != $plot );
    print STDERR "finished reading plot $plot\n";
    $plot = 0;
  }

  if( $plot ) {				# ------- inside plot area
    if( /^LCb/ and $change_color ) {	# change line color
      $color = "LC" . $plot;		# use color $plot
      print STDERR "  $_" if $debug;
      s/LCb/$color/;
      print STDERR "  $_" if $debug;
    }
    if( / UL/ ) {			# change line width
      print STDERR "  $_" if $debug;
      $_ = "$width UL\n";
      print STDERR "  $_" if $debug;
    }
    if( /Helvetica/ ) {			# change text size in label
      print STDERR "  $_" if $debug;
      s/$size_old/$size_new_plot/;
      print STDERR "  $_" if $debug;
    }
  } else {				# ------- outside plot area
    if( /Helvetica/ ) {			# change text size in general text
      print STDERR "  $_" if $debug;
      s/$size_old/$size_new_general/;
      print STDERR "  $_" if $debug;
    }
  }

  print;
}

