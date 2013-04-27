package network::nfs;

use strict;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;

sub read_nfs_ports() {
    my $statd_port = 4001;
    my $statd_outgoing_port;
    my $lockd_tcp_port = 4002;
    my $lockd_udp_port = 4002;
    my $rpc_mountd_port = 4003;
    my $rpc_rquotad_port = 4004;
    if (-f "$::prefix/etc/sysconfig/nfs-common") {
            foreach (cat_("$::prefix/etc/sysconfig/nfs-common")) {
                /^STATD_OPTIONS=.*(--port|-p) (\d+)/ and $statd_port = $2;
                /^STATD_OPTIONS=.*(--outgoing-port|-o) (\d+)/ and $statd_outgoing_port = $2;
                /^LOCKD_TCPPORT=(\d+)/ and $lockd_tcp_port = $1;
                /^LOCKD_UDPPORT=(\d+)/ and $lockd_udp_port = $1;
        }
    }
    if (-f "$::prefix/etc/sysconfig/nfs-server") {
        foreach (cat_("$::prefix/etc/sysconfig/nfs-server")) {
            /^RPCMOUNTD_OPTIONS=.*(--port|-p) (\d+)/ and $rpc_mountd_port = $2;
            /^RPCRQUOTAD_OPTIONS=.*(--port|-p) (\d+)/ and $rpc_rquotad_port = $2;
        }
    }

    my $ports = { statd_port => $statd_port,
        lockd_tcp_port => $lockd_tcp_port,
        lockd_udp_port => $lockd_udp_port,
        rpc_mountd_port => $rpc_mountd_port,
        rpc_rquotad_port => $rpc_rquotad_port,
    };
    if (defined $statd_outgoing_port) {
        $ports->{statd_outgoing_port} = $statd_outgoing_port;
    }
    $ports;
}

sub list_nfs_ports() {
    my $ports = read_nfs_ports();

    my $portlist = $ports->{lockd_tcp_port} . "/tcp " . $ports->{lockd_udp_port} . "/udp";
    if (defined $ports->{statd_outgoing_port} && $ports->{statd_outgoing_port} ne $ports->{statd_port}) {
        $portlist .= " " . $ports->{statd_outgoing_port} . "/tcp " . $ports->{statd_outgoing_port} . "/udp";
    }
    foreach (qw(statd_port rpc_mountd_port rpc_rquotad_port)) {
        my $port = $ports->{$_};
        $portlist .= " $port/tcp $port/udp";
    }
    # list of ports in shorewall format
    $portlist;
}

sub write_nfs_ports {
    my ($ports) = @_;
    # enabling fixed ports for NFS services
    # nfs-common
    my $lockd_options="";
    substInFile {
        if ($ports->{statd_port}) {
            my $port = $ports->{statd_port};
            s/^(STATD_OPTIONS)=$/$1="--port $port"/;
            s/^(STATD_OPTIONS)="(.*)(--port \d+)(.*)"$/$1="$2--port $port$4"/;
            s/^(STATD_OPTIONS)="(.*)(-p \d+)(.*)"$/$1="$2--port $port$4"/;
        }
        if ($ports->{lockd_tcp_port}) {
            my $port = $ports->{lockd_tcp_port};
            s/^LOCKD_TCPPORT=.*/LOCKD_TCPPORT=$port/;
        }
        if ($ports->{lockd_udp_port}) {
            my $port = $ports->{lockd_udp_port};
            s/^LOCKD_UDPPORT=.*/LOCKD_UDPPORT=$port/;
        }
    } "$::prefix/etc/sysconfig/nfs-common";
    # kernel-side configuration of nlockmgr
    $lockd_options .= " nlm_tcpport=$ports->{lockd_tcp_port}" if $ports->{lockd_tcp_port};
    $lockd_options .= " nlm_udpport=$ports->{lockd_udp_port}" if $ports->{lockd_udp_port};
    if ($lockd_options ne "") {
        output("$::prefix/etc/modprobe.d/lockd.drakx.conf", "options lockd $lockd_options\n");
    }
    # nfs-server
    substInFile {
        if ($ports->{rpc_mountd_port}) {
            my $port = $ports->{rpc_mountd_port};
            s/^(RPCMOUNTD_OPTIONS)=$/$1="--port $port"/;
            s/^(RPCMOUNTD_OPTIONS)="(.*)(--port \d+)(.*)"$/$1="$2--port $port$4"/;
            s/^(RPCMOUNTD_OPTIONS)="(.*)(-p \d+)(.*)"$/$1="$2--port $port$4"/;
        }
        if ($ports->{rpc_rquotad_port}) {
            my $port = $ports->{rpc_rquotad_port};
            s/^(RPCRQUOTAD_OPTIONS)=$/$1="--port $port"/;
            s/^(RPCRQUOTAD_OPTIONS)="(.*)(--port \d+)(.*)"$/$1="$2--port $port$4"/;
            s/^(RPCRQUOTAD_OPTIONS)="(.*)(-p \d+)(.*)"$/$1="$2--port $port$4"/;
        }
    } "$::prefix/etc/sysconfig/nfs-server";
}

1;
