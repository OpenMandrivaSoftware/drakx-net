package network::adsl; # $Id: adsl.pm 219797 2007-05-25 15:39:46Z blino $

use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;
use run_program;
use network::tools;
use modules;

sub adsl_probe_info {
    my ($net) = @_;
    my $pppoe_file = "$::prefix/etc/ppp/pppoe.conf";
    my $login;
    foreach (qw(/etc/ppp/peers/ppp0 /etc/ppp/options /etc/ppp/options.adsl)) {
	($login) = map { if_(/^user\s+"([^"]+)"/, $1) } cat_("$::prefix/$_") if !$login && -r "$::prefix/$_";
    }
    my %pppoe_conf = -f $pppoe_file && getVarsFromSh($pppoe_file);
    $login = $pppoe_conf{USER} if !$login || $net->{adsl}{method} eq 'pppoe';
    my $passwd = network::tools::passwd_by_login($login);
    if (!$net->{adsl}{vpi} && !$net->{adsl}{vci}) {
        foreach (cat_("$::prefix/etc/ppp/peers/ppp0")) {
            if (/^.*-vpi\s+(\d+)\s+-vci\s+(\d+)/ || /^plugin pppoatm.so (\d+)\.(\d+)$/) {
                ($net->{adsl}{vpi}, $net->{adsl}{vci}) = ($1, $2);
                last;
            }
        }
    }
    $pppoe_conf{DNS1} ||= '';
    $pppoe_conf{DNS2} ||= '';
    add2hash($net->{resolv}, { dnsServer2 => $pppoe_conf{DNS1}, dnsServer3 => $pppoe_conf{DNS2}, DOMAINNAME2 => '' });
    add2hash($net->{adsl}, { login => $login, passwd => $passwd });
}

sub adsl_conf_backend {
    my ($in, $net) = @_;

    require network::connection::xdsl;
    my $xdsl = network::connection::xdsl->new(
        $net->{adsl}{method} eq "capi" ?
          $net->{adsl}{capi_card} :
          { driver => $net->{adsl}{driver}, ethernet_device => $net->{adsl}{ethernet_device} });
    $xdsl->{protocol} = $net->{adsl}{method};
    $xdsl->{access}{login} = $net->{adsl}{login};
    $xdsl->{access}{password} = $net->{adsl}{passwd};
    $xdsl->{access}{vpi} = $net->{adsl}{vpi};
    $xdsl->{access}{vci} = $net->{adsl}{vci};

    $xdsl->install_packages($in);
    $xdsl->unload_connection;
    $xdsl->write_settings($net);
    $xdsl->prepare_connection;
}

1;
