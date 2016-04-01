#!/usr/bin/perl -w
use strict;
use SVG;

# create an SVG object
my %hash;
$hash{width} = 1000;
$hash{height} = 1000;
my $filename = "./filename.svg";
my $filename2 = "./filename.png";
my $svg= SVG->new(%hash);
#
my $x;
my $y;
my @xpitcha = (2,4,6,8,10,12);
my @ypitcha = (1,3,5,7,11,13);
my @radiusa = (1,2,3,4,5,6,7,8,9,10);
my ($xpitch, $ypitch);
my $outline_width = 10;
my $outline_color = "black";
my $id;
my @color_list = ();
my $run= "RUN6";
open_colorlist();
#method for list of colors;
#method for varying size of elements randomly with tolerance
#
$svg->rect( x=>0,
            y=>0,
            height=>$hash{height},
            width=>$hash{width},
            fill=>"black");
foreach my $line (@color_list){
  my @colors = split(/,/,$line);

   for(my $x = 0; $x <= $hash{width}; $x=$x+$xpitch){
     $xpitch = $xpitcha[rand @xpitcha];
    for(my $y = 0; $y <= $hash{height}; $y=$y+$xpitch){
      my $color = $colors[rand @colors];
      my $radius = $radiusa[rand @radiusa];
      $ypitch = $ypitcha[rand @ypitcha];
      $id = $x."_".$y."_".$radius."_".$color."_".$xpitch."_".$ypitch."_";
      #drawacircle
      if($radius % 2 == 0){
        $svg->circle(id=>$id,cx=>$x,cy=>$y,r=>$radius,fill=> $color );
      }
      elsif($radius % 3 == 0){
        my $xv = [$x+$radius,$x+$radius*2,$x+$radius*3];
        my $yv = [$y+$radius,$y+$radius*2,$y+$radius];
        my $points = $svg->get_path(x=>$xv, y=>$yv, -type=>'polygon');
        $svg->polygon( %$points, id=>$id, fill => $color );
      }
      else{
      $svg->rect(x => $x, y => $y, width => $radius, height => $radius,
                 id => $id, fill=> $color );
      }
    }
  }
  $line =~ s/# //g;
  print $line."\n";
  $filename = $run.$line.".svg";
  open(FILE, '>', $filename) or die "Could not open file '$filename' $!";
  my $out = $svg->xmlify;
  print FILE $out;
  $svg= SVG->new(%hash);
  $svg->rect( x=>0,
              y=>0,
              height=>$hash{height},
              width=>$hash{width},
              fill=>"black");
}

my @files = grep { -f && /\.svg$/ } readdir ".";
foreach my $filename (@files){
  my $filename2 = $filename;
  $filename2 =~ s/\.svg/\.png/;
  `convert $filename $filename2`;
}
sub open_colorlist
{
  my $filename = 'color_list.csv';
  open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
  while (my $row = <$fh>) {
    chomp $row;
    push(@color_list,$row);
    #print $row."\n";
  }
}
