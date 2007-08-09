package network::connection_manager;

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
use modules;

sub create_pixbufs() {
    {
        state => { map { $_ => gtkcreate_pixbuf($_) } qw(connected disconnected refresh) },
        link_level => { map {
            $_ => gtkcreate_pixbuf('wifi-' . sprintf('%03d', $_) . '.png')->scale_simple(24, 24, 'hyper');
        } qw(20 40 60 80 100) },
        encryption => { map {
            $_ => gtkcreate_pixbuf("encryption-$_-24.png");
        } qw(open weak strong) },
    };
}

sub create {
    my ($in, $net, $w, $pixbufs) = @_;
    { in => $in, net => $net, gui => { w => $w, pixbufs => $pixbufs } };
}

sub prepare_connection {
    my ($droam) = @_;

    my @packages = $droam->{connection}->can('get_packages') ? $droam->{connection}->get_packages : ();
    if (@packages && !$droam->{in}->do_pkgs->install(@packages)) {
        $droam->{in}->ask_warn(N("Error"), N("Could not install the packages (%s)!", join(', ', @packages)));
        return;
    }
    $droam->{connection}->prepare_device;
    $droam->{connection}->setup_thirdparty($droam->{in}) or return;
    if ($droam->{connection}->can("check_device") && !$droam->{connection}->check_device) {
        $droam->{in}->ask_warn(N("Error"), $droam->{connection}{device}{error});
        return;
    }
    if ($droam->{connection}->can('get_hardware_settings')) {
        $droam->{connection}->guess_hardware_settings if $droam->{connection}->can('guess_hardware_settings');
        $droam->{in}->ask_from_({
            title => "Network settings",
            messages => N("Please enter settings for network")
        }, $droam->{connection}->get_hardware_settings) or return;
    }
    if ($droam->{connection}->can('check_hardware')) {
        my $_w = $droam->{in}->wait_message('', N("Configuring device..."));
        if (!$droam->{connection}->check_hardware) {
            $droam->{in}->ask_warn(N("Error"), $droam->{connection}{hardware}{error}) if $droam->{connection}{hardware}{error};
            return;
        }
    }
}

sub load_settings {
    my ($droam) = @_;

    $droam->{connection}->load_interface_settings;
    $droam->{connection}->guess_network_access_settings if $droam->{connection}->can('guess_network_access_settings');
    $droam->{connection}->guess_protocol($droam->{net}) if $droam->{connection}->can('guess_protocol');
    $droam->{connection}->guess_access_settings if $droam->{connection}->can('guess_access_settings');
    $droam->{connection}->guess_address_settings if $droam->{connection}->can('guess_address_settings');
    $droam->{connection}->guess_hostname_settings if $droam->{connection}->can('guess_hostname_settings');
    $droam->{connection}->guess_network_control_settings if $droam->{connection}->can('guess_network_control_settings');
    $droam->{connection}->guess_control_settings;
}

sub configure_connection {
    my ($droam) = @_;

    load_settings($droam);

    $droam->{in}->ask_from_({
        title => "Network settings",
        messages => N("Please enter settings for network")
    },
                   [
                       $droam->{connection}->can('get_network_access_settings') ? (
                           { label => $droam->{connection}->get_network_access_settings_label, title => 1, advanced => 1 },
                           @{$droam->{connection}->get_network_access_settings},
                       ) : (),
                       $droam->{connection}->can('get_protocols') ? (
                         @{$droam->{connection}->get_protocol_settings},
                       ) : (),
                       $droam->{connection}->can('get_access_settings') ? (
                         { label => $droam->{connection}->get_access_settings_label, title => 1, advanced => 1 },
                         @{$droam->{connection}->get_access_settings}
                       ) : (),
                       $droam->{connection}->can('get_address_settings') ? (
                         { label => $droam->{connection}->get_address_settings_label, title => 1, advanced => 1 },
                         @{$droam->{connection}->get_address_settings('show_all')}
                       ) : (),
                       $droam->{connection}->can('get_network_control_settings') ? (
                         @{$droam->{connection}->get_network_control_settings}
                       ) : (),
                   ],
               ) or return;

    $droam->{connection}->install_packages($droam->{in}) if $droam->{connection}->can('install_packages');
    $droam->{connection}->unload_connection if $droam->{connection}->can('unload_connection');

    my $modules_conf = modules::any_conf->read;
    $droam->{connection}->write_settings($droam->{net}, $modules_conf);
    $modules_conf->write;

    1;
}

sub start_connection {
    my ($droam) = @_;

    $droam->{connection} && $droam->{connection}{network} or return;
    if ($droam->{connection}->selected_network_is_configured || configure_connection($droam)) {
        gtkset_mousecursor_wait($droam->{gui}{w}{window}->window);
        my $_wait = $droam->{in}->wait_message(N("Please wait"), N("Connecting..."));
        #- settings have to be rewritten only if they are impacted by choices from the main window
        if ($droam->{connection}->can('get_networks')) {
            load_settings($droam);
            $droam->{connection}->write_settings($droam->{net});
        }
        $droam->{connection}->prepare_connection if $droam->{connection}->can('prepare_connection');
        $droam->{connection}->disconnect;
        $droam->{connection}->connect($droam->{in}, $droam->{net});
        gtkset_mousecursor_normal($droam->{gui}{w}{window}->window);
    }

    update_on_network_change($droam);
}

sub stop_connection {
    my ($droam) = @_;

    gtkset_mousecursor_wait($droam->{gui}{w}{window}->window);
    my $_wait = $droam->{in}->wait_message(N("Please wait"), N("Disconnecting..."));
    $droam->{connection}->disconnect;
    gtkset_mousecursor_normal($droam->{gui}{w}{window}->window);

    update_on_network_change($droam);
}

sub toggle_would_disconnect {
    my ($droam) = @_;

    my $network = $droam->{connection} && $droam->{connection}->get_selected_network;
    $droam->{connection} && $droam->{connection}->get_status &&
      (!$network || keys(%{$droam->{connection}{networks}}) <= 1 || $network->{current});
}

sub toggle_connection {
    my ($droam) = @_;

    if (toggle_would_disconnect($droam)) {
        stop_connection($droam);
    } else {
        start_connection($droam);
    }
}

sub create_networks_list {
    my ($droam) = @_;

    $droam->{gui}{networks_list} = Gtk2::SimpleList->new(
        "AP" => "hidden",
        '' => "pixbuf",
        N("SSID") => "text",
        N("Signal strength") => "pixbuf",
        N("Encryption") => "pixbuf",
        N("Operating Mode") => "text",
    );
    $droam->{gui}{networks_list}->get_selection->set_mode('single');
    $droam->{gui}{networks_list}->get_selection->signal_connect('changed' => sub { select_network($droam) });

    $droam->{gui}{networks_list}->signal_connect('query-tooltip' => sub {
        my ($widget, $x, $y, $kbd_tip, $tooltip) = @_;
        my ($x, $y, $model, $path, $iter) = $widget->get_tooltip_context($x, $y, $kbd_tip) or return;
        my $ap = $model->get($iter, 0);
        my $network = $droam->{connection}{networks}{$ap};
        $tooltip->set_text("$network->{signal_strength}% $network->{flags}");
        $widget->set_tooltip_row($tooltip, $path);
        1;
    });
    $droam->{gui}{networks_list}->set_has_tooltip(1);
}

sub update_networks {
    my ($droam) = @_;
    @{$droam->{gui}{networks_list}{data}} = ();

    if ($droam->{connection}) {
        my $wait = $droam->{connection}->network_scan_is_slow && $droam->{in}->wait_message('', N("Scanning for networks..."));
        $droam->{connection}{networks} = $droam->{connection}->get_networks;
        undef $wait;

        $droam->{connection}{network} ||= find { $droam->{connection}{networks}{$_}{current} } keys %{$droam->{connection}{networks}};

        my $routes = network::tools::get_routes();
        my $interface = $droam->{connection}->get_interface;
        my $connected = exists $routes->{$interface}{network};

        my @networks = values %{$droam->{connection}{networks}};
        $droam->{filter_networks} and @networks = $droam->{filter_networks}(@networks);
        foreach my $network (@networks) {
            my $ap = $network->{ap};
            push @{$droam->{gui}{networks_list}{data}}, [
                $ap || $network->{name},
                $network->{current} ? $connected ? $droam->{gui}{pixbufs}{state}{connected} : $droam->{gui}{pixbufs}{state}{refresh} : undef,
                !$network->{essid} && exists $droam->{net}{wireless}{$ap} && $droam->{net}{wireless}{$ap}{WIRELESS_ESSID} || $network->{name},
                network::signal_strength::get_strength_icon($network),
                $droam->{gui}{pixbufs}{encryption}{$network->{flags} =~ /WPA/i ? 'strong' : $network->{flags} =~ /WEP/i ? 'weak' : 'open'},
                $network->{mode},
            ];
        }

        if ($droam->{connection}{network}) {
            my $index = eval { find_index { $_->[0] eq $droam->{connection}{network} } @{$droam->{gui}{networks_list}{data}} };
            $droam->{gui}{networks_list}->select($index) if defined $index;
        }
    }

    update_on_network_change($droam);
}

sub update_on_network_change {
    my ($droam) = @_;

    if ($droam->{gui}{buttons}{connect_toggle}) {
        $droam->{gui}{buttons}{connect_toggle}->set_label(toggle_would_disconnect($droam) ? N("Disconnect") : N("Connect"));
        #- always allow to disconnect if connected
        $droam->{gui}{buttons}{connect_toggle}->set_sensitive($droam->{connection} && ($droam->{connection}->get_status || $droam->{connection}{network}));
    }

    $droam->{gui}{buttons}{connect_start}->set_sensitive($droam->{connection} && (!$droam->{connection}->get_status || $droam->{connection}{network}))
      if $droam->{gui}{buttons}{connect_start};
    $droam->{gui}{buttons}{connect_stop}->set_sensitive($droam->{connection} && $droam->{connection}->get_status)
      if $droam->{gui}{buttons}{connect_stop};

    #- allow to configure only if a network is selected
    $droam->{gui}{buttons}{configure}->set_sensitive($droam->{connection} && $droam->{connection}{network})
      if $droam->{gui}{buttons}{configure};
}

1;
