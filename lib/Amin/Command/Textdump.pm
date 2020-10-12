package Amin::Command::Textdump;

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
     $self->command_name("textdump");
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
                    if ($attrs->{'{}name'}->{Value} eq "content") {
                         $self->content($data);
                    }
                    if ($attrs->{'{}name'}->{Value} eq "target") {
                         $self->target($data);
                    }
               }
               $self->chars_flag($element, $attrs, $data);
               $self->chars_shell($element, $attrs, $data);
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
		my $target = $self->target;
		my $content = $self->content;
          my $log = $self->{Spec}->{Log};

		if (! open (FILE, ">> $target")) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to open $target for dumping, $!";
			$self->text($text);

			$log->error_message($text);
			$self->{'CONTENT'} = undef;
			$self->SUPER::end_element($element);
			return;
		}

		foreach my $line(@$content) {
			$line =~ s/(^\s+|\s+$)//gm;
			if ($line) {
				print FILE "$line\n";
			}
		}
		close (FILE);

		my $text;
		if ($dir) {
			$text = "Dumping text to $target in $dir";
		} else {
			$text = "Dumping text to $target";
		}
		$log->success_message($text);
		#reset this command
		$self->reset_command;
		$self->{TARGET} = undef;
		$self->{CONTENT} = [];
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub content {
	my $self = shift;
#     $self->{CONTENT} = shift if @_;
#     return $self->{CONTENT};
	if (@_) {push @{$self->{CONTENT}}, @_; }
	return \@{ $self->{CONTENT} };
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
		if ($_ =~ /^.*=.*$/) {
			my %shell;
			#it is an env variable 
			$shell{"name"} = 'env';
			$shell{"char"} = $_;
			push @shells, \%shell;
		} else {
			#it is either a param, command name
			my $x = 1; 
			if (!$command{name}) {
				$command{name} = $_;
			} else {
				my %param;
				$param{"char"} = $_;
				
				if ($x == 1) {
					$param{"name"} = "target";
				} elsif ($x == 2) {
					$param{"name"} = "content";
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

Textdump - reader class filter for the textdump command.

=head1 version

amin 0.5.0

=head1 DESCRIPTION

  A reader class for the textdump command. Textdump by 
  default will append to the target file or will create 
  the target file if it does not exist.
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="textdump">
                <amin:param name="target">pass</amin:param>
                <amin:param name="content">root</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="textdump">
                <amin:param name="target">hg</amin:param>
                <amin:param name="content">Hello
                                Does This
                        all
        line
                up
right?
		</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="textdump">
                <amin:param name="target">pass</amin:param>
                <amin:param name="content">root</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
	<amin:command name="textdump">
		<amin:param name="target">hg</amin:param>
		<amin:param name="content">Hello
				Does This
			all
	line
		up
right?
		</amin:param>
		<amin:shell name="dir">/tmp/amin-tests/</amin:shell>
	</amin:command>
        <amin:command name="textdump">
                <amin:param name="target">pass</amin:param>
                <amin:param name="content">root</amin:param>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
	<amin:command name="textdump">
		<amin:param name="target">hg</amin:param>
		<amin:param name="content">Hello
				Does This
			all
	line
		up
right?
		</amin:param>
		<amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
	</amin:command>
 </amin:profile>

=back  

=cut

