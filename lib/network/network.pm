package network::network; # $Id: network.pm 268044 2010-04-30 13:31:34Z blino $wir

#-######################################################################################
#- misc imports
#-######################################################################################

use strict;

use c;
use lang;
use Socket;
use common;
use run_program;
use network::tools;
use vars qw(@ISA @EXPORT);
use log;

our $network_file = "/etc/sysconfig/network";
my $hostname_file = "/etc/hostname";
my $resolv_file = "/etc/resolv.conf";
my $tmdns_file = "/etc/tmdns.conf";
our $wireless_d = "/etc/sysconfig/network-scripts/wireless.d";

# list of CRDA domains
our @crda_domains = qw(AE AL AM AN AR AT AU AZ BA BE BG BH BL BN BO BR BY BZ CA CH CL CN CO CR CS CY CZ DE DK DO DZ EC EE EG ES FI FR GB GE GR GT HK HN HR HU ID IE IL IN IR IS IT JM JO JP KP KR KW KZ LB LI LK LT LU LV MA MC MK MO MT MX MY NL NO NP NZ OM PA PE PG PH PK PL PR PT QA RO RU SA SE SG SI SK SV SY TH TN TR TT TW UA US UY UZ VE VN YE ZA ZW);

@ISA = qw(Exporter);
@EXPORT = qw(addDefaultRoute dns dnsServers gateway guessHostname is_ip is_ip_forbidden masked_ip netmask resolv);

#- $net hash structure
#-   autodetect
#-   type
#-   net_interface
#-   PROFILE: selected netprofile
#-   network (/etc/sysconfig/network) : NETWORKING FORWARD_IPV4 NETWORKING_IPV6 HOSTNAME GATEWAY GATEWAYDEV NISDOMAIN
#-     NETWORKING : networking flag : string : "yes" by default
#-     FORWARD_IPV4 : forward IP flag : string : "false" by default
#-     HOSTNAME : hostname : string : "localhost.localdomain" by default
#-     GATEWAY : gateway
#-     GATEWAYDEV : gateway interface
#-     NISDOMAIN : nis domain
#-     NETWORKING_IPV6 : use IPv6, "yes" or "no"
#-     IPV6_DEFAULTDEV
#-   resolv (/etc/resolv.conf): dnsServer, dnsServer2, dnsServer3, DOMAINNAME, DOMAINNAME2, DOMAINNAME3
#-     dnsServer : dns server 1
#-     dnsServer2 : dns server 2
#-     dnsServer3 : dns server 3 : note that we uses the dns1 for the LAN, and the 2 others for the internet conx
#-     DOMAINNAME : domainname : string : $net->{network}{HOSTNAME} =~ /\.(.*)/ by default
#-     DOMAINNAME2 : well it's another domainname : have to look further why we used 2
#-   adsl: bus, Encapsulation, vpi, vci provider_id, method, login, passwd, ethernet_device, capi_card
#-   cable: bpalogin, login, passwd
#-   zeroconf: hostname
#-   auth: LDAPDOMAIN WINDOMAIN
#-   ifcfg (/etc/sysconfig/network-scripts/ifcfg-*):
#-     key : device name
#-     value : hash containing ifcfg file values, see write_interface_conf() for an exhaustive list
#-       DHCP_HOSTNAME : If you have a dhcp and want to set the hostname
#-       IPADDR : IP address
#-       NETMASK : netmask
#-       DEVICE : device name
#-       BOOTPROTO : boot prototype : "bootp" or "dhcp" or "pump" or ...
#-       IPV6INIT
#-       IPV6TO4INIT
#-       MS_DNS1
#-       MS_DNS2
#-       DOMAIN

sub read_conf {
    my ($file) = @_;
    +{ getVarsFromSh($file) };
}

sub read_resolv_conf_raw {
    my ($o_file) = @_;
    my $s = cat_($o_file || $::prefix . $resolv_file);
    { nameserver => [ $s =~ /^\s*nameserver\s+(\S+)/mg ],
      search => [ if_($s =~ /^\s*search\s+(.*)/m, split(' ', $1)) ] };
}

sub read_resolv_conf {
    my ($o_file) = @_;
    my $resolv_conf = read_resolv_conf_raw($o_file);
    +{
      (mapn { $_[0] => $_[1] } [ qw(dnsServer dnsServer2 dnsServer3) ], $resolv_conf->{nameserver}),
      (mapn { $_[0] => $_[1] } [ qw(DOMAINNAME DOMAINNAME2 DOMAINNAME3) ], $resolv_conf->{search}),
     };
}

sub read_interface_conf {
    my ($file) = @_;
    my %intf = getVarsFromSh($file);

    $intf{BOOTPROTO} ||= 'static';
    $intf{isPtp} = $intf{NETWORK} eq '255.255.255.255';
    $intf{isUp} = 1;
    \%intf;
}

sub read_zeroconf() {
    cat_($::prefix . $tmdns_file) =~ /^\s*hostname\s*=\s*(\w+)/m && { ZEROCONF_HOSTNAME => $1 };
}

sub write_network_conf {
    my ($net) = @_;

    if ($net->{network}{HOSTNAME} && $net->{network}{HOSTNAME} =~ /\.(.+\..+)$/) {
	$net->{resolv}{DOMAINNAME} ||= $1;
    }
    $net->{network}{NETWORKING} = 'yes';

    setVarsInSh($::prefix . $network_file, $net->{network}, qw(HOSTNAME NETWORKING GATEWAY GATEWAYDEV NISDOMAIN FORWARD_IPV4 NETWORKING_IPV6 IPV6_DEFAULTDEV CRDA_DOMAIN));
    output($::prefix . $hostname_file, ($net->{network}{HOSTNAME} || "localhost") . "\n");
}

sub write_zeroconf {
    my ($net, $in) = @_;
    my $zhostname = $net->{zeroconf}{hostname};
    my $file = $::prefix . $tmdns_file;

    if ($zhostname) {
	$in->do_pkgs->ensure_binary_is_installed('tmdns', 'tmdns', 'auto') if !$in->do_pkgs->is_installed('bind');
	$in->do_pkgs->ensure_binary_is_installed('zcip', 'zcip', 'auto');
    }

    #- write blank hostname even if disabled so that drakconnect does not assume zeroconf is enabled
    eval { substInFile { s/^\s*(hostname)\s*=.*/$1 = $zhostname/ } $file } if $zhostname || -f $file;

    require services;
    services::set_status('tmdns', $net->{zeroconf}{hostname}, $::isInstall);
}

sub write_resolv_conf {
    my ($net) = @_;
    my $resolv = $net->{resolv};
    my $file = $::prefix . $resolv_file;

    my %new = (
        search => [ grep { $_ } uniq(@$resolv{'DOMAINNAME', 'DOMAINNAME2', 'DOMAINNAME3'}) ],
        nameserver => [ grep { $_ } uniq(@$resolv{'dnsServer', 'dnsServer2', 'dnsServer3'}) ],
    );

    my (%prev, @unknown);
    foreach (cat_($file)) {
	s/\s+$//;
	s/^[#\s]*//;

	if (my ($key, $val) = /^(search|nameserver)\s+(.*)$/) {
	    push @{$prev{$key}}, $val;
	} elsif (/^ppp temp entry$/) {
	} elsif (/\S/) {
	    push @unknown, $_;
	}
    }
    unlink $file if -l $file;  #- workaround situation when /etc/resolv.conf is an absolute link to /etc/ppp/resolv.conf or whatever

    if (@{$new{search}} || @{$new{nameserver}}) {
	$prev{$_} = [ difference2($prev{$_} || [], $new{$_}) ] foreach keys %new;

	my @search = do {
	    my @new = if_(@{$new{search}}, "search " . join(' ', @{$new{search}}) . "\n");
	    my @old = if_(@{$prev{search}}, "# search " . join(' ', @{$prev{search}}) . "\n");
	    @new, @old;
	};
	my @nameserver = do {
	    my @new = map { "nameserver $_\n" } @{$new{nameserver}};
	    my @old = map { "# nameserver $_\n" } @{$prev{nameserver}};
	    @new, @old;
	};
	output_with_perm($file, 0644, @search, @nameserver, (map { "# $_\n" } @unknown), "\n# ppp temp entry\n");

	c::res_init(); # reinit the resolver so DNS changes take affect
	1;
    } else {
	log::explanations("neither domain name nor dns server are configured");
	0;
    }
}

sub update_broadcast_and_network {
    my ($intf) = @_;
    my @ip = split '\.', $intf->{IPADDR};
    my @mask = split '\.', $intf->{NETMASK};
    #- FIXME: NETWORK and BROADCAST are deprecated, see sysconfig.txt
    $intf->{BROADCAST} = join('.', mapn { int($_[0]) | ((~int($_[1])) & 255) } \@ip, \@mask);
    $intf->{NETWORK} = join('.', mapn { int($_[0]) &        $_[1]          } \@ip, \@mask);
}

sub write_interface_settings {
    my ($intf, $file) = @_;
    setVarsInSh($file, $intf, qw(DEVICE BOOTPROTO IPADDR NETMASK NETWORK BROADCAST GATEWAY ONBOOT HWADDR MACADDR METRIC MII_NOT_SUPPORTED TYPE USERCTL ATM_ADDR ATM_DEVICE ETHTOOL_OPTS VLAN MTU DNS1 DNS2 DOMAIN RESOLV_MODS LINK_DETECTION_DELAY),
                qw(WIRELESS_MODE WIRELESS_ESSID WIRELESS_NWID WIRELESS_FREQ WIRELESS_SENS WIRELESS_RATE WIRELESS_ENC_KEY WIRELESS_ENC_MODE WIRELESS_RTS WIRELESS_FRAG WIRELESS_IWCONFIG WIRELESS_IWSPY WIRELESS_IWPRIV WIRELESS_WPA_DRIVER WIRELESS_WPA_REASSOCIATE CRDA_DOMAIN),
                qw(DVB_ADAPTER_ID DVB_NETWORK_DEMUX DVB_NETWORK_PID),
                qw(IPV6INIT IPV6TO4INIT),
                qw(MRU REMIP PPPOPTIONS HARDFLOWCTL DEFABORT RETRYTIMEOUT PAPNAME LINESPEED MODEMPORT DEBUG ESCAPECHARS INITSTRING),
                qw(DISCONNECTTIMEOUT PERSIST DEFROUTE),
                qw(VPN_NAME VPN_TYPE),
                qw(ACCOUNTING),
                qw(NM_CONTROLLED),
                qw(UUID NAME LAST_CONNECT),
                qw(CELLULAR_CID),
                if_($intf->{BOOTPROTO} eq "dhcp", qw(DHCP_CLIENT DHCP_HOSTNAME NEEDHOSTNAME PEERDNS PEERYP PEERNTPD DHCP_TIMEOUT)),
                if_($intf->{DEVICE} =~ /^ippp\d+$/, qw(DIAL_ON_IFUP))
               );
    substInFile { s/^DEVICE='(`.*`)'/DEVICE=$1/g } $file; #- remove quotes if DEVICE is the result of a command
    chmod $intf->{WIRELESS_ENC_KEY} ? 0700 : 0755, $file; #- hide WEP key for non-root users
    log::explanations("written $intf->{DEVICE} interface configuration in $file");
}

sub get_ifcfg_file {
    my ($name) = @_;
    "$::prefix/etc/sysconfig/network-scripts/ifcfg-$name";
}

sub write_interface_conf {
    my ($net, $name) = @_;

    my $file = get_ifcfg_file($name);
    #- prefer ifcfg-XXX files
    unlink("$::prefix/etc/sysconfig/network-scripts/$name");

    my $intf = $net->{ifcfg}{$name};

    require network::connection::ethernet;
    my (undef, $mac_address) = network::connection::ethernet::get_eth_card_mac_address($intf->{DEVICE});
    $intf->{HWADDR} &&= $mac_address; #- set HWADDR to MAC address if required

    update_broadcast_and_network($intf);

    defined($intf->{METRIC}) or $intf->{METRIC} = network::tools::get_default_metric(network::tools::get_interface_type($intf)),
    $intf->{BOOTPROTO} =~ s/dhcp.*/dhcp/;

    write_interface_settings($intf, $file);
}

sub write_wireless_conf {
    my ($ssid, $ifcfg) = @_;
    my $wireless_file = $::prefix . $wireless_d . '/' . $ssid;
    my %wireless_ifcfg = %$ifcfg;
    # FIXME: be smarter to keep only DHCP/IP settings here
    delete $wireless_ifcfg{$_}
      foreach qw(DEVICE MII_NOT_SUPPORTED ONBOOT);
    write_interface_settings(\%wireless_ifcfg, $wireless_file);
}

sub add2hosts {
    my ($hostname, @ips) = @_;
    my ($sub_hostname) = $hostname =~ /(.*?)\./;

    my $file = "$::prefix/etc/hosts";

    my @l;
    push @l, [ $_, $hostname, if_($sub_hostname, $sub_hostname) ] foreach @ips;
    foreach (cat_($file)) {
        # strip our own comments
        next if /# generated by drak/;
        my ($ip, $aliases) = /^\s*(\S+)\s+(\S+.*)$/ or next;
        my @hosts = difference2([ split /\s+/, $aliases ], [ $hostname, $sub_hostname ]);
        if (@hosts) {
            push @l, [ $ip, @hosts ];
        }
    }

    log::explanations("writing host information to $file");
    output($file, "# generated by drakconnect\n");
    foreach (@l) {
        append_to_file($file, join(" ", @$_) . "\n");
    }
}

# The interface/gateway needs to be configured before this will work!
sub guessHostname {
    my ($net, $intf_name) = @_;

    $net->{ifcfg}{$intf_name}{isUp} && dnsServers($net) or return 0;
    $net->{network}{HOSTNAME} && $net->{resolv}{DOMAINNAME} and return 1;

    write_resolv_conf($net);

    my $name = gethostbyaddr(Socket::inet_aton($net->{ifcfg}{$intf_name}{IPADDR}), Socket::AF_INET()) or log::explanations("reverse name lookup failed"), return 0;

    log::explanations("reverse name lookup worked");

    $net->{network}{HOSTNAME} ||= $name;
    1;
}

sub addDefaultRoute {
    my ($net) = @_;
    c::addDefaultRoute($net->{network}{GATEWAY}) if $net->{network}{GATEWAY};
}

sub write_hostname {
    my ($hostname) = @_;

    addVarsInSh($::prefix . $network_file, { HOSTNAME => $hostname }, qw(HOSTNAME));
    output($::prefix . $hostname_file, $hostname || "localhost");

    add2hosts("localhost", "127.0.0.1");
    add2hosts($hostname, "127.0.0.1") if $hostname;

    unless ($::isInstall) {
        my $rc = syscall_("sethostname", $hostname, length $hostname);
        log::explanations($rc ? "set sethostname to $hostname" : "sethostname failed: $!");
        run_program::run("/usr/bin/run-parts", "--arg", $hostname, "/etc/sysconfig/network-scripts/hostname.d");
    }
}

sub resolv($) {
    my ($name) = @_;
    is_ip($name) and return $name;
    my $a = join(".", unpack "C4", (gethostbyname $name)[4]);
    #-log::explanations("resolved $name in $a");
    $a;
}

sub dnsServers {
    my ($net) = @_;
    #- FIXME: that's weird
    my %used_dns; @used_dns{$net->{network}{dnsServer}, $net->{network}{dnsServer2}, $net->{network}{dnsServer3}} = (1, 2, 3);
    sort { $used_dns{$a} <=> $used_dns{$b} } grep { $_ } keys %used_dns;
}

sub findIntf {
    my ($net, $device) = @_;
    $net->{ifcfg}{$device}{DEVICE} = undef;
    $net->{ifcfg}{$device};
}

my $ip_regexp = qr/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;

sub is_ip {
    my ($ip) = @_;
    my @fields = $ip =~ $ip_regexp or return;
    every { 0 <= $_ && $_ <= 255 } @fields or return;
    @fields;
}

sub ip_compare {
    my ($ip1, $ip2) = @_;
    my (@ip1_fields) = $ip1 =~ $ip_regexp;
    my (@ip2_fields) = $ip2 =~ $ip_regexp;
    
    every { $ip1_fields[$_] eq $ip2_fields[$_] } (0 .. 3);
}

sub is_ip_forbidden {
    my ($ip) = @_;
    my @forbidden = ('127.0.0.1', '255.255.255.255');
    
    any { ip_compare($ip, $_) } @forbidden;
}

sub is_domain_name {
    my ($name) = @_;
    my @fields = split /\./, $name;
    $name !~ /\.$/ && @fields > 0 && @fields == grep { /^[[:alnum:]](?:[\-[:alnum:]]{0,61}[[:alnum:]])?$/ } @fields;
}

sub netmask {
    my ($ip) = @_;
    return "255.255.255.0" unless is_ip($ip);
    $ip =~ $ip_regexp or warn "IP_regexp failed\n" and return "255.255.255.0";
    if ($1 >= 1 && $1 < 127) {
	"255.0.0.0";    #-1.0.0.0 to 127.0.0.0
    } elsif ($1  >= 128 && $1 <= 191) {
	"255.255.0.0";  #-128.0.0.0 to 191.255.0.0
    } elsif ($1 >= 192 && $1 <= 223) {
	"255.255.255.0";
    } else {
	"255.255.255.255"; #-experimental classes
    }
}

sub netmask_to_vlsm {
    my ($netmask) = @_;
    #- based on Network::IPv4Addr::ipv4_msk2cidr
    my @bytes = split /\./, $netmask;
    my $prefix = 0;
    foreach (@bytes) {
        my $bits = unpack("B*", pack("C", $_));
        $prefix += $bits =~ tr/1/1/;
    }
    return $prefix;
}

sub masked_ip {
    my ($ip) = @_;
    my @ip = is_ip($ip) or return '';
    my @mask = netmask($ip) =~ $ip_regexp;
    for (my $i = 0; $i < @ip; $i++) {
	$ip[$i] &= int $mask[$i];
    }
    join(".", @ip);
}

sub dns {
    my ($ip) = @_;
    my @masked = masked_ip($ip) =~ $ip_regexp;
    $masked[3]  = 1;
    join(".", @masked);

}

sub gateway {
    my ($ip) = @_;
    my @masked = masked_ip($ip) =~ $ip_regexp;
    $masked[3]  = 1;
    join(".", @masked);
}

sub netprofile_modules() {
    my @m = split('\n', `/sbin/netprofile modules`);
    my @modules;

    foreach my $module (@m) {
        my @params = split('\t', $module);
        my $vals = {
                module => $params[0],
                enabled => $params[1] eq '+' ? 1 : 0,
                name => $params[2],
                description => $params[3],
            };
        push(@modules, $vals);
    }
    @modules;
}

sub netprofile_module_enable {
    my ($module) = @_;
    system('/sbin/netprofile', 'module_enable', $module);
    log::explanations(qq(Enabling netprofile module $module));
}

sub netprofile_module_disable {
    my ($module) = @_;
    system('/sbin/netprofile', 'module_disable', $module);
    log::explanations(qq(Disabling netprofile module $module));
}

sub netprofile_set {
    my ($net, $profile) = @_;
    $net->{PROFILE} = $profile;
    system('/sbin/netprofile', 'switch', $net->{PROFILE});
    log::explanations(qq(Switching to "$net->{PROFILE}" profile));
}

sub netprofile_delete {
    my ($profile) = @_;
    return if !$profile;
    system('/sbin/netprofile', 'delete', $profile);
    log::explanations(qq(Deleting "$profile" profile));
}

sub netprofile_list() {
    map { if_(m!([^/]*)/$!, common::from_utf8($1)) } glob("$::prefix/etc/netprofile/profiles/*/");
}

sub netprofile_count() {
    my @profiles = netprofile_list();
    return $#profiles;
}

sub netprofile_read {
    my ($net) = @_;
    my $profile = cat_("$::prefix/etc/netprofile/current");
    chomp $profile if $profile;
    $net->{PROFILE} = $profile || 'default';
}

sub advanced_settings_read() {
    my $modprobe = "$::prefix/etc/modprobe.conf";
    my $sysctl = "$::prefix/etc/sysctl.conf";
    my $msecconf = "$::prefix/etc/security/msec/security.conf";

    my $ipv6_disabled = find { /^options ipv6 disable=1$/ } cat_($modprobe);
    my $disable_window_scaling = find { /^net\.ipv4\.tcp_window_scaling\s*=\s*0$/ } cat_($sysctl);
    my $disable_tcp_timestamps = find { /^net\.ipv4\.tcp_timestamps\s*=\s*0$/ } cat_($sysctl);
    my $log_martians = find { /^net\.ipv4\.conf\.all\.log_martians\s*=\s*1$/ } cat_($sysctl);
    my $disable_icmp = find { /^net\.ipv4\.icmp_echo_ignore_all\s*=\s*1$/ } cat_($sysctl);
    my $disable_icmp_broadcasts = find { /^net\.ipv4\.icmp_echo_ignore_broadcasts\s*=\s*1$/ } cat_($sysctl);
    my $disable_bogus_error_responses = find { /^net\.ipv4\.icmp_ignore_bogus_error_responses\s*=\s*1$/ } cat_($sysctl);
    my $msec = find { /^BASE_LEVEL=/ } cat_($msecconf);

    { ipv6_disabled => $ipv6_disabled, disable_window_scaling => $disable_window_scaling,
        disable_tcp_timestamps => $disable_tcp_timestamps, log_martians => $log_martians,
        disable_icmp => $disable_icmp, disable_icmp_broadcasts => $disable_icmp_broadcasts,
        disable_bogus_error_responses => $disable_bogus_error_responses,
        msec => $msec,
    };
}

sub advanced_settings_write {
    my ($u) = @_;
    # ipv6
    substInFile {
        /^(options ipv6 .*|install ipv6 .*|alias net-pf-10 off)/ and $_="";
        if (eof && $u->{ipv6_disabled}) {
            $_ .= "options ipv6 disable=1\n";
        }
    } "$::prefix/etc/modprobe.conf";
    # sysctl
    substInFile {
        # remove old entries
        /^net\.ipv4\.(tcp_window_scaling|tcp_timestamps|conf\.all\.log_martians|icmp_echo_ignore_all|icmp_echo_ignore_broadcasts|icmp_ignore_bogus_error_responses)/ and $_="";
        if (eof) {
            # add new values
            my $window_scaling = $u->{disable_window_scaling} ? "0" : "1";
            my $tcp_timestamps = $u->{disable_tcp_timestamps} ? "0" : "1";
            my $log_martians = $u->{log_martians} ? "1" : "0";    # this is inversed property
            my $disable_icmp = $u->{disable_icmp} ? "1" : "0";    # this is inversed property
            my $disable_icmp_broadcasts = $u->{disable_icmp_broadcasts} ? "1" : "0";    # this is inversed property
            my $disable_bogus_error_responses = $u->{disable_bogus_error_responses} ? "1" : "0";    # this is inversed property
            $_ .= "net.ipv4.tcp_window_scaling=$window_scaling\n";
            $_ .= "net.ipv4.tcp_timestamps=$tcp_timestamps\n";
            $_ .= "net.ipv4.conf.all.log_martians=$log_martians\n";
            $_ .= "net.ipv4.icmp_echo_ignore_all=$disable_icmp\n";
            $_ .= "net.ipv4.icmp_echo_ignore_broadcasts=$disable_icmp_broadcasts\n";
            $_ .= "net.ipv4.icmp_ignore_bogus_error_responses=$disable_bogus_error_responses\n";
        }
    } "$::prefix/etc/sysctl.conf";
}

sub advanced_choose {
    my ($in, $net, $u) = @_;

    $in->ask_from(N("Advanced network settings"),
       N("Here you can configure advanced network settings. Please note that you have to reboot the machine for changes to take effect."),
       [
         { label => N("Wireless regulatory domain"), val => \$net->{network}{CRDA_DOMAIN}, sort => 1, list => \@crda_domains },
         { label => "<b>" . N("TCP/IP settings") . "</b>" },
         { text => N("Disable IPv6"), val => \$u->{ipv6_disabled}, type => "bool" },
         { text => N("Disable TCP Window Scaling"), val => \$u->{disable_window_scaling}, type => "bool" },
         { text => N("Disable TCP Timestamps"), val => \$u->{disable_tcp_timestamps}, type => "bool" },
         { label => "<b>" . N("Security settings (defined by MSEC policy)") . "</b>" },
         { text => N("Disable ICMP echo"), val => \$u->{disable_icmp}, type => "bool", disabled => sub { $u->{msec} } },
         { text => N("Disable ICMP echo for broadcasting messages"), val => \$u->{disable_icmp_broadcasts}, type => "bool", disabled => sub { $u->{msec} } },
         { text => N("Disable invalid ICMP error responses"), val => \$u->{disable_bogus_error_responses}, type => "bool", disabled => sub { $u->{msec} } },
         { text => N("Log strange packets"), val => \$u->{log_martians}, type => "bool", disabled => sub { $u->{msec} } },
       ]
    ) or return;
    1;
}

sub miscellaneous_choose {
    my ($in, $u) = @_;

    my $net = {};
    netprofile_read($net);

    my $use_http_for_https = $u->{https_proxy} eq $u->{http_proxy};
    $in->ask_from(N("Proxies configuration"),
       N("Here you can set up your proxies configuration (eg: http://my_caching_server:8080)") .  if_($net->{PROFILE} && netprofile_count() > 0, "\n" . N("Those settings will be saved for the network profile <b>%s</b>", $net->{PROFILE})),
       [ { label => N("HTTP proxy"), val => \$u->{http_proxy} },
         { text => N("Use HTTP proxy for HTTPS connections"), val => \$use_http_for_https, type => "bool" },
         { label => N("HTTPS proxy"), val => \$u->{https_proxy}, disabled => sub { $use_http_for_https } },
         { label => N("FTP proxy"),  val => \$u->{ftp_proxy} },
         { label => N("No proxy for (comma separated list):"),  val => \$u->{no_proxy} },
       ],
       complete => sub {
           $use_http_for_https and $u->{https_proxy} = $u->{http_proxy};
           $u->{no_proxy} =~ s/\s//g;
	   $u->{http_proxy} =~ m,^($|http://), or $in->ask_warn('', N("Proxy should be http://...")), return 1,0;
	   $u->{https_proxy} =~ m,^($|https?://), or $in->ask_warn('', N("Proxy should be http://... or https://...")), return 1,2;
	   $u->{ftp_proxy} =~ m,^($|ftp://|http://), or $in->ask_warn('', N("URL should begin with 'ftp:' or 'http:'")), return 1,3;
	   0;
       }
    ) or return;
    1;
}

sub proxy_configure_shell {
    my ($proxy) = @_;
    my $sh_file = "$::prefix/etc/profile.d/proxy.sh";
    setExportedVarsInSh($sh_file, $proxy, qw(http_proxy https_proxy ftp_proxy no_proxy));
    chmod 0755, $sh_file;
    my $csh_file = "$::prefix/etc/profile.d/proxy.csh";
    setExportedVarsInCsh($csh_file, $proxy, qw(http_proxy https_proxy ftp_proxy no_proxy));
    chmod 0755, $csh_file;
}

sub proxy_configure_kde {
    my ($proxy) = @_;

    my $kde_config_dir = "$::prefix/usr/share/config";
    -d $kde_config_dir or return;

    my $kde_config_file = "$kde_config_dir/kioslaverc";
    update_gnomekderc($kde_config_file,
                      undef,
                      PersistentProxyConnection => "false"
                  );
    update_gnomekderc($kde_config_file,
                      "Proxy Settings",
                      AuthMode => 0,
                      ProxyType => $proxy->{http_proxy} || $proxy->{https_proxy} || $proxy->{ftp_proxy} ? 4 : 0,
                      ftpProxy => "ftp_proxy",
                      httpProxy => "http_proxy",
                      httpsProxy => "https_proxy",
                      NoProxyFor => "no_proxy",
                  );
}

#- (protocol, user, password, host, port)
my $http_proxy_match = qr,^(http)://(?:([^:\@]+)(?::([^:\@]+))?\@)?([^\:]+)(?::(\d+))?$,;
#- (protocol, host, port)
my $https_proxy_match = qr,^(https?)://(?:[^:\@]+(?::[^:\@]+)?\@)?([^\:]+)(?::(\d+))?$,;
#- (protocol, protocol, host, port)
my $ftp_proxy_match = qr,^(http|ftp)://(?:[^:\@]+(?::[^:\@]+)?\@)?([^\:]+)(?::(\d+))?$,;
my %proxy_default_port = (
    http => 80,
    https => 443,
    ftp => 21,
);

sub proxy_configure_gnome {
    my ($proxy) = @_;

    -d "$::prefix/etc/gconf/2/" or return;

    my $defaults_dir = "/etc/gconf/gconf.xml.local-defaults";
    my $p_defaults_dir = "$::prefix$defaults_dir";

    my $use_alternate_proxy;
    my $gconf_set = sub {
        my ($key, $type, $value) = @_;
        #- gconftool-2 is available since /etc/gconf/2/ exists
        run_program::rooted($::prefix, 'gconftool-2', '>', '/dev/null', "--config-source=xml::$p_defaults_dir", "--direct", "--set", "--type=$type", if_($type eq "list", '--list-type', 'string'), $key, $value);
    };

    #- http proxy
    if (my ($protocol, $user, $password, $host, $port) = $proxy->{http_proxy} =~ $http_proxy_match) {
        $port ||= $proxy_default_port{$protocol} || $proxy_default_port{http};
        $gconf_set->("/system/http_proxy/use_http_proxy", "bool", 1);
        $gconf_set->("/system/http_proxy/host", "string", $host);
        $gconf_set->("/system/http_proxy/port", "int", $port);
        $gconf_set->("/system/http_proxy/use_authentication", "bool", to_bool($user));
        $user and $gconf_set->("/system/http_proxy/authentication_user", "string", $user);
        $password and $gconf_set->("/system/http_proxy/authentication_password", "string", $password);
    } else {
        $gconf_set->("/system/http_proxy/use_http_proxy", "bool", 0);
    }

    #- https proxy
    if (my ($protocol, $host, $port) = $proxy->{https_proxy} =~ $https_proxy_match) {
        $port ||= $proxy_default_port{$protocol} || $proxy_default_port{https};
        $gconf_set->("/system/proxy/secure_host", "string", $host);
        $gconf_set->("/system/proxy/secure_port",  "int", $port);
        $use_alternate_proxy = 1;
    } else {
        #- clear the ssl host so that it isn't used if the manual proxy is activated for ftp
        $gconf_set->("/system/proxy/secure_host", "string", "");
    }

    #- ftp proxy
    if (my ($protocol, $host, $port) = $proxy->{ftp_proxy} =~ $ftp_proxy_match) {
        $port ||= $proxy_default_port{$protocol} || $proxy_default_port{ftp};
        $gconf_set->("/system/proxy/ftp_host", "string", $host);
        $gconf_set->("/system/proxy/ftp_port", "int", $port);
        $use_alternate_proxy = 1;
    } else {
        #- clear the ftp host so that it isn't used if the manual proxy is activated for ssl
        $gconf_set->("/system/proxy/ftp_host", "string", "");
    }

    my $ignore_hosts = join(',', uniq(qw(localhost 127.0.0.0/8)), split(',', $proxy->{no_proxy}));
    $gconf_set->("/system/http_proxy/ignore_hosts", "list", "[$ignore_hosts]");

    #- set proxy mode to manual if either https or ftp is used
    $gconf_set->("/system/proxy/mode", "string", $use_alternate_proxy ? "manual" : "none");

    #- make gconf daemons reload their settings
    system("killall -s HUP gconfd-2");
}

sub proxy_configure_mozilla_firefox {
    my ($proxy) = @_;

    my $firefox_config_file = "$::prefix/etc/firefox.cfg";
    -f $firefox_config_file or return;

    my %prefs;
    foreach (qw(http ssl ftp)) {
        undef $prefs{"network.proxy.${_}"};
        undef $prefs{"network.proxy.${_}_port"};
    }
    if (my ($protocol, undef, undef, $host, $port) = $proxy->{http_proxy} =~ $http_proxy_match) {
        $prefs{"network.proxy.http"} = qq("$host");
        $prefs{"network.proxy.http_port"} = $port || $proxy_default_port{$protocol} || $proxy_default_port{http};
    }
    if (my ($protocol, $host, $port) = $proxy->{https_proxy} =~ $https_proxy_match) {
        $prefs{"network.proxy.ssl"} =  qq("$host");
        $prefs{"network.proxy.ssl_port"} = $port || $proxy_default_port{$protocol} || $proxy_default_port{https};
    }
    if (my ($protocol, $host, $port) = $proxy->{ftp_proxy} =~ $ftp_proxy_match) {
        $prefs{"network.proxy.ftp"} =  qq("$host");
        $prefs{"network.proxy.ftp_port"} = $port || $proxy_default_port{$protocol} || $proxy_default_port{ftp};
    }
    if ($proxy->{no_proxy}) {
        $prefs{"network.proxy.no_proxies_on"} = qq("$proxy->{no_proxy}");
    }
    $prefs{"network.proxy.type"} = any { defined $prefs{"network.proxy.${_}_port"} } qw(http ssl ftp);

    substInFile {
        while (my ($key, $value) = each(%prefs)) {
            if (/^defaultPref\("$key",/) {
                $_ = defined $value && qq(defaultPref("$key", $value);\n);
                delete $prefs{$key};
            }
        }
        $_ .= join('', map { if_(defined $prefs{$_}, qq(defaultPref("$_", $prefs{$_});\n)) } sort(keys %prefs)) if eof;
    } $firefox_config_file;
}

sub proxy_configure {
    my ($proxy) = @_;
    proxy_configure_shell($proxy);
    proxy_configure_kde($proxy);
    proxy_configure_gnome($proxy);
    proxy_configure_mozilla_firefox($proxy);
}

sub detect_crda_domain() {
    my $crda = { getVarsFromSh($::prefix . $network_file) }->{CRDA_DOMAIN};
    if (!$crda) {
        my $locale = lang::read($>);
        my $country = $locale->{country};
        if (member($country, @crda_domains)) {
            $crda = $country;
        } else {
            $crda = "US";
        }
    }
    $crda;
}

sub read_net_conf {
    my ($net) = @_;
    add2hash($net->{network} ||= {}, read_conf($::prefix . $network_file));
    add2hash($net->{resolv} ||= {}, read_resolv_conf());
    add2hash($net->{zeroconf} ||= {}, read_zeroconf());

    foreach (all("$::prefix/etc/sysconfig/network-scripts")) {
	my ($device) = /^ifcfg-([A-Za-z0-9.:_-]+)$/;
	next if $device =~ /.rpmnew$|.rpmsave$/;
	if ($device && $device ne 'lo') {
	    my $intf = findIntf($net, $device);
	    add2hash($intf, { getVarsFromSh("$::prefix/etc/sysconfig/network-scripts/$_") });
	    $intf->{DEVICE} ||= $device;
	}
    }
    $net->{wireless} ||= {};
    foreach (all($::prefix . $wireless_d)) {
        $net->{wireless}{$_} = { getVarsFromSh($::prefix . $wireless_d . '/' . $_) };
    }
    # detect default CRDA_DOMAIN
    $net->{network}{CRDA_DOMAIN} ||= detect_crda_domain();
    netprofile_read($net);
    if (my $default_intf = network::tools::get_default_gateway_interface($net)) {
	$net->{net_interface} = $default_intf;
	$net->{type} = network::tools::get_interface_type($net->{ifcfg}{$default_intf});
    }
}

#- FIXME: this is buggy, use network::tools::get_default_gateway_interface
sub probe_netcnx_type {
    my ($net) = @_;
    #- try to probe $netcnx->{type} which is used almost everywhere.
    unless ($net->{type}) {
	#- ugly hack to determine network type (avoid saying not configured in summary).
	-e "$::prefix/etc/ppp/peers/adsl" and $net->{type} ||= 'adsl'; # enough ?
	-e "$::prefix/etc/ppp/ioptions1B" || -e "$::prefix/etc/ppp/ioptions2B" and $net->{type} ||= 'isdn'; # enough ?
	$net->{ifcfg}{ppp0} and $net->{type} ||= 'modem';
	$net->{ifcfg}{eth0} and $net->{type} ||= 'lan';
    }
}

sub easy_dhcp {
    my ($net, $modules_conf) = @_;

    return if text2bool($net->{network}{NETWORKING});

    require modules;
    require network::connection::ethernet;
    modules::load_category($modules_conf, list_modules::ethernet_categories());
    my @all_dev = sort map { $_->[0] } network::connection::ethernet::get_eth_cards($modules_conf);

    my @ether_dev = grep { /^eth[0-9]+$/ && `LC_ALL= LANG= $::prefix/sbin/ip -o link show $_ 2>/dev/null` =~ m|\slink/ether\s| } @all_dev;
    foreach my $dhcp_intf (@ether_dev) {
        log::explanations("easy_dhcp: found $dhcp_intf");
        $net->{ifcfg}{$dhcp_intf} ||= {};
        put_in_hash($net->{ifcfg}{$dhcp_intf}, {
				      DEVICE => $dhcp_intf,
				      BOOTPROTO => 'dhcp',
				      NETMASK => '255.255.255.0',
				      ONBOOT => 'yes'
                                  });
    }

    1;
}

sub reload_net_applet() {
    #- make net_applet reload the configuration
    my $pid = chomp_(`pidof -x net_applet`);
    $pid and eval { kill 1, $pid };
}

sub configure_network {
    my ($net, $in, $modules_conf) = @_;
    if (!$::testing) {
        require network::connection::ethernet;
        network::connection::ethernet::configure_eth_aliases($modules_conf);

        write_network_conf($net);
        write_resolv_conf($net);
        write_hostname($net->{network}{HOSTNAME}) if $net->{network}{HOSTNAME};
        foreach (keys %{$net->{ifcfg}}) {
            write_interface_conf($net, $_);
            my $ssid = $net->{ifcfg}{$_}{WIRELESS_ESSID} or next;
            write_wireless_conf($ssid, $net->{ifcfg}{$_});
        }
        network::connection::ethernet::install_dhcp_client($in, $_->{DHCP_CLIENT}) foreach grep { $_->{BOOTPROTO} eq "dhcp" } values %{$net->{ifcfg}};
        write_zeroconf($net, $in);

        any { $_->{BOOTPROTO} =~ /^(pump|bootp)$/ } values %{$net->{ifcfg}} and $in->do_pkgs->install('pump');

        require network::shorewall;
        network::shorewall::update_interfaces_list();

    }

    reload_net_applet();
}

1;
