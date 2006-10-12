#######################################
# Module  : Deco::Dive::Table.pm
# Author  : Jaap Voets
# Date    : 10-10-2006
#######################################
package Deco::Dive::Table;

use strict;
use warnings;
use Carp;

use constant INITIAL_NODECO => 1000000;
our $VERSION = '0.1';


# Constructor
sub new {
    my $class = shift;
    my $dive = shift;   

    croak "Please provide a Deco::Dive object for plotting" unless ref($dive) eq 'Deco::Dive';

    my $self = { dive => $dive };
		
    # depth in meters, we will use these for the table
    # can be overridden by ->setdepths
    $self->{depths} = [10, 12, 14, 16, 18, 20, 24, 27, 30, 33, 36, 40, 42, 45, 50];
    
    # place to store our numbers
    $self->{table} = undef;
    bless $self, $class;
    
    return $self;
}

# set the depths for the table you want
sub setdepths {
    my $self = shift;
    $self->{depths} = \@_;
}

sub calculate {
    my $self = shift;
    
    foreach my $depth ( @{ $self->{depths} } ) {
	my $nodeco_min = INITIAL_NODECO;
	foreach my $tissue ( @{ $self->{dive}->{tissues} } ) {
	    next if ! defined $tissue;   # first array element is empty
	    
	    # we go instantly to the depth and ask for the no_deco time
	    $tissue->point( 0, $depth );	
	    
	    # we like to have 
		    # no_deco time, is special, it can return - for not applicable
	    my $nodeco = $tissue->nodeco_time();
	    $nodeco = undef if $nodeco eq '-';
	    
	    if ($nodeco) {
		if ($nodeco < $nodeco_min) {
		    $nodeco_min = int($nodeco);	
		}	
	    } 
    	}
    	if ($nodeco_min == INITIAL_NODECO) {
	    $nodeco_min = '-';
    	}
	
	$self->{table}->{$depth} = $nodeco_min; 
    }
    
}

sub output {
	my $self = shift;
	my %opt  = @_;
	
	my $template = $opt{template} || 'No Decompression limit at #DEPTH# is #TIME# minutes';
	my $output = '';
	foreach my $depth ( @{ $self->{depths} }) {
		my $row = $template;
		$row =~ s/#DEPTH#/$depth/gi;
		$row =~ s/#TIME#/$self->{table}->{$depth}/gi;
		$output .= $row;
	}	
	
	return $output;
}
1;


__END__

=head1 NAME

Deco::Dive::Table - Generate a list of no stop limits for your model 

=head1 SYNOPSIS

    use Deco::Dive;
    use Deco::Dive::Table;
    
    my $dive = new Deco::Dive( );
    $dive->model( config => './conf/haldane.cnf');

    my $divetable = new Deco::Dive::Table( dive => $dive );
    $divetable->calculate();
    my $table = $divetable->output();

=head1 DESCRIPTION

This package will plot the profile of the dive and internal pressures of the tissues of the model.


=head2 METHODS

=over 4

=item $divetable->new( dive => $dive );

The constructor of the class. There is only one parameter: a Deco::Dive object.

=item $divetable->setdepths( $depth1, $depth2, $depth3, ....  );

Set the list of depths you want the table to be for manually. There is a default list provided, but with this method you can overrule it. Depths should be entered in B<meters>

=item $divetable->calculate();

Performs the calculation of the table. You will need to call this function before retrieving output.

=item $divetable->output( [template => $template ] );

Retrieve the table as a string. Optionally you can supply your own template for each line of output.
The placeholders #DEPTH# and #TIME# will be replaced by the actual values for the depth (in meters) and time (in minutes) that you can stay at that depth without required decompression stops. 

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
