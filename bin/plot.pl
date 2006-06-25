#!perl -w -I ../lib

use strict;
use GD::Graph::lines;
use Getopt::Long;
use Carp;

my $file = '';
my $width = 300; # pixels
my $height= 300; # pixels
my $out   = 'plot.png';

GetOptions ( "file=s"   => \$file ,
	     "out=s"   => \$out ,
	     "width=i"   => \$width ,
	     "height=i"   => \$height ,
	     );

if (! -e $file) {
    croak "File $file does not exist!";
}
open(IN, $file) || croak "can't open file $file for reading";
my (@x, @y);
while (my $line = <IN>) {
    chop($line);
    my ($minute, $press) = split(/\t/, $line);
    push @x, $minute;
    push @y, $press; 
}
close(IN);

my $graph =  GD::Graph::lines->new($width, $height);
$graph->set( 
	     x_label           => 'Time (minutes)',
	     y_label           => 'N2 Tissue pressure (bar)',
	     title             => 'Tissue pressure',
	     ) or die $graph->error;

my @data = (\@x, \@y);

my $gd = $graph->plot(\@data) or die $graph->error;
open(IMG, ">$out") or die $!;
binmode IMG;
print IMG $gd->png;
close IMG;
