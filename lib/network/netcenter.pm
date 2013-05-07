#!/usr/bin/perl
# Olivier Blin, 2007 <oblin@mandriva.com>
# Licensed under the GPL

package network::netcenter;

use strict;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;
use mygtk2;
use ugtk2 qw(:create :helpers :wrappers);
use network::connection;
use network::connection_manager::gtk;
use network::tools;
use network::network;
use run_program;

sub build_cmanager {
    my ($in, $net, $w, $connection) = @_;

    my $cmanager = network::connection_manager::gtk->new($in, $net, $w);
    $cmanager->set_connection($connection);
    $cmanager->{gui}{show_unique_network} = $cmanager->{connection}->has_unique_network;

    if ($connection->can('get_networks')) {
        $cmanager->create_networks_list;
        #- do not check if it is slow (either scan or device check) or unavailable
        $cmanager->update_networks
            if !$connection->network_scan_is_slow && $cmanager->check_setup;
    }
    $cmanager;
}

sub build_cmanager_box {
    my ($cmanager, $is_first) = @_;

    my $head = gtknew('HBox', children => [
        0, $cmanager->{gui}{status_image} = gtknew('Image'),
        0, gtknew('Label', padding => [ 5, 0 ]),
        1, gtknew('VBox', children_tight => [
            gtknew('HBox', children => [
                1, gtknew('Label', alignment => [ 0, 0 ], text_markup => '<b>' . $cmanager->{connection}->get_type_description . '</b>'),
                0, gtknew('Label', padding => [ 2, 0 ]),
                0, $cmanager->{gui}{labels}{interface} = gtknew('Label', alignment => [ 0, 0 ], text_markup => $cmanager->{connection}->get_interface ? '<b>' . $cmanager->{connection}->get_interface . '</b>' : ""),
            ]),
            gtknew('Label', ellipsize => 'end', alignment => [ 0, 0 ], text_markup => $cmanager->{connection}->get_description),
        ]),
    ]);
    my $content = gtknew('HBox', children => [
        0, gtknew('Label', padding => [ 5, 0 ]),
        1, gtknew('VBox', spacing => 5, children_tight => [
            ($cmanager->{connection}->can('get_networks') ? (
                $cmanager->{gui}{show_unique_network} ? (
                    $cmanager->{gui}{networks_list},
                ) : (
                    gtknew('Label', text => N("Please select your network:"), alignment => [ 0, 0 ]),
                    gtknew('ScrolledWindow', height => 160, child => $cmanager->{gui}{networks_list})
                ),
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
    my $on_expand = sub {
        my ($expanded) = @_;
        if ($expanded && $cmanager->{connection}->can('get_networks') &&
              !$cmanager->{connection}{probed_networks} && $expanded) {
            gtkflush();
            $cmanager->update_networks;
        }
    };
    my $toggle_expand = sub {
        my $was_expanded = $expander->get_expanded;
        $was_expanded ? $content->hide : $content->show_all;
        $on_expand->(!$was_expanded);
    };
    $expander->signal_connect(activate => $toggle_expand);
    my $eventbox = gtksignal_connect(Gtk2::EventBox->new, button_press_event => sub {
                                         $_[1]->button == 1 or return;
                                         $toggle_expand->();
                                         my $was_expanded = $expander->get_expanded;
                                         $expander->set_expanded(!$was_expanded);
                                     });
    my $box = gtknew('VBox', spacing => 5, children_tight => [
        (!$is_first ? Gtk2::HSeparator->new : ()),
        gtknew('HBox', children => [
            0, $expander,
            1, gtkadd($eventbox, $head),
        ]),
        $content,
    ]);
    $content->hide;

    $cmanager->update_on_status_change;

    $cmanager->{parent_box} = $box;
}

sub get_connections() {
    my @all_connections = map { $_->get_connections(automatic_only => 1, fast_only => 1) } network::connection::get_types;
    @all_connections = grep { !network::tools::is_zeroconf_interface($_->get_interface) } @all_connections;
    my ($sysfs, $no_sysfs) = partition { exists $_->{device}{sysfs_device} } @all_connections;
    my ($real, $other) = partition { network::tools::is_real_interface($_->get_interface) } @$sysfs;
    (
        (uniq_ { $_->{device}{sysfs_device} } @$real),
        (uniq_ { $_->{device}{sysfs_device} } @$other),
        (uniq_ { $_->{device}{interface} } @$no_sysfs),
    );
}

sub advanced_settings {
	my ($in, $net) = @_;
	my $u = network::network::advanced_settings_read();
	my $old_crda = $net->{network}{CRDA_DOMAIN};
	if (network::network::advanced_choose($in, $net, $u)) {
		network::network::advanced_settings_write($u);
        # check if the CRDA changed
        if ($old_crda ne $net->{network}{CRDA_DOMAIN}) {
            # reconfiguring wireless domain
            run_program::run("iw", "reg", "set", $net->{network}{CRDA_DOMAIN});
        }
        network::network::write_network_conf($net);
	}
}

sub main {
    my ($in, $net, $dbus) = @_;

    my $wait = $in->wait_message(N("Please wait"), N("Please wait"));

    my $title = N("Network Center");
    my $icon = '/usr/share/mcc/themes/default/drakroam-mdk.png';

    $ugtk2::wm_icon = $icon;
    my $w = ugtk2->new($title);
    #- so that transient_for is defined, for wait messages and popups to be centered
    $::main_window = $w->{real_window};

    my @connections = get_connections();

    my @cmanagers = map { build_cmanager($in, $net, $w, $_) } @connections;

    (undef, my $rootwin_height) = gtkroot()->get_size;
    my $scrolled_height = $rootwin_height > 480 ? 400 : 295;
    my $managers_box;
    gtkadd($w->{window},
       gtknew('VBox', spacing => 5, children => [
           $::isEmbedded ? () : (0, Gtk2::Banner->new($icon, $title)),
           if_($net->{PROFILE} && network::network::netprofile_count() > 0, 0, gtknew('Label', text_markup => N("You are currently using the network profile <b>%s</b>", $net->{PROFILE}))),
           1, gtknew('ScrolledWindow', width => 600, height => $scrolled_height, shadow_type => 'none',
                     child => $managers_box = gtknew('VBox', spacing => 5, children_tight => [
               map_index { build_cmanager_box($_, $::i == 0) } @cmanagers,
           ])),
           0, gtknew('HButtonBox', spacing => 6, layout => 'end', children_loose => [
               gtknew('Button', text => N("Advanced settings"), clicked => sub { advanced_settings($in, $net) }),
               gtknew('Button', text => N("Quit"), clicked => sub { Gtk2->main_quit }),
           ]),
       ]),
    );

    if ($dbus) {
        $dbus->{connection}->add_filter(sub {
            my ($_con, $msg) = @_;
            if ($msg->get_interface eq 'org.mageia.network' && $msg->get_member eq 'status') {
                my ($status, $interface) = $msg->get_args_list;
                my $cmanager = find { $_->{connection}->get_interface eq $interface } @cmanagers;
                if ($status eq "add") {
                    if (!$cmanager) {
                        detect_devices::probeall_update_cache();
                        my $connection = find { $_->get_interface eq $interface } get_connections()
                          or return;
                        $cmanager = build_cmanager($in, $net, $w, $connection);
                        push @connections, $connection;
                        push @cmanagers, $cmanager;
                        my $box = build_cmanager_box($cmanager, @connections == 0);
                        $managers_box->add($box);
                        $box->show_all;
                    }
                    $cmanager->{parent_box}->show;
                }
                if ($status eq "remove") {
                    $cmanager->{parent_box}->hide if $cmanager;
                }
            }
        });
        network::connection_manager::gtk::setup_dbus_handlers(\@cmanagers, \@connections, undef, $dbus);
    }

    undef $wait;
    $w->main;
}

1;
