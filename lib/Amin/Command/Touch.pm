package Amin::Command::Touch;

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
     $self->command_name("touch");
     $self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
     my $data = $self->fix_text($chars->{'Data'});
     if ($data) {
          my $attrs = $self->attrs;
          my $element = $self->element;
          if ($self->command eq $self->command_name) {
               if ($element->{LocalName} eq "flag") {
                    if (! $attrs->{'{}name'}->{Value}) {
                         $self->flag(split(/\s+/, $data));
                    } else {
                         if (($attrs->{'{}name'}->{Value} eq "date") ||
                         ($attrs->{'{}name'}->{Value} eq "d")) {
                              $self->date($data);
                         }
                         if (($attrs->{'{}name'}->{Value} eq "reference") ||
                         ($attrs->{'{}name'}->{Value} eq "r")) {
                              $self->options($data);
                         }
                    }
               }
               $self->chars_shell($element, $attrs, $data);
               if ($element->{LocalName} eq "param") {
                    $self->param(split(/\s+/, $data));
               }
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

		my $date = $self->date;
		my $reference = $self->reference;
		my $log = $self->{Spec}->{Log};
          my @doubles = qw (help version nocreate);
          my $flag = $self->get_flag($flags, \@doubles);
		if ($date) { push @$flag, "-d" . $date; }
          if ($reference) { push @$flag, "-r" . $reference; }
          my $acmd = $self->get_command($self->command_name, $flag, $params);
          my $cmd = $self->amin_command($acmd);
		my $error = "Touch Failed. Reason: $cmd->{ERR}";
		my $success = "Touch was successful.";
          #send $cmd messages;
          $self->command_message($cmd, $success, $error);
          #reset this command
          $self->reset_command;
		$self->{DATE} = undef;
		$self->{REFERENCE} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub date {
	my $self = shift;
	$self->{DATE} = shift if @_;
	return $self->{DATE};
}

sub reference {
	my $self = shift;
	$self->{REFERENCE} = shift if @_;
	return $self->{REFERENCE};
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
				} elsif ($_ eq "d") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "r") {
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

touch - reader class filter for the touch command.

=head1 version

touch (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the umount command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="touch">
                <amin:param>/tmp/amin-tests/touchfile</amin:param>
        </amin:command>
        <amin:command name="touch">
                <amin:param>/tmp/amin-tests/touchfile2</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="touch">
                <amin:param>/tmp/amin-tests/touchfile</amin:param>
        </amin:command>
        <amin:command name="touch">
                <amin:param>/tmp/amin-tests/touchfile2</amin:param>
        </amin:command>
        <amin:command name="touch">
                <amin:param>/tmp/amin-tests2/touchfile</amin:param>
        </amin:command>
        <amin:command name="touch">
                <amin:param>/tmp/amin-tests2/touchfile2</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut

