package Amin::Machine::Handler::Writer;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

sub start_element {
	my ($self, $element) = @_;
	my $spec = $self->{Spec};
	my $el = '<' . $element->{Name};
	if ($element->{Attributes}) {
		my %attrs = %{$element->{Attributes}};
		for my $k (keys %attrs) {
			$el .= " " . $attrs{$k}->{Name} . "=\"" . $attrs{$k}->{Value} . "\"";
		}
	}
	$el .= ">";
	push @{$self->{Spec}->{Buffer}}, $el;
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
     $data =~ s/(^\s+|\s+$)//gm;

	#xml escape the output
	if ($data ne "") {
		$data = $self->escape_it($data);
		push @{$self->{Spec}->{Buffer}}, $data;
	}
}

sub end_element {
	my ($self, $element) = @_;
    	my $el = '</' . $element->{Name} . '>';
	push @{$self->{Spec}->{Buffer}}, $el;
}



sub comment {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data =~ s/(^\s+|\s+$)//gm;	
	if ($data) {
		push @{$self->{Spec}->{Buffer}}, "<!--" . $data . "-->";
	}
}


sub escape_it {
	my ($self, $string) = @_;
	#$string =~ s///oge;
	$string =~ s|\&|\&amp;|oge;
    $string =~ s|<|\&lt;|oge;
	$string =~ s|>|\&gt;|oge;
	#$string =~ s|\"|\&quot;|oge;
	#$string =~ s|\'|\&apos;|oge;
	return $string;
}

sub start_document {
	my $self = shift;
	#do what?
	$self->{Spec}->{Buffer_End} = "begin";
}

sub end_document {
	my $self = shift;
	my $buffer = $self->{Spec}->{Buffer};
	my $line;
	foreach (@$buffer) {
		if ($_ eq "") {
			$line = "end";
			last;
		} else {
			$line .= "$_";
		}
	}
	$self->{Spec}->{Buffer_End} = $line;
}


#sub start_prefix_mapping {}
#sub end_prefix_mapping {}
#sub processing_instruction {}
#sub ignorable_whitespace {
#sub notation_decl {
#sub unparsed_entity_decl {
#sub element_decl {
#sub attribute_decl {
#sub skipped_entity {
#sub internal_entity_decl {
#sub external_entity_decl {
#sub start_entity {
#sub end_entity {
#sub start_dtd {
#sub end_dtd {
#sub comment {
#sub start_cdata {}
#sub end_cdata {}

1;
