package network::drakvpn;

=head1 NAME

network::drakvpn - Interactive VPN configuration

=head1 SYNOPSIS

 use interactive;
 use network::drakvpn;

 my $in = 'interactive'->vnew('su');
 network::drakvpn::create_connection($in);

=cut


use common;

use network::vpn;

sub create_connection {
    my ($in) = @_;
    my $vpn_type;
    my $vpn_connection;
    my $new_name;
    require wizards;
    my $wiz = wizards->new({
        defaultimage => "drakvpn",
        name => N("VPN configuration"),
        pages => {
            welcome => {
                if_(!$::isInstall, no_back => 1),
                name => N("Choose the VPN type"),
                data => [ {
                    val => \$vpn_type, type => 'list',
                    list => [ sort { $a->get_description cmp $b->get_description } network::vpn::list_types ],
                    format => sub { $_[0] && $_[0]->get_description },
                    allow_empty_list => 1,
                } ],
                complete => sub {
                    $vpn_type or return 1;
                    my @packages = $vpn_type->get_packages;
                    if (@packages && !$in->do_pkgs->install(@packages)) {
                        $in->ask_warn(N("Error"), N("Could not install the packages (%s)!", join(', ', @packages)));
                        return 1;
                    }
                    if ($vpn_type->can('prepare')) {
                        my $wait = $in->wait_message(N("Please wait"), N("Initializing tools and detecting devices for %s...", $vpn_type->get_type));
                        if (!$vpn_type->prepare) {
                          undef $wait;
                          $in->ask_warn(N("Error"), N("Unable to initialize %s connection type!", $vpn_type->get_type));
                          return 1;
                        }
                    }
                },
                next => "vpn_name",
            },
            vpn_name => {
                name => N("Please select an existing VPN connection or enter a new name."),
                data => sub { [
                    { label => N("VPN connection"), val => \$vpn_connection, type => 'list',
                      list => [ $vpn_type->get_configured_connections, '' ],
                      format => sub { $_[0] ? $_[0]{name} : N("Configure a new connection...") },
                      gtk => { use_boxradio => 1 } },
                    { label => N("New name"), val => \$new_name, disabled => sub { $vpn_connection } },
                ] },
                complete => sub {
                    if (!$vpn_connection && !$new_name) {
                        $in->ask_warn(N("Warning"), N("You must select an existing connection or enter a new name."));
                        1;
                    }
                },
                post => sub {
                    $vpn_connection ||= $vpn_type->new($new_name);
                    $vpn_connection->read_config;
                    $vpn_connection->can('get_key_settings') ? "vpn_key_settings" : "vpn_settings";
                },
            },
            vpn_key_settings => {
                name => N("Please enter the required key(s)"),
                data => sub { $vpn_connection->get_key_settings },
                next => "vpn_settings",
            },
            vpn_settings => {
                name => N("Please enter the settings of your VPN connection"),
                data => sub { $vpn_connection->get_settings },
                post => sub {
                    $vpn_connection->write_config;
                    "connect";
                },
            },
            connect => {
                name => N("Do you want to start the connection now?"),
                type => "yesorno",
                post => sub {
                    my ($connect) = @_;
                    if ($connect) {
                        $vpn_connection->is_started and $vpn_connection->stop;
                        $vpn_connection->start($in) or $in->ask_warn(N("Warning"), N("Connection failed."));
                    }
                    require network::network;
                    network::network::reload_net_applet();
                    "end";
                },
            },
            end => {
                name => N("The VPN connection is now configured.

This VPN connection can be automatically started together with a network connection.
It can be done by reconfiguring the network connection and selecting this VPN connection.
"),
                end => 1,
            },
        },
    });
    $wiz->process($in);
}

1;
