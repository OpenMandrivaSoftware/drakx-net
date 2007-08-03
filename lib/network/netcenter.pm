#!/usr/bin/perl
# Olivier Blin, 2007 <oblin@mandriva.com>
# Licensed under the GPL

package network::netcenter;

use strict;
use common;
use run_program;
use detect_devices;
use interactive;
use mygtk2;
use ugtk2 qw(:create :helpers :wrappers);
use Gtk2::SimpleList;
use network::monitor;
use network::signal_strength;
use network::network;
use network::tools;
use network::connection;
use network::connection::wireless;
use network::connection::cellular_card;
use network::drakroam;

sub filter_networks {
    my ($connection) = @_;
    $_->{configured} = $connection->network_is_configured($_) foreach values %{$connection->{networks}};
    my @networks = sort {
        $b->{configured} <=> $a->{configured} || $b->{signal_strength} <=> $a->{signal_strength} || $a->{name} cmp $b->{name};
    } values %{$connection->{networks}};
    splice @networks, 0, 3;
}

sub build_networks_list {
    my ($connection, $net) = @_;

    my $droam = { connection => $connection, net => $net };
    network::drakroam::build_pixbufs($droam);
    network::drakroam::build_network_frame($droam);
    $droam->{filter_networks} = sub { filter_networks($connection) };
    network::drakroam::update_networks($droam);

    $droam->{gui}{networks_list};
}

sub gtkset_image {
    my ($w, $file, $o_size) = @_;
    my $image = $o_size
    ?  Gtk2::Image->new_from_pixbuf(gtkcreate_pixbuf($file)->scale_simple($o_size, $o_size, 'hyper'))
    :  gtknew('Image', file => $file);
    $w->set_image($image);
    $w;
}

sub main() {
    my $title = N("Network Center");
    my $icon = '/usr/share/mcc/themes/default/drakroam-mdk.png';

    $ugtk2::wm_icon = $icon;
    my $w = ugtk2->new($title);
    #- so that transient_for is defined, for wait messages and popups to be centered
    $::main_window = $w->{real_window};

    my @connections = map { $_->get_connections(automatic_only => 1) } network::connection::get_types;
    @connections = reverse(uniq_ { $_->{device} } reverse(@connections));

    my $net = {};
    network::network::read_net_conf($net);

    gtkadd($w->{window},
       gtknew('VBox', spacing => 5, children => [
           $::isEmbedded ? () : (0, Gtk2::Banner->new($icon, $title)),
           1, gtknew('ScrolledWindow', width => 500, height => 300, child => gtknew('VBox', spacing => 5, children_tight => [
               map {
                   gtknew('HBox', children_tight => [
                       gtknew('Image', file => $_->get_type_icon),
                       gtknew('VBox', children_tight => [
                           gtknew('Title2', label => $_->get_description),
                           gtknew('HBox', children_tight => [
                               gtknew('Label', padding => [ 20, 0 ]),
                               gtknew('VBox', children_tight => [
                                   ($_->can('get_networks') && !$_->network_scan_is_slow ? build_networks_list($_, $net) : ()),
                                   gtknew('HBox', children_tight => [
                                       gtknew('VBox', children_tight => [
                                           gtknew('HButtonBox', children_tight => [
                                               gtkset_image(gtknew('Button'), 'connected'),
                                               gtkset_image(gtknew('Button'), 'monitor-24'),
                                               gtkset_image(gtknew('Button'), 'configure-24'),
                                               ($_->can('get_networks') ? (0, gtkset_image(gtknew('Button'), 'refresh')) : ()),
                                           ]),
                                       ]),
                                   ]),
                               ]),
                           ]),
                       ]),
                   ]);
               } @connections,
           ])),
       ]),
    );

    $w->main;
}

1;
