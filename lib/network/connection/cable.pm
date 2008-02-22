package network::connection::cable;

use base qw(network::connection::ethernet);

use strict;
use common;
use modules;
use detect_devices;

sub get_type_name() { N("Cable") }
sub get_type_description() { N("Cable modem") }
sub _get_type_icon() { 'cablemodem' }
sub get_metric { 20 }

sub handles_ifcfg {
    my ($_class, $_ifcfg) = @_;
    0;
}

my $bpalogin_file = '/etc/bpalogin.conf';

sub guess_protocol {
    my ($self) = @_;
    $self->{protocol} = 'dhcp';
}

sub guess_access_settings {
    my ($self) = @_;
    $self->{access}{use_bpalogin} = -e $::prefix . $bpalogin_file;
    if ($self->{access}{use_bpalogin}) {
        foreach (cat_($::prefix . $bpalogin_file)) {
            /^username (.*)/ and $self->{access}{login} = $1;
            /^password (.*)/ and $self->{access}{password} = $1;
        }
    }
}

sub get_access_settings {
    my ($self) = @_;
    my %auth = (
        0 => N("None"),
        1 => N("Use BPALogin (needed for Telstra)"),
    );
    [
        { label => N("Authentication"), type => "list", val => \$self->{access}{use_bpalogin},
          list => [ sort keys %auth ], format => sub { $auth{$_[0]} } },
        { label => N("Account Login (user name)"), val => \$self->{access}{login},
          disabled => sub { !$self->{access}{use_bpalogin} } },
        { label => N("Account Password"),  val => \$self->{access}{password}, hidden => 1,
          disabled => sub { !$self->{access}{use_bpalogin} } },
    ];
}

sub write_settings {
    my ($self, $o_net, $o_modules_conf) = @_;
    if ($self->{access}{use_bpalogin}) {
        substInFile {
            s/username\s+.*\n/username $self->{access}{login}\n/;
            s/password\s+.*\n/password $self->{access}{password}\n/;
        } $::prefix . $bpalogin_file;
    }
    services::set_status("bpalogin", $self->{access}{use_bpalogin});
    $self->SUPER::write_settings($o_net, $o_modules_conf);
}

sub install_packages {
    my ($self, $in) = @_;
    if ($self->{access}{use_bpalogin}) {
        $in->do_pkgs->ensure_is_installed('bpalogin', '/usr/sbin/bpalogin') or return;
    }
    $self->SUPER::install_packages($in);
}

1;
