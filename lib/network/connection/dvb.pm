package network::connection::dvb;

use strict;
use common;

use base qw(network::connection::ethernet);

use strict;
use common;
use modules;

sub get_type_name() { N("DVB") }
sub get_type_description() { N("Satellite (DVB)") }
sub _get_type_icon() { 'dvb' }

sub get_devices() {
    require detect_devices;
    detect_devices::probe_category("multimedia/dvb");
}

sub get_metric { 15 }

sub handles_ifcfg {
    my ($_class, $ifcfg) = @_;
    exists $ifcfg->{DVB_ADAPTER_ID};
}

sub get_interface {
    my ($self) = @_;
    defined $self->{hardware}{adapter_id} && defined $self->{hardware}{network_demux} or return "dvb";
    'dvb' . $self->{hardware}{adapter_id} . '_' . $self->{hardware}{network_demux};
}

sub get_dvb_device {
    find { sysopen(undef, $_, c::O_RDWR() | c::O_NONBLOCK()) } glob("/dev/dvb/adapter*/net*");
}

sub load_interface_settings {
    my ($self) = @_;
    $self->guess_hardware_settings; #- so that matching interface settings can be loaded
    $self->network::connection::load_interface_settings;
    $self->{hardware}{adapter_id} = $self->{ifcfg}{DVB_ADAPTER_ID};
    $self->{hardware}{network_demux} = $self->{ifcfg}{DVB_NETWORK_DEMUX};
    $self->{hardware}{network_pid} = $self->{ifcfg}{DVB_NETWORK_PID};
}

sub guess_hardware_settings {
    my ($self) = @_;
    my $device = get_dvb_device() or return;
    ($self->{hardware}{adapter_id}, $self->{hardware}{network_demux}) = $device =~ m,/dev/dvb/adapter(\d+)/net(\d+),;
}

sub get_hardware_settings {
   my ($self) = @_;
   [
       { label => N("Adapter card"), val => \$self->{hardware}{adapter_id} },
       { label => N("Net demux"), val => \$self->{hardware}{network_demux} },
       { label => N("PID"), val => \$self->{hardware}{network_pid} },
   ];
}

sub build_ifcfg_settings {
    my ($self) = @_;
    my $settings = {
        DVB_ADAPTER_ID => qq("$self->{hardware}{adapter_id}"),
        DVB_NETWORK_DEMUX => qq("$self->{hardware}{network_demux}"),
        DVB_NETWORK_PID => qq("$self->{hardware}{network_pid}"),
        MII_NOT_SUPPORTED => "yes",
    };
    $self->SUPER::build_ifcfg_settings($settings);
}

1;
