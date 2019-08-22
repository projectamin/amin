package Amin::Profile::Type;

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

sub start_document {
	my $self = shift;
	$self->{'type'} = undef;
}

sub start_element {
	my ($self, $element) = @_;
	if (! $self->{'type'}) {
		if ($element->{Name} eq "amin:profile") {
			$self->{'type'} = "profile";
		}
		if ($element->{Name} eq "amin:adminlist") {
			$self->{'type'} = "adminlist";
		}
		if ($element->{Name} eq "amin:networkmap") {
			$self->{'type'} = "networkmap";
		}
	}
	$self->SUPER::start_element($element);
}

sub end_document {
	my $self = shift;
	return $self->{'type'};
}

1;

=head1 NAME

Amin::Profile::Type - 

=head1 version 1.0

=head1 DESCRIPTION

This is a filter whose sole purpose is to find which type
of xml document this is, ie adminlist, networkmap or profile. 
It does this by grabbing whatever comes "first" and then 
returning that type. 

=cut
