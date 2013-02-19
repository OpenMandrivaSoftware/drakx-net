package network::connection;

use common;
use network::vpn;

sub get_types {
    sort { $a->get_metric <=> $b->get_metric } grep { $_->can('get_devices') } common::load_modules_from_base(__PACKAGE__);
}

=item get_type_name()

Get the connection type name, unstranslated

=cut

sub get_type_name() { N("Unknown connection type") }
sub get_type_description {
    my ($class) = @_;
    $class->get_type_name;
}

=item get_type_icon()

Get the connection type icon path

=cut

sub get_type_icon {
    my ($self, $o_size) = @_;
    my $size = $o_size || 24;
    my $icon = eval { $self->_get_type_icon . '-' . $size };
    $icon || '/usr/share/mcc/themes/default/drakconnect-mdk';
}

=item get_devices(%options)

Get the devices supported by this connection type
Options:
- automatic_only (no device requiring manual configuration should be returned)
- fast_only (no slow detection should be performed)

=cut

=item get_connections(%options)

List connections that can be configured by the class
Options: see get_devices()

=cut

sub get_connections {
    my ($class, %options) = @_;
    map { $class->new($_) } $class->get_devices(%options);
}

=item find_ifcfg_type($ifcfg)

Returns the class matching the connection type of the ifcfg hash

=cut

sub find_ifcfg_type {
    my ($_class, $ifcfg) = @_;
    find { $_->can('handles_ifcfg') && $_->handles_ifcfg($ifcfg) } sort { $b->get_metric <=> $a->get_metric } get_types();
}

sub new {
    my ($class, $device) = @_;
    bless {
        device => $device,
        networks => {},
    }, $class;
}

sub get_description {
    my ($self) = @_;
    my $description = $self->{device}{description};
    $description =~ s/\|/ /g;
    $description;
}

sub get_label {
    my ($self) = @_;
    my $intf = $self->get_interface;
    my $descr = $self->get_description;
    $intf ? sprintf("%s (%s)", $descr, $intf) : $descr;
}

sub get_driver {
    my ($self) = @_;
    $self->{device}{driver};
}

sub get_interface {
    my ($_self) = @_;
    die "unable to get interface";
}

sub get_metric { 60 }

sub get_up_timeout { 10 }

sub get_status {
    my ($self) = @_;
    require network::tools;
    my ($_is_up, $gw_address) = network::tools::get_interface_status($self->get_interface);
    $self->{status} = to_bool($gw_address);
}

=item get_status_icon()

Get status icon path (connected/disconnected/unconfigured)
The file may not exist

=cut

sub get_status_icon {
    my ($self) = @_;
    my $icon = $self->get_type_icon;
    my $status = $self->get_interface ? $self->get_status ? "on" : "off" : "w";
    $icon . "-" . $status;
}

sub get_ifcfg_bool {
    my ($self, $field) = @_;
    defined $self->{ifcfg}{$field} ? text2bool($self->{ifcfg}{$field}) : undef;
}

sub get_selected_network {
    my ($self) = @_;
    exists $self->{networks}{$self->{network}} && $self->{networks}{$self->{network}};
}

sub selected_network_is_configured {
    my ($self) = @_;

    my $network = $self->get_selected_network or return;
    $self->network_is_configured($network);
}

sub load_interface_settings {
    my ($self) = @_;
    require network::network;
    my $file = network::network::get_ifcfg_file($self->get_interface);
    $self->{ifcfg} = { getVarsFromSh($file) };
    $self->{vpn_list} = [ map { $_->get_configured_connections } network::vpn->list_types ];
    $self->{control}{onboot} = $self->get_ifcfg_bool('ONBOOT');
    $self->{control}{userctl} = $self->get_ifcfg_bool('USERCTL');
    $self->{control}{metric} = $self->{ifcfg}{METRIC};
    $self->{control}{mtu} = $self->{ifcfg}{MTU};
    $self->{control}{macaddr} = $self->{ifcfg}{MACADDR};
    $self->{control}{hwaddr} = $self->{ifcfg}{HWADDR};
    $self->{control}{ethtool_opts} = $self->{ifcfg}{ETHTOOL_OPTS};
    $self->{control}{accounting} = $self->get_ifcfg_bool('ACCOUNTING');
    $self->{control}{nm_controlled} = $self->get_ifcfg_bool('NM_CONTROLLED');
    $self->{control}{uuid} = $self->{ifcfg}{UUID};
    $self->{control}{name} = $self->{ifcfg}{NAME};
    $self->{control}{last_connect} = $self->{ifcfg}{LAST_CONNECT};
}

#- override to return 1 if the connection network scan is slow
sub network_scan_is_slow { 0 }
#- override to return 1 if the hardware check is slow
sub check_hardware_is_slow { 0 }
#- override to return 1 if only one network is supported
sub has_unique_network { 0 }

sub get_network_access_settings_label { N("Network access settings") }
sub get_access_settings_label { N("Access settings") }
sub get_address_settings_label { N("Address settings") }

#- check that $self->can('get_providers') first
sub guess_provider_settings {
    my ($self) = @_;
    require lang;
    my @providers_data = $self->get_providers;
    my $locale_country = lang::c2name(ref($::o) && $::o->{locale}{country} || lang::read()->{country});
    my $separator = $providers_data[1];
    $self->{provider_name} ||= find { /^\Q$locale_country$separator\E/ } sort(keys %{$providers_data[0]});
}

sub set_provider {
    my ($self, $net) = @_;
    if ($self->{provider_name} ne N("Unlisted - edit manually")) {
        my @providers_data = $self->get_providers;
        $self->{provider} = $providers_data[0]{$self->{provider_name}};
        $self->apply_provider_settings($net);
    }
}

sub apply_provider_settings {
    my ($self, $net) = @_;
    $self->guess_protocol($net) if $self->can('guess_protocol');
    $self->guess_access_settings('provider_only') if $self->can('guess_access_settings');
}

#- check that $self->can('get_providers') first
sub get_provider_settings {
    my ($self, $net) = @_;
    my @providers_data = $self->get_providers;
    [
        {
            type => "list", val => \$self->{provider_name}, separator => $providers_data[1],
            list => [ N("Unlisted - edit manually"), sort(keys %{$providers_data[0]}) ], sort => 0,
            changed => sub { $self->set_provider($net) },
        },
    ];
}

#- check that $self->can('get_protocols') first
sub get_protocol_settings {
    my ($self) = @_;
    my $protocols = $self->get_protocols;
    [
        {
            val => \$self->{protocol}, type => 'list',
            list => [ sort { $protocols->{$a} cmp $protocols->{$b} } keys %$protocols ],
            format => sub { $protocols->{$_[0]} },
        }
    ];
}

sub guess_network_control_settings {
    my ($self) = @_;
    $self->{control}{vpn} = find {
        $self->{ifcfg}{VPN_TYPE} eq $_->get_type &&
        $self->{ifcfg}{VPN_NAME} eq $_->get_name;
    } @{$self->{vpn_list}};
}

sub get_network_control_settings {
    my ($self) = @_;
    [
        if_(@{$self->{vpn_list}},
            { label => N("VPN connection"), val => \$self->{control}{vpn},
              list => [ undef, @{$self->{vpn_list}} ],
              format => sub { defined $_[0] ? $_[0]->get_label : N("None") } }),
    ];
}

sub guess_control_settings {
    my ($self) = @_;
    $self->{control}{metric} ||= $self->get_metric;
}

sub get_control_settings {
    my ($self) = @_;
    [
        { text => N("Allow users to manage the connection"), val => \$self->{control}{userctl}, type => "bool" },
        { text => N("Start the connection at boot"), val => \$self->{control}{onboot}, type => "bool" },
        { text => N("Enable traffic accounting"), val => \$self->{control}{accounting}, type => "bool" },
        { text => N("Allow interface to be controlled by Network Manager"), val => \$self->{control}{nm_controlled}, type => "bool" },
        { label => N("Metric"), val => \$self->{control}{metric}, advanced => 1 },
        { label => N("MTU"), val => \$self->{control}{mtu}, advanced => 1,
          help => N("Maximum size of network message (MTU). If unsure, left blank.") },
        { label => N("MACADDR"), val => \$self->{control}{macaddr}, advanced => 1,
          help => N("Use a fake MAC address. If unset, uses HWADDR or default.") },
        { label => N("HWADDR"), val => \$self->{control}{hwaddr}, advanced => 1,
          help => N("Set the MAC address. If unset, uses default.") },
        { label => N("ETHTOOL_OPTS"), val => \$self->{control}{ethtool_opts}, advanced => 1,
          help => N("Use ethtool to pass options to the NIC. eg. \"autoneg off wol g\"") },
    ];
}

sub build_ifcfg_settings {
    my ($self, $o_options) = @_;
    put_in_hash($o_options, {
        DEVICE => $self->get_interface,
        ONBOOT => bool2yesno($self->{control}{onboot}),
        ACCOUNTING => bool2yesno($self->{control}{accounting}),
        NM_CONTROLLED => bool2yesno($self->{control}{nm_controlled}),
        USERCTL => bool2yesno($self->{control}{userctl}),
        METRIC => $self->{control}{metric},
        MTU => $self->{control}{mtu},
        MACADDR => $self->{control}{macaddr},
        HWADDR => $self->{control}{hwaddr},
        ETHTOOL_OPTS => $self->{control}{ethtool_opts},
        UUID => $self->{control}{uuid},
        NAME => $self->{control}{name},
        LAST_CONNECT => $self->{control}{last_connect},
        VPN_TYPE => defined $self->{control}{vpn} && $self->{control}{vpn}->get_type,
        VPN_NAME => defined $self->{control}{vpn} && $self->{control}{vpn}->get_name,
        #- FIXME: add MS_DNSx variables if DNS servers are specified
    });
}

sub write_settings {
    my ($self, $o_net, $_o_modules_conf) = @_;
    require network::network;
    my $file = network::network::get_ifcfg_file($self->get_interface);
    network::network::write_interface_settings($self->build_ifcfg_settings, $file);
    if ($self->{address}{hostname}) {
            $o_net->{network}{HOSTNAME} = $self->{address}{hostname} if $o_net;
            network::network::write_hostname($self->{address}{hostname});
    }
    network::network::write_network_conf($o_net) if $o_net;
    require network::shorewall;
    network::shorewall::update_interfaces_list($self->get_interface);
    network::network::reload_net_applet();
}

sub probed_networks {
    my ($self) = @_;
    $self->{probed_networks} = 1;
}

sub connect {
    my ($self) = @_;
    require network::tools;
    network::tools::start_interface($self->get_interface, 0);
}

sub disconnect {
    my ($self) = @_;
    require network::tools;
    network::tools::stop_interface($self->get_interface, 0);
}

sub setup_thirdparty {
    my ($self, $in) = @_;
    my $driver = $self->get_driver;
    # FIXME: weird return code
    $driver && $self->can('get_thirdparty_settings') or return 1;
    require network::thirdparty;
    $self->{thirdparty} = network::thirdparty::apply_settings($in, ref $self, $self->get_thirdparty_settings, $driver);
    $self->{device} = $self->{thirdparty}{device} if $self->{thirdparty} && $self->{thirdparty}{device};
    $self->{thirdparty};
}

sub prepare_device {
    my ($self) = @_;
    my $driver = $self->get_driver;
    if ($driver) {
        require modules;
        eval { modules::load($driver) };
    }
}

#- status messages can be sent using mdv-network-event
sub get_status_message {
    my ($self, $status) = @_;
    my $interface = $self->get_interface;
    {
        link_up => N("Link detected on interface %s", $interface),
        link_down => N("Link beat lost on interface %s", $interface),
    }->{$status};
}

=head2 Pure virtual private instance methods

=over

=item _get_type_icon

Get the icon prefix for the connection type

=back

=cut

1;
