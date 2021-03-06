#!/usr/bin/perl -w
#dependencies, Inkscape
use strict;
use SVG;
use Cwd;
use Data::Dumper;
use Getopt::Long;
use File::Path qw(make_path);
use File::Copy qw(copy);
use List::Util qw(min max);
# create an SVG object
my %hash;
$hash{width} = 1000;
$hash{height} = 1000;
my $name = "image_generator.pl";
my $svg= SVG->new(%hash);
my $mode = 4;
#$mode == 1 #Circle
#$mode == 2 #Triangle
#$mode == 3 #Rectangle
#$mode == 4 #Line
#$mode == 5 #Ellipse
#$mode == 6 #Octagon
my $x;
my $y;
my ($xpitch, $ypitch, $xp, $yp);
my ($id,$p_list);
my @point;
my $rotation_seed = 1;
my $rotation_line = 1;
my $convert = 0;
my @color_list  = ();
my @pitch_list = ();
my @radius_list = ();
my $run= "";
my $dir = getcwd;
######################
init();
run_all_modes();
convert_svgs_to_png();
exit 0;
######################
sub init
{
  GetOptions ("c=i" => \$convert)   # flag
  or die("Error in command line arguments\n");
  if($convert >= 1){convert_current_dir($convert); exit 0;}
  run_number('lib/run.txt');
  copy_file($name, "RUN".$run."/".$name.$run);
  load_list('lib/color_list.csv' , \@color_list);
  load_list('lib/radius_list.csv', \@radius_list);
  load_list('lib/pitch_list.csv' , \@pitch_list);
}
sub convert_current_dir
{
  my $r = shift;
  my $s_dir = $dir."/svg/RUN".$r;
  print "checking for svg in $s_dir\n";
  opendir DIR, $s_dir or die "cannot open dir $s_dir: $!";
  my @files = readdir DIR ;
  closedir DIR;
  my $i = 0;
  foreach my $f_name (@files){
    my $f_name2 = $f_name;
    $f_name2 =~ s/\.svg/\.png/;
    if(-e $dir."/RUN".$r."/".$f_name2)
      { splice(@files, $i, 1); }
    $i++;
  }
  my $file_count = scalar(@files);
  my $counter = 1;
  chdir($s_dir);
  print "Converting " . $file_count . " svg files to png.\n";
  foreach my $filename (@files){
    my $filename2 = $filename;
    $filename2 =~ s/\.svg/\.png/;
    unless(-e $dir."/RUN".$r."/".$filename2){
      print "Converting $counter/$file_count\n$filename to\n$filename2\n\n";
      `Inkscape $filename --export-png=$filename2`;
      $counter++;
    }
  }
  move_files("*.png", $dir."/RUN".$r);
}
sub run_all_modes
{
  for(my $i=1; $i<=6; $i++){
    $mode = $i;
    first($mode);
    reset_globals();
    concentric($mode);
    reset_globals();
    fill_frame($mode);
    reset_globals();
  }
}
sub reset_globals
{
  $x = $y = 0;
  ($xpitch,$ypitch,$xp,$yp) = (undef) x 4;
  ($id,$p_list,@point) = (undef) x 3;
  $rotation_seed = 1;
  $rotation_line = 1;
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
  opendir DIR, $dir."/RUN".$run."/" or die "cannot open dir $dir: $!";
  my @files = grep { -f && /\.svg$/ } readdir DIR;
  closedir DIR;
  my $file_count = scalar(@files);
  my $counter = 1;
  print "Converting " . $file_count . " svg files to png.\n";
  foreach my $filename (@files){
    my $filename2 = $filename;
    $filename2 =~ s/\.svg/\.png/;
    print "Converting $counter/$file_count\n$filename to\n$filename2\n\n";
    `Inkscape $filename --export-png=$filename2`;
    $counter++;
  }
  my $savedir = $dir."/RUN".$run."/";
  make_path($savedir,{ verbose => 1, mode => 0711,});
  move_files("*.svg", $dir."/svg/RUN".$run);
}
sub generate_point_list
{ #Generates a list of points to use covering a 2d space.
  my $i=0;
  $p_list = $pitch_list[rand @pitch_list];
  my @p = split(/,/,$p_list);
  for(my $x = min(@p); $x <= $hash{width} - min(@p); $x=$x+$xp){
    $xp = $p[rand @p];
    for(my $y = min(@p); $y <= $hash{height} - min(@p); $y=$y+$yp){
      $yp = $p[rand @p];
      $point[$i]=$x.",".$y;
      $i++;
    }
  }
}
sub generate_fill_list
{ #Generates a list of points to fill an area with a shape covering a 2d space.
  my $mode = shift;
  my $radius = shift;
  my $i = 0;
  $p_list = $pitch_list[rand @pitch_list];
  my @p = split(/,/,$p_list);
  if($mode == 1){ #circle
    for(my $x = $radius; $x <= $hash{width} - $radius; $x+=2*$radius){
      for(my $y = $radius; $y <= $hash{height} - $radius; $y+=2*$radius){
        $point[$i]=$x.",".$y; #print "point $i = $x, $y\n";
        $i++;
      }
    }
  }
  elsif($mode == 2){ #Triangle
    for(my $y = 0; $y <= $hash{height}; $y+=5*$radius){
      for(my $x = 0; $x <= $hash{width}; $x+=2.5*$radius){
        $point[$i]=$x.",".$y;
        $i++;
      }
    }
  }
  elsif($mode == 3){ #Rectangle
    for(my $y = 0; $y <= $hash{height}; $y+=$radius){
      for(my $x = 0; $x <= $hash{width}; $x+=1.618*$radius){
        $point[$i]=$x.",".$y;
        $i++;
      }
    }
  }
  elsif($mode == 4){ #Line
    for(my $y = 0; $y <= $hash{height}; $y+=3*1.618*$radius){
      for(my $x = 0; $x <= $hash{width}; $x+=$radius){
        $point[$i]=$x.",".$y;
        $i++;
      }
    }
  }
  elsif($mode == 5){ #Ellipse
    for(my $y = 0; $y <= $hash{height}; $y+=2*$radius){
      for(my $x = 0; $x <= $hash{width}; $x+=.5*$radius){
        $point[$i]=$x.",".$y;
        $i++;
      }
    }
  }
  elsif($mode == 6){ #octagon
    for(my $x = min(@p); $x <= $hash{width} - min(@p); $x=$x+$xp){
      $xp = $p[1];
      for(my $y = min(@p); $y <= $hash{height} - min(@p); $y=$y+$yp){
        $yp = $p[1];
        $point[$i]=$x.",".$y; #print "point $i = $x, $y\n";
        $i++;
      }
      $i++;
    }
  }
}
sub fill_frame
{
  my $mode = shift;
  my $i = 0;
  foreach my $radiusa (@radius_list){
  my @radiusb = split(/,/,$radiusa);
  foreach my $color_list (@color_list){
    my @colors = split(/,/,$color_list);
    add_bg();
    my $radius = (sort { $b <=> $a } @radiusb)[0];
    generate_fill_list($mode,$radius);
    my $previous_x = 0;
    foreach my $loc (@point){
      my ($x,$y) = split(/,/,$loc);
      if(defined($x) && defined($y)){
      foreach my $r (sort {$b <=> $a} @radiusb){ #this is modified to use all radius list and decrement downward.
        my $c = $colors[rand @colors];
        if(defined($mode) && defined($r) && defined($c) && defined($i) && defined($radius)){
          make_shape($x,$y,$mode,$r,$c,$i,$radius);
        }
        $i++;
        $rotation_line++;
      }}
      $rotation_seed++;
    }
    save_file($color_list,$radiusa,"fill",$mode,"ConCent");
    $i = 0;
    @point = ();
  }}
}
sub concentric
{
  my $mode = shift;
  my $i = 0;
  foreach my $radiusa (@radius_list){
  my @radiusb = split(/,/,$radiusa);
  foreach my $color_list (@color_list){
    my @colors = split(/,/,$color_list);
    add_bg($colors[rand @colors]);
    generate_point_list();
    my $radius = (sort { $b <=> $a } @radiusb)[0];
    my $pitches = $p_list;
    foreach my $loc (@point){
      my ($x,$y) = split(/,/,$loc);
      if(defined($x) && defined($y)){
      foreach my $r (sort {$b <=> $a} @radiusb){ #this is modified to use all radius list and decrement downward.
        my $c = $colors[rand @colors];
        if(defined($mode) && defined($r) && defined($c) && defined($i) && defined($radius)){
          make_shape($x,$y,$mode,$r,$c,$i,$radius);
        }
        $i++;
      }}}
      save_file($color_list,$radiusa,$pitches,$mode,"ConCent");
      $i = 0;
      @point = ();
  }}
}
sub first
{
  my $mode = shift;
  my $i = 0;
  add_bg();
  foreach my $radiusa (@radius_list){
  my @radiusb = split(/,/,$radiusa);
  my $radius = (sort { $b <=> $a } @radiusb)[0];
  foreach my $pitcha (@pitch_list){
  my @pitchb = split(/,/,$pitcha);
  foreach my $color_list (@color_list){
    if(defined($color_list)){
    my @colors = split(/,/,$color_list);
    my $pitch = $pitchb[rand @pitchb];
     for(my $x = 0; $x <= $hash{width}; $x=$x+$pitch){
      $pitch = $pitchb[rand @pitchb];
      for(my $y = 0; $y <= $hash{height}; $y=$y+$pitch){
        my $c = $colors[rand @colors];
        my $r = $radiusb[rand @radiusb];
        if(defined($x) && defined($y) && defined($mode) && defined($r) &&
           defined($c) && defined($i) && defined($radius)){
          make_shape($x,$y,$mode,$r,$c,$i,$radius);
        }
        $i++;
      }
    }
    save_file($color_list,$radiusa,$pitcha,$mode,"first");
    $i = 0;
    @point = ();
  }
  else{
    print "Undefined line.";
  }}}}
}
sub make_shape
{
  my $x = shift;
  my $y = shift;
  my $mode = shift;
  my $r = shift;
  my $c = shift;
  my $i = shift;
  my $pitch = shift;
  if($mode == 1){ #Circle
    $svg->circle(id=>$i, cx=>$x, cy=>$y, r=>$r, fill=>$c);
  }
  elsif($mode == 2){ #Triangle
    my $xv;
    my $yv;
    my $rotate_step = 180;
    my $rotation = $rotate_step*$rotation_seed;
    if($rotation >= 360){$rotation -= 360; $rotation_seed = 0;}
    if($rotation == 0){
      $xv = [$x+2.5*($r),$x,$x-2.5*($r)];
      $yv = [$y+2.5*($r),$y-2.5*($r),$y+2.5*($r)];
    }
    elsif( $rotation == 180){
      $xv = [$x-2.5*($r),$x,$x+2.5*($r)];
      $yv = [$y-2.5*($r),$y+2.5*($r),$y-2.5*($r)];
    }
    if(defined($xv) && defined($yv) && defined($c)){
      my $points = $svg->get_path(x=>$xv, y=>$yv, -type=>'polygon');
      $svg->polygon(%$points, id=>$i, fill=>$c);
    }
  }
  elsif($mode == 3){ #Rectangle
    my $xv = [$x-(1.618*$r/2),$x-(1.618*$r/2),$x+(1.618*$r/2),$x+(1.618*$r/2)];
    my $yv = [$y-($r/2),$y+($r/2),$y+($r/2),$y-($r/2)];
    my $points = $svg->get_path(x=>$xv, y=>$yv, -type=>'polygon');
    $svg->polygon(%$points, id=>$i, fill=>$c);
  }
  elsif($mode == 4){ #Line
    my $rotate_step = 45;
    my $rotation = $rotate_step*$rotation_line;
    if($rotation >= 360){$rotation -= 360; $rotation_line = 0;}
    my $y_mod = $y+$r;
    my $x_mod = $x+2*$r;
    $svg->line(x1 => $x, y1 => $y-(3*1.618*$r/2), x2 =>$x, y2 =>$y+(3*1.618*$r/2), id => $i,
               transform => "rotate($rotation $x_mod $y_mod)", style=>{
      'stroke'=>$c,
      'stroke-width'=>$pitch/2,
      }
    );
  }
  elsif($mode == 5){ #Ellipse
    $svg->ellipse(cx => $x, cy => $y, rx=> .25*$r, ry => $r, id => $i, style=>{
            'fill'=> $c,
            'stroke'=>$c,
        });
  }
  elsif($mode == 6){ #Octagon
    my $xv = [$x+1.5*($r),$x+1.5*($r),$x+0.5*($r),$x-0.5*($r),$x-1.5*($r),$x-1.5*($r),$x-0.5*($r),$x+0.5*($r)];
    my $yv = [$y+0.5*($r),$y-0.5*($r),$y-1.5*($r),$y-1.5*($r),$y-0.5*($r),$y+0.5*($r),$y+1.5*($r),$y+1.5*($r)];
    my $points = $svg->get_path(x=>$xv, y=>$yv, -type=>'polygon');
    $svg->polygon(%$points, id=>$i, fill=>$c);
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
  my $colors_list = shift;
  my $radiusa = shift;
  my $pitches = shift;
  my $mode = shift;
  my $func = shift;
  (my $colors = $colors_list) =~ s/#| |\.//g;
  $radiusa =~ s/#| |\.//g;
  $pitches  =~ s/#| |\.//g;
  $func = ".".$func;
  $mode = ".".$mode;
  $radiusa = ".".$radiusa;
  $pitches = ".".$pitches;
  $colors = ".".$colors;
  print $run.$func.$mode.$colors.$radiusa.$pitches."\n";
  my $filename = $dir."/RUN".$run."/"."RUN".$run.$func.$mode.$colors.$radiusa.$pitches.".svg";
  my $savedir = $dir."/RUN".$run."/";
  make_path($savedir,{ verbose => 1, mode => 0711,});
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
