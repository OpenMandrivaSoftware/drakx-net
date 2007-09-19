package network::connection::isdn;

use base qw(network::connection);

use strict;
use common;

sub get_type_name { N("ISDN") }
sub _get_type_icon { 'isdn' }

sub get_devices {
    require modules;
    #- FIXME: module alias should be written when config is written only
    @{detect_backend(modules::any_conf->read)};
}
sub get_metric { 30 }

use network::connection::isdn::consts;
use modules;
use run_program;
use log;
use network::tools;
use services;

sub apply_config {
    my ($in, $isdn) = @_;

    $isdn = find_capi_card($isdn) if $isdn->{driver} eq "capidrv";
    unload_connection($isdn);
    install_packages($isdn, $in);
    write_settings($isdn);
    write_capi_conf($isdn) if $isdn->{driver} eq "capidrv";
    prepare_connection($isdn);
}

sub write_settings {
    my ($isdn) = @_;

    output_with_perm("$::prefix/etc/isdn/profile/link/myisp", 0600,
	  qq(
I4L_USERNAME="$isdn->{login}"
I4L_SYSNAME=""
I4L_LOCALMSN="$isdn->{phone_in}"
I4L_REMOTE_OUT="$isdn->{phone_out}"
I4L_DIALMODE="$isdn->{dialing_mode}"
I4L_IDLETIME="$isdn->{huptimeout}"
) . if_($isdn->{speed} =~ /128/, 'SLAVE="ippp1"
'));
	output "$::prefix/etc/isdn/profile/card/mycard",
	  qq(
I4L_MODULE="$isdn->{driver}"
I4L_TYPE="$isdn->{type}"
I4L_IRQ="$isdn->{irq}"
I4L_MEMBASE="$isdn->{mem}"
I4L_PORT="$isdn->{io}"
I4L_IO0="$isdn->{io0}"
I4L_IO1="$isdn->{io1}"
I4L_ID="HiSax"
I4L_FIRMWARE="$isdn->{firmware}"
I4L_PROTOCOL="$isdn->{protocol}"
);

	output "$::prefix/etc/ppp/ioptions",
	  "lock
usepeerdns
defaultroute
";

    network::tools::write_secret_backend($isdn->{login}, $isdn->{passwd});

    1;
}

sub write_capi_conf {
    my ($capi_card) = @_;
    my $capi_conf;
    my $firmware = $capi_card->{firmware} || '-';
    if ($capi_card->{driver} eq "fcclassic") {
        $capi_conf = "fcclassic     -       -       0x300   5    -       -\n# adjust IRQ and IO !!        ^^^^^  ^^^\n";
    } elsif ($capi_card->{driver} eq "fcpnp") {
        $capi_conf = "fcpnp      -       -       0x300   5    -       -\n# adjust IRQ and IO !!     ^^^^^  ^^^\n";
    } else {
        $capi_conf = "$capi_card->{driver}        $firmware       -       -       -       -       -\n";
    }

    output("$::prefix/etc/capi.conf", $capi_conf);
}

sub unload_connection {
    my ($isdn) = @_;
    require services;
    services::stop("isdn4linux"); #- to be stopped before capi is loaded
    if ($isdn->{driver} eq "capidrv") {
        #- stop capi4linux before new config is written so that it can unload the driver
        services::stop("capi4linux");
    }
}

sub install_packages {
    my ($isdn, $in) = @_;

    $in->do_pkgs->install(
        'isdn4k-utils',
        $isdn->{driver} eq "capidrv" ?
          (if_(!modules::module_is_available($isdn->{driver}), @{$isdn->{packages}}),
           if_($isdn->{firmware} && ! -f "$::prefix/usr/lib/isdn/$isdn->{firmware}", "$isdn->{driver}-firmware"))
           :
          ('isdn4net', if_($isdn->{speed} =~ /128/, 'ibod'))
      );
}

sub prepare_connection {
    my ($isdn) = @_;
    if ($isdn->{driver} eq "capidrv") {
        services::enable('capi4linux');
    } else {
        services::disable('capi4linux');
    }
    services::enable('isdn4linux');
}

sub read_config {
    my ($isdn) = @_;
    
    my %match = (I4L_USERNAME => 'login',
		 I4L_LOCALMSN => 'phone_in',
		 I4L_REMOTE_OUT => 'phone_out',
		 I4L_DIALMODE => 'dialing_mode',
		 I4L_IDLETIME => 'huptimeout',
		 I4L_MODULE => 'driver',
		 I4L_TYPE => 'type',
		 I4L_IRQ => 'irq',
		 I4L_MEMBASE => 'mem',
		 I4L_PORT => 'io',
		 I4L_IO0 => 'io0',
		 I4L_IO1 => 'io1',
		 I4L_FIRMWARE => 'firmware');
    foreach ('link/myisp', 'card/mycard') {
	my %conf = getVarsFromSh("$::prefix/etc/isdn/profile/$_");
	foreach (keys %conf) {	 
	    $isdn->{$match{$_}} = $conf{$_} if $match{$_} && $conf{$_};
	}
    }

    $isdn->{passwd} = network::tools::passwd_by_login($isdn->{login});
}

my $file = "$ENV{SHARE_PATH}/ldetect-lst/isdn.db";
$file = "$::prefix$file" if !-e $file;

sub get_info_providers_backend {
    my ($isdn, $name) = @_;
    $name eq N("Unlisted - edit manually") and return;
    foreach (catMaybeCompressed($file)) {
	chop;
	my ($name_, $phone, $real, $dns1, $dns2) = split '=>';
	if ($name eq $name_) {
	    @$isdn{qw(user_name phone_out DOMAINNAME2 dnsServer3 dnsServer2)} =
	               ((split(/\|/, $name_))[2], $phone, $real, $dns1, $dns2);
	}
    }
}

sub read_providers_backend() { map { /(.*?)=>/ } catMaybeCompressed($file) }


sub detect_backend {
    my ($modules_conf) = @_;
    my @isdn;
    require detect_devices;
     each_index {
 	my $c = $_;
 	my $isdn = { map { $_ => $c->{$_} } qw(description vendor id driver card_type type) };
        $isdn->{intf_id} = $::i;
	$isdn->{$_} = sprintf("%0x", $isdn->{$_}) foreach 'vendor', 'id';
	$isdn->{card_type} = $c->{bus} eq 'USB' ? 'usb' : 'pci';
        $isdn->{description} =~ s/.*\|//;
#	$c->{options} !~ /id=HiSax/ && $isdn->{driver} eq "hisax" and $c->{options} .= " id=HiSax";
	if ($c->{options} !~ /protocol=/ && $isdn->{protocol} =~ /\d/) {
	    $modules_conf->set_options($c->{driver}, $c->{options} . " protocol=" . $isdn->{protocol});
	}
	$c->{options} =~ /protocol=(\d)/ and $isdn->{protocol} = $1;
	push @isdn, $isdn;
    } detect_devices::probe_category('network/isdn');
    \@isdn;
}

sub get_cards_by_type {
    my ($isdn_type) = @_;
    grep { $_->{card} eq $isdn_type } @isdndata;
}


sub get_cards() {
    my %buses = (
                 isa => N("ISA / PCMCIA") . "/" . N("I do not know"),
                 pci => N("PCI"),
                 usb => N("USB"),
                );
    # pmcia alias (we should really split up pcmcia from isa in isdn db): 
    $buses{pcmcia} = $buses{isa};

    map { $buses{$_->{card}} . "|" . $_->{description} => $_ } @isdndata;
}


sub find_capi_card {
    my ($isdn) = @_;
    find {
        hex($isdn->{vendor}) == $_->{vendor} && hex($isdn->{id}) == $_->{id};
    } @isdn_capi;
}

sub get_capi_card {
    my ($in, $isdn) = @_;

    my $capi_card =  find_capi_card($isdn) or return;

    #- check if the capi driver is available
    unless (modules::module_is_available($capi_card->{driver}) || ($capi_card->{packages} = $in->do_pkgs->check_kernel_module_packages($capi_card->{driver}))) {
        log::explanations("a capi driver ($capi_card->{driver}) exists to replace $isdn->{driver}, but it is not installed and no packages provide it");
        return;
    }

    $capi_card;
}

1;
