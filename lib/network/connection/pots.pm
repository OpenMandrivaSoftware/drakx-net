package network::connection::pots;

use base qw(network::connection::ppp);

use strict;
use common;

sub get_type_name {
    #-PO: POTS means "Plain old telephone service"
    N("POTS");
}
sub get_type_description {
    #-PO: POTS means "Plain old telephone service"
    #-PO: remove it if it doesn't have an equivalent in your language
    #-PO: for example, in French, it can be translated as "RTC"
    N("Analog telephone modem (POTS)");
}
sub _get_type_icon { 'potsmodem' }
sub get_metric { 50 }

sub handles_ifcfg {
    my ($_class, $ifcfg) = @_;
    $ifcfg->{DEVICE} =~ /^ppp/ && exists $ifcfg->{MODEMPORT};
}

sub get_devices {
    require detect_devices;
    require modules;
    #- FIXME: module alias should be written when config is written only
    #detect_devices::getModem(modules::any_conf->read);
    ();
}

my @thirdparty_settings = (
    {
        matching => qr/^Hcf:/,
        description => 'HCF 56k Modem',
        url => 'http://www.linuxant.com/drivers/hcf/',
        name => 'hcfpcimodem',
        kernel_module => {
            test_file => 'hcfpciengine',
        },
        tools => {
            test_file => '/usr/sbin/hcfpciconfig',
        },
        device => '/dev/ttySHCF0',
        post => '/usr/sbin/hcfpciconfig --auto',
        restart_service => 'hcfpci',
    },

    {
        matching => qr/^Hsf:/,
        description => 'HSF 56k Modem',
        url => 'http://www.linuxant.com/drivers/hsf/',
        name => 'hsfmodem',
        kernel_module => {
            test_file => 'hsfengine',
        },
        tools => {
            test_file => '/usr/sbin/hsfconfig',
        },
        device => '/dev/ttySHSF0',
        post => '/usr/sbin/hsfconfig --auto',
        restart_service => 'hsf',
    },

    {
        matching => qr/^LT:/,
        description => 'LT WinModem',
        url => 'http://www.heby.de/ltmodem/',
        name => 'ltmodem',
        kernel_module => 1,
        tools => {
            test_file => '/etc/devfs/conf.d/ltmodem.conf',
        },
        device => '/dev/ttyS14',
        links => [
            'http://linmodems.technion.ac.il/Ltmodem.html',
            'http://linmodems.technion.ac.il/packages/ltmodem/',
        ],
    },

    {
        matching => [ list_modules::category2modules('network/slmodem') ],
        description => 'Smartlink WinModem',
        url => 'http://www.smlink.com/content.aspx?id=135/',
        name => 'slmodem',
        kernel_module => 1,
        tools => {
            test_file => '/usr/sbin/slmodemd',
        },
        device => '/dev/ttySL0',
        post => sub {
            my ($driver) = @_;
            addVarsInSh("$::prefix/etc/sysconfig/slmodemd", { SLMODEMD_MODULE => $driver });
        },
        restart_service => "slmodemd",
    },

    {
        name => 'sm56',
        description => 'Motorola SM56 WinModem',
        url => 'http://www.motorola.com/softmodem/driver.htm#linux',
        kernel_module => {
            package => 'sm56',
        },
        no_club => 1,
        device => '/dev/sm56',
    },
);

sub get_thirdparty_settings { \@thirdparty_settings }

sub get_providers {
    my $db_path = "/usr/share/apps/kppp/Provider";
    #$in->do_pkgs->ensure_is_installed('kdenetwork-kppp-provider', $db_path);
    my $separator = "|";
    my %providers;
    foreach (all($::prefix . $db_path)) {
        s!_! !g;
        my $country = $_;
        my $t_country = translate($country);
        my $country_root = $::prefix . $db_path . '/' . $country;
        foreach (grep { $_ ne '.directory' } all($country_root)) {
            my $path = $country_root . $_;
            s/%([0-9]{3})/chr(int($1))/eg;
            $providers{$t_country . $separator . $_} = { path => $path };
        }
    }
    (\%providers, $separator);
}

1;
