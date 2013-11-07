package network::connection_manager::gtk;

use base qw(network::connection_manager);

use strict;
use common;

use mygtk3;
use ugtk3 qw(:create :helpers :wrappers);
use Gtk3::SimpleList;
use network::signal_strength;
use locale; # for cmp

our %pixbufs = (
    state => { map { $_ => gtkcreate_pixbuf($_) } qw(connected disconnected refresh) },
    encryption => { map {
        $_ => gtkcreate_pixbuf("encryption-$_-24");
    } qw(open weak strong) },
);

sub new {
    my ($class, $in, $net, $w) = @_;
    bless {
        in => $in, net => $net, gui => { w => $w },
    }, $class;
}

sub start_connection {
    my ($cmanager) = @_;
    gtkset_mousecursor_wait($cmanager->{gui}{w}{window}->window);
    $cmanager->SUPER::start_connection;
    gtkset_mousecursor_normal($cmanager->{gui}{w}{window}->window);
}

sub stop_connection {
    my ($cmanager) = @_;
    gtkset_mousecursor_wait($cmanager->{gui}{w}{window}->window);
    $cmanager->SUPER::stop_connection;
    gtkset_mousecursor_normal($cmanager->{gui}{w}{window}->window);
}

sub select_network {
    my ($cmanager) = @_;

    if ($cmanager->{connection}) {
        my ($selected) = $cmanager->{gui}{networks_list}->get_selected_indices;
        $cmanager->{connection}{network} = defined $selected && $cmanager->{gui}{networks_list}{data}[$selected][0];
    }
    $cmanager->update_on_status_change;
}

sub create_networks_list {
    my ($cmanager) = @_;

    if ($cmanager->{gui}{show_unique_network}) {
        $cmanager->{gui}{networks_list} = gtknew('HBox', spacing => 20);
        return;
    }

    $cmanager->{gui}{networks_list} = Gtk3::SimpleList->new(
        "AP" => "hidden",
        '' => "pixbuf",
        N("SSID") => "text",
        N("Signal strength") => "pixbuf",
        N("Encryption") => "pixbuf",
        N("Operating Mode") => "text",
    );
    $cmanager->{gui}{networks_list}->get_selection->set_mode('single');
    $cmanager->{gui}{networks_list}->get_selection->signal_connect('changed' => sub { $cmanager->select_network });

    $cmanager->{gui}{networks_list}->signal_connect('query-tooltip' => sub {
        my ($widget, $x, $y, $kbd_tip, $tooltip) = @_;
        (undef, undef, my $model, my $path, my $iter) = $widget->get_tooltip_context($x, $y, $kbd_tip) or return;
        my $ap = $model->get($iter, 0);
        my $network = $cmanager->{connection}{networks}{$ap};
        $tooltip->set_text(sprintf("%2.2f%% %s\n", $network->{signal_strength}, $network->{flags}));
        $widget->set_tooltip_row($tooltip, $path);
        1;
    });
    $cmanager->{gui}{networks_list}->set_has_tooltip(1);
    $cmanager->{gui}{networks_list}->get_column(1)->set_sort_column_id(1);
    $cmanager->{gui}{networks_list}->get_model->set_sort_func(1, sub {
        my ($sortable, $iter_left, $iter_right) = @_;
        my $s1 = $sortable->get($iter_left, 2);
        my $s2 = $sortable->get($iter_right, 2);
        return $s1 cmp $s2;
    });
    $cmanager->{gui}{networks_list}->get_column(2)->set_sort_column_id(2);
    $cmanager->{gui}{networks_list}->get_model->set_sort_func(2, sub {
        my ($sortable, $iter_left, $iter_right) = @_;
        my $s1 = $cmanager->{connection}{networks}{$sortable->get($iter_left, 0)}{signal_strength};
        my $s2 = $cmanager->{connection}{networks}{$sortable->get($iter_right, 0)}{signal_strength};
        return $s1 <=> $s2;
    });
    $cmanager->{gui}{networks_list}->get_column(3)->set_sort_column_id(3);
    $cmanager->{gui}{networks_list}->get_model->set_sort_func(3, sub {
        my ($sortable, $iter_left, $iter_right) = @_;
        my $s1 = $cmanager->{connection}{networks}{$sortable->get($iter_left, 0)}{flags};
        my $s2 = $cmanager->{connection}{networks}{$sortable->get($iter_right, 0)}{flags};
	#FIXME Should define an explicit order OPEN < WEP < WPA
        return $s1 cmp $s2;
    });
    $cmanager->{gui}{networks_list}->set_enable_search(1);
    $cmanager->{gui}{networks_list}->set_search_column(1);
    $cmanager->{gui}{networks_list}->set_search_equal_func(sub {
                    my ($model, $_column, $key, $iter) = @_;
                        return $model->get($iter, 2) !~ /^\Q$key/i;
                    });
    # Sort by signal level by default
    $cmanager->{gui}{networks_list}->get_model->set_sort_column_id(2, 'descending');
}

sub update_on_status_change {
    my ($cmanager) = @_;

    if ($cmanager->{gui}{buttons}{connect_toggle}) {
        my $disconnect = $cmanager->toggle_would_disconnect;
        $cmanager->{gui}{buttons}{connect_toggle}->set_label($disconnect ? N("Disconnect") : N("Connect"));
        gtkset($cmanager->{gui}{buttons}{connect_toggle}, image => gtknew('Image', file => $disconnect ? 'stop-16' : 'activate-16'))
          if $cmanager->{gui}{buttons}{connect_toggle}->get_image;
        $cmanager->{gui}{buttons}{connect_toggle}->set_sensitive(
            $cmanager->{connection} && (
                !$cmanager->{connection}->can('get_networks') ||
                $cmanager->{connection}->get_status || #- always allow to disconnect if connected
                $cmanager->{connection}{network}
            ));
    }

    $cmanager->{gui}{buttons}{connect_start}->set_sensitive($cmanager->{connection} && (!$cmanager->{connection}->get_status || $cmanager->{connection}{network}))
      if $cmanager->{gui}{buttons}{connect_start};
    $cmanager->{gui}{buttons}{connect_stop}->set_sensitive($cmanager->{connection} && $cmanager->{connection}->get_status)
      if $cmanager->{gui}{buttons}{connect_stop};

    my $allow_configure;
    if ($cmanager->{connection}) {
        my $may_have_network =
          !$cmanager->{connection}->can('get_networks') ||
          $cmanager->{connection}{network};
        $allow_configure = $may_have_network || !$cmanager->check_setup;
    }

    $cmanager->{gui}{buttons}{configure}->set_sensitive($allow_configure)
      if $cmanager->{gui}{buttons}{configure};

    my $has_interface = to_bool($cmanager->{connection} && $cmanager->{connection}->get_interface);
    $cmanager->{gui}{buttons}{refresh}->set_sensitive($has_interface)
      if $cmanager->{gui}{buttons}{refresh};
    $cmanager->{gui}{buttons}{monitor}->set_sensitive($has_interface)
      if $cmanager->{gui}{buttons}{monitor};

    if ($cmanager->{gui}{status_image} && $cmanager->{connection}) {
        my $icon = $cmanager->{connection}->get_status_icon;
        ugtk3::_find_imgfile($icon) or $icon = $cmanager->{connection}->get_type_icon;
        gtkset($cmanager->{gui}{status_image}, file => $icon);
    }
}

sub filter_networks {
    my ($connection) = @_;
    $_->{configured} = $connection->network_is_configured($_) foreach values %{$connection->{networks}};
    sort {
        $b->{current} <=> $a->{current} || $b->{configured} <=> $a->{configured} || $b->{signal_strength} <=> $a->{signal_strength} || $a->{name} cmp $b->{name};
    } values %{$connection->{networks}};
}

sub update_networks {
    my ($cmanager) = @_;
    @{$cmanager->{gui}{networks_list}{data}} = ();
    $cmanager->SUPER::update_networks;
}

sub update_networks_list {
    my ($cmanager) = @_;

    my $routes = network::tools::get_routes();
    my $interface = $cmanager->{connection}->get_interface;
    my $connected = exists $routes->{$interface}{network};

    my @networks = filter_networks($cmanager->{connection});
    foreach my $network (@networks) {
        my $ap = $network->{ap};
        my $connected_pixbuf = $network->{current} ? $connected ? $pixbufs{state}{connected} : $pixbufs{state}{refresh} : undef;
        my $network_name = !$network->{essid} && exists $cmanager->{net}{wireless}{$ap} && $cmanager->{net}{wireless}{$ap}{WIRELESS_ESSID} || $network->{name};
        my $strength_pixbuf = network::signal_strength::get_strength_icon($network);

        if ($cmanager->{gui}{show_unique_network}) {
            gtkset($cmanager->{gui}{networks_list}, children => [
                1, $network_name,
                0, Gtk3::Image->new_from_pixbuf($strength_pixbuf),
            ]);
            $cmanager->{connection}{network} = $network_name;
        } else {
            push @{$cmanager->{gui}{networks_list}{data}}, [
                $ap || $network->{name},
                $connected_pixbuf,
                $network_name,
                $strength_pixbuf,
                $pixbufs{encryption}{$network->{flags} =~ /WPA/i ? 'strong' : $network->{flags} =~ /WEP/i ? 'weak' : 'open'},
                $network->{mode},
            ];
        }
    }

    if ($cmanager->{connection}{network} && !$cmanager->{gui}{show_unique_network}) {
        my $index = eval { find_index { $_->[0] eq $cmanager->{connection}{network} } @{$cmanager->{gui}{networks_list}{data}} };
        $cmanager->{gui}{networks_list}->select($index) if defined $index;
    }
}

sub setup_dbus_handlers {
    my ($cmanagers, $connections, $on_network_event, $dbus) = @_;
    network::connection_manager::setup_dbus_handlers($cmanagers, $connections, $on_network_event, $dbus);
    dbus_object::set_gtk3_watch_helper($dbus);
}

1;
