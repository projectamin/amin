package Amin::Command::Cp;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Command::Copy;

@ISA = qw(Amin::Command::Copy);

sub start_element {
     my ($self, $element) = @_;
     my $attrs = $element->{Attributes};
     if (($element->{'Prefix'} eq "amin") && ($element->{'LocalName'} eq "command") && ($attrs->{'{}name'}->{Value} eq "cp")) {
          $self->{'Spec'}->{'Prefix'} = "amin";
          $self->{'Spec'}->{'Localname'} = "command";
          $self->command_name("cp");
     }
     $self->SUPER::start_element($element);
}

1;

=head1 NAME

Cp - reader class filter for the copy(cp) command.

=head1 version

cp (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the copy(cp) command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="cp">
                <amin:param name="source">touchfile</amin:param>
                <amin:param name="target">my_new_dir</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	<amin:command name="cp">
		<amin:param name="source">touchfile</amin:param>
		<amin:param name="target">my_new_dir</amin:param>
		<amin:shell name="dir">/tmp/amin-tests/</amin:shell>
	</amin:command>
	<amin:command name="cp">
		<amin:param name="source">touchfile</amin:param>
		<amin:param name="target">my_new_dir</amin:param>
		<amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
	</amin:command>
 </amin:profile>

=back  

=cut