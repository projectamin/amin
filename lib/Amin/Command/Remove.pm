package Amin::Command::Remove;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Command::Elt;

@ISA = qw(Amin::Command::Elt);

sub start_element {
     my ($self, $element) = @_;
     my $attrs = $element->{Attributes};
     if (($element->{'Prefix'} eq "amin") && ($element->{'LocalName'} eq "command") && ($attrs->{'{}name'}->{Value} eq "remove")) {
          $self->{'Spec'}->{'Prefix'} = "amin";
          $self->{'Spec'}->{'Localname'} = "command";
          $self->command_name("remove");
     }
     $self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
     my $data = $self->fix_text($chars->{'Data'});
     if ($data) {
          my $attrs = $self->attrs;
          my $element = $self->element;
          if ($self->command eq $self->command_name) {
               $self->chars_shell($element, $attrs, $data);
               $self->chars_param($element, $attrs, $data);
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
          my $flag = $self->get_flag($flags);
          my @target;
		foreach my $ip (@$params){
			#this is needed if the file is [ because a glob will kill it
			if ($ip =~ /\[/) {
				push @target, $ip;
			} else {
				push @target, glob($ip);
			}
		}
		#force rm
          my $acmd = $self->get_command("rm", $flag, \@target);
          my $cmd = $self->amin_command($acmd);
		my $error;
		my $success;
		my $name = $self->command_name;
		if ($dir) {
               $error = "Unable to execute $name in $dir. Reason: $cmd->{ERR}";
			$success = "Removed " . join (", ", @target) . " from $dir";
		} else {
               $error = "Unable to execute $name. Reason: $cmd->{ERR}";
			$success = "Removed " . join (", ", @target);
		}
		$self->command_message($cmd, $success, $error);
		#reset this command
		$self->reset_command;
		$self->{TARGET} = [];
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

1;

=head1 NAME

Remove - reader class filter for the remove(rm) command.

=head1 version

rm (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the remove(rm) command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="remove">
                <amin:param name="target">limits hg linked_thing touchfile touchfile2</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="remove">
                <amin:param name="target">limits hg linked_thing touchfile touchfile2</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="remove">
                <amin:param name="target">limits hg linked_thing touchfile touchfile2</amin:param>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut
