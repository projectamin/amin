package Amin::Command::Elt;

use vars qw(@ISA);
use strict;
use warnings;
use Amin;
use Amin::Machine::AdminList;
use Amin::Controller::CLIOutput;
use Amin::Machine::AdminList::Name;
use XML::SAX::PurePerl;
use IPC::Run qw(run harness);
use XML::SAX::Base;

#LICENSE:

#Please see the LICENSE file included with this distribution 

@ISA = qw(XML::SAX::Base);

#generic filter methods
sub start_element {
  my ($self, $element) = @_;
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

sub chars_shell {
  my ($self, $element, $attrs, $data) = @_;
  if ($element->{LocalName} eq "shell") {
    if ($attrs->{'{}name'}->{Value} eq "dir") {
      $self->dir($data);
    }
    if ($attrs->{'{}name'}->{Value} eq "env") {
      $self->env_vars($data);
    }
  }
}

sub chars_flag {
  my ($self, $element, $attrs, $data) = @_;
  if ($element->{LocalName} eq "flag") {
    $self->flag(split(/\s+/, $data));
  }
}

sub chars_param {
  my ($self, $element, $attrs, $data) = @_;
  if ($element->{LocalName} eq "param") {
    my @things = $data =~ m/([\+\.\w=\/-]+|'[^']+')\s*/g;
    foreach my $thing (@things) {
       $thing =~ s/(^'|'$)//gm;
       $self->param(split(/\s+/, $thing));
    }
  }
}

#generic parts of an element
sub attrs {
  my $self = shift;
  $self->{'ATTRS'} = shift if @_;
  return $self->{'ATTRS'};
}

sub command {
  my $self = shift;
  $self->{'COMMAND'} = shift if @_;
  if (! $self->{'COMMAND'}) { $self->{'COMMAND'} = ""; }
  return $self->{'COMMAND'};
}

sub prefix {
  my $self = shift;
  $self->{'Prefix'} = shift if @_;
  return $self->{'Prefix'};
}

sub localname {
  my $self = shift;
  $self->{'LocalName'} = shift if @_;
  return $self->{'LocalName'};
}

sub command_name {
  my $self = shift;
  $self->{'COMMAND_NAME'} = shift if @_;
  return $self->{'COMMAND_NAME'};
}

#default <amin:param>

sub param {
	my $self = shift;
	my $param = $self->{'PARAM'} || ();
	if (@_) {push @$param, @_;}
	$self->{'PARAM'} = $param;
	return $self->{'PARAM'};
}

sub target {
	my $self = shift;
	if (@_) {push @{$self->{TARGET}}, @_; }
	return \@{ $self->{TARGET} };
}

#default <amin:flag>

sub flag {
  my $self = shift;
  my $flag = $self->{'FLAG'} || ();
  if (@_) {push @$flag, @_;}
  $self->{'FLAG'} = $flag;
  return $self->{'FLAG'};
}

#these are defaults for <amin:shell>

sub dir {
  my $self = shift;
  $self->{DIR} = shift if @_;
  return $self->{DIR};
}

sub env_vars {
  my $self = shift;
  my $env_vars = $self->{'ENV_VARS'} || ();
  if (@_) {push @$env_vars, @_;}
  $self->{'ENV_VARS'} = $env_vars;
  return $self->{'ENV_VARS'};
}

#element name
sub name {
	my $self = shift;
	$self->{NAME} = shift if @_;
	return $self->{NAME};
}

#element itself
sub element {
	my $self = shift;
	$self->{ELEMENT} = shift if @_;
	return $self->{ELEMENT};
}

#other subs
sub fix_text {
	my ($self, $text) = @_;
	$text =~ s/(^\s+|\s+$)//gm;
	return $text;
}

sub param_data {
  my ($self, $data) = @_;
  my @pd = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
  return \@pd;
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

sub chdir {
  my ($self, $dir) = @_;
  if (! CORE::chdir $dir) {
    $self->{'Spec'}->{'amin_error'} = "red";
    my $text = "Unable to change directory to $dir. Reason: $!";
    my $log = $self->{'Spec'}->{'Log'};
    $log->error_message($text);
  } 
}

sub get_command {
  my ($self, $command_name, $flag, $param) = @_;
  my %cmd;
  $cmd{'CMD'} = $command_name;
  $cmd{'FLAG'} = $flag;
  $cmd{'PARAM'} = $param;
  if ($self->{'ENV_VARS'}) {
    $cmd{'ENV_VARS'} = $self->{'ENV_VARS'};
  }
  return \%cmd;
}

sub get_flag {
  my ($self, $flags, $double) = @_;
  my @flag;
  foreach my $flag (@$flags){
    if (!$flag) {next;};
    if (($flag =~ /^-/) || ($flag =~ /^--/)) {
      push @flag, $flag;
    } else {
        if ($double) {
          if (ref($double) eq 'ARRAY') {
            my $single = 0;
            foreach my $fl (@$double) {
              if ($flag eq $fl) {
                   $flag = "--" . $flag;
                   $single = 1;
              }
            }
            #this is for single flags that are with a doubles array
            if ($single == 0) {
              $flag = "-" . $flag;
            }
          } elsif ($flag eq $double) {
            $flag = "--" . $flag;
          } else {
            $flag = "-" . $flag;
          }
        } else {
          $flag = "-" . $flag;
        }
        push @flag, $flag;
      }
  }
  return \@flag;
}

sub command_message {
     my ($self, $cmd, $success, $error) = @_;
     my $log = $self->{'Spec'}->{'Log'};
     if ($cmd->{'STATUS'}) {
          #there was an error
          #type is either error or both.
          #set the error
          $self->{'Spec'}->{'amin_error'} = "red";
     
          $log->error_message($error);
          if ($cmd->{'ERR'}) {
               $log->ERR_message($cmd->{'ERR'});
          }
          if (($cmd->{'OUT'}) && ($cmd->{'TYPE'} eq "both")) {
               $log->OUT_message($cmd->{'OUT'});
          }
     } else {
          #command was a success
          $log->success_message($success);
          $log->OUT_message($cmd->{'OUT'});
     }
}

sub doc_type {
    my $self = shift;
    $self->{DOC_TYPE} = shift if @_;
    return $self->{DOC_TYPE};
}

sub doc_name {
    my $self = shift;
    $self->{DOC_NAME} = shift if @_;
    return $self->{DOC_NAME};
}

sub text {
	my $self = shift;
	$self->{TEXT} = shift if @_;
	return $self->{TEXT};
}

sub white_wash {
    my $self = shift;
    my $command = shift;
    #passed white wash command examples
    #my $command = "mkdir /tmp/test_dir";
    #my $command = "mkdir -p";
    #my $command = "mkdir -p /tmp/test_dir";
    #my $command = "mkdir -m=0755 /tmp/test_dir";
    #my $command = "ENV=some mkdir -m /tmp/test_dir";
    #my $command = "mkdir /tmp/test_dir /other/dir";
    #my $command = "mkdir -p -m";
    #my $command = "mkdir -p -p";
    #my $command = "ENV=some OTHER=soe mkdir -v -p /tmp/test_dir /other/dir";
    #my $command = "ENV=some OTHER=soe mkdir -i -p /tmp/test_dir /other/param one more \'and another\'";
    
    my $command_name;
    my $flag;
    my $param;
    my %command;
    my @flags;
    my @params;
    my @shells;
    my @things = split(/([\*\+\.\w=\/-]+|'[^']+')\s*/, $command);

    foreach (@things) {
    #check for real stuff
    if ($_) {
        #check for flag
        if (($_ =~ /^-.*$/) || ($_ =~ /^--.*$/)) {
            #it is a flag
            my %flag;
            my $char;
            $_ =~ s/-//;
            $_ =~ s/--//;
            if ($_ =~ /^.*=.*$/) {
                #check for stuff like -m=0755 crap
                ($_, $char) = split (/=/, $_);
            } else  {
                #its just a flag
                $char = $_;
                $_ = undef;
            }
            
            if ($_) {
                $flag{"name"} = $_;
            }
            $flag{"char"} = $char;
            push @flags, \%flag;
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

sub amin_command {
	my $self = shift;
     my @cmds = @_;
     my $debug = $self->{Spec}->{Debug} || "";
     my $cmd = shift;
     my $special = shift || "";
     my $cmd2 = shift || ();

     my ($in, $out, $err, $status, $command, $flag, $param, @cmd2, $flag2, $param2, @cmd);
     if ($special ne "shell") {
          #needs to be an error thrown here for when there is "no command"
          $command = $cmd->{'CMD'} || "";
          $flag = $cmd->{'FLAG'} || ();
          $param = $cmd->{'PARAM'} || ();
          @cmd2 = $cmd2->{'CMD'} || "";
          $flag2 = $cmd2->{'FLAG'} || ();
          $param2 = $cmd2->{'PARAM'} || ();

          push @cmd, $command;

          if ($flag) {
               foreach (@$flag) {
                    if (!defined $_) { next; }
                    push @cmd, $_;
               }
          }
          if ($param) {
               foreach (@$param) {
                    if (!defined $_) {
                         next;
                    }
                    push @cmd, $_;
               }
          }

          if ($cmd2 ne "") {
               if ($flag2) {
                    foreach (@$flag2) {
                         if (!defined $_) { next; }
                         push @cmd2, $_;
                    }
               }

               if ($param2) {
                    foreach (@$param2) {
                         if (!defined $_) { next; }
                         push @cmd2, $_;
                    }
               }
          }
          if (defined $cmd->{'ENV_VARS'}) {
               my $vars = $cmd->{'ENV_VARS'};
               foreach (@$vars) {
                    my ($name, $value) = split(/=/, $_, 2);
                    #define a local %ENV setting for this command
                    if (($debug eq "ac") || ($debug eq "all")) {
                         print "Env: $name = $value\n";
                    }
                    $ENV{$name} = $value;
               }
          }
     }
     if ($special eq "shell") {
          my $h = harness [ "sh", "-c", $cmd ], \$in, \$out, \$err;
          run $h ;
          $status = $h->result;
     } else {
          my $h = harness \@cmd, \$in, \$out, \$err;
          if (($debug eq "ac") || ($debug eq "all")) {
               print "CMD = :@cmd:\n";
          } elsif ($debug eq "acc") {
               print "CMD = :@cmd:\n";
          } else {
               run $h ;
               $status = $h->result;
          }
     }

     if ($special ne "shell") {
          if (defined $cmd->{'ENV_VARS'}) {
               my $vars = $cmd->{'ENV_VARS'};
               foreach (@$vars) {
                    #undefine our %ENV setting
                    my ($name, $value) = split(/=/, $_, 2);
                    delete $ENV->{'$name'};
               }
          }
     }
     my %rcmd;
     $rcmd{OUT} = $out;
     $rcmd{ERR} = $err;
     $rcmd{STATUS} = $status;
     my $cmdtype;
     if (($err) && ($out)) {
          $cmdtype = "both";
     } elsif ((!$err) && ($out)) {
          $cmdtype = "out";
     } elsif (($err) && (!$out)) {
          $cmdtype = "error";
     } elsif ((!$err) && (!$out)) {
     #this is for commands like mkdir which return nothing on success
          $cmdtype = "out";
     }
     $rcmd{TYPE} = $cmdtype;

     return \%rcmd;
}

1;
