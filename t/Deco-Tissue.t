use Test::More tests => 18;
use Test::Exception;

my $Class = 'Deco::Tissue';

use_ok($Class);

my $tissue = new $Class;
isa_ok( $tissue, $Class, "Creating tissue without parameters");

my $tis  =  new Deco::Tissue( halftime => 300, M0 => 1.52, deltaM => 1.10 );
isa_ok( $tis, $Class, "Creating tissue with halftime and max M-value parameters");

# try to set wrong depth and timestamp
throws_ok { $tis->depth( -10 ) } qr/can not be negative/ , "can't set negative depths";
throws_ok { $tis->time( -10 ) } qr/can not be negative/ , "can't set negative timestamps";

# get internal pressure at start
my $N2press = 0.741507; # bar at sealevel
is( $tis->internalpressure(), $N2press, "Starting internal pressure is $N2press");

# check _depth2pressure
is( $tis->_depth2pressure(0), 0, "Sea level should be 0 bar");
is( $tis->_depth2pressure(15), 1.5, "15 meters should be 1.5 bar");

# same for ambient
$tis->depth(0);
is( $tis->ambientpressure(), 1, "Starting ambient pressure is 1 bar");
$tis->depth(22.5);
is( $tis->ambientpressure(), 3.25, "Ambient pressure at 22.5 meters is 3.25 bar");

# try the alveolar pressure (with default RQ=0.8)
$tis->depth(0);
is( $tis->_alveolarPressure(), 0.741507, "Alveolar pressure for 78% N2 is 0.741507 bar at sea level");

# now with RQ=0.9 of US navy alveolar pressure
$tis->depth(0);
$tis->rq(0.9);
is( $tis->_alveolarPressure(), 0.735722, "Alveolar pressure for 78% N2 is 0.735722 bar at sea level with RQ of 0.9");

# check the M value, at depth 0 it is the same as M0
is( $tis->M( depth => 0), $tis->{m0}, "M0 value set OK");

# half time
my $hlf = 3; # minutes
# set it 
is($tis->halftime($hlf), $hlf, "Half time set to $hlf");
# retrieve it
is($tis->halftime(), $hlf, "Half time $hlf returned correctly");
# get the k value (ln(2)/halftime)
is($tis->k(), ( log(2) / $hlf), "K value calculated correctly");

# find the pressure for a 30 minute dive to 30 minutes in the 4 minute tissue
$hlf = 4;
$tis->depth(30);
$tis->halftime($hlf);
my $function_ref = $tis->_haldanePressure();

is( &$function_ref(30), 3.06282716206838, "Haldane pressure calculated OK for $hlf minute tissue");

# get info
my $info = $tis->info();
like($info, qr/= Halftime .*: $hlf/, "Tissue info looks good");

