package Amin::Command::Amin;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use warnings;
use vars qw(@ISA);
use XML::SAX::Base;

@ISA = qw(XML::SAX::Base);

sub start_element {
  my ($self, $element) = @_;
  $self->{'Spec'}->{'Prefix'} = "amin";
  $self->{'Spec'}->{'Localname'} = "command";
  $self->command_name("amin");
  my $eattrs = $element->{'Attributes'};
  my $attrs = $self->attrs($eattrs);
  my $prefix = $self->{'Spec'}->{'Prefix'} || "";
  my $localname = $self->{'Spec'}->{'Localname'} || "";
  if (($element->{Prefix} eq $prefix) && ($element->{LocalName} eq $localname)) {
    if ($attrs->{'{}name'}) { 
      $self->command($attrs->{'{}name'}->{Value});
    } else {
      $self->command($element->{LocalName});
    }
  }
  $self->element($element);
  $self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_; 
  my $data = $chars->{'Data'};
  $data =~ s/(^\s+|\s+$)//gm;
  if ($data) {
      my $attrs = $self->attrs;
      my $element = $self->element;
      if ($self->command_name eq $self->command) {
           if ($element->{'LocalName'} eq "param") {
                if ($attrs->{'{}name'}->{'Value'} eq "version") {
                     $self->version($data);
                }
           }
      }
  }
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;
	my $attrs = $self->attrs;
     if (($element->{LocalName} eq $self->{'Spec'}->{'Localname'}) && ($self->command eq $self->command_name)) {
		my $log = $self->{Spec}->{Log};
		my $version = $self->version;
		chomp $version;
    $self->reset_command;
		#reset this command
		$self->{VERSION} = undef;
		if ($version eq "") {
			$self->{Spec}->{amin_error} = "red";
               my $text = "You must supply version information";
			$self->text($text);
			$log->error_message($text);
		} else {
			my $text = "Starting Amin. Profile version $version";
			$self->text($text);
			$log->success_message($text);
		}
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub version {
     my $self = shift;
     $self->{VERSION} = shift if @_;
     return $self->{VERSION};
}

sub command_name {
     my $self = shift;
     $self->{'COMMAND_NAME'} = shift if @_;
     return $self->{'COMMAND_NAME'};
}

sub attrs {
  my $self = shift;
  $self->{'ATTRS'} = shift if @_;
  return $self->{'ATTRS'};
}

sub element {
  my $self = shift;
  $self->{ELEMENT} = shift if @_;
  return $self->{ELEMENT};
}

sub command {
     my $self = shift;
     $self->{'COMMAND'} = shift if @_;
     if (! $self->{'COMMAND'}) { $self->{'COMMAND'} = ""; }
  return $self->{'COMMAND'};
  
}

sub text {
  my $self = shift;
  $self->{TEXT} = shift if @_;
  return $self->{TEXT};
}
sub reset_command {
     my $self = shift;
     $self->{DIR} = undef;
     $self->{TARGET} = undef;
     $self->{FLAG} = ();
     $self->{SOURCE} = ();
     $self->{PARAM} = ();
     $self->{COMMAND} = undef;
     $self->{COMMAND_NAME} = undef;
     $self->{ATTRS} = undef;
     $self->{ENV_VARS} = ();
     $self->{ELEMENT} = undef;
}

1;

=head1 NAME

Amin - reader class filter for the amin command.

=head1 version 

amin  0.7.5

=head1 DESCRIPTION

  A reader class for the amin command. 
  
  Has one child element 
  
  <amin:param name="version">someversionhere</amin:param>
  
  Will return a profile version. 
  
  Useful for versions in your profiles, 
   
=head1 XML

=over 4

=item Full example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	<amin:command name="amin">
                <amin:param name="version">0.7.5</amin:param>
        </amin:command>
 </amin:profile>


=item Output example

<amin:profile xmlns:amin="http://projectamin.org/ns/">
   <amin:command name="amin">
         <amin:param name="version">
         0.7.5
         </amin:param>
         <amin:message type="success">
         Starting Amin. Profile version 0.7.5
         </amin:message>
   </amin:command>
</amin:profile>

=item Double example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="amin">
                <amin:param name="version">0.7.5</amin:param>
        </amin:command>
        <amin:command name="amin">
                <amin:param name="version">0.7.6</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut