#!perl -w -I ../lib
#
use strict;
use Deco::Dive;
use Deco::Dive::Plot;
use Getopt::Long;

# some defaults
my $model = 'haldane';
my $confdir = '../conf';
my $file    = 'pressures.png';
my $data    = '../t/data/dive.txt';
my $width   = 600;
my $height  = 400;

GetOptions ( "file=s"   => \$file ,
             "data=s"   => \$data ,
             "width=i"   => \$width ,
             "height=i"   => \$height ,
	     "model=s"   => \$model,
	     "confdir=s"  => \$confdir,
             );

my $dive = Deco::Dive->new(configdir => $confdir );
# first load some data
$dive->load_data_from_file( file => $data );

# and simulate haldane model
$dive->simulate( model => $model);

my $diveplot = Deco::Dive::Plot->new( $dive, width => $width, height => $height );

# do the pressure graph
if (-e $file) {
   unlink($file);
}
$diveplot->pressures( file => $file);

$diveplot->depth( );

$diveplot->nodeco( );

