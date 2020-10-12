package Amin::Command::Link;

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
     if (($element->{'Prefix'} eq "amin") && ($element->{'LocalName'} eq "command") && ($attrs->{'{}name'}->{Value} eq "link")) {
          $self->{'Spec'}->{'Prefix'} = "amin";
          $self->{'Spec'}->{'Localname'} = "command";
          $self->command_name("link");
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
               if ($element->{LocalName} eq "param") {
                    if ($attrs->{'{}name'}->{Value} eq "source") {
                         $self->source($data);
                    }
                    if ($attrs->{'{}name'}->{Value} eq "target") {
                         $self->target($data);
                    }
               }
               if ($element->{LocalName} eq "flag") {
                    if (! $attrs->{'{}name'}->{Value}) {
                         $self->flag(split(/\s+/, $data));
                    } else {
                         if ($attrs->{'{}name'}->{Value} eq "type") {
                              $self->type($data);
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
		my $dir = $self->dir;
        if ($dir) { $self->chdir($dir); }
		my $target = $self->target;
        my $source = $self->source;
		my $flags = $self->flag;
        my @param;
		push @param, $source;
		push @param, $target;
		my $flag = $self->get_flag($flags);
		my $acmd = $self->get_command("ln", $flags, \@param);
		my $cmd = $self->amin_command($acmd);
        my $error = "Unable to create symbolic link $target to $source. Reason: $cmd->{ERR}";
        my $success = "Creating a link from ";
        if ($dir) {
           $success .=  "$dir";
         }
        $success .= "$target to $source.";
        $self->command_message($cmd, $success, $error);
        #reset this command
        $self->reset_command;
		$self->{SOURCE} = undef;
		$self->{TYPE} = undef;
		$self->{TARGET} = undef;
		$self->SUPER::end_element($element);
	}else {
		$self->SUPER::end_element($element);
	}
}

sub source {
	my $self = shift;
	$self->{SOURCE} = shift if @_;
	return $self->{SOURCE};
}

sub type {
	my $self = shift;
	$self->{TYPE} = shift if @_;
	return $self->{TYPE};
}

sub target {
	my $self = shift;
	$self->{TARGET} = shift if @_;
	return $self->{TARGET};
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

Link - reader class filter for the gnu ln/Link command.

=head1 version
	
ln (coreutils) 5.0 March 2003


=head1 DESCRIPTION

  A reader class for the ln command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="link">
                <amin:param name="source">original_thing</amin:param>
                <amin:param name="target">linked_thing</amin:param>
                <amin:flag>sf</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="link">
                <amin:param name="source">original_thing</amin:param>
                <amin:param name="target">linked_thing</amin:param>
                <amin:flag>sf</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
       <amin:command name="link">
                <amin:param name="source">original_thing</amin:param>
                <amin:param name="target">linked_thing</amin:param>
                <amin:flag>sf</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut


