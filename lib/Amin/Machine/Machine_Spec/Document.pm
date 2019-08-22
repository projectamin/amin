package Amin::Machine::Machine_Spec::Document;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

my %document;
my @filters;
my @bundle;
my %filters;
my %bundle;

sub start_document {
	my $self = shift;
	@filters = ();
	@bundle = ();
	foreach (keys %document) {
		delete $document{$_};
	}
	foreach (keys %filters) {
		delete $filters{$_};
	}
	foreach (keys %bundle) {
		delete $bundle{$_};
	}
}


sub start_element {
	my ($self, $element) = @_;
	$self->element($element);
	my %attrs = %{$element->{Attributes}};
	if (($element->{LocalName} eq "filter") || ($element->{LocalName} eq "bundle")) {
		$self->module($attrs{'{}name'}->{Value});	
	}
	if ($element->{LocalName} eq "generator") {
		$self->generator($attrs{'{}name'}->{'Value'});
	}
	if ($element->{LocalName} eq "handler") {
		$self->han_name($attrs{'{}name'}->{'Value'});
		$self->han_out($attrs{'{}output'}->{'Value'});
	}
	if ($element->{LocalName} eq "log") {
		$self->log($attrs{'{}name'}->{'Value'});
	}
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data =~ s/(^\s+|\s+$)//gm;
	my $element = $self->{"ELEMENT"};

	if ($data ne "") {
	
		if ($element->{LocalName} eq "element") {
			$self->element_name($data);
		}
		if ($element->{LocalName} eq "namespace") {
			$self->namespace($data);
		}
		if ($element->{LocalName} eq "name") {
			$self->name($data);
		}
		if ($element->{LocalName} eq "machine_name") {
			$self->machine_name($data);
		}
		if ($element->{LocalName} eq "position") {
			$self->position($data);
		}
		if ($element->{LocalName} eq "download") {
			$self->download($data);
		}
		if ($element->{LocalName} eq "version") {
			$self->version($data);
		}
		if ($element->{LocalName} eq "filter_param") {
			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
			foreach (@things) {
				$self->filter_param($_);
			}
		}
	}
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "bundle") {	
		my %mparent = (
			element => $self->{ELEMENT_NAME},
			namespace => $self->{NAMESPACE},
			name => $self->{NAME},
			position => $self->{POSITION},
			download => $self->{DOWNLOAD},
			version => $self->{VERSION},
			module => $self->{MODULE},
		);
		$bundle{$mparent{module}} = \%mparent;
	}
	if ($element->{LocalName} eq "filter") {	
		my %mparent = (
			element => $self->{ELEMENT_NAME},
			namespace => $self->{NAMESPACE},
			name => $self->{NAME},
			position => $self->{POSITION},
			download => $self->{DOWNLOAD},
			version => $self->{VERSION},
			module => $self->{MODULE},
		);
		$filters{$mparent{module}} = \%mparent;
	}
	if ($element->{LocalName} eq "machine") {
		$document{Filter} = \%filters;
		$document{Bundle} = \%bundle;
	}
}

sub end_document {
	my $self = shift;
	
	if ($self->{HAN_NAME}) {
		my %han;
		$han{name} = $self->han_name;
		$han{out} = $self->han_out;
		$document{FHandler} = \%han;
	}
	if ($self->{LOG}) {
		$document{Log} = $self->log;
	}
	if ($self->{MACHINE_NAME}) {
		$document{Machine_Name} = $self->machine_name;
	}
	if ($self->{GENERATOR}) {
		$document{Generator} = $self->generator;
	}
	if ($self->{FILTER_PARAM}) {
		my @params = $self->filter_param;
		$document{Filter_Param} = \@params;
	}
	
	return \%document;
}

sub element {
	my $self = shift;
	$self->{ELEMENT} = shift if @_;
	return $self->{ELEMENT};
}

sub mparent {
	my $self = shift;
	if (@_) {push @{$self->{MPARENT}}, @_; }
	return @{ $self->{MPARENT} };
}

sub name {
	my $self = shift;
	$self->{NAME} = shift if @_;
	return $self->{NAME};
}

sub log {
	my $self = shift;
	$self->{LOG} = shift if @_;
	return $self->{LOG};
}

sub machine_name {
	my $self = shift;
	$self->{MACHINE_NAME} = shift if @_;
	return $self->{MACHINE_NAME};
}

sub filter_param {
	my $self = shift;
	if (@_) {push @{$self->{FILTER_PARAM}}, @_; }
	return @{ $self->{FILTER_PARAM} };
}

sub position {
	my $self = shift;
	$self->{POSITION} = shift if @_;
	return $self->{PSOITION};
}

sub namespace {
	my $self = shift;
	$self->{NAMESPACE} = shift if @_;
	return $self->{NAMESPACE};
}

sub download {
	my $self = shift;
	$self->{DOWNLOAD} = shift if @_;
	return $self->{DOWNLOAD};
}

sub element_name {
	my $self = shift;
	$self->{ELEMENT_NAME} = shift if @_;
	return $self->{ELEMENT_NAME};
}
		
sub module {
	my $self = shift;
	$self->{MODULE} = shift if @_;
	return $self->{MODULE};
}
		
sub version {
	my $self = shift;
	$self->{VERSION} = shift if @_;
	return $self->{VERSION};
}

sub generator {
        my $self = shift;
        $self->{GENERATOR} = shift if @_;
        return $self->{GENERATOR};
}

sub han_name {
        my $self = shift;
        $self->{HAN_NAME} = shift if @_;
        return $self->{HAN_NAME};
}

sub han_out {
        my $self = shift;
        $self->{HAN_OUT} = shift if @_;
        return $self->{HAN_OUT};
}

=head1 NAME

Machine_Spec::Document - reader class filter for Machine_Spec Documents

=head1 Example

  use Amin::Machine::Machine_Spec::Document;
  use XML::SAX::PurePerl;

  my $h = Amin::Machine::Machine_Spec::Document->new();
  my $x = XML::Filter::XInclude->new(Handler => $h);
  my $p = XML::SAX::PurePerl->new(Handler => $x);
  my $spec = $p->parse_uri($some_uri);	
  
  #do something with $spec here

=head1 DESCRIPTION

  This is a reader class for an Amin Machine_Spec document. 
  Please see Amin::Machine::Machine_Spec for full details
  about this reader, and the xml used/returned.
   
=cut

1;
