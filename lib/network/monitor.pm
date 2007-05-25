package network::monitor;

use common;
use dbus_object;

our @ISA = qw(dbus_object);

sub new {
    my ($type, $bus) = @_;
    dbus_object::new($type,
		       $bus,
		       "com.mandriva.monitoring",
		       "/com/mandriva/monitoring/wireless",
		       "com.mandriva.monitoring.wireless");
}

sub list_wireless {
    my ($monitor, $o_intf) = @_;
    my ($results, $list, %networks);
    #- first try to use mandi
    eval {
        $results = $monitor->call_method('ScanResults');
        $list = $monitor->call_method('ListNetworks');
    };
    my $has_roaming = defined $results && defined $list;
    #- try wpa_cli if we're root
    if ($@ && !$>) {
        $results = `/usr/sbin/wpa_cli scan_results 2>/dev/null`;
        $list = `/usr/sbin/wpa_cli list_networks 2>/dev/null`;
    }
    if ($results && $list) {
        #- bssid / frequency / signal level / flags / ssid
        while ($results =~ /^((?:[0-9a-f]{2}:){5}[0-9a-f]{2})\t(\d+)\t(\d+)\t(.*?)\t(.*)$/mg) {
            my ($ap, $frequency, $signal_strength, $flags, $essid) = ($1, $2, $3, $4, $5);
            $networks{$ap}{ap} ||= $ap;
            #- wpa_supplicant may list the network two times, use ||=
            $networks{$ap}{frequency} ||= $frequency;
            #- signal level is really too high in wpa_supplicant
            #- this should be standardized at some point
            $networks{$ap}{signal_strength} ||= int($signal_strength/3.5);
            my $adhoc = $flags =~ s/\[ibss\]//i;
            $networks{$ap}{mode} ||=  $adhoc ? "Ad-Hoc" : "Managed";
            $networks{$ap}{flags} ||= $flags;
            $networks{$ap}{essid} ||= $essid;
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
        if ($o_intf && !$> && !`/sbin/ip link show $o_intf up`) {
            system("/sbin/ip link set $o_intf up");
        }
        my @list = `/sbin/iwlist $o_intf scanning 2>/dev/null`;
        my $net = {};
        my $quality_match = qr/Quality[:=](\S*)/;
        my $eval_quality = sub {
            my ($qual) = @_;
            $qual =~ m!/! ? eval($qual)*100 : $qual;
        };
	foreach (@list) {
            if ((/^\s*$/ || /Cell/) && exists $net->{ap}) {
                $net->{current} = to_bool($net->{essid} && $net->{essid} eq $current_essid || $net->{ap} eq $current_ap);
                $networks{$net->{ap}} = $net;
                $net = {};
            }
            /Address: (.*)/ and $net->{ap} = lc($1);
            /ESSID:"(.*?)"/ and $net->{essid} = $1;
            /Mode:(\S*)/ and $net->{mode} = $1;
            $_ =~ $quality_match and $net->{signal_strength} = $eval_quality->($1);
            m|Signal level:([0-9]+/[0-9]+)| && !$net->{signal_strength} and $net->{signal_strength} = eval($1)*100;
            /Extra:wpa_ie=|IE:.*WPA/ and $net->{flags} = '[WPA]';
            /key:(\S*)\s/ and $net->{flags} ||= $1 eq 'on' && '[WEP]';
	}
        if ($current_ap && exists $networks{$current_ap}) {
            foreach (`/sbin/iwconfig $o_intf 2>/dev/null`) {
                my $quality = $_ =~ $quality_match && $eval_quality->($1);
                $networks{$current_ap}{signal_strength} = $quality if $quality;
            }
        }
    }

    foreach (values %networks) {
        $_->{essid} eq '<hidden>' and undef $_->{essid};
        $_->{name} = $_->{essid} || "[$_->{ap}]";
    }
    (\%networks, $has_roaming);
}

sub select_network {
    my ($o, $id) = @_;
    $o->call_method('SelectNetwork', Net::DBus::dbus_uint32($id));
}

1;
