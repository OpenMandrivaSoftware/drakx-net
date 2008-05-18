package network::netconnect; # $Id$

use strict;
use common;
use log;
use detect_devices;
use list_modules;
use modules;
use mouse;
use services;
use network::network;
use network::tools;
use network::thirdparty;
use network::connection;

sub detect {
    my ($modules_conf, $auto_detect, $o_class) = @_;
    my %l = (
             isdn => sub {
                 require network::connection::isdn;
                 $auto_detect->{isdn} = network::connection::isdn::detect_backend($modules_conf);
             },
             modem => sub {
                 $auto_detect->{modem} = { map { $_->{description} || "$_->{MANUFACTURER}|$_->{DESCRIPTION} ($_->{device})" => $_ } detect_devices::getModem($modules_conf) };
             },
            );
    $l{$_}->() foreach $o_class || keys %l;
    return;
}

sub detect_timezone() {
    my %tmz2country = ( 
		       'Europe/Paris' => N("France"),
		       'Europe/Amsterdam' => N("Netherlands"),
		       'Europe/Rome' => N("Italy"),
		       'Europe/Brussels' => N("Belgium"),
		       'America/New_York' => N("United States"),
		       'Europe/London' => N("United Kingdom")
		      );
    my %tm_parse = MDK::Common::System::getVarsFromSh("$::prefix/etc/sysconfig/clock");
    my @country;
    foreach (keys %tmz2country) {
	if ($_ eq $tm_parse{ZONE}) {
	    unshift @country, $tmz2country{$_};
	} else { push @country, $tmz2country{$_} }
    }
    \@country;
}

sub real_main {
      my ($net, $in, $modules_conf) = @_;
      #- network configuration should have been already read in $net at this point
      my $mouse = $::o->{mouse} || {};
      my (@connections_list, $connection, @providers_data, $provider_name, $protocol_settings, $access_settings, $control_settings);
      my $connection_compat;
      my ($hardware_settings, $network_access_settings, $address_settings, $hostname_settings);
      my ($modem, $modem_name, $modem_dyn_dns, $modem_dyn_ip);
      my ($up);
      my ($isdn, $isdn_name, $isdn_type, %isdn_cards, @isdn_dial_methods);
      my $my_isdn = join('', N("Manual choice"), " (", N("Internal ISDN card"), ")");
      my $success = 1;
      my $db_path = "/usr/share/apps/kppp/Provider";
      my (%countries, @isp, $country, $provider, $old_provider);

      my $system_file = '/etc/sysconfig/drakx-net';
      my %global_settings = getVarsFromSh($system_file);

      my $_w = N("Protocol for the rest of the world");
      my %isdn_protocols = (
                            2 => N("European protocol (EDSS1)"),
                            3 => N("Protocol for the rest of the world\nNo D-Channel (leased lines)"),
                           );

      $net->{autodetect} = {};

      my %ppp_auth_methods = (
                              0 => N("Script-based"),
                              1 => N("PAP"),
                              2 => N("Terminal-based"),
                              3 => N("CHAP"),
                              4 => N("PAP/CHAP"),
                             );

      my %steps_compat = (
          'network::connection::isdn' => 'isdn',
          'network::connection::pots' => 'modem',
      );

      my $get_next = sub {
          my ($step) = @_;
          my @steps = (
              "select_connection" => sub { 0 },
              "configure_hardware" => sub { $connection->can('get_hardware_settings') },
              #- network is for example wireless/3G access point
              "select_network" => sub { $connection->can('get_networks') },
              "configure_network_access" => sub { $connection->can('get_network_access_settings') },
              #- allow to select provider after network
              "select_provider" => sub { $connection->can('get_providers') },
              #- protocol may depend on provider settings (xDSL)
              "select_protocol" => sub { $connection->can('get_protocols') },
              #- peer settings may depend on provider and protocol (VPI/VCI for xDSL)
              "configure_access" => sub { $connection->can('get_access_settings') },
              "configure_address" => sub { ($connection->can('get_address_settings') || $connection->can('get_hostname_settings')) && !text2bool($global_settings{AUTOMATIC_ADDRESS}) },
              "configure_control" => sub { $connection->can('get_control_settings') },
              "apply_connection" => sub { 1 },
          );
          my $can;
          foreach (group_by2(@steps)) {
              $can && $_->[1]->() and return $_->[0];
              $can ||= $_->[0] eq $step;
          }
      };

      use locale;
      set_l10n_sort();

      require wizards;
      my $wiz = wizards->new(
        {
         defaultimage => "drakconnect.png",
         name => N("Network & Internet Configuration"),
         pages => {
                   welcome => {
                    pre => sub { undef $net->{type} },
                    if_(!$::isInstall, no_back => 1),
                    name => N("Choose the connection you want to configure"),
                    interactive_help_id => 'configureNetwork',
                    data => [ { list => [ network::connection::get_types ],
                                type => 'list', val => \$net->{type}, format => sub { $_[0] && $_[0]->get_type_description },
                                gtk => { use_scrolling => 1 } } ],
                    complete => sub {
                        my @packages = $net->{type}->can('get_packages') ? $net->{type}->get_packages : ();
                        if (@packages && !$in->do_pkgs->install(@packages)) {
                            $in->ask_warn(N("Error"), N("Could not install the packages (%s)!", join(', ', @packages)));
                            1;
                        }
                    },
                    post => sub {
                        if (exists $steps_compat{$net->{type}}) {
                            return $steps_compat{$net->{type}};
                        }
                        @connections_list = $net->{type}->get_connections(automatic_only => text2bool($global_settings{AUTOMATIC_IFACE_CHOICE}));
                        @connections_list ? "select_connection" : "no_connection";
                    },
                   },

                   select_connection => {
                       name => sub { $net->{type}->get_type_name . "\n\n" . N("Select the network interface to configure:") },
                       data => [ { val => \$connection, type => 'list', list => \@connections_list,
                                   format => sub { $_[0] && $_[0]->get_description }, allow_empty_list => !text2bool($global_settings{AUTOMATIC_IFACE_CHOICE})} ],
                       complete => sub {
                           $connection->setup_thirdparty($in) or return 1;
                           $connection->prepare_device;
                           if ($connection->can("check_device") && !$connection->check_device) {
                               $in->ask_warn('', $connection->{device}{error});
                               return 1;
                           }
                           return 0;
                       },
                       post => sub {
                           $connection->load_interface_settings;
                           $get_next->("select_connection");
                       },
                   },

                   no_connection => {
                       name => sub { $net->{type}->get_type_name . "\n\n" . N("No device can be found for this connection type.") },
                       end => 1,
                   },

                   configure_hardware => {
                       pre => sub {
                           $hardware_settings = $connection->get_hardware_settings;
                           $connection->guess_hardware_settings if $connection->can('guess_hardware_settings');
                       },
                       name => sub { $net->{type}->get_type_name . "\n\n" . N("Hardware Configuration") },
                       data => sub { $hardware_settings },
                       complete => sub {
                           if ($connection->can("check_hardware_settings") && !$connection->check_hardware_settings) {
                               $in->ask_warn('', $connection->{hardware}{error});
                               return 1;
                           }
                           return 0 if !$connection->can('check_hardware') || $connection->check_hardware;
                           if ($connection->can('configure_hardware')) {
                               my $_w = $in->wait_message(N("Please wait"), N("Configuring device..."));
                               if (!$connection->configure_hardware) {
                                   $in->ask_warn(N("Error"), $connection->{hardware}{error}) if $connection->{hardware}{error};
                                   return 1;
                               }
                           }
                       },
                       post => sub { $get_next->("configure_hardware") },
                   },

                   select_provider => {
                       pre => sub {
                           @providers_data = $connection->get_providers;
                           require lang;
                           my $locale_country = lang::c2name(ref($::o) && $::o->{locale}{country} || lang::read()->{country});
                           my $separator = $providers_data[1];
                           $provider_name = find { /^\Q$locale_country$separator\E/ } sort(keys %{$providers_data[0]});
                       },
                       name => sub { $net->{type}->get_type_name . "\n\n" . N("Please select your provider:") },
                       data => sub {
                           [ { type => "list", val => \$provider_name, separator => $providers_data[1],
                               list => [ N("Unlisted - edit manually"), sort(keys %{$providers_data[0]}) ], sort => 0 } ];
                       },
                       post => sub {
                           if ($provider_name ne N("Unlisted - edit manually")) {
                               $connection->set_provider($providers_data[0]{$provider_name});
                           }
                           $get_next->("select_provider");
                       },
                   },

                   select_network => {
                       pre => sub {
                           my $_w = $in->wait_message(N("Please wait"), N("Scanning for networks..."));
                           $connection->get_networks;
                       },
                       name => sub { $net->{type}->get_type_name . "\n\n" . N("Please select your network:") },
                       data => sub {
                           [ { type => "list", val => \$connection->{network}, allow_empty_list => 1,
                               list => [ keys %{$connection->{networks}}, undef ], gtk => { use_scrolling => 1 },
                               format => sub { exists $connection->{networks}{$_[0]} ?
                                                 $connection->{networks}{$_[0]}{name} :
                                                 N("Unlisted - edit manually");
                                               } } ];
                       },
                       post => sub {
                           $get_next->("select_network");
                       },
                   },

                   configure_network_access => {
                       pre => sub {
                           $network_access_settings = $connection->get_network_access_settings;
                           $connection->guess_network_access_settings if $connection->can('guess_network_access_settings');
                       },
                       name => sub { $net->{type}->get_type_name . "\n\n" . $connection->get_network_access_settings_label },
                       data => sub { $network_access_settings },
                       complete => sub {
                           if ($connection->can('check_network_access_settings') && !$connection->check_network_access_settings) {
                               $in->ask_warn(N("Error"), $connection->{network_access}{error}{message});
                               my $index = eval { find_index { $_->{val} eq $connection->{network_access}{error}{field} } @$network_access_settings };
                               return 1, $index;
                           }
                           return 0;
                       },
                       post => sub { $get_next->("configure_network_access") },
                   },

                   select_protocol => {
                       pre => sub {
                           $protocol_settings = $connection->get_protocol_settings;
                           $connection->guess_protocol($net) if $connection->can('guess_protocol');
                       },
                       name => sub { $net->{type}->get_type_name . "\n\n" . N("Please select your connection protocol.
If you do not know it, keep the preselected protocol.") },
                       data => sub { $protocol_settings },
                       post => sub { $get_next->("select_protocol") },
                   },

                   configure_access => {
                       pre => sub {
                           $access_settings = $connection->get_access_settings;
                           $connection->guess_access_settings if $connection->can('guess_access_settings');
                       },
                       name => sub { $net->{type}->get_type_name . "\n\n" . $connection->get_access_settings_label },
                       data => sub { $access_settings },
                       post => sub { $get_next->("configure_access") },
                   },

                   configure_address => {
                       pre => sub {
                           $address_settings = $connection->can('get_address_settings') && $connection->get_address_settings;
                           $connection->guess_address_settings if $connection->can('guess_address_settings');
                           $hostname_settings = $connection->can('get_hostname_settings') && $connection->get_hostname_settings;
                           $connection->guess_hostname_settings if $connection->can('guess_hostname_settings');
                       },
                       name => sub { $net->{type}->get_type_name . "\n\n" . $connection->get_address_settings_label },
                       data => sub { [ @$address_settings, @$hostname_settings ] },
                       complete => sub {
                           if ($connection->can('check_address_settings') && !$connection->check_address_settings($net)) {
                               $in->ask_warn(N("Error"), $connection->{address}{error}{message});
                               my $index = eval { find_index { $_->{val} eq $connection->{address}{error}{field} } @$address_settings };
                               return 1, $index;
                           }
                           return 0;
                       },
                       post => sub { $get_next->("configure_address") },
                   },

                   configure_control => {
                       pre => sub {
                           $control_settings = $connection->get_control_settings;
                           $connection->can('get_network_control_settings') and
                             push @$control_settings, @{$connection->get_network_control_settings};
                           $connection->guess_control_settings if $connection->can('guess_control_settings');
                           $connection->guess_network_control_settings if $connection->can('guess_network_control_settings');
                       },
                       name => sub { $net->{type}->get_type_name . "\n\n" . N("Connection control") },
                       data => sub { $control_settings },
                       post => sub { $get_next->("configure_control") },
                   },

                   apply_connection => {
                       name => N("Do you want to start the connection now?"),
                       type => "yesorno",
                       complete => sub {
                           $connection->can('install_packages') && !$connection->install_packages($in);
                       },
                       post => sub {
                           my ($answer) = @_;
                           my $_w = $in->wait_message(N("Please wait"), N("Testing your connection..."), 1);
                           $connection->unload_connection if $connection->can('unload_connection');
                           $connection->write_settings($net, $modules_conf);
                           $connection->prepare_connection if $connection->can('prepare_connection');
                           if ($answer) {
                               $connection->disconnect;
                               $connection->connect;
                               #- FIXME: should use network::test for ppp (after future merge with network::connection)
                               #- or start interface synchronously
                               services::start('network-up') unless $::isInstall;
                           }
                           "end"; #- handle disconnection in install?
                       },
                   },

                   isdn_account =>
                   {
                    pre => sub {
                        network::connection::isdn::get_info_providers_backend($isdn, $provider);
                        $isdn->{huptimeout} ||= 180;
                    },
                    name => N("Connection Configuration") . "\n\n" . N("Please fill or check the field below"),
                    data => sub {
			[
			 { label => N("Your personal phone number"), val => \$isdn->{phone_in} },
			 { label => N("Provider name (ex provider.net)"), val => \$net->{resolv}{DOMAINNAME2} },
			 { label => N("Provider phone number"), val => \$isdn->{phone_out} },
			 { label => N("Provider DNS 1 (optional)"), val => \$net->{resolv}{dnsServer2} },
			 { label => N("Provider DNS 2 (optional)"), val => \$net->{resolv}{dnsServer3} },
			 { label => N("Dialing mode"),  list => ["auto", "manual"], val => \$isdn->{dialing_mode} },
			 { label => N("Connection speed"), list => ["64 Kb/s", "128 Kb/s"], val => \$isdn->{speed} },
			 { label => N("Connection timeout (in sec)"), val => \$isdn->{huptimeout} },
			 { label => N("Account Login (user name)"), val => \$isdn->{login} },
			 { label => N("Account Password"),  val => \$isdn->{passwd}, hidden => 1 },
			 { label => N("Card IRQ"), val => \$isdn->{irq}, advanced => 1 },
			 { label => N("Card mem (DMA)"), val => \$isdn->{mem}, advanced => 1 },
			 { label => N("Card IO"), val => \$isdn->{io}, advanced => 1 },
			 { label => N("Card IO_0"), val => \$isdn->{io0}, advanced => 1 },
			 { label => N("Card IO_1"), val => \$isdn->{io1}, advanced => 1 },
			];
		    },
                    post => sub {
                        network::connection::isdn::apply_config($in, $isdn);
                        $net->{net_interface} = 'ippp0';
                        "isdn_dial_on_boot";
                    },
                   },

                   isdn =>
                   {
                    pre=> sub {
                        detect($modules_conf, $net->{autodetect}, 'isdn');
                        %isdn_cards = map { $_->{description} => $_ } @{$net->{autodetect}{isdn}};
                    },
                    name => N("Select the network interface to configure:"),
                    data =>  sub {
                        [ { label => N("Net Device"), type => "list", val => \$isdn_name, allow_empty_list => 1,
                            list => [ $my_isdn, N("External ISDN modem"), keys %isdn_cards ] } ];
                    },
                    post => sub {
                        if ($isdn_name eq $my_isdn) {
                            return "isdn_ask";
                        } elsif ($isdn_name eq N("External ISDN modem")) {
                            $net->{type} = 'isdn_external';
                            return "modem";
                        }

                        # FIXME: some of these should be taken from isdn db
                        $isdn = { map { $_ => $isdn_cards{$isdn_name}{$_} } qw(description vendor id card_type driver type mem io io0 io1 irq firmware) };

                        if ($isdn->{id}) {
                            log::explanations("found isdn card : $isdn->{description}; vendor : $isdn->{vendor}; id : $isdn->{id}; driver : $isdn->{driver}\n");
                            $isdn->{description} =~ s/\|/ -- /;
                        }

                        network::connection::isdn::read_config($isdn);
                        $isdn->{driver} = $isdn_cards{$isdn_name}{driver}; #- do not let config overwrite default driver

                        #- let the user choose hisax or capidrv if both are available
                        $isdn->{driver} ne "capidrv" && network::connection::isdn::get_capi_card($in, $isdn) and return "isdn_driver";
                        return "isdn_protocol";
                    },
                   },


                   isdn_ask =>
                   {
                    pre => sub {
                        %isdn_cards = network::connection::isdn::get_cards();
                    },
                    name => N("Select a device!"),
                    data => sub { [ { label => N("Net Device"), val => \$isdn_name, type => 'list', separator => '|', list => [ keys %isdn_cards ], allow_empty_list => 1 } ] },
                    pre2 => sub {
                        my ($label) = @_;

                        #- ISDN card already detected
                        goto isdn_ask_step_3;

                      isdn_ask_step_1:
                        my $e = $in->ask_from_list_(N("ISDN Configuration"),
                                                    $label . "\n" . N("What kind of card do you have?"),
                                                    [ N_("ISA / PCMCIA"), N_("PCI"), N_("USB"), N_("I do not know") ]
                                                   ) or return;
                      isdn_ask_step_1b:
                        if ($e =~ /PCI/) {
                            $isdn->{card_type} = 'pci';
                        } elsif ($e =~ /USB/) {
                            $isdn->{card_type} = 'usb';
                        } else {
                            $in->ask_from_list_(N("ISDN Configuration"),
                                                N("
If you have an ISA card, the values on the next screen should be right.\n
If you have a PCMCIA card, you have to know the \"irq\" and \"io\" of your card.
"),
                                                [ N_("Continue"), N_("Abort") ]) eq 'Continue' or goto isdn_ask_step_1;
                            $isdn->{card_type} = 'isa';
                        }

                      isdn_ask_step_2:
                        $e = $in->ask_from_listf(N("ISDN Configuration"),
                                                 N("Which of the following is your ISDN card?"),
                                                 sub { $_[0]{description} },
                                                 [ network::connection::isdn::get_cards_by_type($isdn->{card_type}) ]) or goto($isdn->{card_type} =~ /usb|pci/ ? 'isdn_ask_step_1' : 'isdn_ask_step_1b');
                        $e->{$_} and $isdn->{$_} = $e->{$_} foreach qw(driver type mem io io0 io1 irq firmware);

                        },
                    post => sub {
                        $isdn = $isdn_cards{$isdn_name};
                        return "isdn_protocol";
                    }
                   },


                   isdn_driver =>
                   {
                    pre => sub {
                        $isdn_name = "capidrv";
                    },
                    name => N("A CAPI driver is available for this modem. This CAPI driver can offer more capabilities than the free driver (like sending faxes). Which driver do you want to use?"),
                    data => sub { [
                                   { label => N("Driver"), type => "list", val => \$isdn_name,
                                     list => [ $isdn->{driver}, "capidrv" ] }
                                  ] },
                    post => sub {
                        $isdn->{driver} = $isdn_name;
                        return "isdn_protocol";
                    }
                   },


                   isdn_protocol =>
                   {
                    name => N("ISDN Configuration") . "\n\n" . N("Which protocol do you want to use?"),
                    data => [
                             { label => N("Protocol"), type => "list", val => \$isdn_type,
                               list => [ keys %isdn_protocols ], format => sub { $isdn_protocols{$_[0]} } }
                            ],
                    post => sub { 
                        $isdn->{protocol} = $isdn_type;
                        return "isdn_db";
                    }
                   },


                   isdn_db =>
                   {
                    name => N("ISDN Configuration") . "\n\n" . N("Select your provider.\nIf it is not listed, choose Unlisted."),
                    data => sub {
                        [ { label => N("Provider:"), type => "list", val => \$provider, separator => '|',
                            list => [ N("Unlisted - edit manually"), network::connection::isdn::read_providers_backend() ] } ];
                    },
		    next => "isdn_account",
                   },


                   no_supported_winmodem =>
                   {
                    name => N("Warning") . "\n\n" . N("Your modem is not supported by the system.
Take a look at http://www.linmodems.org"),
                    end => 1,
                   },


                   modem =>
                   {
                    pre => sub {
			require network::modem;
			detect($modules_conf, $net->{autodetect}, 'modem');
			$modem = {};
			if ($net->{type} eq 'isdn_external') {
			    #- FIXME: seems to be specific to ZyXEL Adapter Omni.net/TA 128/Elite 2846i
			    #- it does not even work with TA 128 modems
			    #- http://bugs.mandrakelinux.com/query.php?bug=1033
			    $modem->{special_command} = 'AT&F&O2B40';
			}
                    },
                    name => N("Select the modem to configure:"),
                    data => sub {
                        [ { label => N("Modem"), type => "list", val => \$modem_name, allow_empty_list => 1,
                            list => [ keys %{$net->{autodetect}{modem}}, N("Manual choice") ], } ];
                    },
		    complete => sub {
                        my $driver = $net->{autodetect}{modem}{$modem_name}{driver} or return 0;
                        #- some modem configuration programs modify modprobe.conf while we're loaded
                        #- so write it now and reload then
                        $modules_conf->write;
                        require network::connection::pots;
                        my $settings = network::thirdparty::apply_settings($in, 'pots', network::connection::pots::get_thirdparty_settings(), $driver);
                        $modem->{device} = $settings->{device} if $settings;
                        $modules_conf->read if $settings;
                        !$settings;
		    },
                    post => sub {
                        return 'choose_serial_port' if $modem_name eq N("Manual choice");
			if (exists $net->{autodetect}{modem}{$modem_name}{device}) {
			    #- this is a serial probed modem
			    $modem->{device} = $net->{autodetect}{modem}{$modem_name}{device};
			}
			if (exists $modem->{device}) {
			    return "ppp_provider";
			} else {
			    #- driver exists but device field hasn't been filled by network::thirdparty::setup_device
			    return "no_supported_winmodem";
			}
		    },
		   },


                   choose_serial_port =>
                   {
                    pre => sub {
                        $modem->{device} ||= readlink "$::prefix/dev/modem";
                    },
                    name => N("Please choose which serial port your modem is connected to."),
                    interactive_help_id => 'selectSerialPort',
                    data => sub {
                        [ { val => \$modem->{device}, format => \&mouse::serial_port2text, type => "list",
                            list => [ grep { $_ ne $mouse->{device} } (mouse::serial_ports(), glob_("/dev/ttyUSB*"), grep { -e $_ } '/dev/modem', '/dev/ttySL0', '/dev/ttyS14',) ] } ];
                        },
                    post => sub {
                        return 'ppp_provider';
                    },
                   },


                   ppp_provider =>
                   {
                    pre => sub {
                        add2hash($modem, network::modem::ppp_read_conf());
                        $in->do_pkgs->ensure_is_installed('kdenetwork-kppp-provider', $db_path);
                        my $p_db_path = "$::prefix$db_path";
                        @isp = map {
                            my $country = $_;
                            map { 
                                s!$p_db_path/$country!!;
                                s/%([0-9]{3})/chr(int($1))/eg;
                                $countries{$country} ||= translate($country);
                                join('', $countries{$country}, $_);
                            } grep { !/.directory$/ } glob_("$p_db_path/$country/*");
                        } map { s!$p_db_path/!!o; s!_! !g; $_ } glob_("$p_db_path/*") if !@isp;
                        $old_provider = $provider;
                    },
                    name => N("Select your provider:"),
                    data => sub {
                        [ { label => N("Provider:"), type => "list", val => \$provider, separator => '/',
                            list => [ N("Unlisted - edit manually"), @isp ] } ];
                    },
                    post => sub {
                        if ($provider ne N("Unlisted - edit manually")) {
                            ($country, $provider) = split('/', $provider);
                            $country = { reverse %countries }->{$country};
                            my %l = getVarsFromSh("$::prefix$db_path/$country/$provider");
                            if (defined $old_provider && $old_provider ne $provider) {
                                $modem->{connection} = $l{Name};
                                $modem->{phone} = $l{Phonenumber};
                                $modem->{$_} = $l{$_} foreach qw(Authentication AutoName Domain Gateway IPAddr SubnetMask);
                                ($modem->{dns1}, $modem->{dns2}) = split(',', $l{DNS});
                            }
                        }
                        return "ppp_account";
                    },
                   },


                   ppp_account =>
                   {
                    name => N("Dialup: account options"),
                    data => sub {
                            [
                             { label => N("Connection name"), val => \$modem->{connection} },
                             { label => N("Phone number"), val => \$modem->{phone} },
                             { label => N("Login ID"), val => \$modem->{login} },
                             { label => N("Password"), val => \$modem->{passwd}, hidden => 1 },
                             { label => N("Authentication"), val => \$modem->{Authentication},
                               list => [ sort keys %ppp_auth_methods ], format => sub { $ppp_auth_methods{$_[0]} } },
                            ];
                        },
                    next => "ppp_ip",
                   },


                   ppp_ip =>
                   {
                    pre => sub {
                        $modem_dyn_ip = sub { $modem->{auto_ip} eq N("Automatic") };
                    },
                    name => N("Dialup: IP parameters"),
                    data => sub {
                        [
                         { label => N("IP parameters"), type => "list", val => \$modem->{auto_ip}, list => [ N("Automatic"), N("Manual") ] },
                         { label => N("IP address"), val => \$modem->{IPAddr}, disabled => $modem_dyn_ip },
                         { label => N("Subnet mask"), val => \$modem->{SubnetMask}, disabled => $modem_dyn_ip },
                        ];
                    },
                    next => "ppp_dns",
                   },


                   ppp_dns =>
                   {
                    pre => sub {
                        $modem_dyn_dns = sub { $modem->{auto_dns} eq N("Automatic") };
                    },
                    name => N("Dialup: DNS parameters"),
                    data => sub {
                        [
                         { label => N("DNS"), type => "list", val => \$modem->{auto_dns}, list => [ N("Automatic"), N("Manual") ] },
                         { label => N("Domain name"), val => \$modem->{domain}, disabled => $modem_dyn_dns },
                         { label => N("First DNS Server (optional)"), val => \$modem->{dns1}, disabled => $modem_dyn_dns },
                         { label => N("Second DNS Server (optional)"), val => \$modem->{dns2}, disabled => $modem_dyn_dns },
                         { text => N("Set hostname from IP"), val => \$modem->{AutoName}, type => 'bool', disabled => $modem_dyn_dns },
                        ];
                    },
                    next => "ppp_gateway",
                   },


                   ppp_gateway =>
                   {
                    name => N("Dialup: IP parameters"),
                    data => sub {
                        [
                         { label => N("Gateway"), type => "list", val => \$modem->{auto_gateway}, list => [ N("Automatic"), N("Manual") ] },
                         { label => N("Gateway IP address"), val => \$modem->{Gateway},
                           disabled => sub { $modem->{auto_gateway} eq N("Automatic") } },
                        ];
                        },
                    post => sub {
                        network::modem::ppp_configure($net, $in, $modem);
                        $net->{net_interface} = 'ppp0';
                        "configure_control_compat";
                    },
                   },


                   configure_control_compat => {
                       pre => sub {
                           $connection_compat = $net->{type}->new($connection || {});
                           network::connection::guess_control_settings($connection_compat);
                           $control_settings = network::connection::get_control_settings($connection_compat);
                       },
                       name => sub { N("Connection control") },
                       data => sub { $control_settings },
                       post => sub {
                           $net->{ifcfg}{$net->{net_interface}}{USERCTL} = bool2yesno($connection_compat->{control}{userctl});
                           $net->{ifcfg}{$net->{net_interface}}{ONBOOT} = bool2yesno($connection_compat->{control}{onboot});
                           network::network::configure_network($net, $in, $modules_conf);
                           "ask_connect_now";
                       },
                   },

                   isdn_dial_on_boot =>
                   {
                    pre => sub {
                        $net->{ifcfg}{ippp0} ||= {}; # we want the ifcfg-ippp0 file to be written
                        $net->{ifcfg}{ippp0}{DEVICE} = "ippp0";
                        @isdn_dial_methods = ({ name => N("Automatically at boot"),
                                                ONBOOT => 1, DIAL_ON_IFUP => 1 },
                                              { name => N("By using Net Applet in the system tray"),
                                                ONBOOT => 0, DIAL_ON_IFUP => 1 },
                                              { name => N("Manually (the interface would still be activated at boot)"),
                                               ONBOOT => 1, DIAL_ON_IFUP => 0 });
                        my $method =  find {
                            $_->{ONBOOT} eq text2bool($net->{ifcfg}{ippp0}{ONBOOT}) &&
                              $_->{DIAL_ON_IFUP} eq text2bool($net->{ifcfg}{ippp0}{DIAL_ON_IFUP});
                        } @isdn_dial_methods;
                        #- use net_applet by default
                        $isdn->{dial_method} = $method->{name} || $isdn_dial_methods[1]{name};
                    },
                    name => N("How do you want to dial this connection?"),
                    data => sub {
                        [ { type => "list", val => \$isdn->{dial_method}, list => [ map { $_->{name} } @isdn_dial_methods ] } ];
                    },
                    post => sub {
                        my $method = find { $_->{name} eq $isdn->{dial_method} } @isdn_dial_methods;
                        $net->{ifcfg}{ippp0}{$_} = bool2yesno($method->{$_}) foreach qw(ONBOOT DIAL_ON_IFUP);
                        return "configure_control_compat";
                    },
                   },

                   ask_connect_now =>
                   {
                    name => N("Do you want to try to connect to the Internet now?"),
                    type => "yesorno",
                    post => sub {
                        my ($a) = @_;
                        my $type = $net->{type};
                        $up = 1;
                        if ($a) {
                            # local $::isWizard = 0;
                            my $_w = $in->wait_message(N("Please wait"), N("Testing your connection..."), 1);
                            network::tools::stop_net_interface($net, 0);
                            sleep 1;
                            network::tools::start_net_interface($net, 1);
                            my $s = 30;
                            $type =~ /modem/ and $s = 50;
                            $type =~ /isdn/ and $s = 20;
                            sleep $s;
                            $up = network::tools::connected();
                        }
                        $success = $up;
                        return $a ? "disconnect" : "end";
                    }
                   },


                   disconnect =>
                   {
                    name => sub {
                        $up ? N("The system is now connected to the Internet.") .
                          if_($::isInstall, N("For security reasons, it will be disconnected now.")) :
                            N("The system does not seem to be connected to the Internet.
Try to reconfigure your connection.");
                    },
                    no_back => 1,
                    end => 1,
                    post => sub {
                        $::isInstall and network::tools::stop_net_interface($net, 0);
                        return "end";
                    },
                   },


                   end =>
                   {
                    name => sub {
                        return $success ? join('', N("Congratulations, the network and Internet configuration is finished.

"), if_($::isStandalone && $in->isa('interactive::gtk'),
        N("After this is done, we recommend that you restart your X environment to avoid any hostname-related problems."))) :
          N("Problems occurred during configuration.
Test your connection via net_monitor or mcc. If your connection does not work, you might want to relaunch the configuration.");
                    },
                           end => 1,
                   },
                  },
        });
      $wiz->process($in);

      #- keeping the translations in case someone want to restore these texts
      if_(0,
          N("Alcatel speedtouch USB modem"),
          N("Sagem USB modem"),
          N("Bewan modem"),
          N("Bewan modem"),
          N("ECI Hi-Focus modem"), # this one needs eci agreement
          N("LAN connection"),
          N("Wireless connection"),
          N("ADSL connection"),
          N("Cable connection"),
          N("ISDN connection"),
          N("Modem connection"),
          N("DVB connection"),
	  # keep b/c of translations in case they can be reused somewhere else:
	  N("(detected on port %s)", 'toto'),
	  #-PO: here, "(detected)" string will be appended to eg "ADSL connection"
	  N("(detected %s)", 'toto'), N("(detected)"),
	  N("Network Configuration"),
	  N("Zeroconf hostname resolution"),
	  N("If desired, enter a Zeroconf hostname.
This is the name your machine will use to advertise any of
its shared resources that are not managed by the network.
It is not necessary on most networks."), 
	  N("Zeroconf Host name"),
	  N("Zeroconf host name must not contain a ."),
	  N("Because you are doing a network installation, your network is already configured.
Click on Ok to keep your configuration, or cancel to reconfigure your Internet & Network connection.
"),
	  N("The network needs to be restarted. Do you want to restart it?"),
	  N("A problem occurred while restarting the network: \n\n%s", 'foo'),
	  N("We are now going to configure the %s connection.\n\n\nPress \"%s\" to continue.", 'a', 'b'),
	  N("Configuration is complete, do you want to apply settings?"),
	  N("You have configured multiple ways to connect to the Internet.\nChoose the one you want to use.\n\n"),
	  N("Internet connection"),
          N("Select the network interface to configure:"),
          N("Configuring network device %s (driver %s)", '', ''),
          N("The following protocols can be used to configure a LAN connection. Please choose the one you want to use."),
          N("Please enter your host name.
Your host name should be a fully-qualified host name,
such as ``mybox.mylab.myco.com''.
You may also enter the IP address of the gateway if you have one."),
          # better looking text (to be merged into texts since some languages (eg: ja) doesn't need it
          N("Last but not least you can also type in your DNS server IP addresses."),
          N("DNS server address should be in format 1.2.3.4"),
          N("Gateway address should be in format 1.2.3.4"),
          N("Gateway device"),
	  );
}

sub safe_main {
    my ($net, $in, $modules_conf) = @_;
    eval { real_main($net, $in, $modules_conf) };
    my $err = $@;
    if ($err) { # && $in->isa('interactive::gtk')
	$err =~ /wizcancel/ and $in->exit(0);

	local $::isEmbedded = 0; # to prevent sub window embedding
        local $::isWizard = 0 if !$::isInstall; # to prevent sub window embedding
        #err_dialog(N("Error"), N("An unexpected error has happened:\n%s", $err));
        $in->ask_warn(N("Error"), N("An unexpected error has happened:\n%s", $err));
    }
}

1;

=head1 network::netconnect::detect()

=head2 example of usage

 use lib qw(/usr/lib/libDrakX);
 use network::netconnect;
 use modules;
 use Data::Dumper;

 my %i;
 my $modules_conf = modules::any_conf->read;
 network::netconnect::detect($modules_conf, \%i);
 print Dumper(\%i),"\n";

=cut
