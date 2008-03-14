package network::drakconnect;

use common;
use network::network;

sub apply {
    my ($in, $net, $modules_conf) = @_;
    network::network::configure_network($net, $in, $modules_conf);
}

sub get_intf_ip {
    my ($net, $interface) = @_;
    my ($ip, $state, $mask);
    if (-x "/sbin/ifconfig") {
	local $_ = `LC_ALL=C LANGUAGE=C /sbin/ifconfig $interface`;
	$ip = /inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/mso ? $1 : N("No IP");
	$mask = /Mask:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/mso ? $1 : N("No Mask");
	$state = /inet/ ? N("up") : N("down");
    } else {
	$ip = $net->{ifcfg}{$interface}{IPADDR};
	$state = "n/a";
    }
    ($ip, $state, $mask);
}

1;
