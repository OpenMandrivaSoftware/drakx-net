package network::connection::cellular_bluetooth;

use base qw(network::connection::cellular);

use strict;
use common;

my $rfcomm_dev_prefix = "/dev/rfcomm";

sub get_type_name { N("Bluetooth") }
sub get_type_description { N("Bluetooth Dial Up Networking") }
sub _get_type_icon { 'bluetooth' }
sub get_devices {
    my ($_class, %options) = @_;
    ($options{fast_only} ? () : search_services('DUN'));
}

sub get_metric { 45 }
sub get_interface { "ppp0" }

sub get_packages { 'bluez-utils', 'ppp' }

sub get_rfcomm_device {
    my ($self) = @_;
    $self->{rfcomm_device} ||= find { ! -e ($rfcomm_dev_prefix . $_) } 0 .. 99;
}

sub get_tty_device {
    my ($self) = @_;
    $rfcomm_dev_prefix . $self->get_rfcomm_device;
}

# http://www.hingston.demon.co.uk/mike/nokia6680.html
# http://kapsi.fi/~mcfrisk/linux_gprs.html
# GPRS specific commands http://www.phonestar.com.my/s_at_10.html

sub search_services {
    my ($service_type) = @_;
    my (@services);
    my $service = {};
    my ($key, $value);
    my $push_service = sub { push @services, $service if exists $service->{class} };
    my $use_key = sub { $key = $_[0]; undef $value };
    foreach (run_program::rooted_get_stdout($::prefix, 'sdptool', 'search', $service_type)) {
        if (/^Searching for $service_type on (.+) \.\.\.$/) {
            $push_service->();
            $service = { addr => $1 };
        } elsif (/^Service Name:\s+(.*)$/) {
            $service->{name} = $1;
        } elsif (/^Service Provider:\s+(.*)$/) {
            $service->{name} = $1;
        } elsif (/^\s*Channel:\s*(\d+)$/) {
            $service->{channel} = $1;
        } elsif (/^Service Class ID List/) {
            $use_key->('class');
        } else {
            $value = chomp_($_);
        }
        if ($key && $value) {
            $service->{$key} = $value;
            $use_key->(undef);
        }
    }
    $push_service->();
    my %names;
    foreach (@services) {
        $names{$_->{addr}} ||= chomp_(run_program::rooted_get_stdout($::prefix, 'hcitool', 'name', $_->{addr}));
        $_->{description} = $names{$_->{addr}};
    }
    @services;
}

sub set_ppp_settings {
    my ($self) = @_;

    $self->{access}{cid} = 1;
    $self->{access}{at_commands} = [ qq(AT+CGDCONT=$self->{access}{cid},"IP","$self->{access}{apn}") ];

    $self->SUPER::set_ppp_settings;
}

sub write_settings {
    my ($self) = @_;

    my $dev = $self->get_rfcomm_device;
    output("$::prefix/etc/bluetooth/rfcomm.conf", qq(
rfcomm$dev {
	bind yes;
	device $self->{device}{addr};
	channel $self->{device}{channel};
	comment "Dial-up networking";
}
));

    $self->SUPER::write_settings;
}

sub prepare_connection {
    my ($self) = @_;
    run_program::rooted_get_stdout($::prefix, 'rfcomm', 'bind', $self->get_rfcomm_device);
}

1;
