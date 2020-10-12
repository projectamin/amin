package Amin::Command::Mv;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Command::Move;

@ISA = qw(Amin::Command::Move);


sub start_element {
     my ($self, $element) = @_;
     my $attrs = $element->{Attributes};
     if (($element->{'Prefix'} eq "amin") && ($element->{'LocalName'} eq "command") && ($attrs->{'{}name'}->{Value} eq "mv")) {
          $self->{'Spec'}->{'Prefix'} = "amin";
          $self->{'Spec'}->{'Localname'} = "command";
          $self->command_name("mv");
     }
     $self->SUPER::start_element($element);
}

1;

=head1 NAME

Mv - reader class filter for the move(mv) command.

=head1 version


=head1 DESCRIPTION

  A reader class for the move(mv) command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mv">
                <amin:param name="source">limit-new</amin:param>
                <amin:param name="target">limits</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mv">
                <amin:param name="source">limit-new</amin:param>
                <amin:param name="target">limits</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="mv">
                <amin:param name="source">limit-new</amin:param>
                <amin:param name="target">limits</amin:param>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut
