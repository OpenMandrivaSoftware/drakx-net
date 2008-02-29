package network::connection::wireless;

use base qw(network::connection::ethernet);

use strict;
use common;

sub get_type_name() { N("Wireless") }
sub _get_type_icon() { 'wireless' }
sub get_devices {
    my ($_class, %options) = @_;
    require detect_devices;
    my @devices = detect_devices::probe_category('network/wireless');
    my @wireless = grep { detect_devices::is_wireless_interface($_) } detect_devices::get_lan_interfaces();
    my @all_devices = (@devices, network::connection::ethernet::get_unlisted_devices(\@wireless, \@devices));
    foreach (@all_devices) {
        my $interface = network::connection::ethernet::device_to_interface($_) or next;
        my $driver = network::connection::ethernet::interface_to_driver($interface) or next;
        $_->{driver} = $driver if $driver;
    }
    @all_devices,
    if_(!$options{automatic_only}, {
        driver => 'ndiswrapper',
        description => N("Use a Windows driver (with ndiswrapper)"),
    });
}

sub handles_ifcfg {
    my ($_class, $ifcfg) = @_;
    require detect_devices;
    detect_devices::is_wireless_interface($ifcfg->{DEVICE}) || exists $ifcfg->{WIRELESS_MODE};
}

sub get_metric { 35 }

#- class attributes:
#-   network: ID of the selected network

our %wireless_enc_modes = (
    none => N_("None"),
    open => N_("Open WEP"),
    restricted => N_("Restricted WEP"),
    'wpa-psk' => N_("WPA Pre-Shared Key"),
    'wpa-eap' => N_("WPA2/WPA Enterprise"),
);
#define the eap related variables we handle
#0 means we preserve value if found
#1 means we save without quotes
#2 save with quotes
my %eap_vars = (
	ssid => 2,
	scan_ssid => 1,
	identity => 2,
	password => 2,
	key_mgmt => 1,
	eap => 1,
	pairwise => 1,
	group => 1,
	proto => 1,
	ca_cert => 2,
	client_cert => 2,
	phase2 => 2,
	anonymous_identity => 2,
	subject_match => 2,
	disabled => 0,
	id_str => 0,
	bssid => 0,
	priority => 0,
	auth_alg => 0,
	eapol_flags => 0,
	proactive_key_caching => 0,
	peerkey => 0,
	ca_path => 0,
	private_key => 0,
	private_key_passwd => 0,
	dh_file => 0,
	altsubject_match => 0,
	phase1 => 0,
	fragment_size => 0,
	eap_workaround => 0,
);

my @thirdparty_settings = (
    {
        name => 'zd1201',
        description => 'ZyDAS ZD1201',
        url => 'http://linux-lc100020.sourceforge.net/',
        firmware => {
            test_file => 'zd1201*.fw',
        },
    },

    (map {
        {
            name => "ipw${_}",
            description => "Intel(R) PRO/Wireless ${_}",
            url => "http://ipw${_}.sourceforge.net/",
            firmware => {
                url => "http://ipw${_}.sourceforge.net/firmware.php",
                test_file => "ipw$_-*.fw",
            },
        };
    } (2100, 2200)),

    {
        name => "ipw3945",
        description => "Intel(R) PRO/Wireless 3945",
        url => "http://ipw3945.sourceforge.net/",
        firmware => {
            package => "ipw3945-ucode",
            test_file => "ipw3945.ucode",
        },
        tools => {
            package => "ipw3945d",
            test_file => '/usr/sbin/ipw3945d',
        },
    },

    (map {
        {
            name => "iwl${_}",
            description => "Intel(R) PRO/Wireless ${_}",
            url => "http://intellinuxwireless.org/",
            firmware => {
                package => "iwlwifi-${_}-ucode",
                test_file => "iwlwifi-${_}.ucode",
            },
            sleep => 1,
        };
    } (3945, 4965)),

    {
        name => 'prism54',
        description => 'Prism GT / Prism Duette / Prism Indigo Chipsets',
        url => 'http://prism54.org/',
        firmware => {
            url => 'http://prism54.org/~mcgrof/firmware/',
            test_file => "isl38*",
        },
    },

    {
        name => 'atmel',
        matching => [ qw(at76_usb atmel_cs atmel_pci) ],
        description => 'Atmel at76c50x cards',
        url => 'http://thekelleys.org.uk/atmel/',
        firmware => {
            test_file => 'atmel_at76c50*',
        },
        links => 'http://at76c503a.berlios.de/',
    },

    {
        name => 'madwifi',
        matching => 'ath_pci',
        description => 'Multiband Atheros Driver for WiFi',
        url => 'http://madwifi.org/',
        kernel_module => 1,
        tools => {
            optional => 1,
            test_file => '/usr/bin/athstats',
        },
    },

    {
        name => 'prism2',
        matching => qr/^prism2_/,
        description => 'Prism2 based cards',
        tools => {
            package => 'prism2-utils',
            test_file => '/sbin/wlanctl-ng',
        },
    },

    {
        name => 'zd1211',
        matching => 'zd1211rw',
        description => 'ZD1211 chip',
        firmware => {
            url => 'http://sourceforge.net/projects/zd1211/',
            test_file => 'zd1211/zd1211_*',
        },
    },

    {
        name => 'bcm43xx',
        description => 'Broadcom bcm43xx wireless chips',
        url => 'http://bcm43xx.berlios.de/',
        firmware => {
            test_file => 'bcm43xx_microcode*.fw',
            extract => {
                name => 'bcm43xx-fwcutter',
                test_file => '/usr/bin/bcm43xx-fwcutter',
                windows_source => 'bcmwl5.sys',
                default_source => 'bcmwl5.sys',
                run => sub {
                    my ($file) = @_;
                    run_program::rooted($::prefix, '/usr/bin/bcm43xx-fwcutter',
                                        '-w', $network::thirdparty::firmware_directory, $file);
                },
            },
        },
    },

    {
        name => 'acx100',
        matching => [ qw(acx_pci acx_usb) ],
        description => 'ACX100/ACX111/TNETW1450',
        firmware => {
            url => 'http://acx100.sourceforge.net/wiki/Firmware',
            test_file => 'tiacx1*',
            no_package => 1,
        },
    },

    {
        name => 'ndiswrapper',
        description => 'Wireless device using ndiswrapper (windows drivers)',
        tools => {
            test_file => '/usr/sbin/ndiswrapper',
        },
        firmware => {
            user_install => sub {
                my ($settings, $in) = @_;
                require network::ndiswrapper;
                $settings->{device} = network::ndiswrapper::select_device($in) or return;
                network::ndiswrapper::setup_device($in, $settings->{device});
                $settings->{device}{driver} = $settings->{name};
            },
            url => 'http://ndiswrapper.sourceforge.net/mediawiki/index.php/List',
            component_name => N_("Windows driver"),
            no_package => 1,
        },
        no_module_reload => 1,
    },

    {
        name => 'rt61',
        description => 'Ralink RT61 802.11abg WLAN',
        firmware => {
            url => 'http://rt2x00.serialmonkey.com/',
            test_file => 'rt2661.bin',
        },
    },

    {
        name => 'rt73',
        description => 'Ralink RT73 802.11abg WLAN',
        firmware => {
            url => 'http://rt2x00.serialmonkey.com/',
            test_file => 'rt73.bin',
        },
    },

);

sub get_packages { 'wireless-tools' }

sub get_thirdparty_settings() {
    \@thirdparty_settings;
}

sub setup_thirdparty {
    my ($self, $in) = @_;
    require network::rfswitch;
    network::rfswitch::configure();
    if ($self->get_driver eq 'ndiswrapper') {
        require network::ndiswrapper;
        my @devices = map { network::ndiswrapper::present_devices($_) } network::ndiswrapper::installed_drivers();
        return {} if member($self->{device}, @devices) && network::ndiswrapper::find_interface($self->{device});
    }
    my $thirdparty = $self->SUPER::setup_thirdparty($in);
    my $driver = $self->get_driver;
    if ($self->{thirdparty} && $driver eq 'ipw3945' && !$self->rf_killed && !$self->SUPER::check_device) {
        log::explanations("Reloading module $driver");
        eval { modules::unload($driver) };
        eval { modules::load($driver) };
    }
    $thirdparty;
}

sub rf_killed {
    my ($self) = @_;
    if ($self->{device}{sysfs_device}) {
        my $rf_kill_path = $self->{device}{sysfs_device} . "/rf_kill";
        if (-e $rf_kill_path) {
            my $rf_kill = chomp_(cat_($rf_kill_path));
            #- for ipw drivers, 0 means no RF kill switch
            return $rf_kill != 0;
        }
    }
    undef;
}

sub check_device {
    my ($self) = @_;
    if ($self->rf_killed) {
        $self->{device}{error} = N("Your wireless card is disabled, please enable the wireless switch (RF kill switch) first.");
        return 0;
    }
    return $self->SUPER::check_device;
}

sub load_interface_settings {
    my ($self) = @_;
    $self->SUPER::load_interface_settings;
}

sub get_networks {
    my ($self) = @_;
    require network::monitor;
    ($self->{networks}, $self->{control}{roaming}) = network::monitor::list_wireless(undef, $self->get_interface);
    $self->{networks};
}

sub guess_network {
    my ($_self) = @_;
    #- FIXME: try to find the AP matching $self->{ifcfg}{WIRELESS_ESSID};
}

sub get_network_ifcfg {
    my ($ssid) = @_;
    require network::network;
    my $file = $::prefix . $network::network::wireless_d . '/' . $ssid;
    -f $file && { getVarsFromSh($file) };
}

sub guess_network_access_settings {
    my ($self) = @_;

    my $ifcfg;
    my $network = $self->get_selected_network;
    $ifcfg = $network ?
      get_network_ifcfg($network->{ap}) || get_network_ifcfg($network->{essid}) :
      $self->{ifcfg};
    $ifcfg ||= {};

    $self->{access}{network}{essid} = $network && $network->{essid} || $ifcfg->{WIRELESS_ESSID} || !$network && "any";
    ($self->{access}{network}{key}, my $restricted) = get_wep_key_from_iwconfig($ifcfg->{WIRELESS_ENC_KEY});
    $self->{access}{network}{encryption} =
      $network && $network->{flags} =~ /eap/i ?
        'wpa-eap' :
      $network && $network->{flags} =~ /wpa/i ?
        'wpa-psk' :
      $network && $network->{flags} =~ /wep/i || $self->{access}{network}{key} ?
        ($restricted ? 'restricted' : 'open') :
        'none';

    undef $self->{ifcfg}{WIRELESS_IWPRIV} if is_old_rt2x00($self->get_driver) && $self->{ifcfg}{WIRELESS_IWPRIV} =~ /WPAPSK/;

    $self->{control}{roaming} = exists $self->{ifcfg}{WIRELESS_WPA_DRIVER} && !is_old_rt2x00($self->get_driver);

    $self->{access}{network}{mode} =
        $network && $network->{mode} ||
        $ifcfg->{WIRELESS_MODE} ||
        'Managed';

    wpa_supplicant_load_eap_settings($self->{access}{network}) if $self->need_wpa_supplicant;
}

sub get_network_access_settings_label { N("Wireless settings") }

sub get_network_access_settings {
    my ($self) = @_;
    [
        { label => N("Operating Mode"), val => \$self->{access}{network}{mode},
          list => [ N_("Ad-hoc"), N_("Managed"), N_("Master"), N_("Repeater"), N_("Secondary"), N_("Auto") ],
          format => \&translate,
        },
        { label => N("Network name (ESSID)"), val => \$self->{access}{network}{essid},
          disabled => sub { my $network = $self->get_selected_network; $network && $network->{essid} } },
        { label => N("Encryption mode"), val => \$self->{access}{network}{encryption}, list => [ keys %wireless_enc_modes ],
          sort => 1, format => sub { translate($wireless_enc_modes{$_[0]}) } },
        { label => N("Encryption key"), val => \$self->{access}{network}{key},
          disabled => sub { member($self->{access}{network}{encryption}, qw(none wpa-eap)) } },
        { label => N("EAP Login/Username"), val => \$self->{access}{network}{eap_identity},
          disabled => sub { $self->{access}{network}{encryption} ne 'wpa-eap' },
	  help => N("The login or username. Format is plain text. If you
need to specify domain then try the untested syntax
  DOMAIN\\username") },
        { label => N("EAP Password"), val => \$self->{access}{network}{eap_password},
          disabled => sub { $self->{access}{network}{encryption} ne 'wpa-eap' },
	  help => N(" Password: A string.
Note that this is not the same thing as a psk.
____________________________________________________
RELATED ADDITIONAL INFORMATION:
In the Advanced Page, you can select which EAP mode
is used for authentication. For the eap mode setting
   Auto Detect: implies all possible modes are tried.

If Auto Detect fails, try the PEAP TTLS combo bofore others
Note:
	The settings MD5, MSCHAPV2, OTP and GTC imply
automatically PEAP and TTLS modes.
  TLS mode is completely certificate based and may ignore
the username and password values specified here.") },
        { label => N("EAP client certificate"), val => \$self->{access}{network}{eap_client_cert},
          disabled => sub { $self->{access}{network}{encryption} ne 'wpa-eap' },
          help => N("The complete path and filename of client certificate. This is
only used for EAP certificate based authentication. It could be
considered as the alternative to username/password combo.
 Note: other related settings are shown on the Advanced page.")  },
        { label => N("Network ID"), val => \$self->{ifcfg}{WIRELESS_NWID}, advanced => 1 },
        { label => N("Operating frequency"), val => \$self->{ifcfg}{WIRELESS_FREQ}, advanced => 1 },
        { label => N("Sensitivity threshold"), val => \$self->{ifcfg}{WIRELESS_SENS}, advanced => 1 },
        { label => N("Bitrate (in b/s)"), val => \$self->{ifcfg}{WIRELESS_RATE}, advanced => 1 },
        { label => N("RTS/CTS"), val => \$self->{ifcfg}{WIRELESS_RTS}, advanced => 1,
          help => N("RTS/CTS adds a handshake before each packet transmission to make sure that the
channel is clear. This adds overhead, but increase performance in case of hidden
nodes or large number of active nodes. This parameter sets the size of the
smallest packet for which the node sends RTS, a value equal to the maximum
packet size disable the scheme. You may also set this parameter to auto, fixed
or off.")
      },
        { label => N("Fragmentation"), val => \$self->{ifcfg}{WIRELESS_FRAG}, advanced => 1 },
        { label => N("iwconfig command extra arguments"), val => \$self->{ifcfg}{WIRELESS_IWCONFIG}, advanced => 1,
          help => N("Here, one can configure some extra wireless parameters such as:
ap, channel, commit, enc, power, retry, sens, txpower (nick is already set as the hostname).

See iwconfig(8) man page for further information."),
      },
        { label =>
            #-PO: split the "xyz command extra argument" translated string into two lines if it's bigger than the english one
            N("iwspy command extra arguments"), val => \$self->{ifcfg}{WIRELESS_IWSPY}, advanced => 1,
          help => N("iwspy is used to set a list of addresses in a wireless network
interface and to read back quality of link information for each of those.

This information is the same as the one available in /proc/net/wireless :
quality of the link, signal strength and noise level.

See iwpspy(8) man page for further information."),
 },
        { label => N("iwpriv command extra arguments"), val => \$self->{ifcfg}{WIRELESS_IWPRIV}, advanced => 1,
          disabled => sub { $self->need_rt2x00_iwpriv },
          help => N("iwpriv enable to set up optionals (private) parameters of a wireless network
interface.

iwpriv deals with parameters and setting specific to each driver (as opposed to
iwconfig which deals with generic ones).

In theory, the documentation of each device driver should indicate how to use
those interface specific commands and their effect.

See iwpriv(8) man page for further information."),
          },
        { label => N("EAP Protocol"), val => \$self->{access}{network}{forceeap},
          list => [ N_("Auto Detect"), N_("WPA2"), N_("WPA") ],
          sort => 1, format => \&translate, advanced => 1,
	  help => N("Auto Detect is recommended as it first tries WPA version 2 with
a fallback to WPA version 1") },
        { label => N("EAP Mode"), val => \$self->{access}{network}{eap_eap},
          list => [ N_("Auto Detect"), N_("PEAP"), N_("TTLS"), N_("TLS"), N_("MSCHAPV2"), N_("MD5"), N_("OTP"), N_("GTC"), N_("LEAP") , N_("PEAP TTLS"), N_("TTLS TLS") ],
          sort => 1, format => \&translate, advanced => 1, },
        { label => N("EAP key_mgmt"), val => \$self->{access}{network}{eap_key_mgmt}, advanced => 1,
          disabled => sub { $self->{access}{network}{encryption} ne 'wpa-eap' },
          help => N("list of accepted authenticated key management protocols.
possible values are WPA-EAP, IEEE8021X, NONE") },
        { label => N("EAP outer identity"), val => \$self->{access}{network}{eap_anonymous_identity}, advanced => 1,
          disabled => sub { $self->{access}{network}{encryption} ne 'wpa-eap' },
          help => N("Anonymous identity string for EAP: to be used as the
unencrypted identity with EAP types that support different
tunnelled identity, e.g., TTLS") },
        { label => N("EAP phase2"), val => \$self->{access}{network}{eap_phase2}, advanced => 1,
          disabled => sub { $self->{access}{network}{encryption} ne 'wpa-eap' } ,
          help => N("Inner authentication with TLS tunnel parameters.
input is string with field-value pairs, Examples:
auth=MSCHAPV2 for PEAP or
autheap=MSCHAPV2 autheap=MD5 for TTLS") },
        { label => N("EAP CA certificate"), val => \$self->{access}{network}{eap_ca_cert}, advanced => 1,
          disabled => sub { $self->{access}{network}{encryption} ne 'wpa-eap' },
          help => N("Full file path to CA certificate file (PEM/DER). This file
can have one or more trusted CA certificates. If ca_cert are not
included, server certificate will not be verified. If possible,
a trusted CA certificate should always be configured
when using TLS or TTLS or PEAP.") },
        { label => N("EAP certificate subject match"), val => \$self->{access}{network}{eap_subject_match}, advanced => 1,
          disabled => sub { $self->{access}{network}{encryption} ne 'wpa-eap' },
          help => N(" Substring to be matched against the subject of
the authentication server certificate. If this string is set,
the server sertificate is only accepted if it contains this
string in the subject.  The subject string is in following format:
/C=US/ST=CA/L=San Francisco/CN=Test AS/emailAddress=as\@example.com") },
        { label => N("EAP extra directives"), val => \$self->{access}{network}{eapextra}, advanced => 1,
          disabled => sub { $self->{access}{network}{encryption} ne 'wpa-eap' },
          help => N("Here one can pass extra settings to wpa_supplicant
The expected format is a string field=value pair. Multiple values
maybe specified, separating each value with the # character.
Note: directives are passed unchecked and may cause the wpa
negotiation to fail silently. Supported directives are preserved
across editing.
Supported directives are :
	disabled, id_str, bssid, priority, auth_alg, eapol_flags,
	proactive_key_caching, peerkey, ca_path, private_key,
	private_key_passwd, dh_file, altsubject_match, phase1,
	fragment_size and eap_workaround, pairwise, group
	Others such as key_mgmt, eap maybe used to force
	special settings different from the U.I settings.") },
    ];
}

sub check_network_access_settings {
    my ($self) = @_;

    if (!member($self->{access}{network}{encryption}, qw(none wpa-eap)) && !$self->{access}{network}{key}) {
        $self->{network_access}{error}{message} = N("An encryption key is required.");
        $self->{network_access}{error}{field} =  \$self->{access}{network}{key};
        return 0;
    }

    if ($self->{ifcfg}{WIRELESS_FREQ} && $self->{ifcfg}{WIRELESS_FREQ} !~ /[0-9.]*[kGM]/) {
        $self->{network_access}{error}{message} = N("Freq should have the suffix k, M or G (for example, \"2.46G\" for 2.46 GHz frequency), or add enough '0' (zeroes).");
        $self->{network_access}{error}{field} = \$self->{ifcfg}{WIRELESS_FREQ};
        return 0;
    }

    if ($self->{ifcfg}{WIRELESS_RATE} && $self->{ifcfg}{WIRELESS_RATE} !~ /[0-9.]*[kGM]/) {
        $self->{network_access}{error}{message} = N("Rate should have the suffix k, M or G (for example, \"11M\" for 11M), or add enough '0' (zeroes).");
        $self->{network_access}{error}{field} = \$self->{ifcfg}{WIRELESS_RATE};
        return 0;
    }

    return 1;
}

sub get_control_settings {
    my ($self) = @_;
    [
        @{$self->SUPER::get_control_settings},
        { text => N("Allow access point roaming"), val => \$self->{control}{roaming}, type => "bool",
          disabled => sub { is_wpa_supplicant_blacklisted($self->get_driver) } },
    ];
}

sub need_wpa_supplicant {
    my ($self) = @_;
    ($self->{control}{roaming} || $self->{access}{network}{encryption} =~ /^wpa-/) && !is_old_rt2x00($self->get_driver);
}

sub install_packages {
    my ($self, $in) = @_;
    if ($self->need_wpa_supplicant) {
        $in->do_pkgs->ensure_is_installed('wpa_supplicant', '/usr/sbin/wpa_supplicant') or return;
    }
    $self->SUPER::install_packages($in);
}


sub build_ifcfg_settings {
    my ($self) = @_;
    my $settings = {
        WIRELESS_MODE => $self->{access}{network}{mode},
        if_($self->need_wpa_supplicant,
            WIRELESS_WPA_DRIVER => wpa_supplicant_get_driver($self->get_driver),
            MII_NOT_SUPPORTED => 'no',
        ),
        WIRELESS_ESSID => $self->{access}{network}{essid},
        if_($self->{access}{network}{encryption} ne 'none',
            WIRELESS_ENC_KEY => convert_wep_key_for_iwconfig($self->{access}{network}{key}, $self->{access}{network}{encryption} eq 'restricted')),
        if_($self->need_rt2x00_iwpriv,
            #- use iwpriv for WPA with rt2400/rt2500 drivers, they don't plan to support wpa_supplicant
            WIRELESS_IWPRIV => qq(set AuthMode=WPAPSK
set EncrypType=TKIP
set SSID=$self->{access}{network}{essid}
set WPAPSK="$self->{access}{network}{key}"
set TxRate=0)),
        (map { $_ => $self->{ifcfg}{$_} }
           qw(WIRELESS_NWID WIRELESS_FREQ WIRELESS_SENS WIRELESS_RATE WIRELESS_RTS WIRELESS_FRAG WIRELESS_IWCONFIG WIRELESS_IWSPY), if_(!$self->need_rt2x00_iwpriv, 'WIRELESS_IWPRIV')),
    };
    $self->SUPER::build_ifcfg_settings($settings);
}

sub write_settings {
    my ($self, $o_net, $o_modules_conf) = @_;

    if ($self->need_wpa_supplicant) {
	if ($self->{access}{network}{encryption} eq 'wpa-eap') {
            wpa_supplicant_add_eap_network($self->{access}{network});
	} else {
            wpa_supplicant_add_network($self->{access}{network}{essid}, $self->{access}{network}{encryption}, $self->{access}{network}{key}, $self->{access}{network}{mode});
	}
    }

    wlan_ng_configure($self->{access}{network}{essid}, $self->{access}{network}{key}, $self->get_interface, $self->get_driver) if $self->{thirdparty}{name} eq 'prism2';

    my $network = $self->get_selected_network;
    network::network::write_wireless_conf($_, $self->build_ifcfg_settings) foreach
        grep { $_ } ($network ? $network->{ap} : ()), $self->{access}{network}{essid};

    $self->SUPER::write_settings($o_net, $o_modules_conf);
}

sub network_is_configured {
    my ($self, $network) = @_;
    if ($self->{control}{roaming}) {
        return defined $network->{id};
    } else {
        my $wireless_ifcfg = get_network_ifcfg($network->{ap}) || defined $network->{essid} && get_network_ifcfg($network->{essid});
        return $wireless_ifcfg;
    }
}

sub prepare_connection {
    my ($self) = @_;
    if ($self->{control}{roaming}) {
        #- this should be handled by the monitoring daemon instead
        run_program::run('/usr/sbin/wpa_cli', 'reconfigure');
        sleep 2;
    }
}

sub connect {
    my ($self, $_in, $net) = @_;

    $self->SUPER::connect;

    if ($self->{control}{roaming}) {
        my $network = $self->get_selected_network;
        if ($network && defined $network->{id}) {
            eval { $net->{monitor}->select_network($network->{id}) };
            return !$@;
        }
    }
}

sub get_status_message {
    my ($self, $status) = @_;
    my $interface = $self->get_interface;
    my ($current_essid, $current_ap) = get_access_point($interface);
    my $network = $current_essid || $current_ap && "[$current_ap]";
    {
        link_up => N("Associated to wireless network \"%s\" on interface %s", $network, $interface),
        link_down => N("Lost association to wireless network on interface %s", $interface),
    }->{$status} || $self->SUPER::get_status_message($status);
}



my $wpa_supplicant_conf = "/etc/wpa_supplicant.conf";

sub get_access_point {
    my ($intf) = @_;
    (chomp_(`/sbin/iwgetid -r $intf 2>/dev/null`), lc(chomp_(`/sbin/iwgetid -r -a $intf 2>/dev/null`)));
}

sub is_old_rt2x00 {
    my ($module) = @_;
    member($module, qw(rt2400 rt2500 rt2570 rt61 rt73));
}

sub is_wpa_supplicant_blacklisted {
    my ($module) = @_;
    is_old_rt2x00($module);
}

sub need_rt2x00_iwpriv {
    my ($self) = @_;
    is_old_rt2x00($self->get_driver) && $self->{access}{network}{encryption} eq 'wpa-psk';
}

sub get_hex_key {
    my ($key) = @_;
    if ($key =~ /^([[:xdigit:]]{4}[\:-]?)+[[:xdigit:]]{2,}$/) {
        $key =~ s/[\:-]//g;
        return lc($key);
    }
}

sub convert_wep_key_for_iwconfig {
    #- 5 or 13 characters, consider the key as ASCII and prepend "s:"
    #- else consider the key as hexadecimal, do not strip dashes
    #- always quote the key as string
    my ($real_key, $restricted) = @_;
    my $key = get_hex_key($real_key) || "s:$real_key";
    $restricted ? "restricted $key" : "open $key";
}

sub convert_wep_key_for_wpa_supplicant {
    my ($key) = @_;
    get_hex_key($key) || qq("$key");
}

sub get_wep_key_from_iwconfig {
    #- strip "s:" if the key is 5 or 13 characters (ASCII)
    #- else the key as hexadecimal, do not modify
    my ($key) = @_;
    my ($mode, $real_key) = $key =~ /^(?:(open|restricted)\s+)?(.*)$/;
    $real_key =~ s/^s://;
    ($real_key, $mode eq 'restricted');
}

sub convert_key_for_wpa_supplicant {
    my ($key) = @_;
    length($key) == 64 && get_hex_key($key) || qq("$key");
}

#- FIXME: to be improved (quotes, comments) and moved in common files
sub wlan_ng_update_vars {
    my ($file, $vars) = @_;
    substInFile {
        while (my ($key, $value) = each(%$vars)) {
            s/^#?\Q$key\E=(?:"[^#]*"|[^#\s]*)(\s*#.*)?/$key=$value$1/ and delete $vars->{$key};
        }
        $_ .= join('', map { "$_=$vars->{$_}\n" } keys %$vars) if eof;
    } $file;
}

sub wlan_ng_configure {
    my ($essid, $key, $device, $module) = @_;
    my $wlan_conf_file = "$::prefix/etc/wlan/wlan.conf";
    my @wlan_devices = split(/ /, (cat_($wlan_conf_file) =~ /^WLAN_DEVICES="(.*)"/m)[0]);
    push @wlan_devices, $device unless member($device, @wlan_devices);
    #- enable device and make it use the choosen ESSID
    wlan_ng_update_vars($wlan_conf_file,
                        {
                            WLAN_DEVICES => qq("@wlan_devices"),
                            "SSID_$device" => qq("$essid"),
                            "ENABLE_$device" => "y"
                        });

    my $wlan_ssid_file = "$::prefix/etc/wlan/wlancfg-$essid";
    #- copy default settings for this ESSID if config file does not exist
    -f $wlan_ssid_file or cp_f("$::prefix/etc/wlan/wlancfg-DEFAULT", $wlan_ssid_file);

    #- enable/disable encryption
    wlan_ng_update_vars($wlan_ssid_file,
                        {
                            (map { $_ => $key ? "true" : "false" } qw(lnxreq_hostWEPEncrypt lnxreq_hostWEPDecrypt dot11PrivacyInvoked dot11ExcludeUnencrypted)),
                            AuthType => $key ? qq("sharedkey") : qq("opensystem"),
                            if_($key,
                                dot11WEPDefaultKeyID => 0,
                                dot11WEPDefaultKey0 => qq("$key")
                            )
                        });
    #- hide settings for non-root users
    chmod 0600, $wlan_conf_file;
    chmod 0600, $wlan_ssid_file;

    #- apply settings on wlan interface
    require services;
    services::restart($module eq 'prism2_cs' ? 'pcmcia' : 'wlan');
}

sub wpa_supplicant_get_driver {
    my ($module) = @_;
    $module =~ /^hostap_/ ? "hostap" :
    $module eq "prism54" ? "prism54" :
    $module =~ /^ath_/ ? "madwifi" :
    $module =~ /^at76c50|atmel_/ ? "atmel" :
    "wext";
}

sub wpa_supplicant_add_network {
    my ($essid, $enc_mode, $key, $mode) = @_;
    my $conf = wpa_supplicant_read_conf();
    my $network = {
        ssid => qq("$essid"),
        scan_ssid => 1,
    };

    if ($enc_mode eq 'wpa-psk') {
        $network->{psk} = convert_key_for_wpa_supplicant($key);
    } else {
        $network->{key_mgmt} = 'NONE';
        $network->{mode} = to_bool($mode eq 'Ad-Hoc');
        if (member($enc_mode, qw(open restricted))) {
            put_in_hash($network, {
                wep_key0 => convert_wep_key_for_wpa_supplicant($key),
                wep_tx_keyidx => 0,
                auth_alg => $enc_mode eq 'restricted' ? 'SHARED' : 'OPEN',
            });
        }
    }

    @$conf = difference2($conf, [ wpa_supplicant_find_similar($conf, $network) ]);
    push @$conf, $network;
    wpa_supplicant_write_conf($conf);
}

sub wpa_supplicant_find_similar {
    my ($conf, $network) = @_;
    grep {
        my $current = $_;
        any { exists $network->{$_} && $network->{$_} eq $current->{$_} } qw(ssid bssid);
    } @$conf;
}

sub wpa_supplicant_read_conf() {
    my @conf;
    my $network;
    foreach (cat_($::prefix . $wpa_supplicant_conf)) {
        if ($network) {
            #- in a "network = {}" block
            if (/^\s*(\w+)=(.*?)(?:\s*#.*)?$/) {
                $network->{$1} = $2;
            } elsif (/^\}/) {
                #- end of network block
                push @conf, $network;
                undef $network;
            }
        } elsif (/^\s*network={/) {
            #- beginning of a new network block
            $network = {};
        }
    }
    \@conf;
}

sub wpa_supplicant_write_conf {
    my ($conf) = @_;
    my $buf;
    my @conf = @$conf;
    my $network;
    foreach (cat_($::prefix . $wpa_supplicant_conf)) {
        if ($network) {
            #- in a "network = {}" block
            if (/^\s*(\w+)=(.*)$/) {
                push @{$network->{entries}}, { key => $1, value => $2 };
                member($1, qw(ssid bssid)) and $network->{$1} = $2;
            } elsif (/^\}/) {
                #- end of network block, write it
                $buf .= "network={$network->{comment}\n";

                my $new_network = first(wpa_supplicant_find_similar(\@conf, $network));
                foreach (@{$network->{entries}}) {
                    my $key = $_->{key};
                    if ($new_network) {
                        #- do not write entry if not provided in the new network
                        exists $new_network->{$key} or next;
                        #- update value from the new network
                        $_->{value} = delete $new_network->{$key};
                    }
                    $buf .= "    ";
                    $buf .= "$key=$_->{value}" if $key;
                    $buf .= "$_->{comment}\n";
                }
                if ($new_network) {
                    #- write new keys
                    while (my ($key, $value) = each(%$new_network)) {
                        $buf .= "    $key=$value\n";
                    }
                }
                $buf .= "}\n";
                $new_network and @conf = grep { $_ != $new_network } @conf;
                undef $network;
            } else {
                #- unrecognized, keep it anyway
                push @{$network->{entries}}, { comment => $_ };
            }
        } else {
            if (/^\s*network={/) {
                #- beginning of a new network block
                $network = {};
            } else {
                #- keep other options, comments
                $buf .= $_;
            }
        }
    }

    #- write remaining networks
    foreach (@conf) {
        $buf .= "\nnetwork={\n";
        while (my ($key, $value) = each(%$_)) {
            $buf .= "    $key=$value\n";
        }
        $buf .= "}\n";
    }

    output($::prefix . $wpa_supplicant_conf, $buf);
    #- hide keys for non-root users
    chmod 0600, $::prefix . $wpa_supplicant_conf;
}

sub wpa_supplicant_load_eap_settings {
    my ($network) = @_;
    my $quoted_essid = qq("$network->{essid}");
    my $conf = wpa_supplicant_read_conf();
    foreach my $old_net (@$conf) {
	if ($old_net->{ssid} eq $network->{essid} || $old_net->{ssid} eq $quoted_essid) {
            $network->{eapextra} = '';
            foreach my $eap_var (keys %eap_vars) {
                next if $eap_var eq 'ssid';
                my $ui_var = join('_', "eap", $eap_var);
                if (defined $old_net->{$eap_var}) {
                    if ($eap_vars{$eap_var} == 0) {
                        if ($network->{eapextra} eq "") {
                            $network->{eapextra} = "$eap_var=$old_net->{$eap_var}";
                        } else {
                            $network->{eapextra} = join('#', $network->{eapextra}, "$eap_var=$old_net->{$eap_var}");
                        }
                    } else {
                        $network->{$ui_var} = $old_net->{$eap_var};
                        #- remove quotes on selected variables
                        $network->{$ui_var} = $1 if $eap_vars{$eap_var} == 2 && $network->{$ui_var} =~ /^"(.*)"$/;
                        if ($eap_var eq "proto") {
                            $network->{forceeap} = 'WPA2' if $old_net->{$eap_var} eq "RSN";
                            $network->{forceeap} = 'WPA' if $old_net->{$eap_var} eq "WPA";
                        }
                    }
                }
            }
            last;
	}
    }
}

sub wpa_supplicant_add_eap_network {
    my ($ui_input) = @_;

    #- expect all variables for us to be prefixed with eap_
    my $conf = wpa_supplicant_read_conf();
    my $default_eap_cfg = {
        pairwise => 'CCMP TKIP',
        group => 'CCMP TKIP',
        proto => 'RSN WPA',
        key_mgmt => 'WPA-EAP IEEE8021X NONE',
        scan_ssid => 1,
    };
    if ($ui_input->{forceeap} eq 'WPA') {
        #- WPA only
        $default_eap_cfg->{pairwise} = 'TKIP';
        $default_eap_cfg->{group} = 'TKIP';
        $default_eap_cfg->{proto} = 'WPA';
    } elsif ($ui_input->{forceeap} eq 'WPA2') {
        #- WPA2 only
        $default_eap_cfg->{pairwise} = 'CCMP TKIP';
        $default_eap_cfg->{group} = 'CCMP TKIP';
        $default_eap_cfg->{proto} = 'RSN';
    }
    my $network = { ssid => qq("$ui_input->{essid}") };
    #- set the values
    foreach my $eap_var (keys %eap_vars) {
        my $key = join('_', "eap", $eap_var);
        if (!defined $ui_input->{$key} || $ui_input->{$key} =~ /auto detect/i) {
            $network->{$eap_var} = $default_eap_cfg->{$eap_var} if $default_eap_cfg->{$eap_var};
        } else {
            #- do not define if blank, the save routine will delete entry from file
            next if !$ui_input->{$key};
            $network->{$eap_var} = $eap_vars{$eap_var} == 2 ? qq("$ui_input->{$key}") : $ui_input->{$key};
        }
    }
    #- handle eapextra as final overides
    if (defined $ui_input->{eapextra} && $ui_input->{eapextra} ne "") {
        #- FIXME: should split it on what the # sign?
        foreach my $eap_var (split('#', $ui_input->{eapextra})) {
            my ($key, $val) = split('=', $eap_var, 2);
            $network->{$key} = $val;
        }
    }
    $network->{mode} = to_bool($ui_input->{mode} eq 'Ad-Hoc');

    @$conf = difference2($conf, [ wpa_supplicant_find_similar($conf, $network) ]);
    push @$conf, $network;
    wpa_supplicant_write_conf($conf);
}
1;
