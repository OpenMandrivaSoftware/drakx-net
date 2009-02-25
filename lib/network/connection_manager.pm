package network::connection_manager;

use strict;

use common;
use run_program;
use detect_devices;
use interactive;
use mygtk2;
use ugtk2 qw(:create :helpers :wrappers);
use Gtk2::SimpleList;
use network::signal_strength;
use network::network;
use network::tools;
use network::connection;
use modules;
use locale; # for cmp

sub create_pixbufs() {
    {
        state => { map { $_ => gtkcreate_pixbuf($_) } qw(connected disconnected refresh) },
        link_level => { map {
            $_ => gtkcreate_pixbuf('wifi-' . sprintf('%03d', $_))->scale_simple(24, 24, 'hyper');
        } qw(20 40 60 80 100) },
        encryption => { map {
            $_ => gtkcreate_pixbuf("encryption-$_-24");
        } qw(open weak strong) },
    };
}

sub new {
    my ($class, $in, $net, $w, $pixbufs) = @_;
    bless {
        in => $in, net => $net, gui => { w => $w, pixbufs => $pixbufs },
    }, $class;
}

sub set_connection {
    my ($cmanager, $connection) = @_;
    $cmanager->{connection} = $connection;
    $cmanager->{wait_message_timeout} = 20*1000 if ref($connection) eq 'network::connection::wireless' && $cmanager->{net}{monitor};
}

sub check_setup {
    my ($cmanager) = @_;
    $cmanager->{connection}{passed_setup} =
      (!$cmanager->{connection}->can("check_device") ||
       $cmanager->{connection}->check_device) &&
      (!$cmanager->{connection}->can("check_hardware") ||
       !$cmanager->{connection}->check_hardware_is_slow && $cmanager->{connection}->check_hardware)
        if !defined $cmanager->{connection}{passed_setup};
    $cmanager->{connection}{passed_setup};
}

sub setup_connection {
    my ($cmanager) = @_;

    $cmanager->load_settings;

    my @packages = $cmanager->{connection}->can('get_packages') ? $cmanager->{connection}->get_packages : ();
    if (@packages && !$cmanager->{in}->do_pkgs->install(@packages)) {
        $cmanager->{in}->ask_warn(N("Error"), N("Could not install the packages (%s)!", join(', ', @packages)));
        return;
    }
    $cmanager->{connection}->prepare_device;
    $cmanager->{connection}->setup_thirdparty($cmanager->{in}) or return;
    if ($cmanager->{connection}->can("check_device") && !$cmanager->{connection}->check_device) {
        $cmanager->{in}->ask_warn(N("Error"), $cmanager->{connection}{device}{error});
        return;
    }
    my $device_ready = 1;
    if ($cmanager->{connection}->can('check_hardware')) {
        #- FIXME: change message to "Checking device..." in cooker
        my $_wait = $cmanager->{in}->wait_message(N("Please wait"), N("Configuring device..."));
        $device_ready = $cmanager->{connection}->check_hardware;
    }
    if ($cmanager->{connection}->can('get_hardware_settings') && !$device_ready) {
        $cmanager->{in}->ask_from_({
            title => N("Network settings"),
            messages => N("Please enter settings for network"),
            auto_window_size => 1,
        }, $cmanager->{connection}->get_hardware_settings) or return;
        if ($cmanager->{connection}->can("check_hardware_settings") && !$cmanager->{connection}->check_hardware_settings) {
            $cmanager->{in}->ask_warn(N("Error"), $cmanager->{connection}->{hardware}{error});
            return;
        }
    }
    if ($cmanager->{connection}->can('configure_hardware') && !$device_ready) {
        my $wait = $cmanager->{in}->wait_message(N("Please wait"), N("Configuring device..."));
        if (!$cmanager->{connection}->configure_hardware) {
            undef $wait;
            $cmanager->{in}->ask_warn(N("Error"), $cmanager->{connection}{hardware}{error}) if $cmanager->{connection}{hardware}{error};
            return;
        }
    }
    $cmanager->write_settings;
    $cmanager->{connection}{passed_setup} = 1;
}

sub load_settings {
    my ($cmanager) = @_;

    $cmanager->{connection}->load_interface_settings;
    $cmanager->{connection}->guess_hardware_settings if $cmanager->{connection}->can('guess_hardware_settings');
    $cmanager->{connection}->guess_network_access_settings if $cmanager->{connection}->can('guess_network_access_settings');
    if ($cmanager->{connection}->can('get_providers')) {
        $cmanager->{connection}->guess_provider_settings;
        $cmanager->{connection}->set_provider;
    }
    $cmanager->{connection}->guess_protocol($cmanager->{net}) if $cmanager->{connection}->can('guess_protocol');
    $cmanager->{connection}->guess_access_settings if $cmanager->{connection}->can('guess_access_settings');
    $cmanager->{connection}->guess_address_settings if $cmanager->{connection}->can('guess_address_settings');
    $cmanager->{connection}->guess_hostname_settings if $cmanager->{connection}->can('guess_hostname_settings');
    $cmanager->{connection}->guess_network_control_settings if $cmanager->{connection}->can('guess_network_control_settings');
    $cmanager->{connection}->guess_control_settings;
}

sub write_settings {
    my ($cmanager) = @_;

    my $modules_conf = modules::any_conf->read;
    $cmanager->{connection}->write_settings($cmanager->{net}, $modules_conf);
    $modules_conf->write;
}

sub configure_connection {
    my ($cmanager) = @_;

    if (!$cmanager->check_setup) {
        $cmanager->setup_connection or return;
        $cmanager->update_networks if $cmanager->{connection}->can('get_networks');
        $cmanager->update_on_status_change;
        return;
    }

    $cmanager->load_settings;
    my $system_file = '/etc/sysconfig/drakx-net';
    my %global_settings = getVarsFromSh($system_file);

    my $error;
    do {
        undef $error;
        $cmanager->{in}->ask_from_({
            title => N("Network settings"),
            messages => N("Please enter settings for network"),
            icon => $cmanager->{connection}->get_type_icon(48),
            banner_title => $cmanager->{connection}->get_description,
        },
                   [
                       $cmanager->{connection}->can('get_network_access_settings') ? (
                           { label => $cmanager->{connection}->get_network_access_settings_label, title => 1, advanced => 1 },
                           @{$cmanager->{connection}->get_network_access_settings},
                       ) : (),
                       $cmanager->{connection}->can('get_providers') ? (
                         @{$cmanager->{connection}->get_provider_settings($cmanager->{net})}
                       ) : (),
                       $cmanager->{connection}->can('get_protocols') ? (
                         @{$cmanager->{connection}->get_protocol_settings},
                       ) : (),
                       $cmanager->{connection}->can('get_access_settings') ? (
                         { label => $cmanager->{connection}->get_access_settings_label, title => 1, advanced => 1 },
                         @{$cmanager->{connection}->get_access_settings}
                       ) : (),
                       $cmanager->{connection}->can('get_address_settings') && !text2bool($global_settings{AUTOMATIC_ADDRESS}) ? (
                         { label => $cmanager->{connection}->get_address_settings_label, title => 1, advanced => 1 },
                         @{$cmanager->{connection}->get_address_settings('show_all')}
                       ) : (),
                       $cmanager->{connection}->can('get_network_control_settings') ? (
                         @{$cmanager->{connection}->get_network_control_settings}
                       ) : (),
                   ],
               ) or return;
        if ($cmanager->{connection}->can('check_network_access_settings') && !$cmanager->{connection}->check_network_access_settings) {
            $cmanager->{in}->ask_warn(N("Error"), $cmanager->{connection}{network_access}{error}{message});
            $error = 1;
        }
        if ($cmanager->{connection}->can('check_address_settings') && !$cmanager->{connection}->check_address_settings($cmanager->{net})) {
            $cmanager->{in}->ask_warn(N("Error"), $cmanager->{connection}{address}{error}{message});
            $error = 1;
        }
    } while $error;

    $cmanager->{connection}->install_packages($cmanager->{in}) if $cmanager->{connection}->can('install_packages');
    $cmanager->{connection}->unload_connection if $cmanager->{connection}->can('unload_connection');

    $cmanager->write_settings;

    1;
}

sub start_connection {
    my ($cmanager) = @_;

    $cmanager->{connection} or return;
    if ($cmanager->{connection}->can('get_networks')) {
        $cmanager->{connection}{network} &&
        ($cmanager->{connection}->selected_network_is_configured ||
         $cmanager->configure_connection)
          or return;
    }

    gtkset_mousecursor_wait($cmanager->{gui}{w}{window}->window);
    my $wait = $cmanager->{in}->wait_message(N("Please wait"), N("Connecting..."));
    if ($cmanager->{connection}->can('apply_network_selection')) {
        $cmanager->load_settings;
        $cmanager->{connection}->apply_network_selection($cmanager);
    }
    $cmanager->{connection}->prepare_connection if $cmanager->{connection}->can('prepare_connection');
    $cmanager->{connection}->disconnect;
    $cmanager->{connection}->connect($cmanager->{in}, $cmanager->{net});
    gtkset_mousecursor_normal($cmanager->{gui}{w}{window}->window);

    $cmanager->update_on_status_change;
    if ($cmanager->{wait_message_timeout}) {
        $cmanager->{wait_message} = $wait;
        Glib::Timeout->add($cmanager->{wait_message_timeout}, sub { undef $cmanager->{wait_message} });
    };
}

sub stop_connection {
    my ($cmanager) = @_;

    gtkset_mousecursor_wait($cmanager->{gui}{w}{window}->window);
    my $_wait = $cmanager->{in}->wait_message(N("Please wait"), N("Disconnecting..."));
    $cmanager->{connection}->disconnect;
    gtkset_mousecursor_normal($cmanager->{gui}{w}{window}->window);

    $cmanager->update_on_status_change;
}

sub monitor_connection {
    my ($cmanager) = @_;
    my $interface  = $cmanager->{connection} && $cmanager->{connection}->get_interface or return;
    run_program::raw({ detach => 1 }, '/usr/sbin/net_monitor', '--defaultintf', $interface);
}

sub toggle_would_disconnect {
    my ($cmanager) = @_;

    my $network = $cmanager->{connection} && $cmanager->{connection}->get_selected_network;
    $cmanager->{connection} && $cmanager->{connection}->get_status &&
      (!$network || keys(%{$cmanager->{connection}{networks}}) <= 1 || $network->{current});
}

sub toggle_connection {
    my ($cmanager) = @_;

    if ($cmanager->toggle_would_disconnect) {
        $cmanager->stop_connection;
    } else {
        $cmanager->start_connection;
    }
}

sub create_networks_list {
    my ($cmanager) = @_;

    if ($cmanager->{gui}{show_unique_network}) {
        $cmanager->{gui}{networks_list} = gtknew('HBox', spacing => 20);
        return;
    }

    $cmanager->{gui}{networks_list} = Gtk2::SimpleList->new(
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
        $tooltip->set_text("$network->{signal_strength}% $network->{flags}");
        $widget->set_tooltip_row($tooltip, $path);
        1;
    });
    $cmanager->{gui}{networks_list}->set_has_tooltip(1);
    $cmanager->{gui}{networks_list}->get_column(1)->set_sort_column_id(1);
    $cmanager->{gui}{networks_list}->get_model->set_sort_func (1, sub {
        my ($sortable, $iter_left, $iter_right) = @_;
        my $s1 = $sortable->get($iter_left, 2);
        my $s2 = $sortable->get($iter_right, 2);
        return $s1 cmp $s2;
    });
    $cmanager->{gui}{networks_list}->get_column(2)->set_sort_column_id(2);
    $cmanager->{gui}{networks_list}->get_model->set_sort_func (2, sub {
        my ($sortable, $iter_left, $iter_right) = @_;
        my $s1 = $cmanager->{connection}{networks}{$sortable->get($iter_left, 0)}->{signal_strength};
        my $s2 = $cmanager->{connection}{networks}{$sortable->get($iter_right, 0)}->{signal_strength};
        return $s2 <=> $s1;
    });
    $cmanager->{gui}{networks_list}->get_column(3)->set_sort_column_id(3);
    $cmanager->{gui}{networks_list}->get_model->set_sort_func (3, sub {
        my ($sortable, $iter_left, $iter_right) = @_;
        my $s1 = $cmanager->{connection}{networks}{$sortable->get($iter_left, 0)}->{flags};
        my $s2 = $cmanager->{connection}{networks}{$sortable->get($iter_right, 0)}->{flags};
	#FIXME Should define an explicit order OPEN < WEP < WPA
        return $s1 cmp $s2;
    });
    $cmanager->{gui}{networks_list}->set_enable_search(1);
    $cmanager->{gui}{networks_list}->set_search_column(1);
    $cmanager->{gui}{networks_list}->set_search_equal_func(sub {
                    my ($model, $column, $key, $iter, $data) = @_;
                        return $model->get($iter, 2) !~ /^\Q$key/i;
                    });
}

sub select_network {
    my ($cmanager) = @_;

    if ($cmanager->{connection}) {
        my ($selected) = $cmanager->{gui}{networks_list}->get_selected_indices;
        $cmanager->{connection}{network} = defined $selected && $cmanager->{gui}{networks_list}{data}[$selected][0];
    }
    $cmanager->update_on_status_change;
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

    if ($cmanager->{connection}) {
        $cmanager->check_setup || $cmanager->setup_connection or return;

        my $wait = $cmanager->{connection}->network_scan_is_slow && $cmanager->{in}->wait_message(N("Please wait"), N("Scanning for networks..."));
        $cmanager->{connection}{networks} = $cmanager->{connection}->get_networks($cmanager->{net});
        $cmanager->{connection}{network} ||= find { $cmanager->{connection}{networks}{$_}{current} } keys %{$cmanager->{connection}{networks}};

        my $routes = network::tools::get_routes();
        my $interface = $cmanager->{connection}->get_interface;
        my $connected = exists $routes->{$interface}{network};

        my @networks = filter_networks($cmanager->{connection});
        foreach my $network (@networks) {
            my $ap = $network->{ap};
            my $connected_pixbuf = $network->{current} ? $connected ? $cmanager->{gui}{pixbufs}{state}{connected} : $cmanager->{gui}{pixbufs}{state}{refresh} : undef;
            my $network_name = !$network->{essid} && exists $cmanager->{net}{wireless}{$ap} && $cmanager->{net}{wireless}{$ap}{WIRELESS_ESSID} || $network->{name};
            my $strength_pixbuf = network::signal_strength::get_strength_icon($network);

            if ($cmanager->{gui}{show_unique_network}) {
                gtkset($cmanager->{gui}{networks_list}, children => [
                    1, $network_name,
                    0, Gtk2::Image->new_from_pixbuf($strength_pixbuf),
                ]);
                $cmanager->{connection}{network} = $network_name;
            } else {
                push @{$cmanager->{gui}{networks_list}{data}}, [
                    $ap || $network->{name},
                    $connected_pixbuf,
                    $network_name,
                    $strength_pixbuf,
                    $cmanager->{gui}{pixbufs}{encryption}{$network->{flags} =~ /WPA/i ? 'strong' : $network->{flags} =~ /WEP/i ? 'weak' : 'open'},
                    $network->{mode},
                ];
            }
        }

        if ($cmanager->{connection}{network} && !$cmanager->{gui}{show_unique_network}) {
            my $index = eval { find_index { $_->[0] eq $cmanager->{connection}{network} } @{$cmanager->{gui}{networks_list}{data}} };
            $cmanager->{gui}{networks_list}->select($index) if defined $index;
        }

        undef $wait;
    }

    $cmanager->update_on_status_change;
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
        ugtk2::_find_imgfile($icon) or $icon = $cmanager->{connection}->get_type_icon;
        gtkset($cmanager->{gui}{status_image}, file => $icon);
    }
}

sub _get_network_event_message {
    my ($connections, $member, @args) = @_;
    #- FIXME: the hostname.d script and s2u use a different D-Bus interface
    if ($member eq 'hostname') {
        my ($hostname) = @args;
        N("Hostname changed to \"%s\"", $hostname);
    } elsif ($member eq 'status') {
        my ($status, $interface) = @args;
        my $event_connection = find { $_->get_interface eq $interface } @$connections;
        $event_connection && $event_connection->get_status_message($status);
    }
}

sub setup_dbus_handlers {
    my ($cmanagers, $connections, $on_network_event, $dbus) = @_;
    #- FIXME: use network::monitor?
    $dbus->{connection}->add_filter(
        sub {
            my ($_con, $msg) = @_;
            my $member = $msg->get_member;
            my $message = get_network_event_message($droam, $member, $msg->get_args_list) or return;
            $droam->{on_network_event}($message) if $droam->{on_network_event};
            $droam->update_networks if $member eq 'status';
        });
    $dbus->{connection}->add_match("type='signal',interface='com.mandriva.network'");
    dbus_object::set_gtk2_watch_helper($dbus);
}

1;
