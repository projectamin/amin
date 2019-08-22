package Amin::Machine::Filter::Dispatcher;

#LICENSE:

#Please see the LICENSE file included with this distribution 

#Amin Dispatcher
use strict;
use vars qw(@ISA);
use Amin::Machine::Handler::Empty;
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

sub start_element {
	my ($self, $element) = @_;
	my $spec = $self->{Handler}->{Spec};
	my $fl = $spec->{'Filter_List'};
     if ($fl->{'Spec'}->{'amin_error'}) {
          #if there is an error reset handler to Empty
          $self->set_handler( Amin::Machine::Handler::Empty->new('Handler' => $spec->{'Handler'}, 'Spec' => $spec) );
     } else {
          if ($fl->{$_}->{chain}) {
               my $schain = $fl->{$_}->{chain};
               $self->set_handler($schain);
          }
     }	
	$self->SUPER::start_element($element);
}

1;

=head1 Name

Amin::Machine::Filter::Dispatcher - default Machine_Name filter for Amin

=head1 Description

There are no methods for this module. You use this module in your
own Machines as a Machine_Name. ie

 sub new {
    my ($self, $spec) = @_;
    $spec->{Machine_Name} = Amin::Machine::Filter::Dispatcher->new();
    return $self->SUPER::new($spec);
 }

If there is a chain, then the chain is set as the handler. This means
the sax events are "Dispatched" to the appropriate sax filter through
the chain.


If the $spec that is being passed around the machine to other 
filters ever has 

 $self->{Spec}->{amin_error}
 
set as anything defined, then dispatcher will instead send the
sax events to Amin::Machine::Handler::Empty instead of to the
next appropriate sax filter in this machine spec's filterlist.

 
=cut