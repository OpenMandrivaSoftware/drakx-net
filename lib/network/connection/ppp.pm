package network::connection::ppp;

use strict;
use common;

use base qw(network::connection);

my %authentication_methods = (
    script => N_("Script-based"),
    pap => N_("PAP"),
    terminal_ => N_("Terminal-based"),
    chap => N_("CHAP"),
    pap_chap => N_("PAP/CHAP"),
);

my @kppp_authentication_methods = qw(script pap terminal chap pap_chap);
my @secrets_files = qw(pap-secrets chap-secrets);

sub get_access_settings {
    my ($self) = @_;
    [
        { label => N("Account Login (user name)"), val => \$self->{access}{login} },
        { label => N("Account Password"),  val => \$self->{access}{password}, hidden => 1 },
    ];
}

sub get_secret {
    my ($_self, $login) = @_;
    foreach (@secrets_files) {
        my $file = "$::prefix/etc/ppp/$_";
	foreach (cat_($file)) {
	    my ($l, undef, $password) = split(' ');
	    if ($l && $password) {
		s/^(['"]?)(.*)\1$/$2/ foreach $l, $password;
                return $password if $l eq $login;
	    }
	}
    }
}

sub write_secrets {
    my ($self) = @_;
    foreach (@secrets_files) {
        my $file = "$::prefix/etc/ppp/$_";
	substInFile {
            s/^'$self->{access}{login}'.*\n//;
            $_ .= "\n'$self->{access}{login}' * '$self->{access}{password}' * \n" if eof;
        } $file;
	chmod 0600, $file;
    }
}

sub get_options {
    #- options: PAPNAME PEERDNS
}

sub get_tty_device { "/dev/modem" }

sub build_ifcfg_settings {
    my ($self) = @_;
    my $modemport = $self->get_tty_device;
    my $settings = put_in_hash($self->{settings}, {
        if_($modemport, MODEMPORT => $modemport),
        LINESPEED => "115200",
        PERSIST => "yes",
        DEFROUTE => "yes",
        #- FIXME: move in network::connection::cellular or network::connection::ellular_card
        if_($self->get_interface !~ /^hso/, DEBUG => "yes"),
        if_($self->{access}{cid}, CELLULAR_CID => $self->{access}{cid}),
    });
    $self->SUPER::build_ifcfg_settings($settings);
}

sub build_chat {
    my ($self) = @_;
    #- optional:
    #-   auth_method: key of %authentication_methods
    #-   dial_number
    #-   login
    #-   password
    #-   at_commands: array ref of AT commands
    (map { "ABORT $_" } "BUSY", "ERROR", "'NO CARRIER'", "'NO DIALTONE'", "'Invalid Login'", "'Login incorrect'", "VOICE", "'NO ANSWER'", "DELAYED", "'SIM PIN'"),
    qq('' ATZ),
    if_(ref $self->{access}{at_commands}, map { qq(OK-AT-OK '$_') } @{$self->{access}{at_commands}}),
    if_($self->{access}{dial_number},
        qq(OK 'ATDT$self->{access}{dial_number}'),
        qq(TIMEOUT 120),
        qq(CONNECT ''),
        if_(member($self->{access}{auth_method}, qw(script terminal)),
            qq('ogin:--ogin:' '$self->{access}{login}'),
            qq('ord:' '$self->{access}{password}')),
        qq(TIMEOUT 5),
        qq('~--' ''),
    );
}

sub get_chat_file {
    my ($self) = @_;
    "/etc/sysconfig/network-scripts/chat-" . $self->get_interface;
}

sub write_chat {
    my ($self) = @_;
    output_with_perm($::prefix . $self->get_chat_file, 0755, join("\n", $self->build_chat, ''));
}

sub get_peer_default_options {
    my ($_self) = @_;
    qw(noauth defaultroute usepeerdns);
}

sub build_peer {
    my ($self) = @_;
    #- options:
    #-   init
    #-   connect
    #-   pty
    #-   plugin
    if ($self->{access}{use_chat}) {
        my $chat_file = $self->get_chat_file;
        $self->{access}{peer}{connect} ||= qq("/usr/sbin/chat -v -f $chat_file");
    }
    $self->get_peer_default_options,
    (map { if_($self->{access}{peer}{$_}, $_ . " " . $self->{access}{peer}{$_}) } qw(init connect pty plugin)),
    if_($self->{access}{login}, qq(user "$self->{access}{login}"));
}

sub write_peer {
    my ($self) = @_;
    my $interface = $self->get_interface;
    my $peer_file = "/etc/ppp/peers/$interface";
    output_with_perm($::prefix . $peer_file, 0755, join("\n", $self->build_peer, ''));
}

sub write_ppp_settings {
    my ($self) = @_;
    $self->write_secrets if $self->{access}{login};
    $self->write_chat if $self->{access}{use_chat};
    $self->write_peer;
}

sub write_settings  {
    my ($self) = @_;
    $self->write_ppp_settings;
    $self->network::connection::write_settings;
}

1;
