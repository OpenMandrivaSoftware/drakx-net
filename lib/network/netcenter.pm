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
use network::tools;

sub build_cmanager {
    my ($in, $net, $w, $pixbufs, $connection) = @_;

    my $cmanager = network::connection_manager->new($in, $net, $w, $pixbufs);
    $cmanager->set_connection($connection);

    if ($connection->can('get_networks')) {
        $cmanager->create_networks_list;
        #- do not check if it is slow (either scan or device check) or unavailable
        $cmanager->update_networks
            if !$connection->network_scan_is_slow && $cmanager->check_setup;
    }
    $cmanager;
}

sub main {
    my ($in, $net, $dbus) = @_;

    my $title = N("Network Center");
    my $icon = '/usr/share/mcc/themes/default/drakroam-mdk.png';

    $ugtk2::wm_icon = $icon;
    my $w = ugtk2->new($title);
    #- so that transient_for is defined, for wait messages and popups to be centered
    $::main_window = $w->{real_window};

    $w->show;
    my $wait = $in->wait_message(N("Please wait"), N("Please wait"));

    my @all_connections = map { $_->get_connections(automatic_only => 1, fast_only => 1) } network::connection::get_types;
    @all_connections = grep { !network::tools::is_zeroconf_interface($_->get_interface) } @all_connections;
    my ($sysfs, $no_sysfs) = partition { exists $_->{device}{sysfs_device} } @all_connections;
    my ($real, $other) = partition { network::tools::is_real_interface($_->get_interface) } @$sysfs;
    my @connections = (
        (uniq_ { $_->{device}{sysfs_device} } @$real),
        (uniq_ { $_->{device}{sysfs_device} } @$other),
        (uniq_ { $_->{device}{interface} } @$no_sysfs),
    );

    my $pixbufs = network::connection_manager::create_pixbufs();
    my @cmanagers = map { build_cmanager($in, $net, $w, $pixbufs, $_) } @connections;

    (undef, my $rootwin_height) = gtkroot()->get_size;
    my $scrolled_height = $rootwin_height > 480 ? 400 : 295;
    gtkadd($w->{window},
       gtknew('VBox', spacing => 5, children => [
           $::isEmbedded ? () : (0, Gtk2::Banner->new($icon, $title)),
           1, gtknew('ScrolledWindow', width => 600, height => $scrolled_height, shadow_type => 'none',
                     child => gtknew('VBox', spacing => 5, children_tight => [
               map_index {
                   my $cmanager = $cmanagers[$::i];
                   my $head = gtknew('HBox', children => [
                               0, $cmanager->{gui}{status_image} = gtknew('Image'),
                               0, gtknew('Label', padding => [ 5, 0 ]),
                               1, gtknew('Label', ellipsize => 'end', alignment => [ 0, 0 ], text_markup => '<b>' . $_->get_description . '</b>'),
                               0, gtknew('Label', padding => [ 2, 0 ]),
                               0, $cmanager->{gui}{labels}{interface} = gtknew('Label', alignment => [ 0, 0 ], text_markup => $_->get_interface ? '<b>' . $_->get_interface . '</b>' : ""),
                   ]);
                   my $content = gtknew('HBox', children => [
                               0, gtknew('Label', padding => [ 5, 0 ]),
                               1, gtknew('VBox', spacing => 5, children_tight => [
                                   ($cmanager->{connection}->can('get_networks') ? (
                                       gtknew('Label', text => N("Please select your network:"), alignment => [ 0, 0 ]),
                                       gtknew('ScrolledWindow', height => 160, child => $cmanager->{gui}{networks_list}),
                                   ) : ()),
                                   gtknew('HBox', children => [
                                       1, gtknew('HButtonBox', spacing => 6, layout => 'start', children_loose => [
                                               $cmanager->{gui}{buttons}{monitor} =
                                                 gtknew('Button', text => N("_: This is a verb\nMonitor"),
                                                        image => gtknew('Image', file => 'monitor-16'),
                                                        clicked => sub { $cmanager->monitor_connection }),
                                               $cmanager->{gui}{buttons}{configure} =
                                                 gtknew('Button', text => N("Configure"),
                                                        image => gtknew('Image', file => 'configure-16'),
                                                        clicked => sub { $cmanager->configure_connection }),
                                               ($cmanager->{connection}->can('get_networks') ?
                                                  ($cmanager->{gui}{buttons}{refresh} =
                                                    gtknew('Button', text => N("Refresh"),
                                                           image => gtknew('Image', file => 'refresh', size => 16),
                                                           clicked => sub { $cmanager->update_networks }))
                                                  : ()),
                                           ]),
                                       0, $cmanager->{gui}{buttons}{connect_toggle} =
                                                 gtknew('Button',
                                                        image => gtknew('Image', file => 'activate-16'),
                                                        clicked => sub { $cmanager->toggle_connection }),
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

                   $cmanager->update_on_status_change;

                   ($::i > 0 ? Gtk2::HSeparator->new : ()), $box;
               } @connections,
           ])),
           0, gtknew('HButtonBox', spacing => 6, layout => 'end', children_loose => [
               gtknew('Button', text => N("Quit"), clicked => sub { Gtk2->main_quit }),
           ]),
       ]),
    );

    if ($dbus) {
        my $monitor;
        eval { $monitor = network::monitor->new($dbus) };
        $dbus->{connection}->add_filter(sub {
            my ($_con, $msg) = @_;
            if ($msg->get_member eq 'status') {
                my ($status, $interface) = $msg->get_args_list;
                my $cmanager = find { $_->{connection}->get_interface eq $interface } @cmanagers
                  or return;
                #- FIXME: factorize in update_on_status_change() and check why update_networks() calls update_on_status_change()
                if ($cmanager->{connection}->can('get_networks') && !$cmanager->{connection}->network_scan_is_slow) {
                    $cmanager->update_networks;
                } else {
                    $cmanager->network::connection_manager::update_on_status_change;
                }
            }
        });
        $dbus->{connection}->add_match("type='signal',interface='com.mandriva.network'");
        dbus_object::set_gtk2_watch_helper($dbus);
    }

    undef $wait;
    $w->main;
}

1;
