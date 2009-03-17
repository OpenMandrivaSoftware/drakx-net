package network::nfs;

use strict;
use common;

sub read_nfs_ports {
    my $statd_port = 4001;
    my $statd_outgoing_port = undef;
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

    my $ports = { statd_port => $statd_port,
        lockd_tcp_port => $lockd_tcp_port,
        lockd_udp_port => $lockd_udp_port,
        rpc_mountd_port => $rpc_mountd_port,
        rpc_rquotad_port => $rpc_rquotad_port,
    };
    if (defined $statd_outgoing_port) {
        $ports->{statd_outgoing_port} => $statd_outgoing_port,
    }
    $ports;
}

sub list_nfs_ports {
    my $ports = read_nfs_ports();

    my $portlist = $ports->{lockd_tcp_port}. "/tcp " . $ports->{lockd_udp_port} . "/udp";
    if (defined $ports->{statd_outgoing_port} and $ports->{statd_outgoing_port} ne $ports->{statd_port}) {
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
    } "/etc/sysconfig/nfs-common";
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
    } "/etc/sysconfig/nfs-server";
}

1;
