package Amin::Command::Mkdir;

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
     $self->command_name("mkdir");
     $self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $self->fix_text($chars->{'Data'});
     if (($data) && ($self->command_name eq $self->command)) {
          my $attrs = $self->attrs;
          my $element = $self->element;
          if ($element->{LocalName} eq "param") {
               my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
               foreach my $thing (@things) {
                    $thing =~ s/(^'|'$)//gm;
                    $self->param(split(/\s+/, $thing));
               }
          }
          $self->chars_shell($element, $attrs, $data);
          if ($element->{LocalName} eq "flag") {
               if (! $attrs->{'{}name'}->{'Value'}) {
                    $self->flag(split(/\s+/, $data));
               } elsif (($attrs->{'{}name'}->{Value} eq "mode")|| ($attrs->{'{}name'}->{Value} eq "m")) {
                    $self->mode($data);
               }
          }
		  $self->SUPER::characters($chars);
     } else {
          $self->SUPER::characters($chars);
     }
}

sub end_element {
	my ($self, $element) = @_;
     if (($element->{LocalName} eq $self->{'Spec'}->{'Localname'}) && ($self->command eq $self->command_name)) {
		my $mode = $self->mode;
		my $dir = $self->dir;
		my $log = $self->{Spec}->{Log};
          my $params = $self->param;
          #dir check
          if ($dir) { $self->chdir($dir); }
          my $flags = $self->flag;
          my $flag = $self->get_flag($flags);
          if ($mode) {
               #$flag = "-m " . $mode;
               push @$flags, "-m";
               push @$flags, $mode;
          }
		my $acmd = $self->get_command($self->command_name, $flags, $params);
		my $cmd = $self->amin_command($acmd);
		#prep $cmd messages
          my $error = "Unable to create directory. Reason: $cmd->{ERR}";

          my $success;
          if ($dir) {
               $success = "Created directories in $dir (perm: =";
          } else {
               $success = "Created directories (perm: =";
          }
          if ($mode) {
               $success .= "$mode" 
          } else {
               $success .= "default";
          }
          $success .= "):";
          $success .= join (", ", @$params);
          #send $cmd messages;
          $self->command_message($cmd, $success, $error);
		#reset this command
		$self->{MODE} = undef;
		$self->{TARGET} = [];
		$self->{NAME} = undef;
          $self->reset_command;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub mode {
	my $self = shift;
	$self->{MODE} = shift if @_;
	return $self->{MODE};
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
		#check for flag
		if (($_ =~ /^-.*$/) || ($_ =~ /^--.*$/) || ($scratch{name})) {
			#it is a flag
			my %flag;
			my $char;
			$_ =~ s/-//;
			$_ =~ s/--//;
			if ($scratch{name}) {
				#this completes the -m 0755 crap
				if ($_ =~ /\d+/) {
					$char = $_;
				} else {
					#this is a param and their -m is 0000
					#why they want this is unknown :)
					my %param;
					$param{"char"} = $_;
					push @params, \%param;
				}
				$_ = $scratch{name};
				#undefine stuff
				$stop = undef;
				%scratch = {};
			} else {
				if ($_ =~ /^.*=.*$/) {
					#check for stuff like -m=0755 crap
					($_, $char) = split (/=/, $_);
				} elsif ($_ eq "m") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} else  {
					#its just a flag
					$char = $_;
					$_ = undef;
				}
			}
			
			if (!$stop) {
				if ($_) {
					$flag{"name"} = $_;
				}
			
				$flag{"char"} = $char;
				push @flags, \%flag;
			}
		
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

Mkdir - reader class filter for the mkdir command.

=head1 version

mkdir (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the mkdir command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mkdir">
                <amin:param name="target">/tmp/amin-tests/my_new_dir</amin:param>
                <amin:flag>p</amin:flag>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mkdir">
                <amin:param name="target">/tmp/amin-tests/my_new_dir</amin:param>
                <amin:flag>p</amin:flag>
        </amin:command>
        <amin:command name="mkdir">
                <amin:param name="target">/tmp/amin-tests2/my_new_dir</amin:param>
                <amin:flag>p</amin:flag>
        </amin:command>
 </amin:profile>

=back  

=cut
