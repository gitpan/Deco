#######################################
# Module  : Deco::Dive.pm
# Author  : Jaap Voets
# Date    : 027-05-2006
# Version : 0.1
#######################################
package Deco::Dive;

use strict;
use warnings;
use Carp;
use Config::General;
use Deco::Tissue;

our $VERSION = '0.2';

our @MODELS = ('haldane', 'padi', 'usnavy');

# Constructor
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {};

    # the data points for the dive, bot arrays
    $self->{timepoints} = [];
    $self->{depths}     = [];

    # an array of tissues to use
    $self->{tissues}    = ();
    
    # super structure to remember all tissue info per timepoint
    $self->{info}       = {};

    # where can we find the config?
    $self->{config_dir} = $args{configdir} || '.';

    # theoretical tissue model we'll be using
    $self->{model}      = '';
    bless $self, $class;
    
    return $self;
}

# load the dive profile data from a file
sub load_data_from_file {
    my $self = shift;
    my %opt  = @_;

    my $file = $opt{file};
    croak "No file specified, to load dive profile" unless $file;
    # check whether the file exists
    croak "File $file does not exist" unless ( -e $file);

    # field separator
    my $sep        = $opt{separator} || ';';
    my $timefield  = $opt{timefield} || '0';
    my $depthfield = $opt{depthfield} || 1;
    my $timefactor = $opt{timefactor} || 1; # factor to get each time point in seconds

    my (@times, @depths);
    open (IN, $file) || croak "Can't open file $file for reading";
    while (my $line = <IN>) {
	chomp($line);
	my @fields = split(/$sep/, $line);
	push @times, $timefactor * $fields[$timefield];
	my $depth = $fields[$depthfield];
	if ($depth < 0) {
	    $depth = -1 * $depth;
	}
	push @depths, $depth;
    }
    close(IN);
    
    $self->{depths}     = \@depths;
    $self->{timepoints} = \@times;
    
}

# pick a model and load the corresponding config
# this will create a list of tissues
sub model {
    my $self = shift;
    my %opt  = @_;

    my $model = lc($opt{model}) || 'haldane';
    croak "Invalid model $model" unless grep { $_ eq $model } @MODELS;

    my $config_file = $opt{config};

    # load the config
    my $conf   = new Config::General(  -ConfigFile => $config_file,  -LowerCaseNames => 1 );
    my %config = $conf->getall;
 
    # remember the model we use
    $self->{model} = $config{model};
    
    # cleanup first
    $self->{tissues} = ();

    # create all the tissues
    foreach my $num (keys %{ $config{tissue} }) {
	$self->{tissues}[$num] = new Deco::Tissue( halftime => $config{tissue}{$num}{halftime}, 
						   M0       => $config{tissue}{$num}{m0}, 
						   deltaM   => $config{tissue}{$num}{deltam} ,
						   nr       => $num,
						   );
    }
    
    return 1;
}

# run the simulation
sub simulate {
    my $self = shift;
    my %opt  = @_;

    my $model = lc($opt{model}) || 'haldane';
    croak "Invalid model $model" unless grep { $_ eq $model } @MODELS;
    
    # first load the model
    $self->model( model => $model,  config => $self->{config_dir} . '/' . $model . '.cnf');
    
    # then check whether we loaded data
    if ( scalar( @{ $self->{timepoints} } ) == 0 ) {
	croak "No dive profile data present, forgot to call dive->load_data_from_file() ?";
    }
    
    # step through all the timepoints & depths
    my $i = 0;
    my @times  = @{ $self->{timepoints} };
    my @depths = @{ $self->{depths} };
    foreach my $time ( @times ) {
	# get the corresponding depth
	my $depth = $depths[$i];
	$i++;

	# loop over all the tissues
	foreach my $tissue ( @{ $self->{tissues} } ) {
	    next if ! defined $tissue;

	    my $num  = $tissue->nr;

	    $tissue->point( $time, $depth );
	    
	    # we like to have 
	    # no_deco time
	    $self->{info}->{$num}->{$time}->{nodeco_time}    =  $tissue->nodeco_time();

	    # safe depth
	    $self->{info}->{$num}->{$time}->{safe_depth} =  $tissue->safe_depth();

	    # percentage filled compared to M0 pressure
	    $self->{info}->{$num}->{$time}->{percentage} =  $tissue->percentage();

	    # internal pressure
	    $self->{info}->{$num}->{$time}->{pressure}   = $tissue->internalpressure();

	}
    }
    
}

1;


__END__

=head1 NAME

Dive - Simulate a dive and corresponding tissues

=head1 SYNOPSIS

    use Deco::Dive;
my $dive = new Deco::Dive( );
$dive->load_data_from_file( file => $file);

$dive->simulate( model => 'haldane');


=head1 DESCRIPTION

The Dive model can be used to simulate a dive. You add data points, set some properties and call the simulate method to calculate the entire dive.

After simulating, you can retrieve info in several ways from the dive.



=head2 METHODS

=over 4

=item $dive->load_data_from_file( file => $file , timefield => 0, depthfield => 1, timefactor => 1, separator => ';');

Load data from a csv file. You HAVE to specify the filename. Additional options are timefield, the 0 based field number where the  timestamps are stored. Depthfield, field number where the depth (in meters is stored), separator, the fieldseparator and timefactor, the factor to multiply the time field with to transform them to seconds.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

In the docs directory you will find an extensive treatment of decompression theory in the file Deco.pdf. A lot of it has been copied from the www.deepocean.net website.

=head1 AUTHOR

Jaap Voets, E<lt>voets@blinck.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jaap Voets

=cut
