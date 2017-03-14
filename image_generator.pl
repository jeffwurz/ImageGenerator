#!/usr/bin/perl -w
#dependencies, Inkscape
use strict;
use SVG;
use Cwd;
use Data::Dumper;
use File::Path qw(make_path);
use File::Copy qw(copy);
use List::Util qw(min max);
# create an SVG object
my %hash;
$hash{width} = 1000;
$hash{height} = 1000;
my $name = "image_generator.pl";
my $svg= SVG->new(%hash);
#
my $mode = 1;
my @modes = (1,2,3,4,5,6);
my $x;
my $y;
my ($xpitch, $ypitch, $xp, $yp);
my $outline_width = 10;
my $outline_color = "black";
my ($id,$p_list);
my %point;
my @color_list = ();
my @xpitch_list = ();
my @radius_list = ();
my @ypitch_list = ();
my $run= "";
my $dir = getcwd;
######################
init();#method for list of colors;
first($mode);#method for varying size of elements randomly with tolerance
concentric($mode);
convert_svgs_to_png();
exit 0;
######################
sub init
{
  run_number('lib/run.txt');
  copy_file($name, "RUN".$run."/".$name.$run);
  load_list('lib/color_list.csv' , \@color_list);
  load_list('lib/radius_list.csv', \@radius_list);
  load_list('lib/pitch_list.csv' , \@xpitch_list);
  load_list('lib/pitch_list.csv' , \@ypitch_list);
}
sub load_list
{
  my $filename = shift;
  my $list_ref = shift;
  open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
  while (my $row = <$fh>) { chomp $row; if(defined($row)){push(@$list_ref,$row);} }
  print_list($list_ref);
  close $fh;
}
sub run_number
{
  my $filename = shift;
  open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
  while (my $row = <$fh>) { chomp $row; if(defined($row)){$run = $row;} }
  print "Run number = ".$run."\n";
  close $fh;
  open(my $fh2, '>:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
  my $next_run = $run + 1;
  print "Next Run  = ".$next_run."\n";
  print $fh2 $next_run;
  close $fh2;
}
sub copy_file
{
  my $s = shift;
  my $d = shift;
  print "Copying $s to $d \n";
  copy $s, $d;
  (-e "$d" && -e $s) ? print "Copied successfully\n" : print "Copy error $d \n".$!;
}
sub move_files
{
  my $s = shift;
  my $d = shift;
  print "$s $d \n";
  `move $s $d`;
  (-e "$d" && !-e $s) ? print "Move successfully\n" : print "Move error $d \n".$!;
}
sub print_list
{
  my $array_ref = shift;
  foreach(@$array_ref){ print $_."\n"; }
  print "\n";
}
sub convert_svgs_to_png
{
  opendir DIR, $dir or die "cannot open dir $dir: $!";
  my @files = grep { -f && /\.svg$/ } readdir DIR;
  closedir DIR;
  my $savedir = $dir."/RUN".$run."/";
  make_path($savedir,{ verbose => 1, mode => 0711,});
  print "Converting " . scalar(@files) . " svg files to png.\n";
  foreach my $filename (@files){
    my $filename2 = $filename;
    $filename2 =~ s/\.svg/\.png/;
    print "Converting $filename to $filename2\n";
    `Inkscape $filename --export-png=$filename2`;
  }
  move_files("*.svg", "RUN".$run);
  move_files("*.png", "RUN".$run);
}
sub generate_point_list
{ #Generates a list of points to use covering a 2d space.
  #References pitch_list
  my $i=1;
  $p_list = $xpitch_list[rand @xpitch_list];
  my @p = split(/,/,$p_list);
  for(my $x = min(@p); $x <= $hash{width} - min(@p); $x=$x+$xp){
    $xp = $p[rand @p];
    for(my $y = min(@p); $y <= $hash{height} - min(@p); $y=$y+$yp){
      $yp = $p[rand @p];
      $point{$i}=$x.",".$y;
      $i++;
    }
  }
}
sub concentric
{
  my $mode = shift;
  generate_point_list();
  my $i = 0;
  my $pitches = $p_list;
  foreach my $radiusa (@radius_list){
  my @radiusb = split(/,/,$radiusa);
  foreach my $line (@color_list){
    my @colors = split(/,/,$line);
    add_bg($colors[rand @colors]);
    foreach my $loc (%point){
      my ($x,$y) = split(/,/,$loc);
      if(defined($x) && defined($y)){
      foreach my $r (sort {$b <=> $a} @radiusb){ #this is modified to use all radius list and decrement downward.
        my $c = $colors[rand @colors];
        make_shape($x,$y,$mode,$r, $c, $i);
        $i++;
      }}}
      save_file($line,$radiusa, $pitches);
  }}
}
sub first
{
  my $mode = shift;
  my $i = 0;
  add_bg();
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
        my $c = $colors[rand @colors];
        my $r = $radiusb[rand @radiusb];
        $ypitch = $ypitchb[rand @ypitchb];
        make_shape($x,$y,$mode,$r,$c,$i);
        $i++;
      }
    }
    save_file($line,$radiusa,$xpitcha);
  }
  else{
    print "Undefined line.";
  }}}}}
}
sub make_shape
{
  my $x = shift;
  my $y = shift;
  my $mode = shift;
  my $r = shift;
  my $c = shift;
  my $i = shift;
  if($mode == 1){ #Circle
    $svg->circle(id=>$i, cx=>$x, cy=>$y, r=>$r, fill=>$c);
  }
  elsif($mode == 2){ #Triangle
    my $xv = [$x+$r,$x+$r*2,$x+$r*3];
    my $yv = [$y+$r,$y+$r*2,$y+$r];
    my $points = $svg->get_path(x=>$xv, y=>$yv, -type=>'polygon');
    $svg->polygon( %$points, id=>$i, fill=>$c);
  }
  elsif($mode == 3){ #Rectangle
  $svg->rect(x => $x, y => $y, width => $r, height => $r, id => $i, fill => $c);
  }
  elsif($mode == 4){ #Line
  $svg->line(x => $x, y => $y, width => $r, height => $r, id => $i, fill => $c);
  }
  elsif($mode == 5){ #Ellipse
  $svg->ellipse(x => $x, y => $y, width => $r, height => $r, id => $i, fill => $c);
  }
  elsif($mode == 6){ #Octagon
  my $scale_factor = 4;
  my $xv = [$x+2,$x+4,$x+5,$x+5,$x+4,$x+2,$x+1,$x+1]; #25
  my $yv = [$y,$y,$y+1,$y+3,$y+4,$y+4,$y+3,$y+1];     #25
  my $points = $svg->get_path(x=>$xv, y=>$yv, -type=>'polygon');
  $svg->polygon( %$points, id=>$i, fill=>$c, transform=>'scale('.$r/$scale_factor.')');
  }
}
sub add_bg
{
  my $bg = shift;
  if(!defined($bg)){$bg = "black";}
  $svg->rect( x=>0,
              y=>0,
              height=>$hash{height},
              width=>$hash{width},
              fill=>$bg);
}
sub save_file
{
  my $line = shift;
  my $radiusa = shift;
  my $pitches = shift;
  (my $linea = $line) =~ s/#| |\.//g;
  $radiusa =~ s/#| |\.//g;
  $pitches  =~ s/#| |\.//g;
  print $linea.$radiusa.$pitches."\n";
  my $filename = $dir."/"."RUN".$run.$linea.$radiusa.$pitches.".svg";
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
