package network::drakroam;

# drakroam: wireless network roaming GUI
# Austin Acton, 2004 <austin@mandriva.org>
# Olivier Blin, 2005-2006 <oblin@mandriva.com>
# Licensed under the GPL

use strict;

use common;
use interactive;
use mygtk2;
use ugtk2 qw(:create :helpers :wrappers);
use network::connection;
use network::connection_manager;
use network::connection::wireless;
use network::connection::cellular_card;

sub update_connections_list {
    my ($droam) = @_;

    $droam->{gui}{model}->set($droam->{gui}{model}->append, 0, $droam->{gui}{empty_pixbuf} , 1, N("No device found")) unless @{$droam->{all_connections}};
    $droam->{gui}{model}->set($droam->{gui}{model}->append,
                0, gtknew('Pixbuf', file => $_->get_type_icon)->scale_simple($droam->{gui}{pixbuf_size}, $droam->{gui}{pixbuf_size}, 'hyper'),
                1, $_->get_description) foreach @{$droam->{all_connections}};
    my $index = $droam->{connection} ?
      eval { find_index { $_ == $droam->{connection} } @{$droam->{all_connections}} }
      : 0;
    $droam->{gui}{connections_combo}->set_active($index) if defined $index;
}

sub get_connection {
    my ($droam) = @_;

    @{$droam->{all_connections}} or return;
    my $index = $droam->{gui}{connections_combo}->get_active;
    defined $index && $droam->{all_connections}[$index];
}

sub select_connection {
    my ($droam) = @_;

    $droam->set_connection(get_connection($droam));
    $droam->check_setup || $droam->setup_connection if $droam->{connection};
    update_on_connection_change($droam);
}

sub update_on_connection_change {
    my ($droam) = @_;
    return if !($droam->{connection} && $droam->check_setup);
    $droam->{gui}{buttons}{refresh}->set_sensitive(to_bool($droam->{connection}))
      if $droam->{gui}{buttons}{refresh};
    $droam->update_networks;
}

sub get_network_event_message {
    my ($droam, $member, @args) = @_;
    #- FIXME: the hostname.d script and s2u use a different D-Bus interface
    if ($member eq 'hostname') {
        my ($hostname) = @args;
        N("Hostname changed to \"%s\"", $hostname);
    } elsif ($member eq 'status') {
        my ($status, $interface) = @args;
        my $event_connection = find { $_->get_interface eq $interface } @{$droam->{all_connections}};
        $event_connection && $event_connection->get_status_message($status);
    }
}

sub create_drakroam_gui {
    my ($droam, $dbus, $title, $icon) = @_;

    $droam->{gui}{model} = Gtk2::ListStore->new('Gtk2::Gdk::Pixbuf', 'Glib::String');
    $droam->{gui}{connections_combo} = Gtk2::ComboBox->new($droam->{gui}{model});
    my $pix_r = Gtk2::CellRendererPixbuf->new;
    $droam->{gui}{connections_combo}->pack_start($pix_r, 0,);
    $droam->{gui}{connections_combo}->add_attribute($pix_r, pixbuf => 0);
    my $text_r = Gtk2::CellRendererText->new;
    $droam->{gui}{connections_combo}->pack_start($text_r, 1);
    $droam->{gui}{connections_combo}->add_attribute($text_r, text => 1);

    $droam->{gui}{pixbuf_size} = 32;
    $droam->{gui}{empty_pixbuf} = Gtk2::Gdk::Pixbuf->new('rgb', 1, 8, $droam->{gui}{pixbuf_size}, $droam->{gui}{pixbuf_size});
    $droam->{gui}{empty_pixbuf}->fill(0);

    my $status_bar = Gtk2::Statusbar->new;
    my $status_bar_cid = $status_bar->get_context_id("Network event");
    $droam->{on_network_event} = sub {
        my ($message) = @_;
        my $m_id = $status_bar->push($status_bar_cid, $message);
        Glib::Timeout->add(20000, sub { $status_bar->remove($status_bar_cid, $m_id); 0 });
    };
    if ($dbus) {
        #- FIXME: use network::monitor?
        $dbus->{connection}->add_filter(sub {
                                            my ($_con, $msg) = @_;
                                            my $member = $msg->get_member;
                                            my $message = get_network_event_message($droam, $member, $msg->get_args_list) or return;
                                            $droam->{on_network_event}($message) if $droam->{on_network_event};
                                            $droam->update_networks if $member eq 'status';
                                        });
        $dbus->{connection}->add_match("type='signal',interface='com.mandriva.network'");
        dbus_object::set_gtk2_watch_helper($dbus);
    }

    (undef, my $rootwin_height) = gtkroot()->get_size();
    my $scrolled_height = $rootwin_height > 480 ? 300 : 225;
    gtkadd($droam->{gui}{w}{window},
           gtknew('VBox', spacing => 5, children => [
               $::isEmbedded ? () : (0, Gtk2::Banner->new($icon, $title)),
               0, gtknew('HBox', children_tight => [ gtknew('Label_Left', text => N("Device: "), alignment => [ 0.5, 0.5 ]),
                                                     gtksignal_connect($droam->{gui}{connections_combo}, changed => sub { select_connection($droam) }) ]),
               1, gtknew('ScrolledWindow', width => 500, height => $scrolled_height, child => $droam->{gui}{networks_list}),
               0, gtknew('HButtonBox', layout => 'edge', children_loose => [
                   $droam->{gui}{buttons}{configure} = gtknew('Button', text => N("Configure"), clicked => sub { $droam->configure_connection }),
                   $droam->{gui}{buttons}{connect_start} = gtknew('Button', text => N("Connect"), relief => 'half', clicked => sub { $droam->start_connection }),
                   $droam->{gui}{buttons}{connect_stop} = gtknew('Button', text => N("Disconnect"), relief => 'half', clicked => sub { $droam->stop_connection }),
                   $droam->{gui}{buttons}{refresh} = gtknew('Button', text => N("Refresh"), clicked => sub { $droam->update_networks }),
                   gtknew('Button', text => N("Quit"), clicked => sub { Gtk2->main_quit })
               ]),
               0, $status_bar,
           ]),
       );
}

sub main {
    my ($in, $net, $dbus, $o_interface, $o_ap) = @_;

    my $title = N("Wireless connection");
    my $icon = '/usr/share/mcc/themes/default/drakroam-mdk.png';

    $ugtk2::wm_icon = $icon;
    my $w = ugtk2->new($title);
    #- so that transient_for is defined, for wait messages and popups to be centered
    $::main_window = $w->{real_window};

    my $pixbufs = network::connection_manager::create_pixbufs();
    my $droam = network::connection_manager->new($in, $net, $w, $pixbufs);
    $droam->create_networks_list;
    create_drakroam_gui($droam, $dbus, $title, $icon);

    $droam->{gui}{w}->show;

    my @connection_types = qw(network::connection::wireless network::connection::cellular_card);
    @{$droam->{all_connections}} = map { $_->get_connections(automatic_only => 1) } @connection_types;
    my $connection = $o_interface && find { $_->get_interface eq $o_interface } @{$droam->{all_connections}};
    $connection ||= find { !$_->network_scan_is_slow } @{$droam->{all_connections}};
    $droam->set_connection($connection) if $connection;
    update_connections_list($droam);
    update_on_connection_change($droam);

    if ($o_ap && $droam->{connection}) {
        $droam->{connection}{network} = $o_ap;
        $droam->start_connection;
    }

    $droam->{gui}{w}->main;
}

1;
