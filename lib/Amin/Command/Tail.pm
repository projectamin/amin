package Amin::Command::Tail;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Command::Elt;

@ISA = qw(Amin::Command::Elt);

sub start_element {
     my ($self, $element) = @_;
     $self->{'Spec'}->{'Prefix'} = "amin";
     $self->{'Spec'}->{'Localname'} = "command";
     $self->command_name("tail");
     $self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
     my $data = $self->fix_text($chars->{'Data'});
     if ($data) {
          my $attrs = $self->attrs;
          my $element = $self->element;
          if ($self->command eq $self->command_name) {
               if ($element->{LocalName} eq "param") {
                    my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
                    foreach (@things) {
                         $self->param($_);
                    }
               }
               $self->chars_shell($element, $attrs, $data);
               $self->chars_flag($element, $attrs, $data);
          }
     }
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;
     if (($element->{'LocalName'} eq $self->{'Spec'}->{'Localname'}) && ($self->command eq $self->command_name)) {
          my $dir = $self->dir;
          my $params = $self->param;
          my $flags = $self->flag;
          if ($dir) { $self->chdir($dir); }
		my $log = $self->{Spec}->{Log};
          my $acmd = $self->get_command($self->command_name, $flags, $params);
          my $cmd = $self->amin_command($acmd);
		
          my $error = "Unable to run the tail command. Reason: $cmd->{ERR}";
          my $success = "Tail command was successful";
          $self->command_message($cmd, $success, $error);
		#reset this command
          $self->reset_command;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

1;

=head1 NAME

Tail - reader class filter for the tail command.

=head1 version

Tail 

=head1 DESCRIPTION

  A reader class for the tail command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="tail">
                <amin:param>hg</amin:param>
		<amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="tail">
                <amin:param>hg</amin:param>
		<amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="tail">
                <amin:param>hg</amin:param>
		<amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut