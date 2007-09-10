#!/usr/bin/perl
# Olivier Blin, 2007 <oblin@mandriva.com>
# Licensed under the GPL

package network::netcenter;

use strict;
use common;
use mygtk2;
use ugtk2 qw(:create :helpers :wrappers);
use network::connection;
use network::connection_manager;

sub filter_networks {
    my ($connection) = @_;
    $_->{configured} = $connection->network_is_configured($_) foreach values %{$connection->{networks}};
    my @networks = sort {
        $b->{configured} <=> $a->{configured} || $b->{signal_strength} <=> $a->{signal_strength} || $a->{name} cmp $b->{name};
    } values %{$connection->{networks}};
    splice @networks, 0, 3;
}

sub build_cmanager {
    my ($in, $net, $w, $pixbufs, $connection) = @_;

    my $cmanager = network::connection_manager::create($in, $net, $w, $pixbufs);
    $cmanager->{connection} = $connection;
    $cmanager->{gui}{show_networks} = $connection->can('get_networks') && !$connection->network_scan_is_slow;
    if ($cmanager->{gui}{show_networks}) {
        network::connection_manager::create_networks_list($cmanager);
        $cmanager->{filter_networks} = sub { filter_networks($connection) };
        network::connection_manager::update_networks($cmanager);
    }
    $cmanager;
}

sub main {
    my ($in, $net) = @_;

    my $title = N("Network Center");
    my $icon = '/usr/share/mcc/themes/default/drakroam-mdk.png';

    $ugtk2::wm_icon = $icon;
    my $w = ugtk2->new($title);
    #- so that transient_for is defined, for wait messages and popups to be centered
    $::main_window = $w->{real_window};

    my @connections = map { $_->get_connections(automatic_only => 1) } network::connection::get_types;
    @connections = uniq_ { $_->{device} } @connections;

    my $pixbufs = network::connection_manager::create_pixbufs();

    gtkadd($w->{window},
       gtknew('VBox', spacing => 5, children => [
           $::isEmbedded ? () : (0, Gtk2::Banner->new($icon, $title)),
           1, gtknew('ScrolledWindow', width => 500, height => 300, shadow_type => 'none',
                     child => gtknew('VBox', spacing => 5, children_tight => [
               map_index {
                   my $cmanager = build_cmanager($in, $net, $w, $pixbufs, $_);
                   my $icon = $_->get_status_icon;
                   ugtk2::_find_imgfile($icon) or $icon = $_->get_type_icon;
                   my $head = gtknew('HBox', children => [
                               0, gtknew('Image', file => $icon),
                               0, gtknew('Label', padding => [ 5, 0 ]),
                               1, gtknew('Label', ellipsize => 'end', alignment => [ 0, 0 ], text_markup => '<b>' . $_->get_description . '</b>'),
                               0, gtknew('Label', padding => [ 2, 0 ]),
                               0, $cmanager->{gui}{labels}{interface} = gtknew('Label', alignment => [ 0, 0 ], text_markup => $_->get_interface ? '<b>' . $_->get_interface . '</b>' : ""),
                   ]);
                   my $content = gtknew('HBox', children => [
                               0, gtknew('Label', padding => [ 5, 0 ]),
                               1, gtknew('VBox', spacing => 5, children_tight => [
                                   if_($cmanager->{gui}{show_networks},
                                       gtknew('Label', text => N("Please select your network:"), alignment => [ 0, 0 ]),
                                       gtknew('Frame', shadow_type => 'in', child => $cmanager->{gui}{networks_list})),
                                   gtknew('HBox', children => [
                                       1, gtknew('HButtonBox', spacing => 6, layout => 'start', children_loose => [
                                               $cmanager->{gui}{buttons}{monitor} =
                                                 gtknew('Button', text => N("Monitor"),
                                                        image => gtknew('Image', file => 'monitor-16'),
                                                        clicked => sub { network::connection_manager::monitor_connection($cmanager) }),
                                               $cmanager->{gui}{buttons}{configure} = 
                                                 gtknew('Button', text => N("Configure"),
                                                        image => gtknew('Image', file => 'configure-16'),
                                                        clicked => sub { network::connection_manager::configure_connection($cmanager) }),
                                               ($cmanager->{gui}{show_networks} ?
                                                  $cmanager->{gui}{buttons}{refresh} =
                                                    gtknew('Button', text => N("Refresh"),
                                                           image => gtknew('Image', file => 'refresh', size => 16),
                                                           clicked => sub { network::connection_manager::update_networks($cmanager) })
                                                      : ()),
                                           ]),
                                       0, $cmanager->{gui}{buttons}{connect_toggle} =
                                                 gtknew('Button',
                                                        image => gtknew('Image', file => 'activate-16'),
                                                        clicked => sub { network::connection_manager::start_connection($cmanager) }),
                                           ]),
                               ]),
                   ]);

                   my $expander = gtknew('Expander');
                   my $toggle_expand = sub { $expander->get_expanded ? $content->hide : $content->show_all };
                   $expander->signal_connect(activate => $toggle_expand);
                   my $eventbox = gtksignal_connect(Gtk2::EventBox->new, button_press_event => sub {
                       $_[1]->button == 1 or return;
                       $toggle_expand->();
                       $expander->set_expanded(!$expander->get_expanded);
                   });
                   my $box = gtknew('VBox', spacing => 5, children_tight => [
                       gtknew('HBox', children => [
                           0, $expander,
                           1, gtkadd($eventbox, $head),
                       ]),
                       $content,
                   ]);
                   $content->hide;

                   network::connection_manager::update_on_status_change($cmanager);

                   ($::i > 0 ? Gtk2::HSeparator->new : ()), $box;
               } @connections,
           ])),
           0, gtknew('HButtonBox', spacing => 6, layout => 'end', children_loose => [
               gtknew('Button', text => N("Quit"), clicked => sub { Gtk2->main_quit }),
           ]),
       ]),
    );

    my $base_color = $w->{window}->get_style->base('normal')->to_string;
    Gtk2::Rc->parse_string(<<END);
style "netcenter_bg" {
  bg[NORMAL] = "$base_color"
}
class "*Container*" style "netcenter_bg"

END

    $w->main;
}

1;
