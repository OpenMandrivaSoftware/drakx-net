package network::drakconnect::global;

use ugtk2 qw(:create :dialogs :helpers :wrappers);
use mygtk2 qw(gtknew);
use common;
use network::drakconnect;
use network::test;

my $net_test;
sub update_network_status {
    my ($int_state) = @_;
    unless ($net_test) {
        $net_test = network::test->new;
        $net_test->start;
    }
    if ($net_test->is_done) {
        my $isconnected = $net_test->is_connected;
        $int_state->set($isconnected ? N("Connected") : N("Not connected"));
        $net_test->start;
    }
    1;
}

sub configure_net {
    my ($in, $net, $modules_conf) = @_;
    my $int_state;
    my $int_label = Gtk2::WrappedLabel->new($net->{type} eq 'lan' ? N("Gateway:") : N("Interface:"));
    my $int_name = Gtk2::Label->new($net->{type} eq 'lan' ? $net->{network}{GATEWAY} : $net->{net_interface});

    my $dialog = ugtk2->new(N("Internet connection configuration"));
    my $exit_dialogsub = sub { Gtk2->main_quit };
    if (!$net->{type}) {
        $in->ask_warn(
                    N("Warning"),
                    N("You do not have any configured Internet connection.
Run the \"%s\" assistant from the Mageia Control Center", N("Set up a new network interface (LAN, ISDN, ADSL, ...)")));
        return;
    }
    unless ($::isEmbedded) {
        $dialog->{rwindow}->set_position('center');
        $dialog->{rwindow}->set_size_request(-1, -1);
        $dialog->{rwindow}->set_icon(gtkcreate_pixbuf("drakconnect"));
    }
    $dialog->{rwindow}->signal_connect(delete_event => $exit_dialogsub);

    my $param_vbox = Gtk2::VBox->new(0,0);
    my $i = 0;

    my @conf_data = (
                     [ N("Host name (optional)"), \$net->{network}{HOSTNAME} ],
                     [ N("First DNS Server (optional)"),  \$net->{resolv}{dnsServer} ],
                     [ N("Second DNS Server (optional)"), \$net->{resolv}{dnsServer2} ],
                     [ N("Third DNS server (optional)"),  \$net->{resolv}{dnsServer3} ],
                    );
    my @infos;
    gtkpack($param_vbox,
            create_packtable({},
                             map {
                                 my $c;
                                 if (defined $_->[2]) {
                                     $c = Gtk2::Combo->new;
                                     $c->set_popdown_strings(@{$_->[2]});
                                     $infos[2*$i+1] = $c->entry;
                                 } else {
                                     $c = $infos[2*$i+1] = Gtk2::Entry->new;
                                 }
                                 $infos[2*$i+1]->set_text(${$_->[1]});
                                 $i++;
                                 [ Gtk2::WrappedLabel->new($_->[0]), $c ];
                             } @conf_data
                            )
           );

    $dialog->{rwindow}->add(gtkpack_(Gtk2::VBox->new,
                                     0, Gtk2::Label->new(N("Internet Connection Configuration")),
                                     1, gtkadd(gtkcreate_frame(N("Internet access")),
                                               gtkset_border_width(create_packtable({ col_spacings => 5, row_spacings => 5, homogenous => 1 },
                                                                                    [ Gtk2::WrappedLabel->new(N("Connection type: ")),
                                                                                      Gtk2::WrappedLabel->new(translate($net->{type})) ],
                                                                                    [ $int_label, $int_name ],
                                                                                    [ Gtk2::WrappedLabel->new(N("Status:")),
                                                                                      $int_state = Gtk2::WrappedLabel->new(N("Testing your connection...")) ]
                                                                                   ),
                                                                   5),
                                              ),
                                     1, gtkadd(gtkcreate_frame(N("Parameters")), gtkset_border_width($param_vbox, 5)),
                                     0, gtkpack(create_hbox('edge'),
                                                gtksignal_connect(Gtk2::Button->new(N("Cancel")), clicked => $exit_dialogsub),
                                                gtksignal_connect(Gtk2::Button->new(N("Ok")), clicked => sub {
                                                                          foreach my $i (0..$#conf_data) {
                                                                              ${$conf_data[$i][1]} = $infos[2*$i+1]->get_text;
                                                                          }
                                                                          network::drakconnect::apply($in, $net, $modules_conf);
                                                                          $exit_dialogsub->();
                                                                      }),
                                                ),
                                    ),
                           );

    $dialog->{rwindow}->show_all;
    my $update = sub { update_network_status($int_state) };
    $update->();
    Glib::Timeout->add(2000, $update);
    $dialog->main;
}

1;
