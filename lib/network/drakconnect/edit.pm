package network::drakconnect::edit;

use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use ugtk3 qw(:create :dialogs :helpers :wrappers);
use mygtk3 qw(gtknew);
use common;
use detect_devices;
use run_program;
use network::drakconnect;
use network::adsl;
use network::connection::ethernet;
use network::connection::isdn;
use network::modem;
use network::network;

sub manage {
    my ($in, $net, $modules_conf) = @_;

    my $p = {};
    my ($interface_menu, $selected, $apply_button);
    my $window = ugtk3->new('Manage Connection');
    unless ($::isEmbedded) {
        $window->{rwindow}->set_position('center');
        $window->{rwindow}->set_title(N("Manage connections")); # translation availlable in mcc domain => we need merging
    }

    my $notebook = Gtk3::Notebook->new;
    $notebook->set_property('show-tabs', 0);
    $notebook->set_property('show-border', 0);

    my @all_cards = network::connection::ethernet::get_eth_cards($modules_conf);
    my %names = network::connection::ethernet::get_eth_cards_names(@all_cards);
    foreach (keys %names) {
	my $dev = detect_devices::is_lan_interface($_) ? $names{$_} : $_;
	$p->{$dev} = {
                      name => $_ ,
                      intf => $net->{ifcfg}{$_}
                     };
    }
    while (my ($device, $interface) = each %{$net->{ifcfg}}) {
        exists $names{$device} and next;
        my $type = network::tools::get_interface_type($interface);
        $p->{"$type ($device)"} = {
                                  name => $device,
                                  intf => $interface
                                 };
    }

    $window->{rwindow}->add(gtkpack_(Gtk3::VBox->new,
				     0, gtkpack__(Gtk3::HBox->new,
                                                  gtknew('Label', text => N("Device: "), alignment => [ 0, 0 ]),
                                                  $interface_menu = gtksignal_connect(Gtk3::ComboBoxText->new,
                                                                    changed => sub {
                                                                        $selected = $interface_menu->get_text;
                                                                        $notebook->set_current_page($p->{$selected}{gui}{index});
                                                                    },
                                                                                     ),
                                                 ),
				     1, $notebook,
				     0, create_okcancel(my $oc =
                                                        {
                                                         cancel_clicked => sub { $window->destroy; Gtk3->main_quit },
                                                         ok_clicked => sub {
                                                             if ($apply_button->get_property('sensitive')) {
                                                                 save($in, $net, $modules_conf, $p, $apply_button);
                                                             }
                                                             $window->destroy;
                                                             Gtk3->main_quit;
                                                         },
                                                        },
                                                        undef, undef, '',
                                                        [ N("Help"), sub { run_program::raw({ detach => 1 }, 'drakhelp', '--id', 'internet-connection') } ],
                                                        [ N("Apply"), sub { save($in, $net, $modules_conf, $p, $apply_button) }, 0, 1 ],
                                                       ),
                                    ),
                           );
    $apply_button = $oc->{buttons}{N("Apply")};

    each_index {
	my ($name, $interface) = ($_, $p->{$_}{name});
	$p->{$name}{gui}{index} = $::i;
	$p->{$name}{intf} ||= { DEVICE => $interface };
	build_tree($in, $net, $p->{$name}{intf}, $name);
	build_notebook($net, \@all_cards, $p->{$name}{intf}, $p->{$name}{gui}, $apply_button, $name, $interface);
	$notebook->append_page(gtkpack(Gtk3::VBox->new(0,0), $p->{$name}{gui}{notebook}));
    } (sort keys %$p);

    $interface_menu->set_popdown_strings(sort keys %$p);
    $interface_menu->set_active(0);
    $apply_button->set_sensitive(0);

    $window->{rwindow}->show_all;
    $window->main;
}

sub build_tree {
    my ($in, $net, $intf, $interface) = @_;

    if ($interface eq 'adsl') {
	$intf->{pages} = { 'TCP/IP' => 1, 'DHCP' => 1, 'Account' => 1, 'Options' => 1, 'Information' => 1 };
	network::adsl::adsl_probe_info($net);
	$intf->{save} = sub {
            $net->{type} = 'adsl';
            network::adsl::adsl_conf_backend($in, $net);
          };
    }
    elsif ($interface eq 'modem') {
	$intf->{pages} = { 'TCP/IP' => 1, 'Account' => 1, 'Modem' => 1, 'Options' => 1 };
	put_in_hash($intf, network::modem::ppp_read_conf());
	$intf->{save} = sub { network::modem::ppp_configure($net, $in, $intf) };
    }
    elsif ($interface eq 'isdn') {
	$intf->{pages} = { 'TCP/IP' => 1, 'Account' => 1, 'Modem' => 1, 'Options' => 1 };
	network::connection::isdn::read_config($intf);
	$intf->{save} = sub { network::connection::isdn::apply_config($in, $intf) };
    }
    else {
	#- ethernet is default
	$intf->{pages} = { 'TCP/IP' => 1, 'DHCP' => 1, if_(network::tools::get_interface_type($intf) eq "wifi", 'Wireless' => 1), 'Options' => 1, 'Information' => 1 };
    }
}

sub build_notebook {
    my ($net, $all_cards, $intf, $gui, $apply_button, $interface, $interface_name) = @_;

    my $apply = sub { $apply_button->set_sensitive(1) };
    my $is_ethernet = detect_devices::is_lan_interface($interface);

	my $size_group = Gtk3::SizeGroup->new('horizontal');

    if ($intf->{pages}{'TCP/IP'}) {
	gtkpack__($gui->{sheet}{'TCP/IP'} = gtkset_border_width(Gtk3::VBox->new(0,10), 5),
             gtknew('Title2', label => N("IP configuration")),
                                if_($is_ethernet,
                                    gtkpack(Gtk3::HBox->new(1,0),
                                                 gtknew('Label_Left', text => N("Protocol")),
                                                 $gui->{intf}{BOOTPROTO} = gtksignal_connect(Gtk3::ComboBoxText->new, changed => sub {
                                                     return if !$_[0]->realized;
                                                     my $proto = $gui->{intf}{BOOTPROTO};
                                                     my $protocol = $intf->{BOOTPROTO} = { reverse %{$proto->{protocols}} }->{$proto->get_text};

                                                     foreach ($gui->{intf}{IPADDR}, $gui->{intf}{NETMASK}, $gui->{network}{GATEWAY}) {
                                                         $_->set_sensitive(to_bool($protocol eq "static"));
                                                     }
                                                     $gui->{sheet}{DHCP}->set_sensitive($intf->{BOOTPROTO} eq 'dhcp');
                                                     $apply->();
                                                 },
                                                                                         ),
                                             ),
                                ),
                                gtkpack(Gtk3::HBox->new(1,0),
                                           gtknew('Label_Left', text => N("IP address")),
                                           gtksignal_connect($gui->{intf}{IPADDR} = Gtk3::Entry->new,
                                                                                        key_press_event => $apply),
                                       ),
                                gtkpack(Gtk3::HBox->new(1,0),
                                           gtknew('Label_Left', text => N("Netmask")),
                                           gtksignal_connect($gui->{intf}{NETMASK} = Gtk3::Entry->new,
                                                                                        key_press_event => $apply),
                                       ),
                                if_($is_ethernet,
                                    gtkpack(Gtk3::HBox->new(1,0),
                                               gtknew('Label_Left', text => N("Gateway")),
                                               gtksignal_connect($gui->{network}{GATEWAY} = Gtk3::Entry->new,
                                                                                            key_press_event => $apply),
                                           ),
                                ),
                         gtknew('Title2', label => N("DNS servers")),
               gtknew('Label_Left', text => join(', ', grep { $_ } $intf->{dns1} || $net->{resolv}{dnsServer},
                                                 $intf->{dns2} || $net->{resolv}{dnsServer2},
                                                 $intf->{dns3} || $net->{resolv}{dnsServer3}),
                  ),
                                gtkpack(Gtk3::HBox->new(1,0),
                                             gtknew('Label_Left', text => N("Search Domain")),
                                                    my $w2 = gtknew('Label_Left', text => $intf->{domain} || $net->{resolv}{DOMAINNAME} || 'none'),
                        ),
               );
     $size_group->add_widget($_) foreach $w2, $gui->{intf}{BOOTPROTO}, $gui->{intf}{IPADDR}, $gui->{intf}{NETMASK}, $gui->{network}{GATEWAY};

	if ($is_ethernet) {
            my $proto = $gui->{intf}{BOOTPROTO};
            $proto->{protocols} = { none => N("none"), static => N("static"), dhcp => N("DHCP") };
            $proto->set_popdown_strings(values %{$proto->{protocols}});
            $proto->set_text($proto->{protocols}{$intf->{BOOTPROTO} || 'none'});
            if ($intf->{BOOTPROTO} ne 'static') {
                $_->set_sensitive(0) foreach $gui->{intf}{IPADDR}, $gui->{intf}{NETMASK}, $gui->{network}{GATEWAY};
            }
	} else {
	    $_->set_sensitive(0) foreach $gui->{intf}{IPADDR}, $gui->{intf}{NETMASK}, $gui->{network}{GATEWAY};
	    delete $gui->{intf}{BOOTPROTO};
	}
	!$intf->{IPADDR} and ($intf->{IPADDR}, $gui->{active}, $intf->{NETMASK}) = network::drakconnect::get_intf_ip($net, $interface_name);
	$gui->{network}{$_}->set_text($net->{network}{$_}) foreach keys %{$gui->{network}};
    }

    if ($intf->{pages}{DHCP}) {
	gtkpack(gtkset_border_width($gui->{sheet}{DHCP} = Gtk3::HBox->new(0,10), 5),
                gtkpack__(gtkset_border_width(Gtk3::VBox->new(0,10), 5),
                          gtkpack__(Gtk3::HBox->new(1,0),
                                  gtknew('Label_Left', text => N("DHCP client")),
                                  gtksignal_connect($gui->{intf}{DHCP_CLIENT} = Gtk3::ComboBox->new_with_strings(\@network::connection::ethernet::dhcp_clients,
                                                                                                                 $intf->{DHCP_CLIENT} || $network::connection::ethernet::dhcp_clients[0]),
                                                    changed => $apply)),
                          gtksignal_connect($gui->{intf_bool}{NEEDHOSTNAME} = Gtk3::CheckButton->new(N("Assign host name from DHCP server (or generate a unique one)")), toggled => $apply),
                          gtkpack__(Gtk3::HBox->new(1,0),
                                    gtknew('Label_Left', text => N("DHCP host name")),
                                    gtksignal_connect($gui->{intf}{DHCP_HOSTNAME} = Gtk3::Entry->new,
                                                      key_press_event => $apply)),
                          gtkpack__(Gtk3::HBox->new(1,0),
                                    gtknew('Label_Left', text => N("DHCP timeout (in seconds)")),
                                    gtksignal_connect($gui->{intf}{DHCP_TIMEOUT} = Gtk3::Entry->new,
                                                      key_press_event => $apply)),
                          gtksignal_connect($gui->{intf_bool}{PEERDNS} = Gtk3::CheckButton->new(N("Get DNS servers from DHCP")), toggled => $apply),
                          gtksignal_connect($gui->{intf_bool}{PEERYP} = Gtk3::CheckButton->new(N("Get YP servers from DHCP")), toggled => $apply),
                          gtksignal_connect($gui->{intf_bool}{PEERNTPD} = Gtk3::CheckButton->new(N("Get NTPD servers from DHCP")), toggled => $apply),
                      ),
            );
	foreach (qw(NEEDHOSTNAME PEERDNS)) { #- default these settings to yes
	    defined $intf->{$_} or $intf->{$_} = "yes";
	}
	$gui->{intf}{$_}->set_text($intf->{$_}) foreach qw(DHCP_HOSTNAME DHCP_TIMEOUT);
	$gui->{intf_bool}{$_}->set_active(text2bool($intf->{$_})) foreach qw(NEEDHOSTNAME PEERDNS PEERYP PEERNTPD);
	$gui->{intf}{DHCP_CLIENT}->set_text($intf->{DHCP_CLIENT});
	$gui->{sheet}{DHCP}->set_sensitive($intf->{BOOTPROTO} eq 'dhcp');
    }
    my $size_group2 = Gtk3::SizeGroup->new('horizontal');
    $size_group2->add_widget($_) foreach $gui->{intf}{DHCP_HOSTNAME}, $gui->{intf}{DHCP_TIMEOUT}, $gui->{intf}{DHCP_CLIENT};

    if ($intf->{pages}{Wireless}) {
	gtkpack(gtkset_border_width($gui->{sheet}{Wireless} = Gtk3::HBox->new(0,10), 5),
		gtkpack_(Gtk3::VBox->new(0,0),
			 map { (0, gtkpack_(Gtk3::VBox->new(0,0),
					    1, Gtk3::Label->new($_->[0]),
					    0, gtksignal_connect($gui->{intf}{$_->[1]} = Gtk3::Entry->new,
								 key_press_event => $apply),
					   ));
			   } ([ N("Operating Mode"), "WIRELESS_MODE" ],
			      [ N("Network name (ESSID)"), "WIRELESS_ESSID" ],
			      [ N("Network ID"), "WIRELESS_NWID" ],
			      [ N("Operating frequency"), "WIRELESS_FREQ" ],
			      [ N("Sensitivity threshold"), "WIRELESS_SENS" ],
			      [ N("Bitrate (in b/s)"), "WIRELESS_RATE" ]
			     ),
			),
		Gtk3::VSeparator->new,
		gtkpack_(Gtk3::VBox->new(0,0),
			 map { (0, gtkpack_(Gtk3::VBox->new(0,0),
					    1, Gtk3::Label->new($_->[0]),
					    0, gtksignal_connect($gui->{intf}{$_->[1]} = Gtk3::Entry->new,
								 key_press_event => $apply),
					   ));
			   } ([ N("Encryption key"), 'WIRELESS_ENC_KEY' ],
			      [ N("RTS/CTS"), 'WIRELESS_RTS' ],
			      [ N("Fragmentation"), 'WIRELESS_FRAG' ],
			      [ N("iwconfig command extra arguments"),  'WIRELESS_IWCONFIG' ],
			      [ N("iwspy command extra arguments"), 'WIRELESS_IWSPY' ],
			      [ N("iwpriv command extra arguments"), 'WIRELESS_IWPRIV' ],
			     ),
			),
	       );
    }

    if ($intf->{pages}{Options}) {
	gtkpack__(gtkset_border_width($gui->{sheet}{Options} = Gtk3::VBox->new(0,10), 5),
                  $gui->{intf_bool}{ONBOOT} = gtksignal_connect(Gtk3::CheckButton->new(N("Start at boot")),
                                                                toggled => $apply),
                  if_($is_ethernet,
                      map { ($gui->{intf_bool}{$_->[0]} = gtksignal_connect(Gtk3::CheckButton->new($_->[1]),
                                                                            toggled => $apply));
                        } (
                           [ "MII_NOT_SUPPORTED", N("Network Hotplugging") ],
                          ),
                     ),
                  if_($interface eq 'isdn',
                      gtkpack(Gtk3::HBox->new(0,0),
                              gtkpack__(Gtk3::VBox->new(0,0),
                                        Gtk3::Label->new(N("Dialing mode")),
                                        my @dialing_mode_radio = gtkradio(("auto") x 2, "manual"),
                                       ),
                              Gtk3::VSeparator->new,
                              gtkpack__(Gtk3::VBox->new(0,0),
                                        Gtk3::Label->new(N("Connection speed")),
                                        my @speed_radio = gtkradio(("64 Kb/s") x 2, "128 Kb/s"),
                                       ),
                             ),
                      gtkpack__(Gtk3::HBox->new(0,5),
                               Gtk3::Label->new(N("Connection timeout (in sec)")),
                               gtksignal_connect($gui->{intf}{huptimeout} = Gtk3::Entry->new,
                                                    key_press_event => $apply),
                              ),
                     ),
                  gtkpack__(Gtk3::HBox->new(0,1),
                            gtknew('Label_Left', text => N("Metric")),
                            gtksignal_connect(gtkset_text($gui->{intf}{METRIC} = Gtk3::Entry->new, $intf->{METRIC}),
                                              key_press_event => $apply)),

                 );
        $dialing_mode_radio[0]->signal_connect(toggled => sub { $gui->{intf_radio}{dialing_mode} = 'auto'; $apply->() });
	$dialing_mode_radio[1]->signal_connect(toggled => sub { $gui->{intf_radio}{dialing_mode} = 'static'; $apply->() });
	$speed_radio[0]->signal_connect(toggled => sub { $gui->{intf_radio}{speed} = '64'; $apply->() });
	$speed_radio[1]->signal_connect(toggled => sub { $gui->{intf_radio}{speed} = '128'; $apply->() });
	$gui->{intf_bool}{ONBOOT}->set_active($intf->{ONBOOT} eq 'yes' ? 1 : 0);
	$gui->{intf_bool}{MII_NOT_SUPPORTED}->set_active($intf->{MII_NOT_SUPPORTED} eq 'no' ? 1 : 0);
    }

    if ($intf->{pages}{Account}) {
	if ($interface_name =~ /^speedtouch|sagem$/) {
	    $gui->{description} = $interface_name eq 'speedtouch' ? 'Alcatel|USB ADSL Modem (Speed Touch)' : 'Analog Devices Inc.|USB ADSL modem';
	}
	gtkpack_(gtkset_border_width($gui->{sheet}{Account} = Gtk3::VBox->new(0,10), 5),
		 if_($interface eq 'modem',
                      0, gtkpack(Gtk3::VBox->new(1,0),
				 gtkpack__(Gtk3::HBox->new, Gtk3::Label->new(N("Authentication"))),
				 gtkpack__(Gtk3::HBox->new, $gui->{intf}{auth} = gtksignal_connect(Gtk3::ComboBoxText->new,
                                                                                                   changed => $apply)),
				)),
		 map { (0, gtkpack(Gtk3::VBox->new(1,0),
                                   gtkpack__(Gtk3::HBox->new, Gtk3::Label->new($_->[0])),
                                   gtkpack__(Gtk3::HBox->new, $gui->{intf}{$_->[1]} = gtksignal_connect(Gtk3::Entry->new,
                                                                                                        key_press_event => $apply)),
                                  ),
		       );
		   } ([ N("Account Login (user name)"), 'login' ],
		      [ N("Account Password"), 'passwd' ],
		      if_($interface =~ /^(isdn|modem)$/, [ N("Provider phone number"), $1 eq 'modem' ? 'phone' : 'phone_out' ]),
		     ),
		);

	if ($interface eq 'modem') {
            my %auth_methods = map_index { $::i => $_ } N("PAP"), N("Terminal-based"), N("Script-based"), N("CHAP"), N("PAP/CHAP");
            $gui->{intf}{auth}->set_popdown_strings(sort values %auth_methods);
            $gui->{intf}{auth}->set_text($auth_methods{$intf->{Authentication}});
	}
	$gui->{intf}{passwd}->set_visibility(0);
    }

    if ($intf->{pages}{Modem}) {
	gtkpack(gtkset_border_width($gui->{sheet}{Modem} = Gtk3::HBox->new(0,10), 5),
		if_($interface eq 'modem',
                     gtkpack__(Gtk3::VBox->new(0,5),
                               (map { (gtkpack(Gtk3::VBox->new(1,0),
					       gtkpack__(Gtk3::HBox->new, Gtk3::Label->new($_->[0])),
					       gtkpack__(Gtk3::HBox->new, $gui->{intf}{$_->[1]} = gtksignal_connect(Gtk3::ComboBoxText->new,
                                                                                                                    changed => $apply)),
					      ),
                                   );
                                  } ([ N("Flow control"), 'FlowControl' ],
                                     [ N("Line termination"), 'Enter' ],
                                     [ N("Connection speed"), 'Speed' ],
                                    )),
                               # gtkpack(Gtk3::VBox->new(0,0), # no relative kppp option found :-(
                               #          Gtk3::Label->new(N("Dialing mode")),
                               # 	 gtkradio('', N("Tone dialing"), N("Pulse dialing")),
                               #        ),
                              ),
                     Gtk3::VSeparator->new,
                     gtkpack__(Gtk3::VBox->new(0,10),
                               gtkpack__(Gtk3::HBox->new(0,5),
                                         Gtk3::Label->new(N("Modem timeout")),
                                         $gui->{intf}{Timeout} = gtksignal_connect(Gtk3::SpinButton->new(Gtk3::Adjustment->new($intf->{Timeout}, 0, 120, 1, 5, 0), 0, 0),
                                                                                   value_changed => $apply),
                                        ),
                               gtksignal_connect($gui->{intf_bool}{UseLockFile} = Gtk3::CheckButton->new(N("Use lock file")),
                                                 toggled => $apply),
                               gtkpack__(Gtk3::HBox->new, gtksignal_connect($gui->{intf_bool}{WaitForDialTone} = Gtk3::CheckButton->new(N("Wait for dialup tone before dialing")),
                                                                            toggled => $apply)),
                               gtkpack__(Gtk3::HBox->new(0,5),
                                         Gtk3::Label->new(N("Busy wait")),
                                         $gui->{intf}{BusyWait} = gtksignal_connect(Gtk3::SpinButton->new(Gtk3::Adjustment->new($intf->{BusyWait}, 0, 120, 1, 5, 0), 0, 0),
                                                                                    value_changed => $apply),
                                        ),
                               gtkpack__(Gtk3::HBox->new(0,5),
                                         Gtk3::Label->new(N("Modem sound")),
                                         gtkpack__(Gtk3::VBox->new(0,5), my @volume_radio = gtkradio('', N("Enable"), N("Disable"))),
                                        ),
                              ),
                    ),
		if_($interface eq 'isdn',
                     gtkpack_(Gtk3::VBox->new(0,0),
                              map { (0, gtkpack(Gtk3::VBox->new(1,0),
						gtkpack__(Gtk3::HBox->new, Gtk3::Label->new($_->[0])),
						gtkpack__(Gtk3::HBox->new, $gui->{intf}{$_->[1]} = gtksignal_connect(Gtk3::Entry->new,
                                                                                                   key_press_event => $apply)),
					       ),
                                    );
                                } ([ N("Card IRQ"), 'irq' ],
                                   [ N("Card mem (DMA)"), 'mem' ],
                                   [ N("Card IO"), 'io' ],
                                   [ N("Card IO_0"), 'io0' ],
                                  ),
                             ),
                     Gtk3::VSeparator->new,
                     gtkpack__(Gtk3::VBox->new(0,0),
                               Gtk3::Label->new(N("Protocol")),
                               my @protocol_radio = gtkradio('', N("European protocol (EDSS1)"),
                                                             N("Protocol for the rest of the world\nNo D-Channel (leased lines)")),
                              ),
                    ),
	       );
	$protocol_radio[0]->signal_connect(toggled => sub { $gui->{intf_radio}{protocol} = 2; $apply->() });
	$protocol_radio[1]->signal_connect(toggled => sub { $gui->{intf_radio}{protocol} = 3; $apply->() });
	$volume_radio[0]->signal_connect(toggled => sub { $gui->{intf_radio}{Volume} = 1; $apply->() });
	$volume_radio[1]->signal_connect(toggled => sub { $gui->{intf_radio}{Volume} = 0; $apply->() });
	$gui->{intf}{FlowControl}->set_popdown_strings('Hardware [CRTSCTS]', 'Software [XON/XOFF]', 'None');
	$gui->{intf}{Enter}->set_popdown_strings('CR', 'CF', 'CR/LF');
	$gui->{intf}{Speed}->set_popdown_strings('2400', '9600', '19200', '38400', '57600', '115200');
    }

    if ($intf->{pages}{Information}) {
	my ($info) = $gui->{description} ?
	  find { $_->{description} eq $gui->{description} } detect_devices::probeall : network::connection::ethernet::mapIntfToDevice($interface_name);
	my @intfs = grep { $interface_name eq $_->[0] } @$all_cards;
	if (is_empty_hash_ref($info) && @intfs == 1) {
	    my $driver = $intfs[0][1];
	    my @cards = grep { $_->{driver} eq $driver } detect_devices::probeall();
	    @cards == 1 and $info = $cards[0];
	}

	gtkpack(gtkset_border_width($gui->{sheet}{Information} = Gtk3::VBox->new(0,10), 5),
		gtktext_insert(Gtk3::TextView->new,
			       join('',
				    map { $_->[0] . ": \x{200e}" . $_->[1] . "\n" } (
					 [ N("Vendor"), split('\|', $info->{description}) ],
					 [ N("Description"), reverse split('\|', $info->{description}) ],
					 [ N("Media class"), $info->{media_type} || '-' ],
					 [ N("Module name"), $info->{driver} || '-' ],
					 [ N("Mac Address"), c::get_hw_address($interface_name) || '-' ],
					 [ N("Bus"), $info->{bus} || '-' ],
					 [ N("Location on the bus"), $info->{pci_bus} || '-' ],
										    )
				   )
			      ),
	       );
    }

    foreach (keys %{$gui->{intf}}) {
        next if ref($gui->{intf}{$_}) !~ /Gtk3::(ComboBox|Entry)/;
        # skip unset fields:
        next if !$intf->{$_};
        # special case b/c of translation:
        next if member($_, qw(BOOTPROTO ));
        if ($_ eq "FlowControl") {
            # kppp is writing translated strings :-( (eg: s/Software/Logiciel/):
            # (let's hope that all translations use 'CRTSCTS' and 'XON/OFF' as substring)
            $gui->{intf}{$_}->set_text('Hardware [CRTSCTS]') if $intf->{$_} =~ /CRTSCTS/;
            $gui->{intf}{$_}->set_text('Software [XON/XOFF]') if $intf->{$_} =~ m!XON/XOFF!;
        } else {
            $gui->{intf}{$_}->set_text($intf->{$_});
        }
    }

    $gui->{notebook} = Gtk3::Notebook->new;
    populate_notebook($gui->{notebook}, $gui);
}

sub populate_notebook {
    my ($notebook, $gui) = @_;
    foreach ('TCP/IP', 'DHCP', 'Account', 'Wireless', 'Modem', 'Options', 'Information') {
	!$gui->{sheet}{$_} and next;
	$notebook->append_page($gui->{sheet}{$_}, Gtk3::Label->new(translate($_)));
    }
}

sub save {
    my ($in, $net, $modules_conf, $p, $apply_button) = @_;

    my $dialog = _create_dialog(N("Please wait"));
    gtkpack($dialog->vbox,
            gtkshow(Gtk3::Label->new(N("Please Wait... Applying the configuration"))));
    $dialog->show_all;
    gtkset_mousecursor_wait();

    Glib::Timeout->add(200, sub {
                           gtkflush();
                           delete $net->{network}{GATEWAY};
                           foreach (keys %$p) {
                               save_notebook($in, $net, $p->{$_}{intf}, $p->{$_}{gui}) or return;
                               $p->{$_}{intf}{save} and $p->{$_}{intf}{save}->();
                           }
                           network::drakconnect::apply($in, $net, $modules_conf);
                           system("/etc/rc.d/init.d/network restart");
                           $dialog->response(0);
                       });
    $dialog->run;

    $apply_button->set_sensitive(0);
    gtkset_mousecursor_normal();
    $dialog->destroy;
}

sub save_notebook {
    my ($in, $net, $intf, $gui) = @_;

    if ($gui->{network}{GATEWAY}->is_sensitive && $gui->{network}{GATEWAY}->get_text) {
        $net->{network}{GATEWAY} =  $gui->{network}{GATEWAY}->get_text;
    }
    $gui->{intf}{$_} and $intf->{$_} = $gui->{intf}{$_}->get_text foreach keys %{$gui->{intf}};
    $gui->{intf_radio}{$_} and $intf->{$_} = $gui->{intf_radio}{$_} foreach keys %{$gui->{intf_radio}};
    $intf->{$_} = bool2yesno($gui->{intf_bool}{$_}->get_active) foreach keys %{$gui->{intf_bool}};
    $gui->{intf_bool}{MII_NOT_SUPPORTED} and $intf->{MII_NOT_SUPPORTED} = bool2yesno(!$gui->{intf_bool}{MII_NOT_SUPPORTED}->get_active);

    if (my $proto = $gui->{intf}{BOOTPROTO}) {
        $intf->{BOOTPROTO} = { reverse %{$proto->{protocols}} }->{$proto->get_text};
    }
    if ($intf->{BOOTPROTO} eq 'static') {
        if (!is_ip($intf->{IPADDR})) {
            $in->ask_warn(N("Error"), N("IP address should be in format 1.2.3.4"));
            return 0;
        }
        if (!is_ip($intf->{NETMASK})) {
            $in->ask_warn(N("Error"), N("Netmask should be in format 255.255.224.0"));
            return 0;
        }
    }

    delete $intf->{IPADDR} if $intf->{IPADDR} eq N("No IP");
    delete $intf->{NETMASK} if $intf->{NETMASK} eq N("No Mask");

    if ($net->{network}{GATEWAY} && !is_ip($net->{network}{GATEWAY})) {
        $in->ask_warn(N("Error"), N("Gateway address should be in format 1.2.3.4"));
        return 0;
    }
    1;
}

1;
