#!/usr/bin/perl -w
use strict;
use SVG;
use Image::LibRSVG;

# create an SVG object
my %hash;
$hash{width} = 1000;
$hash{height} = 1000;
my $filename = "filename.svg";
my $filename = "filename.png";
my $svg= SVG->new(%hash); 

# draw a circle at position (100,100) with ID 'this_circle'
$svg->circle(id=>'this_circle',cx=>100,cy=>100,r=>50);
open FILE, ">", $filename or die $!
my $out = $svg->xmlify;
print FILE $out;
convert($filename,filename2);

#convert SVG to PNG
sub convert
{
    my $in  = shift;
    my $out = shift;
    if (not $out) {
    	die <<"END_USAGE";
    Converting svg file to png file:
    
    Usage: $0 file.svg  file.png
    END_USAGE
    }
    
    my $rsvg = Image::LibRSVG->new();
    $rsvg->convert( $in, $out );
}