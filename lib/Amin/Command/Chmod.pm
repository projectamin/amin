package Amin::Command::Chmod;

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
     $self->command_name("chmod");
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
	if (($element->{LocalName} eq $self->{'Spec'}->{'Localname'}) && ($self->command eq $self->command_name)) {
		my $dir = $self->dir;
		my $flags = $self->flag;
		my $params = $self->param;
		my $log = $self->{Spec}->{Log};
          if ($dir) { $self->chdir($dir); }
          my @doubles = qw(help version silent quiet changes recursive verbose);
          my $flag = $self->get_flag($flags, \@doubles);
          my @params;
          foreach (@$params) {
			push @params, glob($_);
		}
		my $acmd = $self->get_command($self->command_name, $flag, \@params);
		my $cmd = $self->amin_command($acmd);
          my $error = "Unable to set permissions for " . join (", ", @$params) . "Reason: $cmd->{ERR}";
          my $success;
          if ($dir) {
               $success = "Changing permissions in $dir for " . join (", ", @$params);
          } else {
               $success = "Changing permissions for " . join (", ", @$params);
          }
          $self->command_message($cmd, $success, $error);
		#reset this command
          $self->reset_command;
          $self->{REFERNCE} = undef;
          $self->{SET} = undef;
          $self->{TARGET} = [];
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub filter_map {
	my $self = shift;
	my $command = shift;
	my %command;
	my @flags;
	my @params;
	my @shells;
	my @things = split(/([\*\+\.\w=\/-]+|'[^']+')\s*/, $command);

	my %scratch;
	my $stop;
	foreach (@things) {
	#check for real stuff
	if ($_) {
		my $x = 1; 
		#check for flag
		if (($_ =~ /^-.*$/) || ($_ =~ /^--.*$/)) {
			#it is a flag
			my %flag;
			my $char;
			$_ =~ s/-//;
			$_ =~ s/--//;
			if ($_ =~ /^.*=.*$/) {
				#check for stuff like -r=/some/file
				($_, $char) = split (/=/, $_);
			} else  {
				#its just a flag
				$char = $_;
				$_ = undef;
			}
			
			if ($_) {
				$flag{"name"} = $_;
			}
			$flag{"char"} = $char;
			push @flags, \%flag;
		} elsif ($_ =~ /^.*=.*$/) {
			my %shell;
			#it is an env variable 
			$shell{"name"} = 'env';
			$shell{"char"} = $_;
			push @shells, \%shell;
		} else {
			#it is either a param, command name
			if (!$command{name}) {
				$command{name} = $_;
			} else {
				my %param;
				$param{"char"} = $_;
				if ($x == 1) {
					$param{"name"} = "group";
				} elsif ($x == 2) {
					$param{"name"} = "target";
				}
				$x++;
				push @params, \%param;
			}
		}
	}
	}
	
	
	if (@shells) {
		$command{shell} = \@shells;
	}
	if (@flags) {
		$command{flag} = \@flags;
	}
	if (@params) {
		$command{param} = \@params;
	}
	
	my %fcommand;
	$fcommand{command} = \%command;
	return \%fcommand;	
}

1;

=head1 NAME

chmod - reader class filter for the chmod command.

=head1 version

chmod (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the chmod command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="chmod">
                <amin:param>0750</amin:param>
                <amin:param>/tmp/amin-tests/limits</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="chmod">
                <amin:param>0750</amin:param>
                <amin:param>/tmp/amin-tests/limits</amin:param>
        </amin:command>
        <amin:command name="chmod">
                <amin:param>0750</amin:param>
                <amin:param>/tmp/amin-tests2/limits</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut
