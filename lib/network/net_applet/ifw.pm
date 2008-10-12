package network::net_applet::ifw;

use common;
use network::ifw;
use ugtk2 qw(:create :helpers :wrappers :dialogs);
use mygtk2 qw(gtknew gtkset);

sub create() {
    $network::net_applet::ifw = network::ifw->new($network::net_applet::dbus, sub {
        my ($_con, $msg) = @_;
        my $member = $msg->get_member;
        if ($member eq 'Attack') {
            handle_ifw_message($msg->get_args_list);
        } elsif ($member eq 'Listen') {
            handle_ifw_listen($msg->get_args_list);
        } elsif ($member eq 'Init') {
            $network::net_applet::ifw->attach_object;
            main::checkNetworkForce();
        } elsif ($member eq 'AlertAck') {
            $network::net_applet::ifw_alert = 0;
        }
    });
}

sub enable_ifw_alert() {
    unless ($network::net_applet::ifw_alert) {
        $network::net_applet::ifw_alert = 1;
        network::net_applet::update_tray_icon();
        Glib::Timeout->add(1000, sub {
            network::net_applet::update_tray_icon();
            $network::net_applet::ifw_alert;
        });
    }
}

sub disable_ifw_alert() {
    eval { $network::net_applet::ifw->send_alert_ack };
    $network::net_applet::ifw_alert = 0;
    network::net_applet::update_tray_icon();
}

sub get_unprocessed_ifw_messages() {
    my @packets = eval { $network::net_applet::ifw->get_reports };
    while (my @ifw_message = splice(@packets, 0, 10)) {
        handle_ifw_message(@ifw_message);
    }
}

sub set_verdict {
    my ($attack, $apply_verdict) = @_;
    eval { $apply_verdict->($attack) };
    $@ and err_dialog(N("Interactive Firewall"), N("Unable to contact daemon"));
}

sub apply_verdict_blacklist {
    my ($attack) = @_;
    $network::net_applet::ifw->set_blacklist_verdict($attack->{seq}, 1);
}

sub apply_verdict_ignore {
    my ($attack) = @_;
    $network::net_applet::ifw->set_blacklist_verdict($attack->{seq}, 0);
}

sub apply_verdict_whitelist {
    my ($attack) = @_;
    $network::net_applet::ifw->whitelist($attack->{addr});
    apply_verdict_ignore($attack);
}

sub handle_ifw_message {
    my $message = network::ifw::attack_to_hash(\@_);
    unless ($message->{msg}) {
        print "unhandled attack type, skipping\n";
        return;
    }
    my $is_attack = $message->{prefix} ne 'NEW';
    enable_ifw_alert() if $is_attack;
    $network::net_applet::notification_queue->add({
        title => N("Interactive Firewall"),
        pixbuf => $network::net_applet::pixbufs{firewall},
        message => $message->{msg},
        timeout => sub {
            set_verdict($message, \&apply_verdict_ignore);
        },
        if_($is_attack,
            urgency => 'critical',
            actions => [ {
                action => 'clicked',
                label => #-PO: "Process" is a verb
                  N("Process attack"),
                callback => sub {
                    disable_ifw_alert();
                    ask_attack_verdict($message);
                },
            } ],
        ),
    });
}

sub ask_attack_verdict {
    my ($attack) = @_;

    my $w = ugtk2->new(N("Interactive Firewall: intrusion detected"),
                       icon => "drakfirewall");
    my ($blacklist, $whitelist, $ignore, $auto);

    my $update_automatic_mode = sub { $auto->get_active and $network::net_applet::interactive_cb->set_active(1) };
    my $set_verdict = sub {
        my ($verdict) = @_;
        set_verdict($attack, $verdict);
        $network::net_applet::notification_queue->process_next;
    };
    gtkadd($w->{window},
           gtknew('VBox', spacing => 5, children_loose => [
               gtknew('HBox', children => [
                   0, Gtk2::Image->new_from_stock('gtk-dialog-warning', 'dialog'),
                   0, gtknew('Label', text => "   "),
                   1, gtknew('VBox', children => [
                       0, $attack->{msg},
                       0, N("What do you want to do with this attacker?")
                   ])
               ]),
               gtksignal_connect(gtkadd(Gtk2::Expander->new(N("Attack details")),
                                        gtknew('HBox', children => [
                                            0, gtknew('Label', text => "     "),
                                            1, gtknew('VBox', children_loose => [
                                                N("Attack time: %s", $attack->{date}),
                                                N("Network interface: %s", $attack->{indev}),
                                                N("Attack type: %s", $attack->{prefix}),
                                                if_($attack->{protocol}, N("Protocol: %s", $attack->{protocol})),
                                                N("Attacker IP address: %s", $attack->{ip_addr}),
                                                if_($attack->{hostname} ne $attack->{ip_addr}, N("Attacker hostname: %s", $attack->{hostname})),
                                                (
                                                    $attack->{service} ne $attack->{port} ?
                                                      N("Service attacked: %s", $attack->{service}) :
                                                      N("Port attacked: %s", $attack->{port}),
                                                ),
                                                if_($attack->{icmp_type}, N("Type of ICMP attack: %s", $attack->{icmp_type}))
                                            ]),
                                        ])),
                                 activate => sub { $_[0]->get_expanded and $w->shrink_topwindow }
                             ),
               $auto = gtknew('CheckButton', text => N("Always blacklist (do not ask again)"), toggled => sub {
                   $whitelist->set_sensitive(!$_[0]->get_active);
                   $ignore->set_sensitive(!$_[0]->get_active);
               }),
               gtknew('HButtonBox', layout => 'edge', children_loose => [
                   $blacklist = gtknew('Button', text => N("Blacklist"), clicked => sub {
                       $w->destroy;
                       $update_automatic_mode->();
                       $set_verdict->(\&apply_verdict_blacklist);
                   }),
                   $whitelist = gtknew('Button', text => N("Whitelist"), clicked => sub {
                       $w->destroy;
                       $update_automatic_mode->();
                       $set_verdict->(\&apply_verdict_whitelist);
                   }),
                   $ignore = gtknew('Button', text => N("Ignore"), clicked => sub {
                       $w->destroy;
                       $set_verdict->(\&apply_verdict_ignore);
                   }),
               ]),
           ]));
    eval { $auto->set_active(!$network::net_applet::ifw->get_interactive) };
    $blacklist->grab_focus;
    gtksignal_connect($w->{window}, delete_event => sub {
        $set_verdict->(\&apply_verdict_ignore);
    });
    $w->{window}->show_all;
}

sub handle_ifw_listen {
    my $listen = network::ifw::parse_listen_message(\@_);
    enable_ifw_alert();
    $network::net_applet::notification_queue->add({
        title => N("Interactive Firewall: new service"),
        pixbuf => $network::net_applet::pixbufs{firewall},
        message => $listen->{message},
        actions => [ {
            action => 'clicked',
            label => #-PO: "Process" is a verb
              N("Process connection"),
            callback => sub {
                disable_ifw_alert();
                ask_listen_verdict($listen);
            },
        } ],
    });
}

sub ask_listen_verdict {
    my ($listen) = @_;

    my $w = ugtk2->new(N("Interactive Firewall: new service"), icon => "drakfirewall");
    my $set_verdict = sub {
        $network::net_applet::notification_queue->process_next;
    };
    gtkadd($w->{window},
           gtknew('VBox', spacing => 5, children_loose => [
               gtknew('HBox', children => [
                   0, Gtk2::Image->new_from_stock('gtk-dialog-warning', 'dialog'),
                   1, gtknew('VBox', children => [
                       0, $listen->{message},
                       0, N("Do you want to open this service?"),
                   ])
               ]),
               gtknew('CheckButton', text => N("Remember this answer"), toggled => sub {}),
               gtknew('HButtonBox', layout => 'edge', children_loose => [
                   gtknew('Button', text => N("Allow"), clicked => sub { $w->destroy; $set_verdict->(1) }),
                   gtknew('Button', text => N("Block"), clicked => sub { $w->destroy; $set_verdict->(0) }),
               ]),
           ]));
    gtksignal_connect($w->{window}, delete_event => sub { $set_verdict->() });
    $w->{window}->show_all;
}

1;
