package network::ifw;

use Socket;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;

our @ISA = qw(dbus_object);

sub init {
    my ($bus, $filter) = @_;
    my $con = $bus->{connection};
    $con->add_filter($filter);
    $con->add_match("type='signal',interface='org.openmandriva.monitoring.ifw'");
}

sub new {
    my ($type, $bus) = @_;
    require dbus_object;
    my $o = dbus_object::new($type,
			     $bus,
			     "org.openmandriva.monitoring",
			     "/org/openmandriva/monitoring/ifw",
			     "org.openmandriva.monitoring.ifw");
    $o;
}

sub set_blacklist_verdict {
    my ($o, $seq, $blacklist) = @_;
    $o->call_method('SetBlacklistVerdict', Net::DBus::dbus_uint32($seq), Net::DBus::dbus_uint32($blacklist));
}

sub unblacklist {
    my ($o, $addr) = @_;
    $o->call_method('UnBlacklist', Net::DBus::dbus_uint32($addr));
}

sub whitelist {
    my ($o, $addr) = @_;
    $o->call_method('Whitelist', Net::DBus::dbus_uint32($addr));
}

sub unwhitelist {
    my ($o, $addr) = @_;
    $o->call_method('UnWhitelist', Net::DBus::dbus_uint32($addr));
}

sub get_interactive {
    my ($o) = @_;
    $o->call_method('GetMode');
}

sub set_interactive {
    my ($o, $mode) = @_;
    $o->call_method('SetMode', Net::DBus::dbus_uint32($mode));
}

sub get_reports {
    my ($o, $o_include_processed) = @_;
    $o->call_method('GetReports', Net::DBus::dbus_uint32(to_bool($o_include_processed)));
}

sub get_blacklist {
    my ($o) = @_;
    $o->call_method('GetBlacklist');
}

sub get_whitelist {
    my ($o) = @_;
    $o->call_method('GetWhitelist');
}

sub clear_processed_reports {
    my ($o) = @_;
    $o->call_method('ClearProcessedReports');
}

sub send_alert_ack {
    my ($o) = @_;
    $o->call_method('SendAlertAck');
}

sub send_manage_request {
    my ($o) = @_;
    $o->call_method('SendManageRequest');
}

sub format_date {
    my ($timestamp) = @_;
    require c;
    # "%c" has strange effects on utf-8 locales
    #c::strftime("%c", localtime($timestamp));
    c::strftime("%Y-%m-%d %H:%M:%S", localtime($timestamp));
}

sub get_service {
    my ($port) = @_;
    getservbyport($port, undef) || $port;
}

sub get_protocol {
    my ($protocol) = @_;
    getprotobynumber($protocol) || $protocol;
}

sub get_ip_address {
    my ($addr) = @_;
    inet_ntoa(pack('L', $addr));
}

sub resolve_address {
    my ($ip_addr) = @_;
    #- try to resolve address, timeout after 2 seconds
    my $hostname;
    eval {
        local $SIG{ALRM} = sub { die "ALARM" };
        alarm 2;
        $hostname = gethostbyaddr(inet_aton($ip_addr), Socket::AF_INET);
        alarm 0;
    };
    $hostname || $ip_addr;
}

sub attack_to_hash {
    my ($args) = @_;
    my $attack = { mapn { $_[0] => $_[1] } [ 'timestamp', 'indev', 'prefix', 'sensor', 'protocol', 'addr', 'port', 'icmp_type', 'seq', 'processed' ], $args };
    $attack->{port} = unpack('S', pack('n', $attack->{port}));
    $attack->{date} = format_date($attack->{timestamp});
    $attack->{ip_addr} = get_ip_address($attack->{addr});
    $attack->{hostname} = resolve_address($attack->{ip_addr});
    $attack->{protocol} = get_protocol($attack->{protocol});
    $attack->{service} = get_service($attack->{port});
    $attack->{type} =
        $attack->{prefix} eq 'SCAN' ? N("Port scanning")
      : $attack->{prefix} eq 'SERV' ? N("Service attack")
      : $attack->{prefix} eq 'PASS' ? N("Password cracking")
      : $attack->{prefix} eq 'NEW' ? N("New connection")
      : N(qq("%s" attack), $attack->{prefix});
    $attack->{msg} =
        $attack->{prefix} eq "SCAN" ? N("A port scanning attack has been attempted by %s.", $attack->{hostname})
      : $attack->{prefix} eq "SERV" ? N("The %s service has been attacked by %s.", $attack->{service}, $attack->{hostname})
      : $attack->{prefix} eq "PASS" ? N("A password cracking attack has been attempted by %s.", $attack->{hostname})
      : $attack->{prefix} eq "NEW" ? N("%s is connecting on the %s service.", $attack->{hostname}, $attack->{service})
      : N(qq(A "%s" attack has been attempted by %s), $attack->{prefix}, $attack->{hostname});
    $attack;
}

sub parse_listen_message {
    my ($args) = @_;
    my $listen = { mapn { $_[0] => $_[1] } [ 'program', 'port' ], $args };
    $listen->{port} = unpack('S', pack('n', $listen->{port}));
    $listen->{service} = get_service($listen->{port});
    $listen->{message} = N("The \"%s\" application is trying to make a service (%s) available to the network.",
                           $listen->{program},
                           $listen->{service} ne $listen->{port} ? $listen->{service} :
                             #-PO: this should be kept lowercase since the expression is meant to be used between brackets
                             N("port %d", $listen->{port}),
                       );
    $listen;
}

1;
