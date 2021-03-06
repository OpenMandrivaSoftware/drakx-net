package network::tools; # $Id: tools.pm 253976 2009-03-13 10:57:55Z eugeni $

use strict;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;
use run_program;
use c;
use Socket;

sub write_secret_backend {
    my ($login, $password) = @_;
    require network::connection::ppp;
    network::connection::ppp::write_secrets({ access => { login => $login, password => $password } });
}

sub passwd_by_login {
    my ($login) = @_;
    require network::connection::ppp;
    network::connection::ppp::get_secret(undef, $login);
}

sub run_interface_command {
    my ($action, $intf, $detach) = @_;
    my $have_perms = !$>;
    if (!$have_perms) {
        my $xxnet = {};
        network::network::read_net_conf($xxnet);
        $have_perms = text2bool($xxnet->{ifcfg}{$intf}{USERCTL});
    }
    my @command =
      $have_perms ?
	('/usr/sbin/if' . $action, $intf, if_(!$::isInstall, "daemon")) :
	('/usr/bin/pkexec', '/usr/sbin/if' . $action, $intf);
    run_program::raw({ detach => $detach, root => $::prefix }, @command);
}

sub start_interface {
    my ($intf, $detach) = @_;
    run_interface_command('up', $intf, $detach);
}

sub stop_interface {
    my ($intf, $detach) = @_;
    run_interface_command('down', $intf, $detach);
}

sub start_net_interface {
    my ($net, $detach) = @_;
    start_interface($net->{net_interface}, $detach);
}

sub stop_net_interface {
    my ($net, $detach) = @_;
    stop_interface($net->{net_interface}, $detach);
}

sub connected() {
    # if no resolv.conf from stage1, use the one we wrote in chroot:
    if ($::isInstall && ! -e "/etc/resolv.conf") {
        symlink "$::prefix/etc/resolv.conf", "/etc/resolv.conf";
    }
    c::res_init(); # reinit the resolver so DNS changes take affect
    gethostbyname("www.openmandriva.org") ? 1 : 0;
}

# request a ref on a bg_connect and a ref on a scalar
sub connected_bg__raw {
    my ($kid_pipe, $status) = @_;
    local $| = 1;
    if (ref($kid_pipe) && ref($$kid_pipe)) {
	my $fd = $$kid_pipe->{fd};
	common::nonblock($fd);
	my $a  = <$fd>;
     $$status = $a if defined $a;
    } else { $$kid_pipe = check_link_beat() }
}

my $kid_pipe;
sub connected_bg {
    my ($status) = @_;
    connected_bg__raw(\$kid_pipe, $status);
}

# test if connected;
# cmd = 0 : ask current status
#     return : 0 : not connected; 1 : connected; -1 : no test ever done; -2 : test in progress
# cmd = 1 : start new connection test
#     return : -2
# cmd = 2 : cancel current test
#    return : nothing
# cmd = 3 : return current status even if a test is in progress
my $kid_pipe_connect;
my $current_connection_status;

sub test_connected {
    local $| = 1;
    my ($cmd) = @_;
    
    $current_connection_status = -1 if !defined $current_connection_status;
    
    if ($cmd == 0) {
        connected_bg__raw(\$kid_pipe_connect, \$current_connection_status);
    } elsif ($cmd == 1) {
        if ($current_connection_status != -2) {
             $current_connection_status = -2;
             $kid_pipe_connect = check_link_beat();
        }
    } elsif ($cmd == 2) {
        if (defined($kid_pipe_connect)) {
	    kill -9, $kid_pipe_connect->{pid};
	    undef $kid_pipe_connect;
        }
    }
    return $current_connection_status;
}

sub check_link_beat() {
    bg_command->new(sub {
                        require Net::Ping;
                        my $p;
                        if ($>) {
                            $p = Net::Ping->new("tcp");
                            # Try connecting to the www port instead of the echo port
                            $p->{port_num} = getservbyname("http", "tcp");
                        } else {
                            $p = Net::Ping->new("icmp");
                        }
                        print $p->ping("www.openmandriva.org") ? 1 : 0;
                    });
}

sub is_dynamic_ip {
  my ($net) = @_;
  any { $_->{BOOTPROTO} !~ /^(none|static|)$/ } values %{$net->{ifcfg}};
}

sub is_dynamic_host {
  my ($net) = @_;
  any { defined $_->{DHCP_HOSTNAME} } values %{$net->{ifcfg}};
}

#- returns interface whose IP address matchs given IP address, according to its network mask
sub find_matching_interface {
    my ($net, $address) = @_;
    my @ip = split '\.', $address;
    find {
        my @intf_ip = split '\.', $net->{ifcfg}{$_}{IPADDR} or return;
        my @mask = split '\.', $net->{ifcfg}{$_}{NETMASK} or return;
        every { $_ } mapn { ($_[0] & $_[2]) == ($_[1] & $_[2]) } \@intf_ip, \@ip, \@mask;
    } sort keys %{$net->{ifcfg}};
}

#- returns the current gateway, with lowest metric
sub get_current_gateway_interface() {
    my $routes = get_routes();
    first(sort { $routes->{$a}{metric} <=> $routes->{$b}{metric} } grep {
        $routes->{$_}{network} eq '0.0.0.0' && $routes->{$_}{gateway};
    } keys %$routes);
}

#- returns gateway interface if found
sub get_default_gateway_interface {
    my ($net) = @_;
    my @intfs = sort keys %{$net->{ifcfg}};
    get_current_gateway_interface() ||
    $net->{network}{GATEWAYDEV} ||
    $net->{network}{GATEWAY} && find_matching_interface($net, $net->{network}{GATEWAY}) ||
    (find { get_interface_type($net->{ifcfg}{$_}) eq 'adsl' } @intfs) ||
    (find { get_interface_type($net->{ifcfg}{$_}) eq 'isdn' && text2bool($net->{ifcfg}{$_}{DIAL_ON_IFUP}) } @intfs) ||
    (find { get_interface_type($net->{ifcfg}{$_}) eq 'modem' } @intfs) ||
    (find { get_interface_type($net->{ifcfg}{$_}) eq 'wifi' && $net->{ifcfg}{$_}{BOOTPROTO} eq 'dhcp' } @intfs) ||
    (find { get_interface_type($net->{ifcfg}{$_}) eq 'ethernet' && $net->{ifcfg}{$_}{BOOTPROTO} eq 'dhcp' } @intfs);
}

#- remove suffix from virtual interfaces
sub get_real_interface {
    my ($intf) = @_;
    $intf =~ s/:\d+$//;
    $intf;
}

sub is_virtual_interface {
    my ($intf) = @_;
    $intf =~ /:\d+$/;
}

sub is_vlan_interface {
    my ($intf) = @_;
    $intf =~ /\.\d+$/;
}

sub is_real_interface {
    my ($intf) = @_;
    !is_virtual_interface($intf) && !is_vlan_interface($intf);
}

sub is_zeroconf_interface {
    my ($intf) = @_;
    is_virtual_interface($intf) && get_interface_ip_address({}, $intf) =~ /^(127|169\.254)\./;
}

sub get_interface_status {
    my ($intf) = @_;
    $intf = get_real_interface($intf);
    my $routes = get_routes();
    return $routes->{$intf}{network}, $routes->{$intf}{network} eq '0.0.0.0' && $routes->{$intf}{gateway};
}

#- returns (gateway_interface, interface is up, gateway address, dns server address)
sub get_default_connection {
    my ($net, $o_gw_intf) = @_;
    my $gw_intf = $o_gw_intf || get_default_gateway_interface($net) or return;
    $net->{resolv} = {};
    require network::network;
    add2hash($net->{resolv}, network::network::read_resolv_conf());
    return $gw_intf, get_interface_status($gw_intf), $net->{resolv}{dnsServer};
}

#- returns the gateway address
#  advantage over get_default_connection() is that we don't fork,
#  which prevent segfaulting when glib/gtk create threads behind us (mga#12041)
sub get_gw_address() {
    my $gateway;
    foreach (cat_('/proc/net/route')) {
	$gateway = $1 if /^\S+\s+00000000\s+([0-9A-F]+)/;
    }
    # Linux gives it as a hex number in network byte order:
    $gateway ? join(".", unpack "CCCC", pack "L", hex $gateway) : undef;
}

sub has_network_connection() {
    my $gw_address = get_gw_address();
    to_bool($gw_address);
}

sub get_interface_type {
    my ($interface, $o_module) = @_;
    require detect_devices;
    member($interface->{TYPE}, "xDSL", "ADSL") && "adsl" ||
    $interface->{DEVICE} =~ /^ippp/ && "isdn" ||
    $interface->{DEVICE} =~ /^ppp/ && "modem" ||
    (detect_devices::is_wireless_interface($interface->{DEVICE}) || exists $interface->{WIRELESS_MODE}) && "wifi" ||
    detect_devices::is_lan_interface($interface->{DEVICE}) &&
        ($o_module && member($o_module, list_modules::category2modules('network/gigabit')) ? "ethernet_gigabit" : "ethernet") ||
    "unknown";
}

sub get_interface_description {
    my ($net, $interface_name) = @_;
    my $type = get_interface_type($net->{ifcfg}{$interface_name});
    #- FIXME: find interface description (from PCI/USB data) and translate
    $type eq 'adsl' ? "DSL: $interface_name" :
    $type eq 'isdn' ? "ISDN: $interface_name" :
    $type eq 'modem' ? "Modem: $interface_name" :
    $type eq 'wifi' ? "WiFi: $interface_name" :
    member($type, qw(ethernet_gigabit ethernet)) ? "Ethernet: $interface_name" :
    $interface_name;
}

sub get_default_metric {
    my ($type) = @_;
    my @known_types = ("ethernet_gigabit", "ethernet", "adsl", "wifi", "isdn", "modem", "unknown");
    my $idx;
    eval { $idx = find_index { $type eq $_ } @known_types };
    $idx = @known_types if $@;
    $idx * 10;
}

sub get_interface_ip_address {
    my ($net, $interface) = @_;
    `/sbin/ip addr show dev $interface` =~ /^\s*inet\s+([\d.]+).*\s+$interface$/m && $1 ||
    $net->{ifcfg}{$interface}{IPADDR};
}

sub get_interface_ptp_address {
    my ($interface) = @_;
    my ($flags, $_link, $addrs) = `/sbin/ip addr show dev $interface`;
    $flags =~ /\bPOINTOPOINT\b/ or return;
    my ($peer) = $addrs =~ /peer\s+([\d.]+)/;
    return $peer if $peer;
    my ($addr) = $addrs =~ /inet\s+([\d.]+)/;
    return $addr if $addr;
}

sub host_hex_to_dotted {
    my ($address) = @_;
    inet_ntoa(pack('N', unpack('L', pack('H8', $address))));
}

sub get_routes() {
    my %routes;
    my @routes = cat_("/proc/net/route");
    @routes = reverse(@routes) if common::cmp_kernel_versions(c::kernel_version(), "2.6.39") >= 0;
    foreach (@routes) {
	if (/^(\S+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+[0-9A-F]+\s+\d+\s+\d+\s+(\d+)\s+([0-9A-F]+)/) {
	    if (defined $3) { $routes{$1}{gateway} = hex($3) ? host_hex_to_dotted($3) : $routes{$1}{network} }
	    if (defined $2) { $routes{$1}{network} = host_hex_to_dotted($2) }
	    if (defined $4) { $routes{$1}{metric} = $4 }
	}
    }
    $routes{$_}{gateway} ||= get_interface_ptp_address($_) foreach keys %routes;
    #- TODO: handle IPv6 with /proc/net/ipv6_route
    \%routes;
}

1;
