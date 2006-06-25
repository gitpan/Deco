#######################################
# Module  : Deco::Dive::Plot.pm
# Author  : Jaap Voets
# Date    : 02-06-2006
# Version : 0.1
#######################################
package Deco::Dive::Plot;

use strict;
use warnings;
use Carp;
use GD::Graph::lines;
use GD::Graph::bars;

our $VERSION = '0.1';

# some constants used 
use constant DEFAULT_WIDTH  => 600;
use constant DEFAULT_HEIGHT => 400;

# Constructor
sub new {
    my $class = shift;
    my $dive = shift;   

    croak "Please provide a Deco::Dive object for plotting" unless ref($dive) eq 'Deco::Dive';

    my $self = { dive => $dive };
    
    bless $self, $class;
    
    return $self;
}

# plot the depth versus time 
sub depth {
    my $self = shift;
    my %opt  = @_;
    
    # divide the seconds by 60 to get minutes
    my @times = map { $_ / 60 } @{ $self->{dive}->{timepoints} };
    croak "There are no timestamps set for this dive" if ( scalar( @times ) == 0);

    # multiply the depths by -1 to get a nicer picture
    my @depths  = map { -1 * $_ } @{ $self->{dive}->{depths} };
    croak "There are no depth points set for this dive" if ( scalar( @depths ) == 0);

    my $width  = $opt{width}  || DEFAULT_WIDTH;
    my $height = $opt{height} || DEFAULT_HEIGHT;
    my $outfile = $opt{file}  || 'depth.png';

    my $graph =  GD::Graph::lines->new($width, $height);
    $graph->set(
             x_label           => 'Time (minutes)',
             y_label           => 'Depth (meter)',
             title             => 'Depth profile',
	     y_max_value       => 0,	
	    ) or die $graph->error;

    my @data = (\@times, \@depths);

    my $gd = $graph->plot(\@data) or die $graph->error;
    open(IMG, ">$outfile") or die $!;
    binmode IMG;
    print IMG $gd->png;
    close IMG;

}

sub pressures {
    my $self = shift;
    my %opt  = @_;

    $self->_info( 'pressure',  %opt );
}

# plot a certain info series for all tissues
sub _info {
    my $self = shift;
    my $what = shift; # one of no_deco, safe_depth, percentage or pressure
    my %opt  =@_;

    my @times = @{ $self->{dive}->{timepoints} };
    croak "There are no timestamps set for this dive" if ( scalar( @times ) == 0);
    
    # divide the seconds by 60 to get minutes
    my @minutes = map { $_ / 60 } @{ $self->{dive}->{timepoints} };
    
    my $width  = $opt{width}  || DEFAULT_WIDTH;
    my $height = $opt{height} || DEFAULT_HEIGHT;
    my $outfile = $opt{file}  || $what . '.png';
    
    my $graph =  GD::Graph::lines->new($width, $height);
    $graph->set(
		x_label           => 'Time (minutes)',
		y_label           => 'Depth (meter)',
		title             => "$what profile",
		) or die $graph->error;
    
    my @data;
    push @data, \@minutes; # load the time values

    foreach my $tissue ( @{ $self->{dive}->{tissues} } ) {
	next if ! defined $tissue;   # first array element is empty
	my $num = $tissue->nr;

	my @y = ();
	foreach my $time (@times) {
	    push @y, $self->{dive}->{info}->{$num}->{$time}->{$what};
	}

	# add the series to the plot data
	push @data, \@y;
    }
    
    my $gd = $graph->plot(\@data) or die $graph->error;
    open(IMG, ">$outfile") or die $!;
    binmode IMG;
    print IMG $gd->png;
    close IMG;

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

Jaap Voets, E<lt>narked@xperience-automatisering.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jaap Voets

=cut
