#!perl -w -I ../lib

use strict;
use Deco::Tissue;

# setup new tissue
my $tis = new Deco::Tissue( halftime => 4 , M0 => 1.52, deltaM => 1.10);
$tis->depth(30);
$tis->rq(0.9);

#print "Go to 30 meters instantly:\n";
#print $tis->info;

my $ppm = 6; #points per minute

# get a series of N2 pressures
my $haldane = $tis->_haldanePressure();
foreach my $minute (0 .. 10) {
    for (my $i = 0; $i < $ppm; $i++) { 
	my $time = ($minute * 60) + ($i * 60) / $ppm;
	$tis->time( $time );
	my $press = $tis->internalpressure(gas => 'n2'); 
	print "$time\t$press\n";
    }
}

print "After 10 minutes at 30 meters:\n";
print $tis->info;

# now go back to 20 meters for 5 minutes
$tis->depth(20);
foreach my $minute (11 .. 15) {
    for (my $i = 0; $i < $ppm; $i++) { 
	my $time = ($minute * 60) + ($i * 60) / $ppm;
	$tis->time( $time );
	my $press = $tis->internalpressure(gas => 'n2'); 
	print "$time\t$press\n";
    }
}

#print "After 5 minutes at 20 meters:\n";
#print $tis->info;

# and to 10 meters for 5 minutes
$tis->depth(10);
foreach my $minute (16 .. 20) {
    for (my $i = 0; $i < $ppm; $i++) { 
	my $time = ($minute * 60) + ($i * 60) / $ppm;
	$tis->time( $time );
	my $press = $tis->internalpressure(gas => 'n2'); 
	print "$time\t$press\n";
    }

}

print "After 5 minutes at 10 meters:\n";
print $tis->info;

# and to surface for 30 minutes
$tis->depth(0);
foreach my $minute (21 .. 50) {
    for (my $i = 0; $i < $ppm; $i++) { 
	my $time = ($minute * 60) + ($i * 60) / $ppm;
	$tis->time( $time );
	my $press = $tis->internalpressure(gas => 'n2'); 
	print "$time\t$press\n";
    }

}

print "After 30 minutes at surface:\n";
print $tis->info;

