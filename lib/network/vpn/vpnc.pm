package network::vpn::vpnc;

use base qw(network::vpn);

use strict;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;

sub get_type { 'vpnc' }
sub get_description { N("Cisco VPN Concentrator") }
sub get_packages { 'vpnc' }

sub read_config {
    my ($connection) = @_;
    my @fields = group_by2(list_fields($connection));
    foreach (cat_($connection->get_config_path)) {
        foreach my $field (@fields) {
            # all strings start exactly one space after the keyword string
            /^$field->[0] (.*)/ and ${$field->[1]{val}} = $1;
        }
    }
}

sub write_config {
    my ($connection) = @_;
    output_with_perm($connection->get_config_path, 0600, map {
        if_(${$_->[1]{val}}, $_->[0], ' ', ${$_->[1]{val}}, "\n");
    } group_by2(list_fields($connection)));
}

sub get_settings {
    my ($connection) = @_;
    second(list2kv(list_fields($connection)));
}

sub list_fields {
    my ($connection) = @_;
    (
        'IPSec gateway' => {
            label => N("Gateway"),
            val => \$connection->{gateway},
        },
        'IPSec ID' => {
            label => N("Group name"),
            val => \$connection->{id},
        },
        'IPSec secret' => {
            label => N("Group secret"),
            val => \$connection->{secret},
            hidden => 1,
        },
        'Xauth username' => {
            label => N("Username"),
            val => \$connection->{username},
        },
        'Xauth password' => {
            label => N("Password"),
            val => \$connection->{password},
            hidden => 1,
        },
        'NAT Traversal Mode' => {
            label => N("NAT Mode"),
            list => [ '', qw(natt none force-natt cisco-udp) ],
            val => \$connection->{udp},
            advanced => 1,
        },
        'Cisco UDP Encapsulation Port' => {
            label => N("Use specific UDP port"),
            val => \$connection->{udp_port},
            advanced => 1,
        },
    );
}

1;
