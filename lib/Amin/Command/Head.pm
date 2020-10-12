package Amin::Command::Head;

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
     $self->command_name("head");
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
               if ($element->{'LocalName'} eq "flag") {
                    if (! $attrs->{'{}name'}->{Value}) {
                         my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
                         foreach (@things) {
                              $self->flag($_);
                         }
                    } else {
                         if ($attrs->{'{}name'}->{Value} eq "bytes") {
                              $self->bytes($data);
                         }
                         if ($attrs->{'{}name'}->{Value} eq "lines") {
                              $self->lines($data);
                         }
                    }
               }
          }
     }
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;
	if (($element->{'LocalName'} eq $self->{'Spec'}->{'Localname'}) && ($self->command eq $self->command_name)) {
		my $bytes = $self->bytes;
		my $lines = $self->lines;
		my $flags = $self->flag;
		my $params = $self->param;
		my $dir = $self->dir;
          if ($dir) { $self->chdir($dir); }
          my @double = qw(help version);
          my $flag = $self->get_flag($flags, \@double);
          my $acmd = $self->get_command($self->command_name, $flags, $params);
		my $cmd = $self->amin_command($acmd);
          my $error = "Unable to run the head command. Reason: $cmd->{ERR}";
          my $success = "Head command was successful";
          $self->command_message($cmd, $success, $error);
		#reset this command
		$self->reset_command;
		$self->{BYTES} = undef;
		$self->{LINES} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub bytes {
	my $self = shift;
	$self->{BYTES} = shift if @_;
	return $self->{BYTES};
}

sub lines {
	my $self = shift;
	$self->{LINES} = shift if @_;
	return $self->{LINES};
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
				#this completes the -n 100 crap
				if ($_ =~ /\d+/) {
					$char = $_;
				} else {
					#this is a param and their -n is not
					#a digit why they want this is unknown
					#:)
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
					#check for stuff like -n=100 crap
					($_, $char) = split (/=/, $_);
				} elsif ($_ eq "n") {
					#check for stuff like -n 100 crap
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

Head - reader class filter for the head command.

=head1 version

Head (coreutils) 

=head1 DESCRIPTION

  A reader class for the head command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="head">
                <amin:param name="bytes">512b</amin:param>
                <amin:param>hg</amin:param>
                <amin:flag>q</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="head">
                <amin:param name="bytes">512b</amin:param>
                <amin:param>hg</amin:param>
                <amin:flag>q</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="head">
                <amin:param name="bytes">512b</amin:param>
                <amin:param>hg</amin:param>
                <amin:flag>q</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut