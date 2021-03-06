package network::connection::cellular_card;

use base qw(network::connection::cellular);

use strict;
use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;

my $wrong_pin_error = N_("Wrong PIN number format: it should be 4 digits.");

sub get_type_name() { N("GPRS/Edge/3G") }
sub _get_type_icon() { 'cellular' }
sub get_devices() {
       require detect_devices;
       my @maybe_usbserial_modules = ('usbserial_generic', 'unknown');
       my @serial = grep { $_->{description} =~ /GPRS|EDGE|3G|UMTS|H.DPA|CDMA/i } detect_devices::matching_driver('serial_cs', 'usbserial', @maybe_usbserial_modules);
       member($_->{driver}, @maybe_usbserial_modules) and $_->{driver} = 'usbserial' foreach @serial;
       #- cdc_acm can not be listed directly in network/cellular, it is already in network/isdn
       @serial, detect_devices::probe_category('network/cellular'), detect_devices::matching_driver('cdc_acm');
}
sub get_metric { 40 }

sub get_packages { 'comgt', 'ppp' }

sub handles_ifcfg {
    my ($_class, $ifcfg) = @_;
    exists $ifcfg->{CELLULAR_CID};
}

my @thirdparty_settings = (
    {
        name => 'nozomi',
        description => 'Option GlobeTrotter 3G/EDGE and FUSION+',
        url => 'http://www.pharscape.org/',
        kernel_module => 1,
    },
    {
        name => 'hso',
        description => 'Option High Speed Mobile Devices',
        url => 'http://www.pharscape.org/',
        kernel_module => 1,
        tools => {
            package => 'hso-rezero',
            test_file => '/usr/sbin/rezero',
        },
    },
);

sub get_thirdparty_settings() {
    \@thirdparty_settings;
}

sub guess_hardware_settings {
    my ($self) = @_;
    $self->{hardware}{pin} ||= chomp_(cat_("/etc/sysconfig/network-scripts/pin-" . $self->get_interface));
}

sub get_interface {
    my ($self) = @_;
    $self->get_driver eq "hso" ?
	"hso0" :
	"ppp0";
}

sub get_tty_device {
    my ($self) = @_;

    my $tty_interface = 0;
    my %udev_env = map { if_(/^([^=]*)=(.*)$/, $1 => $2) } chomp_(run_program::get_stdout("udevadm info --query=property --path=$self->{device}{sysfs_device}"));

    if ($udev_env{USB_MODEM_INTERFACE}) {
        my $dev_sys_path = $self->{device}{sysfs_device};
        my $cfg = chomp_(cat_($dev_sys_path . "/bConfigurationValue"));
        my $tty_usb = basename(glob_("$dev_sys_path/" .
            $self->{device}{pci_bus} . "-" .
            ($self->{device}{usb_port} + 1) . ":$cfg." .
            $udev_env{USB_MODEM_INTERFACE} . "/ttyUSB*"));
        if ($tty_usb) {
            $tty_usb =~ s/ttyUSB//;
            $tty_interface = $tty_usb;
        }
    } else {
        # if no usb interface for tty port given, use first one
        my @intfs = glob_("$self->{device}->{sysfs_device}/" .
                     $self->{device}{pci_bus} . "-" .
                     ($self->{device}{usb_port} + 1) . ":*");
        foreach (@intfs) {
            my $tty_usb = basename(glob_("$_/tty*"));
            if ($tty_usb) {
                $tty_usb =~ s/tty[a-zA-Z]*//;
                $tty_interface = $tty_usb;
                last;
            }
        }
    }

    $self->{device}{device} ?
      "/dev/" . $self->{device}{device} :
    $self->get_driver eq "nozomi" ?
      "/dev/noz" . $tty_interface :
    $self->get_driver eq "cdc_acm" ?
      "/dev/ttyACM0" . $tty_interface :
    $self->get_driver eq "hso" ?
      "/dev/ttyHS" . $tty_interface :
      "/dev/ttyUSB" . $tty_interface;
}

sub get_control_device {
    my ($self) = @_;
    my $tty_device = $self->get_tty_device;
    if ($tty_device eq "/dev/ttyUSB0") {
        foreach my $id (2, 1) {
            my $usb_control_device = "/dev/ttyUSB" . $id;
            return $usb_control_device if -e $usb_control_device;
        }
    }
    $tty_device;
}

sub network_scan_is_slow() { 1 }
sub check_hardware_is_slow() { 1 }
sub has_unique_network() { 1 }

sub get_networks {
    my ($self) = @_;
    my $cmd = 'comgt -d ' . $self->get_control_device;
    my ($network, $state) = `$cmd reg` =~ /^Registered on \w+ network: "(.*)",(\d+)$/m;
    my ($strength) = `$cmd sig` =~ /^Signal Quality:\s+(\d+),\d+$/;
    $self->probed_networks;
    $self->{networks} = $network && {
        $network => {
            name => $network,
            signal_strength => $strength * 5,
            current => $state == 2,
        }
    };
}

sub get_hardware_settings {
   my ($self) = @_;
   [ { label => N("PIN number (4 digits). Leave empty if PIN is not required."), val => \$self->{hardware}{pin}, hidden => 1 } ];
}

sub check_hardware_settings {
    my ($self) = @_;
    if ($self->{hardware}{pin} !~ /(^$|^[0-9]{4}$)/) {
        $self->{hardware}{error} = translate($wrong_pin_error);
        return 0;
    }
    1;
}

sub get_peer_default_options {
    my ($self) = @_;
    $self->SUPER::get_peer_default_options,
    "noccp", # disable CCP to avoid warning messages
    "debug";
}

sub build_peer {
    my ($self) = @_;
    $self->SUPER::build_peer;
    #- don't run comgt for now, it hangs on ttyUSB0 devices when run from pppd
    #- $self->{access}{peer}->{init} = "comgt -d $dev < $pin_file"
}

sub set_ppp_settings {
    my ($self) = @_;
    $self->{access}{no_dial} = $self->get_driver eq "hso";
    $self->{access}{cid} = 3;

    $self->{access}{at_commands} = [
        "AT+CPIN?",
        # Set +CGEE to 2
        "AT+CMEE=2",
        qq(AT+CGDCONT=$self->{access}{cid},"IP","$self->{access}{apn}"),
        # Setup +CGEQREG (QoS, don't set it for now)
        # qq(AT+CGEQREQ=3,3,64,384,0,0,2,0,"0E0","0E0",3,0,0),
        # Attached to network, will return 1
        "AT+CGATT?",
        if_($self->get_driver eq "hso", ""),
    ];

    $self->SUPER::set_ppp_settings;
}

sub write_settings {
    my ($self) = @_;

    my $interface = $self->get_interface;
    my $pin_file = "/etc/sysconfig/network-scripts/pin-$interface";
    output_with_perm($pin_file, 0600, $self->{hardware}{pin} . "\n");

    $self->SUPER::write_settings;
}

sub prepare_device {
    my ($self) = @_;

    my $driver = $self->get_driver;
    require modules;
    my $modules_conf = ref($::o) && $::o->{modules_conf} || modules::any_conf->read;
    modules::load_and_configure($modules_conf, $driver,
                                if_($driver eq 'usbserial', join(
                                    ' ',
                                    "vendor=0x" . sprintf("%04x", $self->{device}{vendor}),
                                    "product=0x" . sprintf("%04x", $self->{device}{id}))));
    $modules_conf->write if !ref $::o;
    sleep 2 if $driver eq 'usbserial';
}

sub check_device {
    my ($self) = @_;

    my $dev = $self->get_tty_device;
    if (! -e $dev) {
      $self->{device}{error} = N("Unable to open device %s", $dev);
      return;
    }

    1;
}

sub check_hardware {
    my ($self) = @_;
    to_bool(run_program::rooted($::prefix, 'comgt', '>', '/dev/null', '-d', $self->get_control_device, 'PIN'));
}

sub configure_hardware {
    my ($self) = @_;

    my $device_ready = 0;

    require IPC::Open2;
    require IO::Select;
    require c;
    use POSIX qw(:errno_h);

    my $pid = IPC::Open2::open2(my $cmd_out, my $cmd_in, 'comgt', '-d', $self->get_control_device);
    common::nonblock($cmd_out);
    my $selector = IO::Select->new($cmd_out);
    my $already_entered_pin;

    while ($selector->can_read) {
        local $_;
        my $rv = sysread($cmd_out, $_, 512);
        $rv == 0 and $selector->remove($cmd_out);
        if (/^\s*\*\*\*SIM ERROR\*\*\*/m) {
            $self->{hardware}{error} = N("Please check that your SIM card is inserted.");
            last;
        } elsif (/^Enter PIN number:/m) {
            $self->{hardware}{pin} or last;
            if ($already_entered_pin) {
                $self->{hardware}{error} = translate($wrong_pin_error);
                last;
            }
            $already_entered_pin = 1;
            print $cmd_in $self->{hardware}{pin} . "\n";
        } elsif (/^ERROR entering PIN/m) {
            $self->{hardware}{error} = N("You entered a wrong PIN code.
Entering the wrong PIN code multiple times may lock your SIM card!");
            last;
        } elsif (/^Waiting for Registration/m) {
            #- the card seems to be reset if comgt is killed right here, wait a bit
            sleep 1;
            #- don't wait the full scan
            $device_ready = 1;
            last;
        }
    }
    kill 'TERM', $pid;
    close($cmd_out);
    close($cmd_in);
    waitpid($pid, 0);

    $device_ready;
}

1;
