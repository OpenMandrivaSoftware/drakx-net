package network::monitor;

use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;
use dbus_object;

our @ISA = qw(dbus_object);

my $monitor_service = "com.mandriva.monitoring";
my $monitor_path = "/com/mandriva/monitoring/wireless";
my $monitor_interface = "com.mandriva.monitoring.wireless";

sub new {
    my ($type, $bus) = @_;
    dbus_object::new($type, $bus, $monitor_service, $monitor_path, $monitor_interface);
}

sub list_wireless {
    my ($monitor, $o_intf) = @_;
    my ($results, $list, %networks);
    my $has_roaming;
    #- first try to use mandi
    eval {
        $results = $monitor->call_method('ScanResults');
        $list = $monitor->call_method('ListNetworks');
        $has_roaming = 1;
    } if $monitor;
    #- try wpa_cli if we're root
    if (!$has_roaming && !$>) {
        $results = `$::prefix/usr/sbin/wpa_cli scan_results 2>/dev/null`;
        $list = `$::prefix/usr/sbin/wpa_cli list_networks 2>/dev/null`;
        s/^Selected interface (.*)\n//g foreach $results, $list;
    }
    if ($results && $list) {
        #- bssid / frequency / signal level / flags / ssid
        while ($results =~ /^((?:[0-9a-f]{2}:){5}[0-9a-f]{2})\t(\d+)\t(-?\d+)\t(.*?)\t(.*)$/mg) {
            my ($ap, $frequency, $signal_strength, $flags, $essid) = ($1, $2, $3, $4, $5);
            $networks{$ap}{ap} ||= $ap;
            #- wpa_supplicant may list the network two times, use ||=
            $networks{$ap}{frequency} ||= $frequency;
            $networks{$ap}{signal_strength} ||= $signal_strength;
            my $adhoc = $flags =~ s/\[ibss\]//i;
            $networks{$ap}{mode} ||=  $adhoc ? "Ad-Hoc" : "Managed";
            $networks{$ap}{flags} ||= $flags;
            $networks{$ap}{essid} ||= $essid;
        }
        if (any { $_->{signal_strength} > 100 } values %networks) {
            #- signal level is really too high in wpa_supplicant
            #- this should be standardized at some point
            $_->{signal_strength} = int($_->{signal_strength}/3.5)
              foreach values %networks;
        } 
# TODO - Check if all drivers now report signal	strength in dBm
	if (any { $_->{signal_strength} < 0 } values %networks) {
	    #- wpa_supplicant now reports signal in dBm
            #- convert to % scale assuming -45 =100% -98 = 1%
	    foreach (values %networks) {
            	$_->{signal_strength} = int(100*(98+$_->{signal_strength})/53);
                $_->{signal_strength} = 100 if $_->{signal_strength} > 100;
                $_->{signal_strength} = 1 if $_->{signal_strength} < 1;
	    }
        }


        #- network id / ssid / bssid / flags
        while ($list =~ /^(\d+)\t(.*?)\t(.*?)\t(.*)$/mg) {
            foreach my $net (uniq(if_($networks{$3}, $networks{$3}), grep { $_->{essid} eq $2 } values(%networks))) {
                $net->{ap} = $3 if $3 ne 'any';
                $net->{id} = $1;
                $net->{essid} ||= $2;
                $net->{current} = to_bool($4 eq '[CURRENT]');
            }
        }
    } else {
        #- else use iwlist
        require network::connection::wireless;
        my ($current_essid, $current_ap) = network::connection::wireless::get_access_point($o_intf);
        if ($o_intf && !$> && !`$::prefix/sbin/ip link show $o_intf up`) {
            system("$::prefix/sbin/ip link set $o_intf up");
        }
        my @list = `$::prefix/sbin/iwlist $o_intf scanning 2>/dev/null`;
        my $net = {};
        my $quality_match = qr/Quality[:=](\S*)/;
        my $eval_quality = sub {
            my ($qual) = @_;
            $qual =~ s!/0+$!/255!; #- prism54 reports quality with division by zero
            $qual =~ m!/! ? eval($qual)*100 : $qual;
        };
        my ($has_key, $has_wpa, $has_eap);
        foreach (@list) {
            if ((/^\s*$/ || /Cell/) && exists $net->{ap}) {
                $net->{current} = to_bool($net->{ap} ? $net->{ap} eq $current_ap : $net->{essid} && $net->{essid} eq $current_essid);
                $net->{flags} = $has_wpa ? '[WPA]' : $has_key ? '[WEP]' : '';
                $net->{flags} .= '[EAP]' if $has_eap;
                $networks{$net->{ap}} = $net;
                $net = {};
                $has_key = $has_wpa = $has_eap = undef;
            }
            /Address: (.*)/ and $net->{ap} = lc($1);
            /ESSID:"(.*?)"/ and $net->{essid} = $1;
            /Mode:(\S*)/ and $net->{mode} = $1;
            $net->{mode} = 'Managed' if $net->{mode} eq 'Master';
            $_ =~ $quality_match and $net->{signal_strength} = $eval_quality->($1);
            m|Signal level[:=]([0-9]+/[0-9]+)| and $net->{signal_level} = $eval_quality->($1);
            /key:(\S*)\s/ && $1 eq 'on' and $has_key = 1;
            /Extra:wpa_ie=|IE:.*WPA/ and $has_wpa = 1;
            /Authentication Suites \(\d+\) :.*\b802\.1x\b/ and $has_eap = 1;
        }
        my $incorrect_quality =
          (every { $_->{signal_strength} == 100 } values %networks) &&
          (any { $_->{signal_strength} != $_->{signal_level} } values %networks);
        foreach (values %networks) {
            my $level = delete $_->{signal_level};
            $_->{signal_strength} ||= $level;
            $_->{signal_strength} = $level if $incorrect_quality;
        }
        if ($current_ap && exists $networks{$current_ap}) {
            foreach (`$::prefix/sbin/iwconfig $o_intf 2>/dev/null`) {
                my $quality = $_ =~ $quality_match && $eval_quality->($1);
                $networks{$current_ap}{signal_strength} = $quality if $quality;
            }
        }
    }

    foreach (values %networks) {
        $_->{hidden} = member($_->{essid}, '', '<hidden>');
        $_->{essid} eq '<hidden>' and undef $_->{essid};
        $_->{name} = $_->{essid} || "[$_->{ap}]";
    }
    (\%networks, $has_roaming);
}

sub select_network {
    my ($o, $id) = @_;
    my $method = 'SelectNetwork';
    if ($o) {
        $o->call_method($method, Net::DBus::dbus_uint32($id));
    } else {
        require run_program;
        run_program::run("dbus-send", "--system", "--type=method_call",
                         "--dest=" . $monitor_service,
                         $monitor_path,
                         $monitor_interface . '.' . $method,
                         'uint32:' . $id);
    }
}

1;
