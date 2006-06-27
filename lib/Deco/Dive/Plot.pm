#######################################
# Module  : Deco::Dive::Plot.pm
# Author  : Jaap Voets
# Date    : 02-06-2006
#######################################
package Deco::Dive::Plot;

use strict;
use warnings;
use Carp;
use GD::Graph::lines;
use GD::Graph::bars;

our $VERSION = '0.2';

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

    $opt{y_label} = 'Internal Pressure (bar)';
    $self->_info( 'pressure',  %opt );
}

sub nodeco {
    my $self = shift;
    my %opt  = @_;

    $opt{y_label} = 'No deco time (minutes)';
    $self->_info( 'nodeco_time',  %opt );
}

# plot a certain info series for all tissues
# after simulating a dive, there are arrays of information setup
# throught this routine you can get the series of each info
sub _info {
    my $self = shift;
    my $what = shift; # one of nodeco_time, safe_depth, percentage or pressure
    my %opt  = @_;

    my @times = @{ $self->{dive}->{timepoints} };
    croak "There are no timestamps set for this dive" if ( scalar( @times ) == 0);
    
    # divide the seconds by 60 to get minutes
    my @minutes = map { $_ / 60 } @{ $self->{dive}->{timepoints} };
    
    my $width  = $opt{width}  || DEFAULT_WIDTH;
    my $height = $opt{height} || DEFAULT_HEIGHT;
    my $outfile = $opt{file}  || $what . '.png';
    
    my $y_label = $opt{y_label} || 'Depth (meter)';
    my $graph =  GD::Graph::lines->new($width, $height);
    $graph->set(
		x_label           => 'Time (minutes)',
		y_label           => $y_label,
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
    use Deco::Dive::Plot;
    
    my $dive = new Deco::Dive( );
    $dive->load_data_from_file( file => $file);
    $dive->simulate( model => 'haldane');

    my $diveplot = new Deco::Dive::Plot( dive => $dive );
    $diveplot->depth( file => 'depth.png' );
    $diveplot->pressures( file => 'pressures.png' );

=head1 DESCRIPTION

This package will plot the profile of the dive and internal pressures of the tissues of the model.


=head2 METHODS

=over 4

=item $diveplot->depth( width=> $width, height => $height, file => $file );

Plots the depth versus time graph of the dive. It will default to a file called depth.png in 
the current directory, with a size of 600 x 400 pixels.

=item $diveplot->pressures( width=> $width, height => $height, file => $file );

This method will plot the internal pressures of all the tissues of the model during the dive.

=item $diveplot->nodeco( width=> $width, height => $height, file => $file );

This method will plot the no deco time during the dive for each tissue

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
