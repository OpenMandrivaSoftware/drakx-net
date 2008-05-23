package network::connection::cellular;

use base qw(network::connection::ppp);

use strict;
use common;

my $cellular_d = "/etc/sysconfig/network-scripts/cellular.d";

sub get_providers {
    require network::connection::providers::cellular;
    (\%network::connection::providers::cellular::data, '|');
}

sub get_cellular_settings_file {
    my ($self) = @_;
    my $network = $self->get_selected_network or return;
    $::prefix . $cellular_d . '/' . $network->{name};
}

sub load_cellular_settings {
    my ($self) = @_;
    my $file = $self->get_cellular_settings_file or return;
    -f $file && { getVarsFromSh($file) };
}

sub network_is_configured {
    my ($self, $_network) = @_;
    #- only one network is supported, assume it is configured if settings are available
    defined($self->load_cellular_settings);
}

sub write_cellular_settings {
    my ($self) = @_;
    my $file = $self->get_cellular_settings_file or return;
    setVarsInShMode($file, 0600, { map { (uc($_) => $self->{access}{$_}) } qw(login password apn) });
}

sub guess_apn_from_chat {
    my ($self) = @_;
    my $chat = cat_($::prefix . $self->get_chat_file);
    my $chat_apn = $chat =~ /\bAT\+CGDCONT=\d+,"IP","([^"]+)"/ && $1;
}

sub guess_provider_settings {
    my ($self) = @_;
    my $settings = $self->load_cellular_settings;
    my $apn = $settings && $settings->{APN} || $self->guess_apn_from_chat;
    if ($apn) {
        my @providers_data = $self->get_providers;
        $self->{provider_name} ||= find { $providers_data[0]{$_}{apn} eq $apn } keys %{$providers_data[0]};
        return;
    }
    $self->SUPER::guess_provider_settings;
}

sub guess_access_settings {
    my ($self) = @_;
    my $settings = $self->load_cellular_settings || {};
    $self->{access}{$_} = $settings->{uc($_)} || $self->{provider}{$_} foreach qw(login password apn);
}

sub get_access_settings {
   my ($self) = @_;
   [
       { label => N("Access Point Name"), val => \$self->{access}{apn} },
       @{$self->SUPER::get_access_settings},
   ];
}

sub set_ppp_settings {
    my ($self) = @_;
    $self->{access}{use_chat} = 1;
    $self->{access}{dial_number} = !$self->{access}{no_dial} && "*99***$self->{access}{cid}#";
}

sub write_settings {
    my ($self) = @_;
    $self->write_cellular_settings;
    $self->set_ppp_settings;
    $self->SUPER::write_settings;
}

sub apply_network_selection {
    my ($self) = @_;
    $self->set_ppp_settings;
    $self->write_ppp_settings;
}

1;
