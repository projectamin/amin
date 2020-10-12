package Amin::Machine::Handler::Empty;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

sub start_element {
     my ($self, $element) = @_;
     $self->{'Spec'}->{'Prefix'} = "amin";
     $self->{'Spec'}->{'Localname'} = "command";
     $self->command_name("empty");
     #reset for the imaginary empty element
     $self->command("empty");
     $self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
	$self->SUPER::characters($chars);
}

sub end_element {
	my($self, $element) = @_;
	#get the spec
	my $spec = $self->{Spec};
	my $log = $self->{Spec}->{Log};
     if (($element->{LocalName} eq $spec->{'Localname'}) && ($self->command eq $self->command_name)) {
          my $text = "This element was not processed";
          my %attrs;
          my %att;
          $att{Name} = "type";
          $att{Value} = "not processed";
          $attrs{'{}type'} = \%att;
          $log->driver_start_element('amin:message', %attrs);
          $log->driver_characters($text);
          $log->driver_end_element('amin:message');
	}
	$self->SUPER::end_element($element);
}

sub command_name {
  my $self = shift;
  $self->{'COMMAND_NAME'} = shift if @_;
  return $self->{'COMMAND_NAME'};
}

sub command {
  my $self = shift;
  $self->{'COMMAND'} = shift if @_;
  if (! $self->{'COMMAND'}) { $self->{'COMMAND'} = ""; }
  return $self->{'COMMAND'};
}

1;

=head1 NAME

Empty - A simple pass thru filter for not processed elements

=head1 Example

  $self->set_handler( 
      Amin::Command::Empty->new(Handler => $spec->{Handler}) 
  );
  
=head1 DESCRIPTION

What is Empty? Maybe it should be called Not_Processed, but
that is too long to type. :) Basically Empty is used by Amin
Machines that have an error that occurs in their pipeline,
and the machine wants to filter all the remaining sax events
to a handler like Empty, instead of the normal filters the 
machine would dispatch the sax events to....

The example

  $self->set_handler( 
      Amin::Command::Empty->new(Handler => $spec->{Handler}) 
  );

may seem like some voodoo magic but it is fairly simple.

$self->set_handler is a XML::SAX::Base method that resets the 
SAX stream to a new handler. Since our Amin::Machine::Empty
is interuptting the normal sax process, set up by this machine, we 
must reset the Handler for Amin::Machine::Empty to be the Handler 
from this machine instance. We get this info from $self->{Spec}.

Also Empty uses the spec to determine what elements this 
machine knows how to process, so that it can add the right
message to the remaining elements to be processed... ex. 

	my $spec = $self->{Spec};
	my $log = $self->{Spec}->{Log};
	my $list = $spec->{Filter_List};
	foreach (keys %$list) {
		if ($element->{LocalName} eq $list->{$_}->{element})  {
		
=head1 XML

=over 4

=item Full example

 <amin:message type="not processed">
	This element was not processed
 </amin:message>


=back  

=cut

