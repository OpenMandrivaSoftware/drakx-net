package network::vpn;

=head1 NAME

network::vpn - VPN connection abstract class

=cut

use strict;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;

my $vpn_d = "/etc/sysconfig/network-scripts/vpn.d";

=head1 CLASS METHODS

=head2 Generic class methods

=over

=item list_types

List supported VPN types

=cut

sub list_types {
    common::load_modules_from_base(__PACKAGE__);
}

=item get_configured_connections

Return list of configured connections for this class

=cut

sub get_configured_connections {
    my ($class) = @_;
    map { if_(/^(.*).conf$/, $class->new($1)) } all($::prefix . $vpn_d . '/' . $class->get_type);
}

=item new(NAME)

Create a new VPN connection object named NAME

=cut

sub new {
    my ($class, $name) = @_;
    bless {
        name => $name,
    }, $class;
}

=back

=head2 Pure virtual class methods

=over

=item get_type

Return VPN type (preferably one lowercase word)

=item get_description

Return description of the VPN type

=item get_packages

List package required for configuration

=back

=head1 INSTANCE METHODS

=head2 Generic instance methods

=over

=item get_name

Return name of the VPN connection

=cut

sub get_name {
    my ($connection) = @_;
    $connection->{name};
}

=item get_label

Return label of the VPN connection

=cut

sub get_label {
    my ($connection) = @_;
    sprintf("%s (%s)", $connection->get_name, $connection->get_type);
}

=item get_config_path

Get configuration file path

=cut

sub get_config_path {
    my ($connection) = @_;
    $::prefix . $vpn_d . '/' . $connection->get_type . '/' . $connection->get_name . '.conf';
}

sub _run {
    my ($connection, $action, @args) = @_;
    my @command = ('vpn-' . $action, $connection->get_type, $connection->get_name, @args);
    @command = common::wrap_command_for_root(@command) if $>;
    require run_program;
    run_program::rooted($::prefix, , @command);
}

=item start($o_in)

Start the VPN connection

$o_in is an interactive object used to interact with the user,
used if some interactive username/passwords are required.
If not specified, there is no user interaction.

=cut

sub start {
    my ($connection, $_o_in) = @_;
    $connection->_run('start');
}

=item stop

Stop the VPN connection

=cut

sub stop {
    my ($connection) = @_;
    $connection->_run('stop');
}

=item is_started

Returns true if the VPN connection is started

=cut

sub is_started {
    my ($connection) = @_;
    my $pid = chomp_(cat_($::prefix . '/var/run/' . $connection->get_type . '-' . $connection->get_name . '.pid'));
    $pid && -e '/proc/' . $pid;
}

=back

=head2 Pure virtual instance methods

=over

=item read_config

Read configuration from the file returned by get_config_path()

=item write_config

Write configuration to the file returned by get_config_path()

=item get_settings

Return an array ref of interactive settings

=back

=head2 Optional instance methods

=over

=item prepare

Run commands or services that are required for the VPN type

=back

=cut

1;
