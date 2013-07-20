package network::drakfirewall; # $Id: drakfirewall.pm 268043 2010-04-30 13:29:37Z blino $

use strict;
use diagnostics;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use network::shorewall;
use common;
use network::nfs;
use network::network;

my @all_servers =
(
  {
   name => N_("Web Server"),
   pkg => 'apache apache-mod_perl boa lighttpd thttpd',
   ports => '80/tcp 443/tcp',
  },
  {
   name => N_("Domain Name Server"),
   pkg => 'bind dnsmasq mydsn',
   ports => '53/tcp 53/udp',
  },
  {
   name => N_("SSH server"),
   pkg => 'openssh-server',
   ports => '22/tcp',
  },
  {
   name => N_("FTP server"),
   pkg => 'ftp-server-krb5 wu-ftpd proftpd pure-ftpd',
   ports => '20/tcp 21/tcp',
  },
  {
   name => N_("DHCP Server"),
   pkg => 'dhcp-server udhcpd',
   ports => '67/udp 68/udp',
   hide => 1,
  },
  {
   name => N_("Mail Server"),
   pkg => 'sendmail postfix qmail exim',
   ports => '25/tcp 465/tcp',
  },
  {
   name => N_("POP and IMAP Server"),
   pkg => 'imap courier-imap-pop',
   ports => '109/tcp 110/tcp 143/tcp 993/tcp 995/tcp',
  },
  {
   name => N_("Telnet server"),
   pkg => 'telnet-server-krb5',
   ports => '23/tcp',
   hide => 1,
  },
  {
   name => N_("NFS Server"),
   pkg => 'nfs-utils nfs-utils-clients',
   ports => '111/tcp 111/udp 2049/tcp 2049/udp ' . network::nfs::list_nfs_ports(),
   hide => 1,
   prepare => sub { network::nfs::write_nfs_ports(network::nfs::read_nfs_ports()) },
   restart => 'nfs-common nfs-server',
  },
  {
   name => N_("Windows Files Sharing (SMB)"),
   pkg => 'samba-server',
   ports => '137/tcp 137/udp 138/tcp 138/udp 139/tcp 139/udp 445/tcp 445/udp 1024:1100/tcp 1024:1100/udp',
   hide => 1,
  },
  {
   name => N_("Bacula backup"),
   pkg => 'bacula-fd bacula-sd bacula-dir-common',
   ports => '9101:9103/tcp',
   hide => 1,
  },
  {
   name => N_("Syslog network logging"),
   pkg => 'rsyslog syslog-ng',
   ports => '514/udp',
   hide => 1,
  },
  {
   name => N_("CUPS server"),
   pkg => 'cups',
   ports => '631/tcp 631/udp',
   hide => 1,
  },
  {
   name => N_("MySQL server"),
   pkg => 'mysql',
   ports => '3306/tcp 3306/udp',
   hide => 1,
  },
  {
   name => N_("PostgreSQL server"),
   pkg => 'postgresql8.2 postgresql8.3',
   ports => '5432/tcp 5432/udp',
   hide => 1,
  },
  {
   name => N_("Echo request (ping)"),
   ports => '8/icmp',
   force_default_selection => 0,
  },
  {
   name => N_("Network services autodiscovery (zeroconf and slp)"),
   ports => '5353/udp 427/udp',
   pkg => 'avahi cups openslp',
  },
  {
   name => N_("BitTorrent"),
   ports => '6881:6999/tcp',
   hide => 1,
   pkg => 'bittorrent deluge ktorrent transmission vuze rtorrent ctorrent',
  },
  {
   name => N_("Windows Mobile device synchronization"),
   pkg => 'synce-hal',
   ports => '990/tcp 999/tcp 5678/tcp 5679/udp 26675/tcp',
   hide => 1,
  },
);

my @ifw_rules = (
    {
        name => N_("Port scan detection"),
        ifw_rule => 'psd',
    },
);

# global network configuration
my $net = {};
network::network::read_net_conf($net);

sub port2server {
    my ($port) = @_;
    find {
	any { $port eq $_ } split(' ', $_->{ports});
    } @all_servers;
}

sub check_ports_syntax {
    my ($ports) = @_;
    foreach (split ' ', $ports) {
	my ($nb, $range, $nb2) = m!^(\d+)(:(\d+))?/(tcp|udp|icmp)$! or return $_;
	foreach my $port ($nb, if_($range, $nb2)) {
	    1 <= $port && $port <= 65535 or return $_;
	}
	$nb < $nb2 or return $_ if $range;
    }
    '';
}

sub to_ports {
    my ($servers, $unlisted) = @_;
    join(' ', (map { $_->{ports} } @$servers), if_($unlisted, $unlisted));
}

sub from_ports {
    my ($ports) = @_;

    my @l;
    my @unlisted;
    foreach (split ' ', $ports) {
	if (my $s = port2server($_)) {
	    push @l, $s;
	} else {
	    push @unlisted, $_;
	}
    }
    [ uniq(@l) ], join(' ', @unlisted);
}

sub default_from_pkgs {
    my ($do_pkgs) = @_;
    my @pkgs = $do_pkgs->are_installed(map { split ' ', $_->{pkg} } @all_servers);
    [ grep {
	my $s = $_;
	exists $s->{force_default_selection} ?
	  $s->{force_default_selection} :
	  any { member($_, @pkgs) } split(' ', $s->{pkg});
    } @all_servers ];
}

sub default_ports {
    my ($do_pkgs) = @_;
    to_ports(default_from_pkgs($do_pkgs), '');
}

sub get_ports() {
    my $shorewall = network::shorewall::read() or return;
    $shorewall->{ports};
}

sub set_ports {
    my ($do_pkgs, $disabled, $ports, $log_net_drop, $o_in) = @_;

    if (!$disabled || -x "$::prefix/sbin/shorewall") {
	$do_pkgs->ensure_files_are_installed([ [ qw(shorewall shorewall) ], [ qw(shorewall-ipv6 shorewall6) ] ], $::isInstall) or return;
	my $shorewall = network::shorewall::read(!$disabled && $o_in);
	if (!$shorewall) {
	    log::l("unable to read shorewall configuration, skipping installation");
	    return;
	}

	$shorewall->{disabled} = $disabled;
	$shorewall->{ports} = $ports;
        $shorewall->{log_net_drop} = $log_net_drop;
	log::l($disabled ? "disabling shorewall" : "configuring shorewall to allow ports: $ports");
	network::shorewall::write($shorewall, $o_in);
    }
}

sub get_conf {
    my ($in, $disabled, $o_ports) = @_;

    my $possible_servers = default_from_pkgs($in->do_pkgs);
    $_->{hide} = 0 foreach @$possible_servers;

    if ($o_ports) {
	$disabled, from_ports($o_ports);
    } elsif (my $shorewall = network::shorewall::read()) {
	$shorewall->{disabled}, from_ports($shorewall->{ports}), $shorewall->{log_net_drop};
    } else {
	$in->ask_okcancel(N("Firewall configuration"), N("drakfirewall configurator

This configures a personal firewall for this Mageia machine."), 1) or return;

	$in->ask_okcancel(N("Firewall configuration"), N("drakfirewall configurator

Make sure you have configured your Network/Internet access with
drakconnect before going any further."), 1) or return;

	$disabled, $possible_servers, '';
    }
}

sub choose_allowed_services {
    my ($in, $disabled, $servers, $unlisted, $log_net_drop) = @_;

    $_->{on} = 0 foreach @all_servers;
    $_->{on} = 1 foreach @$servers;
    my @l = grep { $_->{on} || !$_->{hide} } @all_servers;

    $in->ask_from_({
		    title => N("Firewall"),
		    icon => $network::shorewall::firewall_icon,
		    if_(!$::isEmbedded, banner_title => N("Firewall")),
		    advanced_messages => N("You can enter miscellaneous ports. 
Valid examples are: 139/tcp 139/udp 600:610/tcp 600:610/udp.
Have a look at /etc/services for information."),
		    callbacks => {
			complete => sub {
			    if (my $invalid_port = check_ports_syntax($unlisted)) {
				$in->ask_warn('', N("Invalid port given: %s.
The proper format is \"port/tcp\" or \"port/udp\", 
where port is between 1 and 65535.

You can also give a range of ports (eg: 24300:24350/udp)", $invalid_port));
				return 1;
			    }
			},
		   } },
		  [
		   { label => N("Which services would you like to allow the Internet to connect to?"), title => 1 },
		   if_($net->{PROFILE} && network::network::netprofile_count() > 0, { label => N("Those settings will be saved for the network profile <b>%s</b>", $net->{PROFILE}) }),
		   { text => N("Everything (no firewall)"), val => \$disabled, type => 'bool' },
		   (map { { text => translate($_->{name}), val => \$_->{on}, type => 'bool', disabled => sub { $disabled } } } @l),
		   { label => N("Other ports"), val => \$unlisted, advanced => 1, disabled => sub { $disabled } },
		   { text => N("Log firewall messages in system logs"), val => \$log_net_drop, type => 'bool', advanced => 1, disabled => sub { $disabled } },
		  ]) or return;

    $disabled, [ grep { $_->{on} } @l ], $unlisted, $log_net_drop;
}

sub set_ifw {
    my ($do_pkgs, $enabled, $rules, $ports) = @_;
    if ($enabled) {
        $do_pkgs->ensure_is_installed('mandi-ifw', '/etc/ifw/start', $::isInstall) or return;

        my $ports_by_proto = network::shorewall::ports_by_proto($ports);
        output_with_perm("$::prefix/etc/ifw/rules", 0644,
            (map { ". /etc/ifw/rules.d/$_\n" } @$rules),
            map {
                my $proto = $_;
                map {
                    my $multiport = /:/ && " -m multiport";
                    "iptables -A Ifw -m conntrack --ctstate NEW -p $proto$multiport --dport $_ -j IFWLOG --log-prefix NEW\n";
                } @{$ports_by_proto->{$proto}};
            } intersection([ qw(tcp udp) ], [ keys %$ports_by_proto ]),
        );
    }

    substInFile {
            undef $_ if m!^INCLUDE /etc/ifw/rules|^iptables -I INPUT 2 -j Ifw!;
    } "$::prefix/etc/shorewall/start";
    network::shorewall::set_in_file('start', $enabled, "INCLUDE /etc/ifw/start", "INCLUDE /etc/ifw/rules", "iptables -I INPUT 1 -j Ifw");
    network::shorewall::set_in_file('stop', $enabled, "iptables -D INPUT -j Ifw", "INCLUDE /etc/ifw/stop");
}

sub choose_watched_services {
    my ($in, $servers, $unlisted) = @_;

    my @l = (@ifw_rules, @$servers, map { { ports => $_ } } split(' ', $unlisted));
    my $enabled = 1;
    $_->{ifw} = 1 foreach @l;

    $in->ask_from_({
        icon => $network::shorewall::firewall_icon,
        if_(!$::isEmbedded, banner_title => N("Interactive Firewall")),
        messages =>
          N("You can be warned when someone accesses to a service or tries to intrude into your computer.
Please select which network activities should be watched."),
        title => N("Interactive Firewall"),
    },
                   [
                       { text => N("Use Interactive Firewall"), val => \$enabled, type => 'bool' },
                       map { {
                           text => (exists $_->{name} ? translate($_->{name}) : $_->{ports}),
                           val => \$_->{ifw},
                           type => 'bool', disabled => sub { !$enabled },
                       } } @l,
                   ]) or return;
    my ($rules, $ports) = partition { exists $_->{ifw_rule} } grep { $_->{ifw} } @l;
    set_ifw($in->do_pkgs, $enabled, [ map { $_->{ifw_rule} } @$rules ], to_ports($ports));

    # return something to say that we are done ok
    $rules, $ports;
}

sub main {
    my ($in, $disabled) = @_;

    ($disabled, my $servers, my $unlisted, my $log_net_drop) = get_conf($in, $disabled) or return;

    ($disabled, $servers, $unlisted, $log_net_drop) = choose_allowed_services($in, $disabled, $servers, $unlisted, $log_net_drop) or return;

    my $system_file = '/etc/sysconfig/drakx-net';
    my %global_settings = getVarsFromSh($system_file);

    if (!$disabled && (!defined($global_settings{IFW}) || text2bool($global_settings{IFW}))) {
        choose_watched_services($in, $servers, $unlisted) or return;
    }

    # preparing services when required
    foreach (@$servers) {
        exists $_->{prepare} and $_->{prepare}();
    }

    my $ports = to_ports($servers, $unlisted);

    set_ports($in->do_pkgs, $disabled, $ports, $log_net_drop, $in) or return;

    # restart mandi
    require services;
    services::is_service_running("mandi") and services::restart("mandi");

    # restarting services if needed
    foreach my $service (@$servers) {
        if ($service->{restart}) {
            services::is_service_running($_) and services::restart($_) foreach split(' ', $service->{restart});
        }
    }

    # clearing pending ifw notifications in net_applet
    system('killall -s SIGUSR1 net_applet');

    ($disabled, $ports);
}

1;
