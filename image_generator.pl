#!/usr/bin/perl -w
use strict;
use SVG;
use Cwd;
use File::Path qw(make_path);
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
my @xpitcha = (10,12,14);
my @ypitcha = (11,13,15);
my @radiusa = (4,5,6,7,8,9,10);
my ($xpitch, $ypitch);
my $outline_width = 10;
my $outline_color = "black";
my $id;
my @color_list = ();
my @xpitch_list = ();
my @radius_list = ();
my @ypitch_list = ();
my $run= "RUN20";
my $dir = getcwd;
open_colorlist('color_list.csv');
open_radiuslist('radius_list.csv');
open_ypitchlist('xpitch_list.csv');
open_xpitchlist('ypitch_list.csv');
#method for list of colors;
#method for varying size of elements randomly with tolerance
#
my $i = 0;
$svg->rect( x=>0,
            y=>0,
            height=>$hash{height},
            width=>$hash{width},
            fill=>"black");
foreach my $radiusa (@radius_list){
my @radiusb = split(/,/,$radiusa);
foreach my $xpitcha (@xpitch_list){
my @xpitchb = split(/,/,$xpitcha);
foreach my $ypitcha (@ypitch_list){
my @ypitchb = split(/,/,$ypitcha);
foreach my $line (@color_list){
  if(defined($line)){
  my @colors = split(/,/,$line);
   for(my $x = 0; $x <= $hash{width}; $x=$x+$xpitch){
     $xpitch = $xpitchb[rand @xpitchb];
    for(my $y = 0; $y <= $hash{height}; $y=$y+$xpitch){
      my $color = $colors[rand @colors];
      my $radius = $radiusb[rand @radiusb];
      $ypitch = $ypitchb[rand @ypitchb];
      $id = $i;
      #print $color."\n";
      #drawacircle
      if($radius){
        $svg->circle(id=>$id, cx=>$x, cy=>$y, r=>$radius, fill=>$color );
      }
      elsif(0){
        my $xv = [$x+$radius,$x+$radius*2,$x+$radius*3];
        my $yv = [$y+$radius,$y+$radius*2,$y+$radius];
        my $points = $svg->get_path(x=>$xv, y=>$yv, -type=>'polygon');
        $svg->polygon( %$points, id=>$id, fill=>$color );
      }
      elsif(0){
      $svg->rect(x => $x, y => $y, width => $radius, height => $radius,
                 id => $id, fill => $color );
      }
      $i++;
    }
  }
  (my $linea = $line) =~ s/#| |\.//g;
  $radiusa=~ s/#| |\.//g;
  $xpitcha =~ s/#| |\.//g;
  $ypitcha =~ s/#| |\.//g;
  print $linea.$radiusa.$xpitcha.$ypitcha."\n";
  $filename = $dir."/".$run.$linea.$radiusa.$xpitcha.$ypitcha.".svg";
  open(FILE, '>', $filename) or die "Could not open file '$filename' $!";
  my $out = $svg->xmlify;
  print FILE $out;
  close FILE;
  undef $svg;
  $svg= SVG->new(%hash);
  $svg->rect( x=>0,
              y=>0,
              height=>$hash{height},
              width=>$hash{width},
              fill=>"black");
}
else{
  print "Undefined line.";
}}}}}
opendir DIR, $dir or die "cannot open dir $dir: $!";
my @files = grep { -f && /\.svg$/ } readdir DIR;
closedir DIR;
my $savedir = $dir."/".$run."/";
make_path($savedir,{ verbose => 1, mode => 0711,});
foreach my $filename (@files){
  my $filename2 = $filename;
  $filename2 =~ s/\.svg/\.png/;
  `Inkscape $filename --export-png=$filename2`;
}
MoveFiles("*.svg", $run);
MoveFiles("*.png", $run);
sub open_colorlist
{
  my $filename = shift;
  open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
  while (my $row = <$fh>) {
    chomp $row;
    if(defined($row)){push(@color_list,$row);}
  }
  foreach(@color_list){print $_."\n";}
  print "\n";
  close $fh;
}
sub open_ypitchlist
{
  my $filename = shift;
  open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
  while (my $row = <$fh>) {
    chomp $row;
    if(defined($row)){push(@ypitch_list,$row);}
  }
  foreach(@ypitch_list){print $_."\n";}
  print "\n";
  close $fh;
}
sub open_xpitchlist
{
  my $filename = shift;
  open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
  while (my $row = <$fh>) {
    chomp $row;
    if(defined($row)){push(@xpitch_list,$row);}
  }
  foreach(@xpitch_list){print $_."\n";}
  print "\n";
  close $fh;
}
sub open_radiuslist
{
  my $filename = shift;
  open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
  while (my $row = <$fh>) {
    chomp $row;
        if(defined($row)){push(@radius_list,$row);}
  }
  foreach(@radius_list){print $_."\n";}
  print "\n";
  close $fh;
}
sub MoveFiles {
    my $s = shift;
    my $d = shift;
    print "$s $d \n";
    `move $s $d`;
    (-e "$d" && !-e $s) ? print "Move successfully\n" : print "Move error $d \n".$!;
}
