#!/usr/bin/perl -w
#dependencies, Inkscape
use strict;
use SVG;
use Cwd;
use File::Path qw(make_path);
use File::Copy qw(copy);
# create an SVG object
my %hash;
$hash{width} = 1000;
$hash{height} = 1000;
my $filename = "./filename.svg";
my $filename2 = "./filename.png";
my $name = "image_generator.pl";
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
my $run= "";
my $dir = getcwd;
#method for list of colors;
#method for varying size of elements randomly with tolerance
######################
init();
first();
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
  my $next_run = $run+1;
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
sub first
{
  my $i = 0;
  my $choice = 0;
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
        $choice = int(rand(3));
        if($choice == 0){
          $svg->circle(id=>$id, cx=>$x, cy=>$y, r=>$radius, fill=>$color );
        }
        elsif($choice == 1){
          my $xv = [$x+$radius,$x+$radius*2,$x+$radius*3];
          my $yv = [$y+$radius,$y+$radius*2,$y+$radius];
          my $points = $svg->get_path(x=>$xv, y=>$yv, -type=>'polygon');
          $svg->polygon( %$points, id=>$id, fill=>$color );
        }
        elsif($choice == 2){
        $svg->rect(x => $x, y => $y, width => $radius, height => $radius, id => $id, fill => $color );
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
}
