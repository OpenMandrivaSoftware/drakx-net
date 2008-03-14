package network::drakconnect::delete;
use lib qw(/usr/lib/libDrakX);

use common;
use wizards;
use interactive;

sub del_intf {
    my ($in, $net, $modules_conf) = @_;
    my ($intf2delete, $failure);
    if (!keys %{$net->{ifcfg}}) {
      $in->ask_warn(N("Error"), N("No ethernet network adapter has been detected on your system. Please run the hardware configuration tool."));
      $in->exit(0);
    }
    my @all_cards = network::connection::ethernet::get_eth_cards($modules_conf);
    my %names = network::connection::ethernet::get_eth_cards_names(@all_cards);

    my $wiz = wizards->new(
      {
       defaultimage => "drakconnect",
       name => N("Remove a network interface"),
       pages => {
                 welcome => {
                             no_back => 1,
                             name => N("Select the network interface to remove:"),
                             data =>  [ { label => N("Net Device"), val => \$intf2delete, allow_empty_list => 1,
                                          list => [ keys %{$net->{ifcfg}} ],
                                          format => sub {
                                              my $type = network::tools::get_interface_type($net->{ifcfg}{$_[0]});
                                              $names{$_[0]} || ($type ? "$type ($_[0])" : $_[0]);
                                            }
                                        }
                                      ],
                             post => sub {
                                 !$::testing and eval {
                                     if (member($intf2delete, qw(adsl modem))) {
                                         eval { rm_rf("/etc/ppp/peers/ppp0") };
                                         eval { rm_rf("/etc/sysconfig/network-scripts/ifcfg-ppp0") };
                                     }
                                     if ($intf2delete eq 'adsl') {
                                         eval { rm_rf("/etc/sysconfig/network-scripts/ifcfg-sagem") };
                                     } elsif ($intf2delete eq 'isdn') {
                                         eval { rm_rf("/etc/sysconfig/network-scripts/ifcfg-ippp0") };
                                     } else {
                                         system("ifdown $intf2delete");
                                         eval { rm_rf("/etc/sysconfig/network-scripts/$intf2delete") };
                                         eval { rm_rf("/etc/sysconfig/network-scripts/ifcfg-$intf2delete") };
                                     }
                                 };
                                 $failure = $@;
                                 network::network::reload_net_applet();
                                 return "end";
                             },
                            },
                 end => {
                         name => sub {
                             $failure ?
                               N("An error occurred while deleting the \"%s\" network interface:\n\n%s", $intf2delete, $failure)
                             : N("Congratulations, the \"%s\" network interface has been successfully deleted", $intf2delete);
                         },
                         end => 1,
                        },
                },
      });
    $wiz->safe_process($in);
    $in->exit(0);
}

1;
