package network::connection::xdsl;

use base qw(network::connection::ppp);

use strict;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;

sub get_type_name() { N("DSL") }
sub _get_type_icon() { 'xdsl' }

sub get_devices() {
    require detect_devices;
    require network::connection::isdn;
    require network::connection::ethernet;
    my @usb_devices = detect_devices::get_xdsl_usb_devices();
    $_->{xdsl_type} = 'usb' foreach @usb_devices;
    my @capi_devices  = grep { $_->{driver} =~ /dsl/i } map { network::connection::isdn::find_capi_card($_) } network::connection::isdn->get_devices;
    $_->{xdsl_type} = 'capi' foreach @capi_devices;
    my @ethernet_devices = network::connection::ethernet::get_devices();
    $_->{xdsl_type} = 'ethernet' foreach @ethernet_devices;
    @usb_devices, @capi_devices, @ethernet_devices;
}

sub get_metric { 25 }
sub get_interface() { "ppp0" }

sub get_up_timeout { 20 }

my @non_ppp_protocols = qw(static dhcp);
sub uses_ppp {
    my ($self) = @_;
    !member($self->{protocol}, @non_ppp_protocols);
}

sub uses_atm_arp {
    my ($self) = @_;
    $self->{device}{xdsl_type} eq 'usb' && !$self->uses_ppp;
}
sub get_atm_arp_interface { "atm0" }

sub uses_atm_bridging {
    my ($self) = @_;
    $self->{device}{xdsl_type} eq 'usb' && member($self->{protocol}, qw(pppoe));
}
sub get_atm_bridging_interface { "nas0" }

sub get_pppoe_interface {
    my ($self) = @_;
    $self->uses_atm_bridging
    ? $self->get_atm_bridging_interface
    : $self->network::connection::ethernet::get_interface;
}

my %protocol_settings = (
    pppoa => {
        plugin => sub {
            my ($self) = @_;
            "pppoatm.so " . join('.', $self->{access}{peer}{vpi}, $self->{access}{peer}{vci});
        },
    },
    pppoe => {
        pty => sub {
            my ($self) = @_;
            my $pppoe_interface = $self->get_pppoe_interface;
            qq("pppoe -m 1412 -I $pppoe_interface");
        },
        options => [
            qw(default-asyncmap noaccomp nobsdcomp novjccomp nodeflate),
            "mru 1492",
            "mtu 1492",
            "lcp-echo-interval 20",
            "lcp-echo-failure 3",
        ],
    },
    pptp => {
        pty => qq("/usr/sbin/pptp 10.0.0.138 --nolaunchpppd"),
        options => [ qw(noipdefault) ],
    },
    capi => {
        plugin => "capiplugin.so avmadsl",
        options => [
            qw(ipcp-accept-remote ipcp-accept-local sync noipx),
            "connect /bin/true",
            "lcp-echo-interval 5",
            "lcp-echo-failure 3",
            "lcp-max-configure 50",
            "lcp-max-terminate 2",
            "mru 1492",
            "mtu 1492"
        ],
    },
);

my @thirdparty_settings = (
    {
        matching => 'speedtch',
        description => N_("Alcatel speedtouch USB modem"),
        url => "http://www.speedtouch.com/supuser.htm",
        name => 'speedtouch',
        firmware =>
          {
              package => 'speedtouch-firmware',
              test_file => 'speedtch-*.bin*',
              extract => {
                  name => 'speedtouch-firmware-extractor',
                  test_file => '/usr/sbin/firmware-extractor',
                  windows_source => 'alcaudsl.sys',
                  floppy_source => 'mgmt*.o',
                  default_source => '/usr/share/speedtouch/mgmt.o',
                  run => sub {
                      my ($file) = @_;
                      run_program::raw({ root => $::prefix, chdir => $network::thirdparty::firmware_directory },
                                       '/usr/sbin/firmware-extractor', $file);
                  },
              },
          },
        links => 'http://linux-usb.sourceforge.net/SpeedTouch/mandrake/index.html',
        ppp => {
            options => [ qw(noaccomp sync) ],
        },
    },

    {
        name => 'eciadsl',
        explanations => N_("The ECI Hi-Focus modem cannot be supported due to binary driver distribution problem.

You can find a driver on http://eciadsl.flashtux.org/"),
        no_distro_package => 1,
        tools => {
            test_file => '/usr/sbin/pppoeci',
        },
        ppp => {
            options => [
                qw(noipdefault noaccomp sync),
                "linkname eciadsl",
                "lcp-echo-interval 0",
            ],
            protocols => {
                pppoe => {
                    pty => sub {
                        my ($self) = @_;
                        qq("/usr/bin/pppoeci -v 1 -vpi $self->{access}{peer}{vpi} -vci $self->{access}{peer}{vci}");
                    },
                },
            },
        },
    },

    {
        matching => 'ueagle_atm',
        description => 'Eagle chipset (from Analog Devices), e.g. Sagem F@st 800/840/908',
        url => 'http://www.eagle-usb.org/',
        name => 'ueagle',
        firmware => {
            test_file => 'ueagle-atm/eagle*.fw',
        },
        links => 'http://atm.eagle-usb.org/wakka.php?wiki=UeagleAtmDoc',
    },

    {
        matching => qr/^unicorn_.*_atm$/,
        description => 'Bewan Adsl (Unicorn)',
        url => 'http://www.bewan.com/bewan/users/downloads/',
        name => 'unicorn',
        kernel_module => 1,
        tools => {
            optional => 1,
            test_file => '/usr/bin/bewan_adsl_status',
        },
        sleep => 10,
        ppp => {
            options => [
                qw(default-asyncmap hide-password noaccomp nobsdcomp nodeflate novjccomp sync),
                "lcp-echo-interval 20",
                "lcp-echo-failure 3",
            ],
        },
    },

    {
        name => 'cxacru',
        firmware => {
            test_file => 'cxacru-fw.bin',
            no_distro_package => 1,
            explanations => N_("Modems using Conexant AccessRunner chipsets cannot be supported due to binary firmware distribution problem."),
            url => 'http://accessrunner.sourceforge.net/firmware.shtml',
        },
    }
);

sub get_thirdparty_settings() {
    \@thirdparty_settings;
}

sub get_providers {
    my ($self) = @_;
    require network::connection::providers::xdsl;
    if_($self->{device}{xdsl_type} ne 'capi', \%network::connection::providers::xdsl::data, '|');
}

sub get_protocols {
    my ($self) = @_;
    $self->{device}{xdsl_type} eq 'capi' ?
      {
            capi   => N("DSL over CAPI"),
      } :
      {
        dhcp   => N("Dynamic Host Configuration Protocol (DHCP)"),
        static => N("Manual TCP/IP configuration"),
        pptp   => N("Point to Point Tunneling Protocol (PPTP)"),
        pppoe  => N("PPP over Ethernet (PPPoE)"),
        pppoa  => N("PPP over ATM (PPPoA)"),
      };
}

sub guess_protocol {
    my ($self, $net) = @_;
    $self->{protocol} = $self->{provider} && $self->{provider}{method};
    if ($self->{device}{xdsl_type} eq 'capi') {
        $self->{protocol} = 'capi';
    } elsif ($self->{device}{xdsl_type} eq 'ethernet') {
        require network::connection::ethernet;
        my $interface = $self->network::connection::ethernet::get_interface;
        if (my $ifcfg = $net->{ifcfg}{$interface}) {
            $self->{protocol} = $ifcfg->{BOOTPROTO} if member($ifcfg->{BOOTPROTO}, @non_ppp_protocols);
            $self->{protocol} ||= 'dhcp';
            #- pppoa shouldn't be selected by default for ethernet devices, fallback on pppoe
            $self->{protocol} = 'pppoe' if $self->{protocol} eq 'pppoa';
        }
    }
}

sub guess_access_settings {
    my ($self) = @_;
    require network::adsl;
    my $probe = {};
    network::adsl::adsl_probe_info($probe);
    $self->{access}{login} = $probe->{adsl}{login};
    $self->{access}{password} = $probe->{adsl}{passwd};
    $self->{access}{peer}{$_} = $probe->{adsl}{$_} foreach qw(vpi vci);
    if ($self->{provider}) {
        $self->{access}{peer}{$_} = hex($self->{provider}{$_}) foreach qw(vpi vci);
    }
}

sub get_access_settings {
    my ($self) = @_;

    [
        @{$self->network::connection::ppp::get_access_settings},
        if_(member($self->{protocol}, qw(pppoa pppoe)),
            { label => N("Virtual Path ID (VPI):"), val => \$self->{access}{peer}{vpi}, advanced => 1 },
            { label => N("Virtual Circuit ID (VCI):"), val => \$self->{access}{peer}{vci}, advanced => 1 }
        ),
    ];
}

sub get_peer_default_options {
    my ($self) = @_;
    $self->network::connection::ppp::get_peer_default_options,
    qw(lock persist nopcomp noccp novj),
    "kdebug 1",
    "holdoff 4",
    "maxfail 5";
}

sub build_peer  {
    my ($self) = @_;
    my $may_call = sub { ref $_[0] eq 'CODE' ? $_[0]->($self) : $_[0] };
    my @ppp_fields = qw(plugin pty);
    my @ppp_options;
    if ($self->{thirdparty}) {
        foreach my $settings (grep { $_ } $self->{thirdparty}{ppp}{protocols}{$self->{protocol}}, $self->{thirdparty}{ppp}) {
            @ppp_options = @{$settings->{options}} if $settings->{options};
            foreach (@ppp_fields) {
                $self->{access}{peer}{$_} ||= $may_call->($settings->{$_}) if defined $settings->{$_};
            }
        }
    }
    if (my $generic_settings = $protocol_settings{$self->{protocol}}) {
        @ppp_options = @{$generic_settings->{options} || []} if !@ppp_options;
        foreach (@ppp_fields) {
            $self->{access}{peer}{$_} ||= $may_call->($generic_settings->{$_}) if defined $generic_settings->{$_};
        }
    }

    @ppp_options, #- write them before pty/plugin stuff
    $self->network::connection::ppp::build_peer;
}

sub write_settings {
    my ($self, $net) = @_;

    if ($self->{device}{xdsl_type} eq 'ethernet' && $self->{protocol} eq 'pppoe') {
        my $interface = $self->network::connection::ethernet::get_interface;
        $net->{ifcfg}{$interface} = {
            DEVICE => $interface,
            BOOTPROTO => 'none',
            NETMASK => '255.255.255.0',
            NETWORK => '10.0.0.0',
            BROADCAST => '10.0.0.255',
            MII_NOT_SUPPORTED => 'yes',
            ONBOOT => 'yes',
        };
    }

    if ($self->{protocol} eq 'capi') {
        require network::connection::isdn;
        network::connection::isdn::write_capi_conf($self->{device});
    }

    #- TODO: add "options ueagle-atm cmv_file= $net->{adsl}{cmv}.bin" in /etc/modprobe.d/ueagle-atm
    # if ($self->get_driver eq 'ueagle-atm') { ... }

    if ($self->uses_ppp) {
        $self->network::connection::ppp::write_settings;
    } else {
        $self->network::connection::write_settings;
    }
}

sub build_ifcfg_settings {
    my ($self) = @_;
    my $settings = {
        if_($self->uses_ppp, TYPE => 'ADSL'),
    };
    if ($self->uses_atm_arp) {
        #- use ATMARP with the atm0 interface
        put_in_hash($settings, {
            DEVICE => $self->get_atm_arp_interface,
            ATM_ADDR => join('.', @{$self->{access}{peer}}{qw(vpi vci)}),
            MII_NOT_SUPPORTED => "yes",
        });
    }
    if ($self->uses_atm_bridging) {
        put_in_hash($settings, {
            ATM_DEVICE => $self->get_atm_bridging_interface,
            ATM_ADDR => join('.', @{$self->{access}{peer}}{qw(vpi vci)}),
        });
    }
    $self->network::connection::build_ifcfg_settings($settings);
}

sub unload_connection {
    my ($self) = @_;
    require network::connection::isdn;
    network::connection::isdn::unload_connection($self->{device}) if $self->{protocol} eq 'capi';
}

sub install_packages {
    my ($self, $in) = @_;
    my $per_type_packages = {
        pppoa => [ qw(ppp-pppoatm) ],
        pppoe => [ qw(rp-pppoe) ],
        pptp  => [ qw(pptp-linux) ],
        capi  => [ qw(ppp) ],
    };
    my @packages = @{$per_type_packages->{$self->{protocol}} || []};
    push @packages, 'linux-atm' if $self->uses_atm_arp || $self->uses_atm_bridging;
    if (@packages && !$in->do_pkgs->install(@packages)) {
        $in->ask_warn(N("Error"), N("Could not install the packages (%s)!", @packages));
        return;
    }
    if ($self->{protocol} eq 'capi') {
        require network::connection::isdn;
        network::connection::isdn::install_packages($self->{device}, $in);
        $in->do_pkgs->ensure_is_installed_if_available("drdsl", "/usr/sbin/drdsl");
    }
    1;
}

sub prepare_connection {
    my ($self) = @_;

    if ($::isInstall) {
        #- load modules that are not automatically loaded during install
        my @modules = qw(ppp_synctty ppp_async ppp_generic n_hdlc); #- required for pppoe/pptp connections
        push @modules, 'pppoatm' if $self->{protocol} eq 'pppoa';
        foreach (@modules) {
            eval { modules::load($_) } or log::l("failed to load $_ module: $@");
        }
    }

    if ($self->{protocol} eq 'capi') {
        require network::connection::isdn;
        network::connection::isdn::prepare_connection($self->{device});
        require run_program;
        run_program::rooted($::prefix, "/usr/sbin/drdsl");
    }

    1;
}

sub connect {
    my ($self) = @_;
    if ($self->{device}{xdsl_type} eq 'ethernet') {
        require network::tools;
        network::tools::start_interface($self->network::connection::ethernet::get_interface, 0);
    }
    $self->network::connection::connect;
}

sub disconnect {
    my ($self) = @_;
    $self->network::connection::disconnect;
    if ($self->{device}{xdsl_type} eq 'ethernet') {
        require network::tools;
        network::tools::stop_interface($self->network::connection::ethernet::get_interface, 0);
    }
}

1;
