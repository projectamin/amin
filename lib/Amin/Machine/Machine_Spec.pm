package Amin::Machine::Machine_Spec;

#LICENSE:

#Please see the LICENSE file included with this distribution 

use strict;
use vars qw(@ISA);
use Amin::Machine::Machine_Spec::Document;
#use Amin::Machine::Filter::XInclude;
use XML::SAX::PurePerl;
#use IPC::Run qw( run );
use File::Basename qw(dirname);
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);
#the spec is defined in one of four ways
#1. any uri - disabled as include...
#2. /etc/amin/machine_spec.xml
#3. ~/.amin/machine_spec.xml
#4. the default machine spec found inside
#   ~perl/site_perl/Amin/Machine/Machine_Spec/machine_spec.xml

sub start_document {
	my $self = shift;

    #reset machine_filters
    $self->{'filters'} = {};

    #find the right uri
    my $homespec = $ENV{'HOME'} . "/.amin/machine_spec.xml";
    my $uri;
	if ($self->{URI}) {
        $uri = $self->{URI};
	} elsif (-f '/etc/amin/machine_spec.xml') {
		$uri = "file://etc/amin/machine_spec.xml";
	} elsif (-f $homespec) {
		$uri = "file:/" . $homespec;
	} else {
		#find the ~perl dir
		my $dir = $INC{'Amin.pm'};
        $dir = dirname($dir);
		$uri = "file:/" . $dir . "/Amin/Machine/Machine_Spec/machine_spec.xml";
	}

    #return the processed machine spec from the uri
    my $h = Amin::Machine::Machine_Spec::Document->new();
    #my $x = Amin::Machine::Filter::XInclude->new(Handler => $h);
    my $p = XML::SAX::PurePerl->new(Handler => $h);
    $self->{'Spec'} = $p->parse_uri($uri);    
}

sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
    my $module = $element->{Prefix} . "::" . $element->{'LocalName'};
    if ($attrs{'{}name'}->{'Value'}) {
        $module .= "::" . $attrs{'{}name'}->{'Value'};
    }
    $self->{'filters'}->{$module} = "";
}


sub end_document {
	my $self = shift;
	my $spec = $self->{'Spec'};
    my $spec_filters = $spec->{'Filter'};
	my $doc_filters = $self->{'filters'};
    my %machine_filters;
	#do all the positions
     foreach my $filter (keys %$spec_filters) {
        if (!defined $spec_filters->{$filter}->{position}) {next;} 
        my @positions = qw(begin permanent middle end);
        foreach my $position (@positions) {
            if ($spec_filters->{$filter}->{position} =~ /$position/) {
               foreach my $doc_filter (%$doc_filters) {
                    my ($namespace, $type, $name) = split(/::/, $doc_filter);
                    $namespace =~ s/^([a-z])/\u$1/;
                    $type =~ s/^([a-z])/\u$1/;
                    $name =~ s/^([a-z])/\u$1/;
                    $doc_filter = join('::', $namespace, $type, $name);
                    $doc_filter = $namespace . "::" . $type;
                    if ($name) {$doc_filter = $doc_filter . "::" . $name;}
                    if ($filter eq $doc_filter) {
                         my %new;
                         my $hash = $spec_filters->{$filter};
                         foreach my $keys (keys %$hash) {
                              $new{$keys} = $spec_filters->{$filter}->{$keys};
                         }
                         $machine_filters{$filter} = \%new;
                    }
               }
            }
        }
	}
     $spec->{Filter_List} = \%machine_filters;
     $spec->{Filter} = undef;
	foreach my $machine_filter (keys %machine_filters) {
		#autoload module check
		no strict 'refs';
		eval "require $machine_filters{$machine_filter}->{'module'}";

		#version check
		#my $version;
		#my $module = $machine_filters{$machine_filter}->{'module'};
		#unless ($@) {
		#	if ($module->can("version")) {
		#		$version = $module->version;
		#	} else {
          #      die "Your filter $machine_filters{$machine_filter}->{module} does not have a version subroutine. Please add one...";
          #  }
		#}	
		#if (($@) || ($version ne $machine_filters{$machine_filter}->{version})) {
		#	if ($machine_filters{$machine_filter}->{'download'}) {
				#removed $0 due to daemon/httpd loops/crashes....
		#		my @cmd = ('amin', '-u', $machine_filters{$_}->{'download'});
		#		run \@cmd;
		#		eval "require $machine_filters{$machine_filter}->{module}";
		#		if ($@) {
		#			die "Machine_Spec failed could not load $machine_filter->{module}. Reason $@";
		#		}
		#	}
		#}
		
	}
	
	return $spec;
}

=head1 NAME

Machine_Spec - The machine spec reader, default setup class.


=head1 Example

  use Amin::Machine::Machine_Spec;	
  use Amin::Machine::Filter::XInclude;	
  use XML::SAX::PurePerl;
  
  $uri = is_uri($profile);
  #load the spec parts that are involved in this machine parse
  my $machine_spec = is_uri($machine_spec);
  my $h;
  if ($machine_spec) {
    $h = Amin::Machine::Machine_Spec->new('URI' => $machine_spec);
  } else {
    $h = Amin::Machine::Machine_Spec->new();
  }
  #don't forget to include other specs this spec may include....
  my $ix = Amin::Machine::Filter::XInclude->new('Handler' => $h);
  my $p = XML::SAX::PurePerl->new('Handler' => $ix);

  my $spec;
  if ($uri) {
    $spec = $p->parse_uri($uri);
  } else {
    $spec = $p->parse_string($profile);
  }
  #do something with $spec
  return $spec;
  
=head1 DESCRIPTION

Machine_Spec - This module controls the machine spec document
reader. It also manipulates that output into the default machine
spec setup. A machine spec is central to any amin machine process.
All admin filters, machine handler, generators, filters and so 
on will check the machine spec to perform their operations.

The spec is defined in one of four ways

 1. by uri - http://example.com/machine_spec.xml

 2. the amin etc dir - /etc/amin/machine_spec.xml

 3. user's home amin dir - ~/.amin/machine_spec.xml

 4. the default machine spec found inside
    ~perl/site_perl/Amin/Machine/Machine_Spec/machine_spec.xml
   
Example machine_spec.xml is shown in the XML section.

After the $spec is defined, several things are done 
with the resulting $spec. 

1. The machine_spec.xml may have more or less filters available 
   than what the current profile.xml has inside. 
   
2. We prune the excess machine_spec.xml filters that are not in
   the current profile being processed. 
   
3. Each filter presented in the profile, is added to the filterlist.
   Each filter added also adds any special relationships, ie begin->middle
   filters and parent->child relationships from the xml. This allows 
   for machine designers to customize the spec/element relationships as 
   needed in an amin machine.
   
All the pruning has a pleasant side effect, that you can 
control filter usage per Amin machine instance, by a xml file called 
machine_spec.xml at this uri over here. Think about it for a bit. 
Think about reconfiguring your xml admin app each time your machine
processes these profiles....

Don't want anyone to use 

 <amin:command name="mkdir"> 

commands?

remove

	<filter name="Amin::Command::Mkdir">
		<namespace>amin</namespace>
		<element>command</element>
		<name>mkdir</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/mkdir.xml</download>
		<version>1.2</version>
		<option>Kewl Stuff</option>
	</filter>
   
in your machine_spec.xml and your Amin machine(s)
will ignore all 

 <amin:command name="mkdir"> 

filter requests. Even if the Mkdir.pm filter is 
installed on said system and present in the profile.

After the first round of $spec manipulation, we move 
onto phase two. Phase two involves loading each 
individual filter listed in the pruned $spec. If the filter
is not available, this module looks at the filter's
"download" setting and runs this as a new amin machine
that tries to process the filter's download profile.

A download profile is just a simple profile on how 
to download, and install this filter. It also cleans
up after itself. 

A bundle on the other hand is just a fancy package for
a complete set of filters. Ex. Amin Command filters
This allows you to have installation, and control on 
two levels. One more generic(<bundle>) and one more 
fine grained(<filter>). ***not implemented yet***

If for some reason <download> is not available in 
the machine_spec, we use some PAR tricks and see if
Amin filter sets will provide the needed filter. 
***not implemented yet***

If all this fails and the filter, can not be loaded
then this machine process can not complete and the
entire machine process fails, with appropriate 
outputs. 

As each filter passes this load test, the filter's 
position is looked at and the filter is added to 
the approriate parent_stage.  

A position for a filter is just it's location in a
sax stream process. Typically most filters have a 
position of "middle". They really don't care what
comes before or after them. Nor do they care about
other filters and if they ran successfully or not.
ie they are self contained units.....

Complex commands like chroot or <amin:cond> do care
about what position they are in relation to the filters
that are their children. ex.

 <amin:chroot>
	<amin:command name="mkdir" />
 </amin:chroot>

So the chroot filter needs to be first in the sax chain
and the mkdir filter would come after in the chain. 

A filter may want to collect events from many filters
before it. It may want to do something with all events
from all the filters before handing it off to the default
machine handler. Say it deleted certain messages any filter
may have produced before final output. So you would want
this filter at the end of the sax processing chain.

Maybe you have a combo filter set. A profile splitter and
a profile merger. The profile splitter was first in the  
sax chain, all the profile's filters would be in the middle,
and then profile merger would be at the end. 

The positions recognized are 

 begin
 middle
 end

After all this filter manipulation is over, the final
thing we do, is add the other $spec defaults, and then 
return the new $spec. 

The other defaults are 

 $spec{Handler}
 $spec{Log}
 $spec{Generator}
 $spec{Filter_Param}

The defaults specified are defined in other modules. 
Filter_Param may be undefined. 


=head1 XML

=over 4

=item Full example

  <machine xmlns:amin="http://projectamin.org/ns/">
	<generator name="XML::SAX::PurePerl"/>
	<handler name="XML::SAX::Writer" output="yes" />
	<name>Amin::Machine::Dispatcher</name>
	<filter name="Amin::Command::Mkdir">
		<namespace>amin</namespace>
		<element>command</element>
		<name>mkdir</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/mkdir.xml</download>
		<version>1.2</version>
		<option>Kewl Stuff</option>
	</filter>
	<filter name="Amin::Command::Mount">
		<element>command</element>
		<namespace>amin</namespace>
		<name>mount</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/mount.xml</download>
		<version>1.0</version>
	</filter>
	<filter name="Amin::Command::Ls">
		<element>command</element>
		<namespace>amin</namespace>
		<name>ls</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/ls.xml</download>
		<version>1.0</version>
	</filter>
	<filter name="Amin::Command::Move">
		<element>command</element>
		<namespace>amin</namespace>
		<name>move</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/move.xml</download>
		<version>1.0</version>
	</filter>
	<bundle name="Amin::Command">
		<element>command</element>
		<namespace>amin</namespace>
		<name>command</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command.xml</download>
		<version>1.0</version>
	</bundle>
  </machine>	
	
=back  

=cut

1;