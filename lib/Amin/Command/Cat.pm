package Amin::Command::Cat;

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
     $self->command_name("cat");
     $self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $self->fix_text($chars->{'Data'});
	if ($data) {
          my $attrs = $self->attrs;
          my $element = $self->element;
          if ($self->command eq $self->command_name) {
               if ($element->{'LocalName'} eq "param") {
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
          my @doubles = qw (show-all help number-nonblank verbose show-ends number squeeze-blank show-tabs show-nonprinting);
          my $flag = $self->get_flag($flags, \@doubles);
          my $acmd = $self->get_command($self->command_name, $flag, $params);
		my $cmd = $self->amin_command($acmd);
          my $success = "Ran the cat command.";
          my $error = "Unable to run the cat command. Reason: $cmd->{'ERR'}";
          #send $cmd messages;
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

Cat - reader class filter for the cat command.

=head1 version

cat (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the cat command. 

=head1 XML

=over 4

=item Single example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="cat">
                <amin:flag>A</amin:flag>
                <amin:param>/tmp/amin-tests/hg</amin:param>
        </amin:command>
 </amin:profile>

=item Double example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	<amin:command name="cat">
        	<amin:flag>A</amin:flag>
        	<amin:param>/tmp/amin-tests/hg</amin:param>
	</amin:command>
	<amin:command name="cat">
        	<amin:flag>A</amin:flag>
        	<amin:param>/tmp/amin-tests2/hg</amin:param>
	</amin:command>
 </amin:profile>


=back  

=cut