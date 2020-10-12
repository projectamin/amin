package Amin::Command::System_command;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use vars qw(@ISA);
use Amin::Command::Elt;

@ISA = qw(Amin::Command::Elt);

sub start_element {
     my ($self, $element) = @_;
     $self->{'Spec'}->{'Prefix'} = "amin";
     $self->{'Spec'}->{'Localname'} = "command";
     $self->command_name("system_command");
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
                    if (! $attrs->{'{}name'}->{Value}) {
                         my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
                         foreach (@things) {
                              $self->param($_);
                         }
                    } else {
                         if ($attrs->{'{}name'}->{Value} eq "basename") {
                              $self->basename($data);
                         }
                    }
               }
               if ($element->{LocalName} eq "special") {
                    $self->special($data);
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
		my $basename = $self->basename;
          my $log = $self->{Spec}->{Log};
		my $special = $self->special;
          my $default = 0;
		my (%acmd, %bcmd, $cmd);
		if ($special) {
			my $special2 = "shell";
			$cmd = $self->amin_command($special, $special2);
		} else {
			if (!$basename) {
				$self->{Spec}->{amin_error} = "red";
				my $text = "There must be a basename!";
				$default = 1;
				$log->error_message($text);
			}
			$acmd{'CMD'} = $basename;
			$acmd{'FLAG'} = $flags;
			$acmd{'PARAM'} = $params;
			if ($self->{'ENV_VARS'}) {
				$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
			}
			$cmd = $self->amin_command(\%acmd);
		}
		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text;
			if ($dir) {
				$text = "Unable to execute $basename in $dir. Reason: $cmd->{ERR}";
			} else {
				$text = "Unable to execute $basename. Reason: $cmd->{ERR}";
			}
			$default = 1;
			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
		}
		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext;
			if ($dir) {
				$otext = "Executing $basename in $dir";
			} else {
				$otext = "Executing $basename";
			}
			my $etext = " There was also some error text $cmd->{ERR}";
			$etext = $otext . $etext; 
			$default = 1;
			if ($cmd->{TYPE} eq "out") {
				$log->success_message($otext);
				$log->OUT_message($cmd->{OUT});
			} else {
				$log->success_message($etext);
				$log->OUT_message($cmd->{OUT});
				$log->ERR_message($cmd->{ERR});
				
			}
		}
		if ($default == 0) {
			my $text = "there was no messages?";
			$log->error_message($text);
		}
		#reset this command
		$self->reset_command;
		$self->{BASENAME} = undef;
		$self->{SPECIAL} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub basename {
	my $self = shift;
	$self->{BASENAME} = shift if @_;
	return $self->{BASENAME};
}

sub special {
	my $self = shift;
	$self->{SPECIAL} = shift if @_;
	return $self->{SPECIAL};
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
		if (($_ =~ /^-.*$/) || ($_ =~ /^--.*$/)) {
			#it is a flag
			my %flag;
			my $char;
			$_ =~ s/-//;
			$_ =~ s/--//;
			if ($_ =~ /^.*=.*$/) {
				#check for stuff like -m=0755 crap
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

System_command - reader class filter for the system_command command.

=head1 version

amin 0.5.0

=head1 DESCRIPTION

  A reader class for the system_command command. System_command
  is a generic catch all for when you need a command with no
  filters available for said command. System_command also has 
  the <amin:special> child element. This element will pass thru
  any command you supply as char data to a "sh" shell. Use only
  in dire cases... :)
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="system_command">
                <amin:param name="basename">touch</amin:param>
                <amin:param>/tmp/amin-tests/limits</amin:param>
        </amin:command>
	
	
	<!-- sample special command

       <amin:command name="system_command">
                <amin:special>straight -pass /thru/of/a/command</amin:special>
        </amin:command>
 	-->
 
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="system_command">
                <amin:param name="basename">touch</amin:param>
                <amin:param>/tmp/amin-tests/limits</amin:param>
        </amin:command>
       <amin:command name="system_command">
                <amin:param name="basename">touch</amin:param>
                <amin:param>/tmp/amin-tests2/limits</amin:param>
        </amin:command>
 </amin:profile>
	
=back  

=cut
