use Test::More tests => 5;
use Test::Exception;

my $Class = 'Deco::Dive::Table';

use_ok($Class);
use Deco::Dive;

throws_ok { my $diveplot = new $Class; } qr/Please provide a Deco::Dive/ , "can't create table without a dive object";

my $dive = new Deco::Dive();
$dive->model( config => './conf/haldane.cnf');

my $divetable = $Class->new( $dive );

isa_ok( $divetable, $Class, "Creating dive-table");

# perform calculation
$divetable->calculate( );

my $table = $divetable->output();
like ($table, qr/No Decomp/, "table returned");

# now do one with a template
my $template= "row #DEPTH# -> #time#\n";
$table = $divetable->output(template => $template);

like ($table, qr/^row \d+/, "and now one with template");

