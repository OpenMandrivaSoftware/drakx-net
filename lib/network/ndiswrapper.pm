package network::ndiswrapper;

use strict;
use common;
use modules;
use detect_devices;

my $ndiswrapper_root = "/etc/ndiswrapper";

sub installed_drivers() {
    grep { -d $::prefix . "$ndiswrapper_root/$_" } all($::prefix . $ndiswrapper_root);
}

sub present_devices {
    my ($driver) = @_;
    my @supported_devices;
    foreach (all($::prefix . "$ndiswrapper_root/$driver")) {
        my ($ids) = /^([0-9A-F]{4}:[0-9A-F]{4})\.[0-9A-F]\.conf$/;
        $ids and push @supported_devices, $ids;
    }
    grep { member(uc(sprintf("%04x:%04x", $_->{vendor}, $_->{id})), @supported_devices) } detect_devices::probeall();
}

sub get_devices {
    my ($in, $driver) = @_;
    my @devices = present_devices($driver);
    @devices or $in->ask_warn(N("Error"), N("No device supporting the %s ndiswrapper driver is present!", $driver));
    @devices;
}

sub ask_driver {
    my ($in) = @_;
    if (my $inf_file = $in->ask_file(N("Please select the Windows driver (.inf file)"), "/media/cdrom")) {
        my $driver = basename(lc($inf_file));
        $driver =~ s/\.inf$//;

        #- first uninstall the driver if present, may solve issues if it is corrupted
        require run_program;
        -d $::prefix . "$ndiswrapper_root/$driver" and run_program::rooted($::prefix, 'ndiswrapper', '-e', $driver);

        unless (run_program::rooted($::prefix, 'ndiswrapper', '-i', $inf_file)) {
            $in->ask_warn(N("Error"), N("Unable to install the %s ndiswrapper driver!", $driver));
            return undef;
        }

        return $driver;
    }
    undef;
}

sub find_matching_devices {
    my ($device) = @_;
    my $net_path = '/sys/class/net';
    my @devices;

    require network::connection::ethernet;
    foreach my $interface (all($net_path)) {
        if (network::connection::ethernet::device_matches_interface($device, $interface)) {
            my $driver = network::connection::ethernet::interface_to_driver($interface);
            push @devices, { interface => $interface, drivers => [ $driver ] } if $driver;
        }
    }

    @devices;
}

sub find_conflicting_devices {
    my ($device) = @_;
    grep { !member("ndiswrapper", @{$_->{drivers}}) } find_matching_devices($device);
}

sub find_interface {
    my ($device) = @_;
    my $dev = find { member("ndiswrapper", @{$_->{drivers}}) } find_matching_devices($device);
    $dev->{interface};
}

sub setup_device {
    my ($in, $device) = @_;

    my @conflicts = find_conflicting_devices($device);
    if (@conflicts) {
        $in->ask_yesorno(N("Warning"), N("The selected device has already been configured with the %s driver.
Do you really want to use a ndiswrapper driver?", $conflicts[0]->{drivers}[0])) or return;
        #- unload the old module and try immediately to load ndiswrapper
        eval { modules::unload($_) } foreach @{$conflicts[0]->{drivers}};
    }

    #- unload ndiswrapper first so that the newly installed .inf files will be read
    eval { modules::unload("ndiswrapper") };
    eval { modules::load("ndiswrapper") };

    if ($@) {
        $in->ask_warn(N("Error"), N("Unable to load the ndiswrapper module!"));
        return;
    }

    my $interface = find_interface($device);
    unless ($interface) {
        $in->ask_warn(N("Error"), N("Unable to find the ndiswrapper interface!"));
        return;
    }

    $interface;
}

sub select_device {
    my ($in) = @_;
    my $driver;
    my @drivers = installed_drivers();
    if (@drivers) {
        $driver ||= first(@drivers);
        $in->ask_from('', N("Choose an ndiswrapper driver"), [
            { type => "list", val => \$driver, allow_empty_list => 1,
              list => [ undef, @drivers ],
              format => sub { defined $_[0] ? N("Use the ndiswrapper driver %s", $_[0]) : N("Install a new driver") } }
        ]) or return;
    }
    $driver ||= ask_driver($in) or return;

    my @devices = get_devices($in, $driver) or return;
    my $device;
    if (@devices == 1) {
        #- only one device matches installed driver
        $device = $devices[0];
    } else {
        $in->ask_from('', N("Select a device:"), [
            { type => "list", val => \$device, allow_empty_list => 1,
              list => [ present_devices($driver) ],
              format => sub { $_[0]{description} } }
        ]) or return;
    }
    return $device;
}

1;
