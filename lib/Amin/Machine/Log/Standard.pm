package Amin::Machine::Log::Standard;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

#standard logging subroutines

sub driver_start_element {
    my $self = shift;
    my $element_name = shift;
    my %attributes = @_;
    $self->SUPER::start_element({Name => $element_name,
                              Attributes => \%attributes});
}

sub driver_end_element {
    my ($self, $element_name) = @_;
    $self->SUPER::end_element({Name => $element_name});
}

sub driver_characters {
    my ($self, $data) = @_;
    my %chars;
    $chars{Data} = $data;
    $self->SUPER::characters(\%chars);
}

sub error_message {
	my ($self, $text) = @_;
	my %attrs;
	my %att;

	$att{Name} = "type";
	$att{Value} = "error";
	$attrs{'{}type'} = \%att;
	$self->driver_start_element('amin:message', %attrs);
	$self->driver_characters($text);
	$self->driver_end_element('amin:message');

}

sub warn_message {
	my ($self, $text) = @_;
	my %attrs;
	my %att;

	$att{Name} = "type";
	$att{Value} = "warn";
	$attrs{'{}type'} = \%att;
	$self->driver_start_element('amin:message', %attrs);
	$self->driver_characters($text);
	$self->driver_end_element('amin:message');

}


sub success_message {
	my ($self, $text) = @_;
	my %attrs;
	my %att;
	
	$att{Name} = "type";
	$att{Value} = "success";
	$attrs{'{}type'} = \%att;
	$self->driver_start_element('amin:message', %attrs);
	$self->driver_characters($text);
	$self->driver_end_element('amin:message');
}

sub OUT_message {
	my ($self, $text) = @_;
	my %attrs;
	my %att;
	
	$att{Name} = "type";
	$att{Value} = "OUT";
	$attrs{'{}type'} = \%att;
	$self->driver_start_element('amin:message', %attrs);
	$self->driver_characters($text);
	$self->driver_end_element('amin:message');
}

sub ERR_message {
	my ($self, $text) = @_;
	my %attrs;
	my %att;
	
	$att{Name} = "type";
	$att{Value} = "ERR";
	$attrs{'{}type'} = \%att;
	$self->driver_start_element('amin:message', %attrs);
	$self->driver_characters($text);
	$self->driver_end_element('amin:message');
}

sub IN_message {
	my ($self, $text) = @_;
	my %attrs;
	my %att;
	
	$att{Name} = "type";
	$att{Value} = "IN";
	$attrs{'{}type'} = \%att;
	$self->driver_start_element('amin:message', %attrs);
	$self->driver_characters($text);
	$self->driver_end_element('amin:message');
}

1;

__END__

=head1 Name

Amin::Machine::Log::Standard - basic Log subroutine class for Amin machines

=head1 Example

  in your filter somewhere
  
  my $log = $spec->{Log};
  
  #success message
  my $text = "All is well";
  $log->success_message($text); 
   
  #error message
  my $text = "Something went wrong";
  $log->error_message($text); 

  #warn message
  my $text = "Warning this is not good";
  $log->warn_message($text); 
   
  #the following deal with the $cmd's messages
  #ex. my $cmd = $self->amin_command(\%acmd);
  
  #IN message
  $log->IN_message($cmd->{IN}); 
   
  #OUT message
  $log->OUT_message($cmd->{OUT}); 
   
  #ERR message
  $log->ERR_message($cmd->{ERR}); 
   
=head1 Description

Amin::Machine::Log::Standard is the basic Log subroutine class 
for Amin machines. All machines must have a logging mechanism 
for filters to log their amin messages too. If no logging mechanism
is supplied to a machine, then this class is used as a default. 

This class provides several basic logging methods. All each 
method does is create the appropriate <amin:message> with the
$text you supply.

=head1 Methods 

=over 4

All of these methods take one value, ie $text or whatever
message you want outputed as chars in your <amin:message>.
The method you select will determine the type of message
created. ie

  my $text = "All is well";
  $log->success_message($text);

will become

  <amin:message type="success">All is well</amin:message>


=item *success_message
  
  $log->success_message($text);
   
=item *error_message
  
  $log->error_message($text);

=item *warn_message
  
  $log->warn_message($text);

=item *IN_message
  
  $log->IN_message($text);

=item *OUT_message
  
  $log->OUT_message($text);

=item *ERR_message
  
  $log->ERR_message($text);

=back

=head1 XML 

=over 4

=item *success_message

  <amin:message type="success">All is well</amin:message>
   
=item *error_message

  <amin:message type="error">There was a problem</amin:message>

=item *warn_message

  <amin:message type="warn">Warning this is not good</amin:message>

=item *IN_message

  <amin:message type="IN">some cmd IN here</amin:message>

=item *OUT_message

  <amin:message type="OUT">some cmd OUT here</amin:message>

=item *ERR_message

  <amin:message type="ERR">some cmd ERR here</amin:message>

=back

=cut





