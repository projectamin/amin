package Amin::Uri;

#code lifted and modified from Richard Sonnen Data-Validate-URI-0.01

#LICENSE for modified bits:

#Please see the LICENSE file included with this distribution 

use strict;
require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(is_uri);

sub is_uri{
	my $value = shift;
	
	return unless defined($value);
	
	# check for illegal characters
	return if $value =~ /[^a-z0-9\:\/\?\#\[\]\@\!\$\&\'\(\)\*\+\,\;\=\.\-\_\~]/i;
	
	#split the uri
	my @bits = $value =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;
	
	# from RFC 3986
	my($scheme, $authority, $path, $query, $fragment) = @bits;
	
	# scheme and path are required, though the path can be empty
	return unless (defined($scheme) && length($scheme) && defined($path));
	
	# if authority is present, the path must be empty or begin with a /
	if(defined($authority) && length($authority)){
		return unless(length($path) == 0 || $path =~ m!^/!);
	
	} else {
		# if authority is not present, the path must not start with //
		return if $path =~ m!^//!;
	}
	
	# scheme must begin with a letter, then consist of letters, digits, +, ., or -
	return unless lc($scheme) =~ m!^[a-z][a-z0-9\+\-\.]*$!;
	
	# re-assemble the URL per section 5.3 in RFC 3986
	my $out = $scheme . ':';
	if(defined $authority && length($authority)){
		$out .= '//' . $authority;
	}
	$out .= $path;
	if(defined $query && length($query)){
		$out .= '?' . $query;
	}
	if(defined $fragment && length($fragment)){
		$out .= '#' . $fragment;
	}
	return $out;
}

1;


=head1 NAME
 
Amin::Uri - URI test module

=head1 version

Amin::Uri 1.0

=head1 DESCRIPTION

  This module provides one method. 
  
  my $uri = is_uri($uri);
  
  If the $uri is a uri, it will be returned, 
  otherwise there will be no return value. 
  
=cut

