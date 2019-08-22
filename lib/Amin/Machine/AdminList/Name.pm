package Amin::Machine::AdminList::Name;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	if ($element->{LocalName} eq "map") {
		if ($attrs{'{}name'}->{Value}) {
			$self->name($attrs{'{}name'}->{Value});
		}
	}
}

sub end_document {
	my $self = shift;
	my $name = $self->{NAME};
	my %name;
	foreach (@$name) {
		$name{$_} = "";
	}
	#reset name
	$self->{NAME} = ();
	return \%name;
}

sub name {
	my $self = shift;
	if (@_) {push @{$self->{NAME}}, @_; }
	return @{ $self->{NAME} };
}

1;

=head1 NAME

Amin::Machine::Adminlist::Name - returns name="" names for an adminlist map

=head1 version 1.0


=head1 DESCRIPTION

  Returns name="" names for an adminlist map. This module reads an adminlist
  map and returns all the name entires in a hash reference.
  
  Use this hash map with your adminlist controller processing to control
  how the maps are applied to any adminlist.
  
  Example Usage:
  
  my $h = Amin::Machine::AdminList::Name->new();
  my $p = XML::SAX::PurePerl->new(Handler => $h);
  my $adminlist_map = $p->parse_uri($self->{adminlist_map});

  #see Amin::Machine::Adminlist to understand where $adminlist comes from
  foreach my $key (nsort keys %$adminlist) {
     if ($adminlistmap->{key}) {
   	#this adminlist name="" mapping matches
	#do something here
     }
  }

=cut
