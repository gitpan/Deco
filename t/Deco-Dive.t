use Test::More tests => 14;
use Test::Exception;

my $Class = 'Deco::Dive';

use_ok($Class);

my $dive = new $Class ( configdir => './conf' );
isa_ok( $dive, $Class, "Creating dive");

# croak on missing parameters
throws_ok { $dive->model( ) } qr/specify the config file or model/ , "Missing parameters";

# croak on non existing config file
throws_ok { $dive->model( model => 'Foobar2' ) } qr/The file .+ does not exist/ , "Model without config file";

# set a right model
my $model = 'haldane';
$file = "./conf/$model.cnf";
ok( $dive->model( model => $model, config => $file ), "can set a $model model");

my $tissue = $dive->{tissues}[2];
isa_ok( $tissue, 'Deco::Tissue', "Tissue 2 is a Deco::Tissue");
is( $dive->{model}, 'haldane', "Model haldane is correct");
is( $dive->{model_name}, 'Original Haldane', "Model name is correct");

# croak on missing data
throws_ok { $dive->simulate( model => 'FooBar' ) } qr/Invalid model/ , "Wrong model";
throws_ok { $dive->simulate( model => $model ) } qr/No dive profile data/ , "Croaks on missing data";

# load some data
my $file = "./t/data/dive.txt";
$dive->load_data_from_file( file => $file);

# peek inside the data
my @times  = @{ $dive->{timepoints} };
my @depths = @{ $dive->{depths} };
is( $times[0], 0,  "Starting time is 0 seconds");
is( $depths[0], 0,  "Starting depth is 0 meter");

is( $times[4], 120,  "4th point is 120 seconds");
is( $depths[4], 3.9,  "and 3.9 meter");
# 
# simulate
$dive->simulate();


