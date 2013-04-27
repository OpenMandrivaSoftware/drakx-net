package network::vpn::openvpn;

use base qw(network::vpn);

use strict;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;

sub get_type { 'openvpn' }
sub get_description { "OpenVPN" }
sub get_packages { 'openvpn', if_(supports_pkcs11(), qw(openct opensc pcsc-lite)) }

my $pkcs11_tokens;

sub prepare {
    require services;
    if (supports_pkcs11()) {
        #- don't fail if SmartCard daemons can't start, it's not mandatory
        services::start_not_running_service($_) foreach qw(openct pcscd);
        cache_pkcs11_tokens();
    }
    1;
}

sub read_config {
    my ($connection) = @_;
    my ($pkcs11_slot, $pkcs11_id);
    foreach (cat_($connection->get_config_path)) {
        /^\s*proto\s+tcp/ and $connection->{tcp} = 1;
        /^\s*dev\s+([[:alpha:]]+)(\d*)/ and ($connection->{dev_type}, $connection->{dev_number}) = ($1, $2);
        if (/^\s*remote\s+(\S+)(?:\s+(\w+))?/) {
            $connection->{gateway} = $1;
            $connection->{port} = $2;
        }
        if (/^\s*tls-auth\s+(\S+)(?:\s+(\d+))?/) {
            $connection->{'tls-auth'} = $1;
            $connection->{key_direction} = $2;
        }
        foreach my $type (qw(ca cert key pkcs12 secret)) {
            /^\s*$type\s+(.+)/ and $connection->{$type . '_file'} = $1;
        }
        /^\s*pkcs11-slot\s+(.+)/ and $pkcs11_slot = $1;
        /^\s*pkcs11-id\s+(.+)/ and $pkcs11_id = $1;
        /^\s*ns-cert-type\s+server/ and $connection->{check_server} = 1;
        /^\s*auth-user-pass/ and $connection->{'auth-user-pass'} = 1;
        if (/^\s*ifconfig\s+(\S+)\s+(\S+)/) {
            $connection->{local_ip} = $1;
            $connection->{remote_ip} = $2;
            $connection->{addressing} = 'manual';
        }
        /^\s*cipher\s+(.+)/ and $connection->{cipher} = $1;
        /^\s*keysize\s+(.+)/ and $connection->{keysize} = $1;
    }
    if (exists $connection->{secret_file}) {
        $connection->{type} = 'static';
        $connection->{key} = delete $connection->{secret_file};
    } else {
        $connection->{type} = 'pki';
        $connection->{key} = delete $connection->{key_file};
    }
    if (defined $pkcs11_slot && defined $pkcs11_id) {
        my $tokens = $connection->get_pkcs11_tokens('no_cache');
        $connection->{pkcs11_object} = find { $_->{slot} eq $pkcs11_slot && $_->{id} eq $pkcs11_id } @{$tokens->{objects}};
        $connection->{pkcs11_object} ||= {};
    }
}

sub write_config {
    my ($connection) = @_;
    my $file = $connection->get_config_path;
    unless (-e $file) {
        mkdir_p(dirname($file));
        cp_f("/usr/share/openvpn/sample-config-files/client.conf", $file);
    }

    delete $connection->{keysize} if !$connection->{cipher};
    delete $connection->{ca_file} if $connection->{pkcs12_file};

    if ($connection->{type} eq 'static') {
        $connection->{secret_file} = delete $connection->{key};
        delete $connection->{ca_file};
        delete $connection->{cert_file};
        delete $connection->{key_file};
    } else {
        $connection->{key_file} = delete $connection->{key};
        delete $connection->{secret_file};
    }

    my @config = $connection->build_config;
    substInFile {
        foreach my $conf (@config) {
            if (/^;?$conf->{key}\b/) {
                if ($conf->{comment}) {
                    $_ = ";$_" unless /^;/;
                } else {
                    $_ = "$conf->{key} $conf->{value}\n";
                    $conf->{comment} = 1;
                }
                last;
            }
        }
        $_ .= join('', map { if_(!$_->{comment}, "$_->{key} $_->{value}\n") } @config) if eof;
    } $file;
}

sub get_key_settings {
    my ($connection) = @_;
    my %ciphers = get_ciphers();
    my @types = (
        pki => N("X509 Public Key Infrastructure"),
        static => N("Static Key"),
    );
    my $pkcs11_separator = '/';
    my $tokens = $connection->get_pkcs11_tokens;
    my %types = @types;
    [
        {
            label => N("Type"),
            val => \$connection->{type},
            list => first(list2kv(@types)),
            format => sub { $types{$_[0]} },
        },
        (supports_pkcs11() ? {
            label => "PKCS #11 token",
            type => 'list',
            list => [ undef, @{$tokens->{objects}} ],
            format => sub { $_[0] ? join($pkcs11_separator,
                                         $tokens->{slots}{$_[0]{slot}}{label} || $_[0]{slot},
                                         $_[0]{label} || $_[0]{id})
                              :  N("None") },
            val => \$connection->{pkcs11_object},
            separator => $pkcs11_separator,
            allow_empty_list => 1,
            disabled => sub { $connection->{type} ne 'pki' || $connection->{cert_file} || $connection->{key_file} || $connection->{pkcs12_file} },
        } : ()),
        {
            label => "PKCS #12",
            type => 'file',
            val => \$connection->{pkcs12_file},
            disabled => sub { $connection->{type} ne 'pki' || $connection->{cert_file} || $connection->{key_file} || $connection->{pkcs11_object} },
        },
        {
            label =>
              #-PO: please don't translate the CA acronym
              N("Certificate Authority (CA)"),
            type => 'file',
            val => \$connection->{ca_file},
            disabled => sub { $connection->{type} ne 'pki' || $connection->{pkcs12_file} },
        },
        {
            label => N("Certificate"),
            type => 'file',
            val => \$connection->{cert_file},
            disabled => sub { $connection->{type} ne 'pki' || $connection->{pkcs11_object} || $connection->{pkcs12_file} },
        },
        {
            label => N("Key"),
            type => 'file',
            val => \$connection->{key},
            disabled => sub { $connection->{type} eq 'pki' && ($connection->{pkcs11_object} || $connection->{pkcs12_file}) },
        },
        {
            label => N("TLS control channel key"),
            type => 'file',
            val => \$connection->{'tls-auth'},
            disabled => sub { $connection->{type} ne 'pki' },
            advanced => 1,
        },
        {
            label => N("Key direction"),
            type => 'list',
            val => \$connection->{key_direction},
            list => [ undef, 0, 1 ],
            format => sub { defined($_[0]) ? $_[0] : N("None") },
            advanced => 1,
        },
        {
            text => N("Authenticate using username and password"),
            type => 'bool',
            val => \$connection->{'auth-user-pass'},
            advanced => 1,
        },
        {
            text => N("Check server certificate"),
            type => 'bool',
            val => \$connection->{check_server},
            advanced => 1,
        },
        {
            label => N("Cipher algorithm"),
            type => 'list',
            val => \$connection->{cipher},
            list => [ '', keys %ciphers ],
            format => sub { exists $ciphers{$_[0]} ? $ciphers{$_[0]} : N("Default") },
            advanced => 1,
        },
        {
            label => N("Size of cipher key"),
            val => \$connection->{keysize},
            advanced => 1,
            disabled => sub { !$connection->{cipher} || $connection->{cipher} eq 'none' },
        },
    ];
}

sub get_settings {
    my ($connection) = @_;
    my @addressing = (
        automatic => N("Get from server"),
        manual => N("Manual configuration"),
    );
    my %addressing = @addressing;
    [
        {
            label => N("Gateway"),
            val => \$connection->{gateway},
        },
        {
            label => N("Gateway port"),
            val => \$connection->{port},
            advanced => 1,
        },
        {
            label => N("IP address"),
            val => \$connection->{addressing},
            list => first(list2kv(@addressing)),
            format => sub { $addressing{$_[0]} },
        },
        {
            label => N("Local IP address"),
            val => \$connection->{local_ip},
            disabled => sub { $connection->{addressing} ne 'manual' },
        },
        {
            label => N("Remote IP address"),
            val => \$connection->{remote_ip},
            disabled => sub { $connection->{addressing} ne 'manual' },
        },
        {
            text => N("Use TCP protocol"),
            type => 'bool',
            val => \$connection->{tcp},
            advanced => 1,
        },
        {
            label => N("Virtual network device type"),
            type => 'list',
            list => [ 'tun', 'tap' ],
            val => \$connection->{dev_type},
            advanced => 1,
        },
        {
            label => N("Virtual network device number (optional)"),
            val => \$connection->{dev_number},
            advanced => 1,
        },
    ];
}

my $lib = arch() =~ /x86_64/ ? "lib64" : "lib";
my $openvpn_default_pkcs11_provider = find { -e $_ } (
    "/usr/local/$lib/libetpkcs11.so",
    "/usr/$lib/opensc-pkcs11.so",
);

my $supports_pkcs11;
sub supports_pkcs11 {
    if (!defined $supports_pkcs11) {
        require run_program;
        $supports_pkcs11 = to_bool(run_program::rooted($::prefix, '/usr/sbin/openvpn', '--show-pkcs11-slots', ''));
    }
    $supports_pkcs11;
}

sub get_pkcs11_tokens {
    my ($_class, $o_no_cache) = @_;
    cache_pkcs11_tokens() if !defined $pkcs11_tokens && !$o_no_cache;
    $pkcs11_tokens;
}

sub cache_pkcs11_tokens {
    $pkcs11_tokens = { slots => {}, objects => [] };
    my $slot_id;
    foreach (run_program::rooted_get_stdout($::prefix, '/usr/bin/pkcs11-tool', '--module', $openvpn_default_pkcs11_provider, '-L')) {
        if (/^Slot\s+(\d+)\s+(.+)$/) {
            $slot_id = $2 ne '(empty)' ? $1 : undef;
            $pkcs11_tokens->{slots}{$slot_id}{name} = $2 if defined $slot_id;
        } elsif (/^\s+token\s+label:\s+(.+)$/) {
            $pkcs11_tokens->{slots}{$slot_id}{label} = $1 if defined $slot_id;
        } elsif (/^\s+flags:\s*(.*)/) {
            my @flags = split(/\s*,\s*/, $1);
            if (defined $slot_id && !member("token present", @flags)) {
                delete $pkcs11_tokens->{slots}{$slot_id};
                undef $slot_id;
            }
        }
    }
    foreach my $slot_id (keys %{$pkcs11_tokens->{slots}}) {
        my ($type, $label);
        my @stdout; #- do rooted_get_stdout manually because pkcs11-tool may exit with non-zero code with proprietary modules
        run_program::rooted($::prefix, '/usr/bin/pkcs11-tool', '>', \@stdout, '--module', $openvpn_default_pkcs11_provider, '-O', '--slot', $slot_id);
        foreach (@stdout) {
            if (/^(\S.*?)\s+Object/) {
                $type = $1;
                undef $label;
            } elsif (/^\s+label:\s+(.+)$/) {
                $label = $1;
            } elsif (/^\s+ID:\s+(.+)$/ && $type eq 'Public Key') {
                push @{$pkcs11_tokens->{objects}}, { id => $1, label => $label, slot => $slot_id };
            }
        }
    }
}

sub build_config {
    my ($connection) = @_;
    (
        { key => 'client', comment => to_bool($connection->{secret_file}) },
        { key => 'proto', $connection->{tcp} ? (value => 'tcp') : (comment => 1) },
        { key => 'dev', value => $connection->{dev_type} . $connection->{dev_number} },
        { key => 'remote', value => join(' ', $connection->{gateway}, if_($connection->{port}, $connection->{port})) },
        (map { +{ key => $_, $connection->{$_ . '_file'} ? (value => $connection->{$_ . '_file'}) : (comment => 1) } } qw(ca cert key pkcs12 secret)),
        { key => 'pkcs11-providers', $connection->{pkcs11_object} ? (value => $openvpn_default_pkcs11_provider) : (comment => 1) },
        { key => 'pkcs11-slot-type', $connection->{pkcs11_object} ? (value => 'id') : (comment => 1) },
        { key => 'pkcs11-slot', $connection->{pkcs11_object} ? (value => $connection->{pkcs11_object}{slot}) : (comment => 1) },
        { key => 'pkcs11-id-type', $connection->{pkcs11_object} ? (value => 'id') : (comment => 1) },
        { key => 'pkcs11-id', $connection->{pkcs11_object} ? (value => $connection->{pkcs11_object}{id}) : (comment => 1) },
        { key => 'tls-auth', $connection->{'tls-auth'} ? (value => join(' ', $connection->{'tls-auth'}, if_($connection->{key_direction}, $connection->{key_direction}))) : (comment => 1) },
        { key => 'ns-cert-type', $connection->{check_server} ? (value => 'server') : (comment => 1) },
        { key => 'auth-user-pass', comment => !$connection->{'auth-user-pass'} },
        { key => 'ifconfig', $connection->{addressing} eq 'manual' ?
            (value => join(' ', $connection->{local_ip}, $connection->{remote_ip})) : (comment => 1) },
        { key => 'cipher', $connection->{cipher} ? (value => $connection->{cipher}) : (comment => 1) },
        { key => 'keysize', $connection->{keysize} ? (value => $connection->{keysize}) : (comment => 1) },
    );
}

sub get_ciphers() {
    my @ciphers = chomp_(`/usr/sbin/openvpn --show-ciphers`);
    #- drop header
    shift @ciphers while $ciphers[0] =~ /^\S/;
    none => N("None"), map { if_($_, first(split(' ', $_)), $_) } @ciphers;
}

sub start {
    my ($connection, $o_in) = @_;
    $connection->read_config if keys %$connection <= 1;
    my %interactive_passwords = if_($o_in, (
        if_($connection->{'auth-user-pass'}, 'Auth' => 1),
        if_($connection->{pkcs11_object}, 'Token' => 1),
    ));
    my $port = 2222;
    my $started = $connection->_run('start',
                                    if_(%interactive_passwords,
                                        '--management', "127.0.0.1", $port,
                                        '--management-query-passwords',
                                    ));
    $started && (!%interactive_passwords || $connection->ask_passwords($o_in, $port, \%interactive_passwords));
}

sub ask_passwords {
    my ($_connection, $in, $port, $interactive_passwords) = @_;
    require Net::Telnet;
    my $t = new Net::Telnet;
    $t->open(host => "localhost", port => $port, errmode => "return");
    my $wait;
    while (1) {
        $wait ||= $in->wait_message(N("VPN connection"), N("Starting connection.."));
        my ($_pre, $match) = $t->waitfor(string => ">PASSWORD:", string => ">NEED-OK:", errmode => "return",
                                        #- don't quit if all interactive passwords have been entered
                                        #- in case some passwords are incorrect
                                        #- though, use a smaller timeout
                                        timeout => (%$interactive_passwords ? 20 : 5));
        if (!defined $match) {
            my $msg = $t->errmsg;
            #- no more interactive password is required, success
            $t->close, return 1 if $msg =~ /timed-out/ && !%$interactive_passwords;
            $t->close, return; #- potential failure
        } elsif ($match eq ">NEED-OK:") {
            my ($type, $msg) = $t->getline =~ /'(.*)'.* MSG:/;
            undef $wait;
            my $ret = $in->ask_okcancel(N("VPN connection"), $type eq 'token-insertion-request' ?
                                          N("Please insert your token") :
                                          $msg);
            $t->print(qq(needok "$type" ) . ($ret ? "ok" : "cancel"));
            $t->close, return if !$ret;
        } elsif ($match eq ">PASSWORD:") {
            my ($full_type) = $t->getline =~ /'(.*)'/;
            #- assume type is "Auth" if not token
            my $type =  $full_type =~ /\btoken$/ ? 'Token' : 'Auth';
            my ($username, $password);
            undef $wait;
            my $ret = $in->ask_from(N("VPN connection"), '', $type eq 'Token' ? [
                { label => N("PIN number"), val => \$password, hidden => 1 }
            ] : [
                { label => N("Account Login (user name)"), val => \$username },
                { label => N("Account Password"),  val => \$password, hidden => 1 },
            ]);
            if ($ret) {
                delete $interactive_passwords->{$type};
                $t->print(qq(username "$full_type" "$username")) if $username;
                $t->print(qq(password "$full_type" "$password"));
            } else {
                $t->close, return;
            }
        }
    }
}

1;
