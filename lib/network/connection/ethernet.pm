package network::connection::ethernet; # $Id: ethernet.pm 147431 2007-03-21 17:06:09Z blino $

use base qw(network::connection);

use strict;
use common;
use network::tools;

our @dhcp_clients = qw(dhclient dhcpcd pump dhcpxd);

sub get_type_name() { N("Ethernet") }
sub get_type_description() { N("Wired (Ethernet)") }
sub _get_type_icon() { 'ethernet' }

sub get_devices() {
    #require list_modules;
    #- FIXME: try to use list_modules::ethernet_categories() (but remove wireless stuff)
    require detect_devices;
    my @devices = detect_devices::probe_category('network/main|gigabit|pcmcia|tokenring|usb|firewire');
    my @lan = grep { detect_devices::is_lan_interface($_) && !detect_devices::is_wireless_interface($_) } detect_devices::get_all_net_devices();
    @devices, get_unlisted_devices(\@lan, \@devices);
}

sub get_unlisted_devices {
    my ($interfaces, $listed_devices) = @_;
    my @unlisted_interfaces = sort(difference2($interfaces, [ map { device_to_interface($_) } @$listed_devices ]));
    map {
        my %device = %{interface_to_device($_) || +{ description => $_ }};
        $device{interface} = $_;
        $device{description} = N("Virtual interface") if network::tools::is_virtual_interface($_);
        \%device;
    } @unlisted_interfaces;
}

sub handles_ifcfg {
    my ($_class, $ifcfg) = @_;
    require detect_devices;
    detect_devices::is_lan_interface($ifcfg->{DEVICE});
}

sub is_gigabit {
    my ($self) = @_;
    require list_modules;
    member($self->get_driver, list_modules::category2modules('network/gigabit'));
}

sub get_metric {
    my ($self) = @_;
    $self->is_gigabit ? 5 : 10;
}

sub get_interface {
    my ($self) = @_;
    $self->{device}{interface} ||= device_to_interface($self->{device});
}

sub check_device {
    my ($self) = @_;
    if (!$self->get_interface) {
        $self->{device}{error} = N("Unable to find network interface for selected device (using %s driver).", $self->get_driver);
        return 0;
    }
    return 1;
}

sub get_protocols() {
    my $system_file = '/etc/sysconfig/drakx-net';
    my %global_settings = getVarsFromSh($system_file);
    +{
        if_(!text2bool($global_settings{AUTOMATIC_ADDRESS}), static => N("Manual configuration")),
        dhcp   => N("Automatic IP (BOOTP/DHCP)"),
    };
}

sub load_interface_settings {
    my ($self) = @_;

    $self->network::connection::load_interface_settings;
    $self->map_ifcfg2config_settings;
}

sub map_ifcfg2config_settings {
    my ($self) = @_;
    $self->{protocol} = $self->{ifcfg}{BOOTPROTO};

    $self->{address}{needhostname} = $self->get_ifcfg_bool('NEEDHOSTNAME');
    $self->{address}{peerdns} = $self->get_ifcfg_bool('PEERDNS');
    $self->{address}{peeryp} = $self->get_ifcfg_bool('PEERYP');
    $self->{address}{peerntpd} = $self->get_ifcfg_bool('PEERNTPD');

    $self->{address}{dhcp_client} = $self->{ifcfg}{DHCP_CLIENT};
    $self->{address}{dhcp_hostname} = $self->{ifcfg}{DHCP_HOSTNAME};
    $self->{address}{dhcp_timeout} = $self->{ifcfg}{DHCP_TIMEOUT};
    $self->{address}{ip_address} = $self->{ifcfg}{IPADDR};
    $self->{address}{netmask} = $self->{ifcfg}{NETMASK};
    $self->{address}{gateway} = $self->{ifcfg}{GATEWAY};
    $self->{address}{dns1} = $self->{ifcfg}{DNS1} || $self->{ifcfg}{MS_DNS1};
    $self->{address}{dns2} = $self->{ifcfg}{DNS2} || $self->{ifcfg}{MS_DNS2};
    $self->{address}{domain} = $self->{ifcfg}{DOMAIN};

    my $blacklist_ifplugd = $self->get_ifcfg_bool('MII_NOT_SUPPORTED');
    $self->{control}{use_ifplugd} = !$blacklist_ifplugd if defined $blacklist_ifplugd;
    $self->{control}{ipv6_tunnel} = $self->get_ifcfg_bool('IPV6TO4INIT');
}

sub guess_protocol {
    my ($self) = @_;
    $self->{protocol} ||= 'dhcp';
}

sub guess_address_settings {
    my ($self) = @_;
    $self->{address}{dhcp_client} ||= find { -x "$::prefix/sbin/$_" } @dhcp_clients;
    $self->{address}{peerdns} = 1 if !defined $self->{address}{peerdns};
    $self->{address}{peeryp} = 1 if !defined $self->{address}{peeryp};
    $self->supplement_address_settings;
}

sub supplement_address_settings {
    my ($self) = @_;
    if ($self->{protocol} eq 'static' && network::network::is_ip($self->{address}{ip_address})) {
        require network::network;
        $self->{address}{netmask} ||= network::network::netmask($self->{address}{ip_address});
        $self->{address}{gateway} ||= network::network::gateway($self->{address}{ip_address});
        $self->{address}{dns1} ||= network::network::dns($self->{address}{ip_address});
    }
}

sub get_address_settings_label { N("IP settings") }

sub get_address_settings {
    my ($self, $o_show_all) = @_;
    my $auto_dns = sub { $self->{protocol} eq 'dhcp' && $self->{address}{peerdns} };
    my $not_static = sub { $self->{protocol} ne 'static' };
    my $not_dhcp = sub { $self->{protocol} ne 'dhcp' };
    [
        if_($self->{protocol} eq 'static' || $o_show_all,
            { label => N("IP address"), val => \$self->{address}{ip_address}, disabled => $not_static,
	      focus_out => sub {
		  $self->supplement_address_settings if $self->can('supplement_address_settings');
	      },
	      help => N("Please enter the IP configuration for this machine.
Each item should be entered as an IP address in dotted-decimal
notation (for example, 1.2.3.4).") },
            { label => N("Netmask"), val => \$self->{address}{netmask}, disabled => $not_static },
            { label => N("Gateway"), val => \$self->{address}{gateway}, disabled => $not_static },
        ),
        if_($self->{protocol} eq 'dhcp' || $o_show_all,
            { text => N("Get DNS servers from DHCP"), val => \$self->{address}{peerdns}, type => "bool", disabled => $not_dhcp },
        ),
        { label => N("DNS server 1"),  val => \$self->{address}{dns1}, disabled => $auto_dns },
        { label => N("DNS server 2"),  val => \$self->{address}{dns2}, disabled => $auto_dns },
        { label => N("Search domain"), val => \$self->{address}{domain}, disabled => $auto_dns, advanced => 1,
          help => N("By default search domain will be set from the fully-qualified host name") },
        if_($self->{protocol} eq 'dhcp',
            { label => N("DHCP client"), val => \$self->{address}{dhcp_client}, list => \@dhcp_clients, advanced => 1 },
            { label => N("DHCP timeout (in seconds)"), val => \$self->{address}{dhcp_timeout}, advanced => 1 },
            { text => N("Get YP servers from DHCP"), val => \$self->{address}{peeryp}, type => "bool", advanced => 1 },
            { text => N("Get NTPD servers from DHCP"), val => \$self->{address}{peerntpd}, type => "bool", advanced => 1 },
            { label => N("DHCP host name"), val => \$self->{address}{dhcp_hostname}, advanced => 1 },
            #- FIXME: install zcip if not checked
            if_(0, { text => N("Do not fallback to Zeroconf (169.254.0.0 network)"), type => "bool", val => \$self->{address}{skip_zeroconf}, advanced => 1 }),
        ),
    ];
}

sub check_address_settings {
    my ($self, $net) = @_;

    if ($self->{protocol} eq 'static') {
        require network::network;
        if (!network::network::is_ip($self->{address}{ip_address})) {
            $self->{address}{error}{message} = N("IP address should be in format 1.2.3.4");
            $self->{address}{error}{field} = \$self->{address}{ip_address};
            return 0;
        }
        if (!network::network::is_ip($self->{address}{netmask})) {
            $self->{address}{error}{message} = N("Netmask should be in format 255.255.224.0");
            $self->{address}{error}{field} = \$self->{address}{netmask};
            return 0;
        }
        if (network::network::is_ip_forbidden($self->{address}{ip_address})) {
            $self->{address}{error}{message} = N("Warning: IP address %s is usually reserved!", $self->{address}{ip_address});
            $self->{address}{error}{field} = \$self->{address}{ip_address};
            return 0;
        }
        #- test if IP address is already used
        if (find { text2bool($_->{ONBOOT}) && $_->{DEVICE} ne $self->get_interface && $_->{IPADDR} eq $self->{address}{ip_address} } values %{$net->{ifcfg}}) {
            $self->{address}{error}{message} = N("%s is already used by connection that starts on boot. To use this address with this connection, first disable all other devices which use it, or configure them not to start on boot", $self->{address}{ip_address});
            $self->{address}{error}{field} = \$self->{address}{ip_address};
            return 0;
        }
    }

    return 1;
}

sub guess_hostname_settings {
    my ($self) = @_;
    $self->{address}{needhostname} = 0 if !defined $self->{address}{needhostname};
    if (!defined $self->{address}{hostname}) {
        require network::network;
        my $network = network::network::read_conf($::prefix . $network::network::network_file);
        $self->{address}{hostname} = $network->{HOSTNAME};
    }
}

# FIXME: add in drakroam/netcenter
sub get_hostname_settings {
    my ($self) = @_;
    my $auto_hostname = sub { $self->{protocol} eq 'dhcp' && $self->{address}{needhostname} };
    [
        if_($self->{protocol} eq 'dhcp',
            { text => N("Assign host name from DHCP server (or generate a unique one)"), val => \$self->{address}{needhostname}, type => "bool" },
        ),
        { label => N("Host name"), val => \$self->{address}{hostname}, disabled => $auto_hostname },
    ];
}

sub guess_control_settings {
    my ($self) = @_;

    $self->network::connection::guess_control_settings($self);

    $self->{control}{onboot} = 1 if !defined $self->{control}{onboot};
    $self->{control}{use_ifplugd} = !is_ifplugd_blacklisted($self->get_driver)
      if !defined $self->{control}{use_ifplugd};
}

sub get_control_settings {
    my ($self) = @_;
    [
        @{$self->network::connection::get_control_settings},
        { text => N("Network Hotplugging"), val => \$self->{control}{use_ifplugd}, type => "bool",
          #- FIXME: force ifplugd if wireless roaming is enabled
          disabled => sub { $self->{control}{force_ifplugd} }, advanced => 1, },
        #- FIXME: $need_network_restart = $ipv6_tunnel ^ text2bool($ethntf->{IPV6TO4INIT});
        { text => N("Enable IPv6 to IPv4 tunnel"), val => \$self->{control}{ipv6_tunnel}, type => "bool", advanced => 1 },
    ];
}

sub install_packages {
    my ($self, $in) = @_;
    if ($self->{protocol} eq 'dhcp') {
        install_dhcp_client($in, $self->{address}{dhcp_client}) or return;
    }
    1;
}

sub build_ifcfg_settings {
    my ($self, $o_options) = @_;
    my $settings = put_in_hash($o_options, {
        BOOTPROTO => $self->{protocol},
        IPADDR => $self->{address}{ip_address},
        GATEWAY => $self->{address}{gateway},
        NETMASK => $self->{address}{netmask},
        NEEDHOSTNAME => bool2yesno($self->{address}{needhostname}),
        PEERYP => bool2yesno($self->{address}{peeryp}),
        PEERDNS => bool2yesno($self->{address}{peerdns}),
        RESOLV_MODS => bool2yesno(!$self->{address}{peerdns} && ($self->{address}{dns1} || $self->{address}{dns2})),
        PEERNTPD => bool2yesno($self->{address}{peerntpd}),
        DHCP_CLIENT => $self->{address}{dhcp_client},
        DHCP_HOSTNAME => $self->{address}{dhcp_hostname},
        DHCP_TIMEOUT => $self->{address}{dhcp_timeout},
        MII_NOT_SUPPORTED => bool2yesno(!$self->{control}{use_ifplugd}),
        IPV6INIT => bool2yesno($self->{control}{ipv6_tunnel}),
        IPV6TO4INIT => bool2yesno($self->{control}{ipv6_tunnel}),
        DNS1 => $self->{address}{dns1},
        DNS2 => $self->{address}{dns2},
        DOMAIN => $self->{address}{domain},
        LINK_DETECTION_DELAY => $self->get_link_detection_delay,
    });
    $self->network::connection::build_ifcfg_settings($settings);
}

sub write_settings {
    my ($self, $o_net, $o_modules_conf) = @_;
    if ($o_modules_conf) {
        $o_modules_conf->set_alias($self->get_interface, $self->get_driver);
        if ($self->{device}{sysfs_device}) {
            my $modalias = chomp_(cat_($self->{device}{sysfs_device} . "/modalias"));
            $o_modules_conf->set_alias($modalias, $self->get_driver) if $modalias;
        }
    }
    $self->SUPER::write_settings($o_net, $o_modules_conf);
    # update udev configuration
    update_udev_net_config();
}

sub get_status_message {
    my ($self, $status) = @_;
    my $interface = $self->get_interface;
    {
        link_up => N("Link beat detected on interface %s", $interface),
        link_down => N("Link beat lost on interface %s", $interface),
        map { (
            "$_->[0]_request" => N("Requesting a network address on interface %s (%s protocol)...", $interface, $_->[1]),
            "$_->[0]_success" => N("Got a network address on interface %s (%s protocol)", $interface, $_->[1]),
            "$_->[0]_failure" => N("Failed to get a network address on interface %s (%s protocol)", $interface, $_->[1]),
        ) } ([ 'dhcp', 'DHCP' ], [ 'zcip', 'ZeroConf' ]),
    }->{$status} || $self->network::connection::get_status_message($status);
}

use c;
use detect_devices;
use common;
use run_program;

sub install_dhcp_client {
    my ($in, $client) = @_;
    my %packages = (
        "dhclient" => "dhcp-client",
    );
    #- use default dhcp client if none is provided
    $client ||= $dhcp_clients[0];
    $client = $packages{$client} if exists $packages{$client};
    $in->do_pkgs->ensure_is_installed($client, undef, 1);
}

my @hwaddr_fields = qw(pci_domain pci_bus pci_device pci_function);

sub are_same_HwIDs {
    my ($device1, $device2) = @_;
    every { $device1->{$_} == $device2->{$_} } @hwaddr_fields;
}

sub parse_hwaddr {
    my ($hw_addr) = @_;
    return if !$hw_addr;
    my %device;
    @device{@hwaddr_fields} = map { hex($_) } ($hw_addr =~ /([0-9a-f]+):([0-9a-f]+):([0-9a-f]+)\.([0-9a-f]+)/);
    (every { defined $_ } keys %device) ? \%device : undef;
}

sub mapIntfToDevice {
    my ($interface) = @_;
    my $hw_addr = c::getHwIDs($interface);
    return {} if $hw_addr =~ /^usb/;
    my $device = parse_hwaddr($hw_addr);
    $device ? grep { are_same_HwIDs($_, $device) } detect_devices::probeall() : {};
}

sub device_matches_interface_HwIDs {
    my ($device, $interface) = @_;
    my $hw_addr = c::getHwIDs($interface);
    $hw_addr =~ /^usb/ and return;
    my ($device2) = parse_hwaddr($hw_addr);
    return if !$device2;
    are_same_HwIDs($device, $device2);
}

sub get_interface_sysfs_path {
    my ($interface) = @_;
    $interface = network::tools::get_real_interface($interface);
    my $dev_path = "/sys/class/net/$interface/device";
    my $bus = detect_devices::get_sysfs_field_from_link($dev_path, 'bus');
    if ($bus eq 'ieee1394') {
	my $child = first(glob("$dev_path/host_id/*-*"));
	$dev_path = $child if $child;
    }
    $dev_path;
}

sub get_interface_ids {
    my ($interface) = @_;
    detect_devices::get_ids_from_sysfs_device(get_interface_sysfs_path($interface));
}

sub device_matches_interface {
    my ($device, $interface) = @_;
    detect_devices::device_matches_sysfs_ids($device, get_interface_ids($interface));
}

sub device_to_interface {
    my ($device) = @_;
    my @all_interfaces = detect_devices::get_net_interfaces();
    my ($real, $other) = partition { network::tools::is_real_interface($_) } @all_interfaces;
    find {
        device_matches_interface_HwIDs($device, $_) ||
        device_matches_interface($device, $_);
    } @$real, @$other;
}

sub interface_to_device {
    my ($interface) = @_;
    my $sysfs_ids = get_interface_ids($interface);
    find { detect_devices::device_matches_sysfs_ids($_, $sysfs_ids) } detect_devices::probeall();
}

sub interface_to_driver {
    my ($interface) = @_;
    my $dev_path = get_interface_sysfs_path($interface);
    #- FIXME: use $bus and move in get_interface_sysfs_path if possible
    my $child = -f "$dev_path/idVendor" && first(glob("$dev_path/*-*:*.*"));
    $dev_path = $child if -f "$child/driver/module";
    detect_devices::get_sysfs_field_from_link($dev_path, 'driver/module');
}

# return list of [ intf_name, module, device_description ] tuples such as:
# [ "eth0", "3c59x", "3Com Corporation|3c905C-TX [Fast Etherlink]" ]
#
# this function try several method in order to get interface's driver and description in order to support both:
# - hotplug managed devices (USB, firewire)
# - special interfaces (IP aliasing, VLAN)
sub get_eth_cards {
    my ($o_modules_conf) = @_;

    detect_devices::probeall_update_cache();
    my @all_cards = detect_devices::get_lan_interfaces();

    my @devs = detect_devices::pcmcia_probe();
    my $saved_driver;
    # compute device description and return (interface, driver, description) tuples:
    return map {
        my $interface = $_;
        my $description;
        # 1) get interface's driver through ETHTOOL ioctl:
        my ($a, $detected_through_ethtool);
        $a = c::getNetDriver($interface);
        if ($a) {
            $detected_through_ethtool = 1;
        } elsif ($o_modules_conf) {
            # 2) get interface's driver through module aliases:
            $a = $o_modules_conf->get_alias($interface);
        }

        # workaround buggy drivers that returns a bogus driver name for the GDRVINFO command of the ETHTOOL ioctl:
        my %fixes = (
                     "p80211_prism2_cs"  => 'prism2_cs',
                     "p80211_prism2_pci" => 'prism2_pci',
                     "p80211_prism2_usb" => 'prism2_usb',
                     "ip1394" => "eth1394",
                     "DL2K" => "dl2k",
                     "orinoco" => undef, #- should be orinoco_{cs,nortel,pci,plx,tmd}
                     "hostap" => undef, #- should be hostap_{cs,pci,plx}
                    );
        if (exists $fixes{$a}) {
            $a = $fixes{$a};
            $a or undef $detected_through_ethtool;
        }

        # 3) try to match a PCMCIA device for device description:
        if (my $b = find { $_->{device} eq $interface } @devs) { # PCMCIA case
            $a = $b->{driver};
            $description = $b->{description};
        } else {
            # 4) try to lookup a device by hardware address for device description:
            #    maybe should have we try sysfs first for robustness?
            my @devices = mapIntfToDevice($interface);
            ($description) = $devices[0]{description} if @devices;
        }
        # 5) try to match a device through sysfs for driver & device description:
        #     (eg: ipw2100 driver for intel centrino do not support ETHTOOL)
        if (!$description || !$a) {
            my $drv = interface_to_driver($interface);
            $a = $drv if $drv && !$detected_through_ethtool;
            my $card = interface_to_device($interface);
            $description ||= $card->{description} if $card;
        }
        # 6) try to match a device by driver for device description:
        #    (eg: madwifi, ndiswrapper, ...)
        if (!$description) {
            my @cards = grep { $_->{driver} eq ($a || $saved_driver) } detect_devices::probeall();
            $description = $cards[0]{description} if @cards == 1;
        }
        $a and $saved_driver = $a; # handle multiple cards managed by the same driver
        [ $interface, $saved_driver, if_($description, $description) ];
    } @all_cards;
}

sub get_eth_cards_names {
    my (@all_cards) = @_;
    map { $_->[0] => join(': ', $_->[0], $_->[2]) } @all_cards;
}

#- returns (link_type, mac_address)
sub get_eth_card_mac_address {
    my ($intf) = @_;
    #- don't look for 6 bytes addresses only because of various non-standard MAC addresses
    `$::prefix/sbin/ip -o link show $intf 2>/dev/null` =~ m|.*link/(\S+)\s((?:[0-9a-f]{2}:?)+)\s|;
}

#- write interfaces MAC address in iftab
sub update_iftab() {
    #- skip aliases and vlan interfaces
    foreach my $intf (grep { network::tools::is_real_interface($_) } detect_devices::get_lan_interfaces()) {
        my ($link_type, $mac_address) = get_eth_card_mac_address($intf) or next;
        #- do not write zeroed MAC addresses in iftab, it confuses ifrename
        $mac_address =~ /^[0:]+$/ and next;
        # ifrename supports alsa IEEE1394, EUI64 and IRDA
        member($link_type, 'ether', 'ieee1394', 'irda', '[27]') or next;
        substInFile {
            s/^$intf\s+.*\n//;
            s/^.*\s+$mac_address\n//;
            $_ .= qq($intf mac $mac_address\n) if eof;
        } "$::prefix/etc/iftab";
    }
}

sub update_udev_net_config() {
    my $lib = arch() =~ /x86_64/ ? "lib64" : "lib";
    my $net_name_helper = "/lib/udev/write_net_rules";
    my $udev_net_config = "$::prefix/etc/udev/rules.d/70-persistent-net.rules";
    my @old_config = cat_($udev_net_config);
    #- skip aliases and vlan interfaces
    foreach my $intf (grep { network::tools::is_real_interface($_) } detect_devices::get_lan_interfaces()) {
        (undef, my $mac_address) = get_eth_card_mac_address($intf) or next;
        #- do not write zeroed MAC addresses
        $mac_address =~ /^[0:]+$/ and next;
        #- skip already configured addresses
        any { !/^\s*#/ && /"$mac_address"/ } @old_config and next;
        my $type = cat_("/sys/class/net/$intf/type") =~ /^\d+$/;
        local $ENV{MATCHIFTYPE} = $type if $type;
        local $ENV{INTERFACE} = $intf;
        local $ENV{MATCHADDR} = $mac_address;
        local $ENV{COMMENT} = "Drakx-net rule for $intf ($mac_address)";
        run_program::rooted($::prefix, $net_name_helper, '>', '/dev/null', $mac_address);
    }
}

# automatic net aliases configuration
sub configure_eth_aliases {
    my ($modules_conf) = @_;
    foreach my $card (get_eth_cards($modules_conf)) {
        $modules_conf->set_alias($card->[0], $card->[1]);
    }
    $::isStandalone and $modules_conf->write;
    update_iftab();
    update_udev_net_config();
}

sub get_link_detection_delay {
    my ($self) = @_;
    member($self->get_driver, qw(b44 forcedeth r8169 skge sky2 tg3 via_velocity e1000e)) && 6;
}

sub is_ifplugd_blacklisted {
    my ($module) = @_;
    !$module;
}

1;
