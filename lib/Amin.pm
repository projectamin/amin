package Amin;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use Amin::Machine::Machine_Spec;
#use Amin::Machine::Filter::XInclude;
use Amin::Uri qw(is_uri);
use Amin::Machine::AdminList;
use Amin::Machine::AdminList::Name;
#use Amin::Machine::NetworkMap;
use Amin::Profile::Type;
use Amin::Machine::Profile::Checker;
use XML::SAX::PurePerl;
#use Sort::Naturally;

use vars qw($VERSION);
$VERSION = '0.7.5';

sub new {
	my $class = shift;
	my %args = @_;
    
	my $self;

    my %defaults = (
        'Handler' => 'Amin::Machine::Handler::Writer',
        'Generator' => 'XML::SAX::PurePerl',
        'Log'  => 'Amin::Machine::Log::Standard',
        'Machine_Name' => 'Amin::Machine::Dispatcher'
    );

    my @types = qw(Handler Generator Machine_Name Log);
    foreach my $type (@types) {
        if (($type eq "Machine_Name") && (!defined $args{'Machine_Name'})) {
            $args{'Machine_Name'} = $defaults{$type};
        } else {
            if ( defined $args{$type} ) {
                if ( ! ref( $args{$type} ) ) {
                    eval "require $args{$type}";
                    $args{$type} = $args{$type}->new();
                }
            } else {
                eval "require $defaults{$type}";
                $args{$type} = $defaults{$type}->new();
            }
        }
    }

	$args{'FILTERLIST'} ||= [];
	$self = bless \%args, $class;
	return $self;
}

sub parse {
	my ($self, $profile, $machine_spec, $error) = @_;
     my $uri = is_uri($profile);
     #load the spec parts that are involved in this machine parse
     my $machine_spec = is_uri($machine_spec);
     my $h;
     if ($machine_spec) {
          $h = Amin::Machine::Machine_Spec->new('URI' => $machine_spec);
     } else {
          $h = Amin::Machine::Machine_Spec->new();
     }
     #my $ix = Amin::Machine::Filter::XInclude->new('Handler' => $h);
     my $p = XML::SAX::PurePerl->new('Handler' => $h);
     my $spec;
     if ($uri) {
          $spec = $p->parse_uri($uri);
     } else {
          $spec = $p->parse_string($profile);
     }

     my @names = qw(Machine_Name Filter_Param Debug);
     foreach my $name (@names) {
          if ($spec->{$name}) {
               #there was a name in the spec use it
               $self->{$name} = $spec->{$name};
          } else {
               #there was no name in the spec use default
               $spec->{$name} = $self->{$name};
          }
     }

     #add in the rest of the parts
     my @parts = qw(Handler Generator Log);
     foreach my $part (@parts) {
          if ($spec->{$part}->{name}) {
               if (! ref($spec->{$part})) {
                    #there was a part in the spec use it
                    no strict 'refs';
                    eval "require $spec->{$part}";
                    if ($spec->{$part}->{out}) {
                         if ($part eq "Log") {
                              $spec->{$part} = $spec->{$part}->{'name'}->new(Handler => $spec->{'Handler'}, Output => $spec->{$part}->{'out'});
                         } else {
                              $spec->{$part} = $spec->{$part}->{'name'}->new(Output => $spec->{$part}->{'out'});
                         }
                    } else {
                         if ($part eq "Log") {
                              $spec->{$part} = $spec->{$part}->{'name'}->new(Handler => $spec->{'Handler'});
                         } else {
                              $spec->{$part} = $spec->{$part}->{'name'}->new();
                         }
                    }
                    if ($@) {
                         my $text = "Could not load a $part named $spec->{$part}. Reason $@";
                         die $text;
                    }
               }
          } else { 
               #there was no part in the spec use the default
               $spec->{$part} = $self->{$part}; 
               if ($spec->{$part}->{out}) {
                    if ($part eq "Log") {
                         $spec->{$part} = $spec->{$part}->new(Handler => $spec->{'Handler'}, Output => $spec->{$part}->{'out'});
                    } else {
                         $spec->{$part} = $spec->{$part}->new(Output => $spec->{$part}->{'out'});
                    }
               } else {
                    if ($part eq "Log") {
                         $spec->{$part} = $spec->{$part}->new(Handler => $spec->{'Handler'});
                    } else {
                         $spec->{$part} = $spec->{$part}->new();
                    }
               }
          }
               
     }
     #load this machine and parse uri/profile
     
     my $machine_name = $spec->{'Machine_Name'};
     eval "require $machine_name";
     if ($@) {
          die "$machine_name does not exist? $@\n";
     } else {
          #add in the machine itself

          if ($error) { $spec->{'amin_error'} = 'red'; }
          my $machine = $machine_name->new('Spec' => $spec);
          #get a parser and hook up our machine to it
          my $parser = $spec->{'Generator'}->new('Handler' => $spec->{'Machine_Name'}, 'Spec' => $spec);
          if ($uri) {
               $parser->parse_uri($uri);
          } else {
               $parser->parse_string($profile);
          }
     }
	return $spec->{'Handler'}->{'Spec'}->{'Buffer_End'};
}

sub process {
     my ($self, $cli) = @_;
     my $text;

     #need to check and process profile, uri and adminlist
     my @in = ($cli->profile, $cli->uri, $cli->adminlist);
     my $h = Amin::Profile::Type->new();
     my $p = XML::SAX::PurePerl->new('Handler' => $h);
     foreach my $in (@in) {
          if (! $in) {next;}
          my $uri = is_uri($in);
          my $type;
          if ($uri) {
               $type = $p->parse_uri($uri);
          } else {
               $type = $p->parse_string($in);
          }
          if ($type eq "adminlist") {
               $text = $self->process_adminlist($in, $cli->adminlist_map);
          } else {
               $text = $self->process_profile($in, $cli->networkmap);
          }
     }
     return $text;
}

sub process_profile {
    my ($self, $profile, $networkmap, $error) = @_;
    my $out;
    if ($networkmap) {
        my $nm = $self->parse_networkmap($networkmap);
        foreach my $networkmap (keys %$nm) {
            my $protocol = $nm->{$networkmap}->{protocol};
            $out .= $protocol->parse($nm->{$networkmap}, $profile, $error);
        }
    } else {
        my $machine_spec = $self->{'Spec'} || undef;
        $out = $self->parse($profile, $machine_spec, $error);
    }
    my @out;
    push @out, $out;
    return \@out;
}

sub process_adminlist {
    my ($self, $adminlist, $adminlist_map) = @_;

    $adminlist = $self->parse_adminlist($adminlist);
    if($adminlist_map) {
        $adminlist_map = $self->parse_adminlistmap($adminlist_map);
    }
    my @types = qw(map profile adminlist);
    my ($profiles, $adminlists,$networkmap);
    if (defined $adminlist_map) {
        ($profiles, $adminlists, $networkmap) = $self->get_types(\@types, $adminlist_map);
        ($profiles, $networkmap) = $self->get_adminlists($profiles, $adminlists, $networkmap, $adminlist_map);
    } else {
        #no mapping
        ($profiles, $adminlists, $networkmap) = $self->get_types(\@types, $adminlist);
        ($profiles, $networkmap) = $self->get_adminlists($profiles, $adminlists, $networkmap);
    }
    my @out;
    my $error;
    foreach my $profile (@$profiles) {
        my $profile_result = $self->process_profile($profile, $networkmap, $error);
        my $text = pop @$profile_result; 
        my $h = Amin::Machine::Profile::Checker->new();
        my $p = XML::SAX::PurePerl->new(Handler => $h);
        my $result = $p->parse_string($text);
        if ($result) {$error = 1;}
        push @out, $text;
    }
    return \@out;
}

sub get_adminlists {
    my ($self, $profiles, $adminlists, $networkmap, $map) = @_;
    foreach (@$adminlists) {
        my $adminlist = $self->parse_adminlist($_);
        foreach my $key (keys %$adminlist) {
            if (defined $map) {
                if ($adminlist->{$key}->{'name'} eq $key) {
                    if ($adminlist->{$key}->{'type'} eq "map") {
                        $networkmap = $self->parse_networkmap($adminlist->{$key}->{uri});
                    } elsif ($adminlist->{$key}->{'type'} eq "adminlist") {
                        push @$adminlists, $adminlist->{$key}->{uri};
                    } elsif ($adminlist->{$key}->{'type'} eq "profile") {
                        push @$profiles, $adminlist->{$key}->{uri};
                    } 
                }
            } else {
                if ($adminlist->{$key}->{'name'} eq $key) {
                    if ($adminlist->{$key}->{type} eq "map") {
                        $networkmap = $self->parse_networkmap($adminlist->{$key}->{uri});
                    } elsif ($adminlist->{$key}->{type} eq "adminlist") {
                        push @$adminlists, $adminlist->{$key}->{uri};
                    } elsif ($adminlist->{$key}->{type} eq "profile") {
                        push @$profiles, $adminlist->{$key}->{uri};
                    } 
                }
            }
        }
    }
    return $profiles, $networkmap;
}

sub get_types {
    my ($self, $types, $adminlist) = @_;
    my ($networkmap, @profiles, @adminlists);
    foreach my $key (keys %$adminlist) {
        #this is a mapping
        if (defined $adminlist->{$key}->{name} eq $key) {
            if ($adminlist->{$key}->{name} eq $key) {
                foreach my $type (@$types) {
                    if ($adminlist->{$key}->{type} eq $type) {
                        if ($type eq "map") {
                            $networkmap = $self->parse_networkmap($adminlist->{$key}->{uri});
                        } elsif ($type eq "profile") {
                            push @profiles, $adminlist->{$key}->{uri};
                        } elsif ($type eq "adminlist") {
                            push @adminlists, $adminlist->{$key}->{uri};
                        }
                    }
                }
            }
        } else {
            foreach my $type (@$types) {
                if ($adminlist->{$key}->{type} eq $type) {
                    if ($type eq "map") {
                        $networkmap = $self->parse_networkmap($adminlist->{$key}->{uri});
                    } elsif ($type eq "profile") {
                        push @profiles, $adminlist->{$key}->{uri};
                    } elsif ($type eq "adminlist") {
                        push @adminlists, $adminlist->{$key}->{uri};
                    }
                }
            }
        }
    }
    return \@profiles, \@adminlists, $networkmap;
}

sub parse_adminlist {
    my ($self, $adminlist) = @_;
    my $h = Amin::Machine::AdminList->new();
    my $p = XML::SAX::PurePerl->new(Handler => $h);
    return $p->parse_uri($adminlist);
}

sub parse_networkmap {
    my ($self, $networkmap) = @_;
    #my $h = Amin::Machine::NetworkMap->new();
    #my $p = XML::SAX::PurePerl->new(Handler => $h);
    #return $p->parse_uri($networkmap);
}

sub parse_adminlistmap {
    my ($self, $adminlist_map) = @_;
    my $h = Amin::Machine::AdminList::Name->new();
    my $p = XML::SAX::PurePerl->new(Handler => $h);
    return $p->parse_uri($adminlist_map);
}

sub handler {
    my $self = shift;
    $self->{Handler} = shift if @_;
    return $self->{Handler};
}

sub generator {
    my $self = shift;
    $self->{Generator} = shift if @_;
    return $self->{Generator};
}

sub log {
    my $self = shift;
    $self->{Log} = shift if @_;
    return $self->{Log};
}

sub network_map {
    my $self = shift;
    $self->{Network_Map} = shift if @_;
    return $self->{Network_Map};
}

sub machine_spec {
    my $self = shift;
    $self->{Machine_Spec} = shift if @_;
    return $self->{Machine_Spec};
}

sub machine_type {
    my $self = shift;
    $self->{Machine_Type} = shift if @_;
    return $self->{Machine_Type};
}

sub filter_param {
    my $self = shift;
    $self->{Filter_Param} = shift if @_;
    return $self->{Filter_Param};
}

sub results {
	my $self = shift;
	if (@_) {push @{$self->{RESULTS}}, @_; }
	return @{ $self->{RESULTS} };
}

sub debug {
    my $self = shift;
    $self->{Debug} = shift if @_;
    return $self->{Debug};
}

sub adminlist_map {
    my $self = shift;
    $self->{Adminlist_Map} = shift if @_;
    return $self->{Adminlist_Map};
}

1;

__END__

=head1 Name

Amin - base class for Amin controllers

=head1 Example

#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Amin;
use Amin::Controller::CLI;
use Amin::Controller::CLIOutput;
use XML::SAX::PurePerl;

my $cli = Amin::Controller::CLI->new();
my $help = (<<END);

amin is a simple Amin controller.

more help here...
END

#define help
$cli->help($help);

my $usage = (<<END);
[-h|-help]
[-u|-uri] uri:// 
more usage...
END

$cli->usage($usage);

my $version = "0.6.0";
$cli->version($version);

#pass the $cli object to the $cli's get_profile
#this will load up the $cli object with
#all the details from the command line
$cli->get_opts($cli);

my $machine = Amin->new(
                Machine_Name => $cli->machine_name, 
                Machine_Spec => $cli->machine_spec,
                Generator => $cli->generator,
                Handler => $cli->handler,
                Filter_Param => $cli->filter_param,
                Log => $cli->log,
                Debug => $cli->debug);

#$out is returned as an array of outputs
my $out = $machine->process($cli);
foreach (@$out) {
     my $h = Amin::Controller::CLIOutput->new();
     my $p = XML::SAX::PurePerl->new(Handler => $h);
     my $text = $p->parse_string($_);
     print "$text\n";
}

exit;

1;

=head1 Description

  This is the base class for an Amin controller. This 
  module is used by a contoller to set various machine 
  settings, and to send/receive Amin profiles, adminlists, etc. 
  
=head1 Methods 

=over 4

=item *new
   
=item *parse_adminlist

=back

=cut
