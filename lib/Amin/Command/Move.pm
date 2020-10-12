package Amin::Command::Move;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Command::Elt;

@ISA = qw(Amin::Command::Elt);
my %attrs;

sub start_element {
     my ($self, $element) = @_;
     my $attrs = $element->{Attributes};
     if (($element->{'Prefix'} eq "amin") && ($element->{'LocalName'} eq "command") && ($attrs->{'{}name'}->{Value} eq "move")) {
          $self->{'Spec'}->{'Prefix'} = "amin";
          $self->{'Spec'}->{'Localname'} = "command";
          $self->command_name("move");
     }
     $self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
     my $data = $self->fix_text($chars->{'Data'});
     if ($data) {
          my $attrs = $self->{"ATTRS"};
          my $element = $self->{"ELEMENT"};
          if ($self->command eq $self->command_name) {
               $self->chars_shell($element, $attrs, $data);
               if ($element->{LocalName} eq "param") {
                    if ($attrs->{'{}name'}->{Value} eq "target") {
                         $self->target($data);
                    }
                    if ($attrs->{'{}name'}->{Value} eq "source") {
                         my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
                         foreach (@things) {
                              $self->source($_);
                         }
                    }
               }
               $self->chars_flag($element, $attrs, $data);
          }
     }
	$self->SUPER::characters($chars);
}

sub end_element {
     my ($self, $element) = @_;

     if (($element->{'LocalName'} eq $self->{'Spec'}->{'Localname'}) && ($self->command eq $self->command_name)) {
          my $dir = $self->dir;
          my @source = $self->source;
          my $target = $self->target;
          my $flags = $self->flag;
          my $log = $self->{Spec}->{Log};
          if ($dir) { $self->chdir($dir); }
          my @nsource;
          foreach (@source) {
               push @nsource, glob($_);
          }
          push @nsource, $target;
          my $acmd = $self->get_command("mv", $flags, \@nsource);
          my $cmd = $self->amin_command($acmd);
          my $error = "Unable to move " . join (", ", @source) . " to $target. Reason: $cmd->{ERR}";
          my $success = "Moving " . join (", ", @source) . " from $dir to $target.";
          $self->command_message($cmd, $success, $error);
          #reset this command
          $self->reset_command;
          $self->{TARGET} = undef;
          $self->{SOURCE} = [];
          $self->SUPER::end_element($element);
	} else {
          $self->SUPER::end_element($element);
	}
}

sub target {
	my $self = shift;
	$self->{TARGET} = shift if @_;
	return $self->{TARGET};
}

sub source {
	my $self = shift;
	if (@_) {push @{$self->{SOURCE}}, @_; }
	return @{ $self->{SOURCE} };
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
				#this completes the -S suffix crap
				if ($_ =~ /\w+\d+/) {
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
					#check for stuff like -S=0755 crap
					($_, $char) = split (/=/, $_);
				} elsif ($_ eq "S") {
					#check for stuff like -S 0755 crap
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

Move - reader class filter for the move(mv) command.

=head1 version


=head1 DESCRIPTION

  A reader class for the move(mv) command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mv">
                <amin:param name="source">limits</amin:param>
                <amin:param name="target">limit-new</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="move">
                <amin:param name="source">limits</amin:param>
                <amin:param name="target">limit-new</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="move">
                <amin:param name="source">limits</amin:param>
                <amin:param name="target">limit-new</amin:param>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut