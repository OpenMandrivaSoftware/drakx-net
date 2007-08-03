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

sub build_networks_list {
    my ($connection) = @_;

    #- from drakroam
    my %pixbufs =
      (
          state => { map { $_ => gtkcreate_pixbuf($_) } qw(connected disconnected refresh) },
          link_level => { map {
              $_ => gtkcreate_pixbuf('wifi-' . sprintf('%03d', $_) . '.png')->scale_simple(24, 24, 'hyper');
          } qw(20 40 60 80 100) },
          encryption => { map {
              $_ => gtkcreate_pixbuf("encryption-$_-24.png");
          } qw(open weak strong) },
      );

    #- from drakroam
    my $networks_list = Gtk2::SimpleList->new(
        "AP" => "hidden",
        '' => "pixbuf",
        '' => "pixbuf",
        N("Signal strength") => "pixbuf",
        N("SSID") => "text",
    );
    $networks_list->get_selection->set_mode('single');
    $networks_list->set_headers_visible(0);

    my $net = {};
    network::network::read_net_conf($net);

    #- from drakroam::update_networks()
    $connection->{networks} = $connection->get_networks;
    $connection->{network} ||= find { $connection->{networks}{$_}{current} } keys %{$connection->{networks}};
    my $routes = network::tools::get_routes();
    my $interface = $connection->get_interface;
    my $connected = exists $routes->{$interface}{network};


    $_->{configured} = $connection->network_is_configured($_) foreach values %{$connection->{networks}};
    my @networks = sort {
        $b->{configured} <=> $a->{configured} || $b->{signal_strength} <=> $a->{signal_strength} || $a->{name} cmp $b->{name};
    } values %{$connection->{networks}};
    my @valuable_networks = splice @networks, 0, 3;
    foreach (@valuable_networks) {
        my $ap = $_->{ap};
        push @{$networks_list->{data}}, [
            $ap || $_->{name},
            $_->{current} ? $connected ? $pixbufs{state}{connected} : $pixbufs{state}{refresh} : undef,
            $pixbufs{encryption}{$_->{flags} =~ /WPA/i ? 'strong' : $_->{flags} =~ /WEP/i ? 'weak' : 'open'},
            network::signal_strength::get_strength_icon($_),
            !$_->{essid} && exists $net->{wireless}{$ap} && $net->{wireless}{$ap}{WIRELESS_ESSID} || $_->{name},
        ];
    }

    $networks_list;
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

    gtkadd($w->{window},
       gtknew('VBox', spacing => 5, children => [
           $::isEmbedded ? () : (0, Gtk2::Banner->new($icon, $title)),
           1, gtknew('ScrolledWindow', width => 500, height => 300, child => gtknew('VBox', spacing => 5, children_tight => [
               map {
                   gtknew('VBox', children_tight => [
                       gtknew('HBox', children_tight => [
                           gtknew('Image', file => $_->get_type_icon),
                           $_->get_description,
                       ]),
                       gtknew('HBox', children => [
                           0, gtknew('Label', padding => [ 20, 0 ]),
                           0, gtknew('VBox', children_tight => [
                               gtknew('HBox', children_tight => [
                                   gtkset_image(gtknew('Button'), 'connected'),
                                   gtkset_image(gtknew('Button'), 'monitor-24'),
                                   gtkset_image(gtknew('Button'), 'configure-24'),
                                   ($_->can('get_networks') ? (0, gtkset_image(gtknew('Button'), 'refresh')) : ()),
                               ]),
                           ]),
                           ($_->can('get_networks') && !$_->network_scan_is_slow ? (1, build_networks_list($_)) : ()),
                       ]),
                   ]);
               } @connections,
           ])),
       ]),
    );

    $w->main;
}

1;
