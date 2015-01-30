#!/usr/bin/perl -w
use strict;
use SVG;

# create an SVG object
my %hash;
$hash{width} = 750;
$hash{height} = 750;
my $filename = "./filename.svg";
my $filename2 = "./filename.png";
my $svg= SVG->new(%hash); 

#
my $x;
my $xpitch = 12;
my $y;
my $ypitch = 11;
my $radius= 12;
my $color = "red";
my $outline_color = "black";
my $outline_width = 10;
my $id;
my @color_list = ("red","blue","black");
#method for list of colors;
#method for varying size of elements randomly with tolerance
#
$svg->rect( x=>0,
            y=>0,
            height=>$hash{height},
            width=>$hash{width},
            fill=>"green");
foreach(@color_list){
    for(my $x = 0; $x <= $hash{width}; $x=$x+$xpitch){
        for(my $y = 0; $y <= $hash{height}; $y=$y+$ypitch){

            $id = $x."_".$y."_".$radius."_".$_; 
            #drawacircle
            $svg->circle(id=>$id,
                         cx=>$x,
                         cy=>$y,
                         r=>$radius,
                         fill=>$_);
            print $_."\n";
            $xpitch+=10;
            $ypitch+=15;
        }
    }
}

open(FILE, '>', $filename) or die "Could not open file '$filename' $!";
my $out = $svg->xmlify;
print FILE $out;
`convert $filename $filename2`;