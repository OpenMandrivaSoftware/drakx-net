package network::connection_manager;

use strict;

use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;
use run_program;
use detect_devices;
use interactive;
use network::network;
use network::tools;
use network::connection;
use modules;

sub new {
    my ($class, $in, $net) = @_;
    bless {
        in => $in, net => $net,
    }, $class;
}

sub set_connection {
    my ($cmanager, $connection) = @_;
    $cmanager->{connection} = $connection;
    $cmanager->{wait_message_timeout} = 20*1000 if ref($connection) eq 'network::connection::wireless';
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
            $cmanager->{in}->ask_warn(N("Error"), $cmanager->{connection}{hardware}{error});
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
        $cmanager->{connection}->set_provider($cmanager->{net});
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
    return if !ref($cmanager->{connection});

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
                       $cmanager->{connection}->can('get_control_settings') ? (
                         @{$cmanager->{connection}->get_control_settings}
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

    my $wait = $cmanager->{in}->wait_message(N("Please wait"), N("Connecting..."));
    if ($cmanager->{connection}->can('apply_network_selection')) {
        $cmanager->load_settings;
        $cmanager->{connection}->apply_network_selection($cmanager);
    }
    $cmanager->{connection}->prepare_connection if $cmanager->{connection}->can('prepare_connection');
    $cmanager->{connection}->disconnect;
    $cmanager->{connection}->connect($cmanager->{in}, $cmanager->{net});

    $cmanager->update_on_status_change;
    if ($cmanager->{wait_message_timeout}) {
        $cmanager->{wait_message} = $wait;
        Glib::Timeout->add($cmanager->{wait_message_timeout},
			   sub {
			       if ($cmanager->{wait_message}) {
				   $cmanager->update_on_status_change;
				   undef $cmanager->{wait_message};
				   $cmanager->{in}->ask_warn(N("Error"), N("Connection failed."))
                                     if !$cmanager->{connection}->get_status;
			       }
			       undef;
			   });
    }
}

sub stop_connection {
    my ($cmanager) = @_;
    my $_wait = $cmanager->{in}->wait_message(N("Please wait"), N("Disconnecting..."));
    $cmanager->{connection}->disconnect;
    $cmanager->update_on_status_change;
}

sub monitor_connection {
    my ($cmanager) = @_;
    my $interface  = $cmanager->{connection} && $cmanager->{connection}->get_interface or return;
    run_program::raw({ detach => 1 }, '/usr/bin/net_monitor', '--defaultintf', $interface);
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

sub update_networks {
    my ($cmanager) = @_;

    if ($cmanager->{connection}) {
        $cmanager->check_setup || $cmanager->setup_connection or return;

        my $wait = $cmanager->{connection}->network_scan_is_slow && $cmanager->{in}->wait_message(N("Please wait"), N("Scanning for networks..."));
        $cmanager->{connection}{networks} = $cmanager->{connection}->get_networks($cmanager->{net});
        $cmanager->{connection}{network} ||= find { $cmanager->{connection}{networks}{$_}{current} } keys %{$cmanager->{connection}{networks}};

        $cmanager->update_networks_list();
        undef $wait;
    }

    $cmanager->update_on_status_change;
}

sub update_networks_list {}
sub update_on_status_change {}

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
            if ($msg->get_interface eq 'com.mandriva.network') {
                my $member = $msg->get_member;
                my $message = _get_network_event_message($connections, $member, $msg->get_args_list);
                $on_network_event->($message) if $on_network_event && $message;
                if ($member eq 'status') {
                    my ($status, $interface) = $msg->get_args_list;
                    print "got connection status event: $status $interface\n";
                    my $cmanager = find { $_->{connection}->get_interface eq $interface } @$cmanagers
                      or return;
                    #- FIXME: factorize in update_on_status_change() and check why update_networks() calls update_on_status_change()
                    if ($cmanager->{connection}->can('get_networks') && !$cmanager->{connection}->network_scan_is_slow) {
                        $cmanager->update_networks;
                    } else {
                        $cmanager->update_on_status_change;
                    }
                    if ($cmanager->{wait_message}) {
                        if ($status eq 'interface_up') {
                            undef $cmanager->{wait_message};
                        } elsif ($status =~ /_failure$/) {
                            undef $cmanager->{wait_message};
                            $cmanager->{in}->ask_warn(N("Error"), join("\n", N("Connection failed."), if_($message, $message)));
                        }
                    }
                }
            }
            if ($msg->get_interface eq 'com.mandriva.monitoring.wireless' && $msg->get_member eq 'Event') {
                my ($event, $interface) = $msg->get_args_list;
                print "got wireless event: $event $interface\n";
                # eugeni: wpa_supplicant seems to issue 'Authentication..timed out messages' even if they
                # are not fatal (#54002). We should either handle them with more care, or just ignore them altogether
#                my $cmanager = find { $_->{connection}->get_interface eq $interface } @$cmanagers;
#                if ($cmanager && $cmanager->{wait_message}) {
#                    # CTRL-EVENT-CONNECTED does not have to be handled, further status will be handled by interface status code
#                    if ($event =~ /Authentication with (.+?) timed out/) {
#                        undef $cmanager->{wait_message};
#                        $cmanager->{in}->ask_warn(N("Error"), N("Connection failed."));
#                    }
#                }
            }
        });
    $dbus->{connection}->add_match("type='signal',interface='com.mandriva.network'");
    $dbus->{connection}->add_match("type='signal',interface='com.mandriva.monitoring.wireless'");
}

1;
