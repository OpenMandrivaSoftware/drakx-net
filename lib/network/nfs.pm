package network::nfs;

use strict;
use common;

sub read_nfs_port_settings {
    my $statd_port = 4001;
    my $statd_outgoing_port = 4001;
    my $lockd_tcp_port = 4002;
    my $lockd_udp_port = 4002;
    my $rpc_mountd_port = 4003;
    my $rpc_rquotad_port = 4004;
    if (-f "/etc/sysconfig/nfs-common") {
            foreach (cat_("/etc/sysconfig/nfs-common")) {
            $_ =~ /^STATD_OPTIONS=.*(--port|-p) (\d+).*$/ and $statd_port = $2;
            $_ =~ /^STATD_OPTIONS=.*(--outgoing-port|-o) (\d+).*$/ and $statd_outgoing_port = $2;
            $_ =~ /^LOCKD_TCPPORT=(\d+)/ and $lockd_tcp_port = $1;
            $_ =~ /^LOCKD_UDPPORT=(\d+)/ and $lockd_udp_port = $1;
        }
    }
    if (-f "/etc/sysconfig/nfs-server") {
        foreach (cat_("/etc/sysconfig/nfs-server")) {
            $_ =~ /^RPCMOUNTD_OPTIONS=.*(--port|-p) (\d+).*$/ and $rpc_mountd_port = $2;
            $_ =~ /^RPCRQUOTAD_OPTIONS=.*(--port|-p) (\d+).*$/ and $rpc_rquotad_port = $2;
        }
    }

    { statd_port => $statd_port,
        statd_outgoing_port => $statd_outgoing_port,
        lockd_tcp_port => $lockd_tcp_port,
        lockd_udp_port => $lockd_udp_port,
        rpc_mountd_port => $rpc_mountd_port,
        rpc_rquotad_port => $rpc_rquotad_port,
    }
}

1;
