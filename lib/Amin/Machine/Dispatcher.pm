package Amin::Machine::Dispatcher;

#LICENSE:
#Please see the LICENSE file included with this distribution 

#Amin Dispatcher Machine
use strict;
use Amin::Machine::Filter::Dispatcher;

sub new {
     my $class = shift;
     my %args = @_;
     my $self = bless \%args, $class;
     my $spec = $self->{'Spec'};
     #deal with the filter_list ie set it up for a dispatcher filter machine
     my $fl = $spec->{'Filter_List'};
     my ($end, $middle, $pbegin, $begin) = undef;
     my @positions = ($end, $middle, $pbegin, $begin);
     my %words = (
          1 => 'end',
          2 => 'middle',
          3 => 'pbegin',
          4 => 'begin'
     );
     my $x = 0;
     my %repeats;
     my $last;
     foreach my $position (@positions) {
          $x++;
          foreach my $filter (keys %$fl) {
               my $repeat = $fl->{$filter}->{module};
               if (defined $repeats{$repeat} eq "r") {
                    next;
               } elsif ($fl->{$filter}->{position} eq $words{$x}) {
                    if (!$position) {
                         if ($last) {
                              $position = $fl->{$filter}->{module}->new(Handler => $last, Spec => $spec);
                              $repeats{$repeat} = "r";
                         } else {
                              $position = $fl->{$filter}->{module}->new(Handler => $spec->{Handler}, Spec => $spec);
                              $repeats{$repeat} = "r";
                         }
                    } else {
                         $position = $fl->{$filter}->{module}->new(Handler => $position, Spec => $spec);
                         $repeats{$repeat} = "r";
                    }
                    delete $fl->{$filter};
               }
          }
          $last = $position;
     }
     foreach my $position (reverse(@positions)) {
          if ($position) {
               $spec->{Filter_List} = $position;
               last;
          } 
     }
     $spec->{'Machine_Name'} = Amin::Machine::Filter::Dispatcher->new('Handler' => $spec->{'Filter_List'});
     #put our new wierd filter list back as the spec's Filter_List
     $self->{Spec} = $spec;
     return $self;
}

1;