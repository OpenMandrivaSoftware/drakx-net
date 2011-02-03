package network::thirdparty;

use strict;
use common;
use detect_devices;
use run_program;
use services;
use fs::get;
use fs;
use log;
use modules;
use list_modules;

#- using bsd_glob() since glob("/DONT_EXIST") return "/DONT_EXIST" instead of () (and we don't want this)
use File::Glob ':glob';

#- network_settings is an hash of categories (rtc, dsl, wireless, ...)
#- each category is an hash of device settings

#- a device settings element must have the following fields:
#- o matching:
#-     specify if this settings element matches a driver
#-     can be a regexp, array ref or Perl code (parameters: driver)
#- o description:
#-     full name of the device
#- o name: name used by the packages

#- the following fields are optional:
#- o url:
#-     url where the user can find tools/drivers/firmwares for this device
#- o device:
#-     device in /dev to be configured
#- o post:
#-     command to be run after all packages are installed
#-     can be a shell command or Perl code
#- o restart_service:
#-     if exists but not 1, name of the service to be restarted
#-     if 1, specify that the service named by the name field should be restarted
#- o tools:
#-     hash of the tools settings
#-     test_file field required
#-     if package field doesn't exist, 'name' is used
#- o kernel_module:
#-     if exists but not 1, hash of the module settings
#-     if 1, kernel modules are needed and use the name field
#-         (name-kernel or dkms-name)
#- o firmware:
#-     hash of the firmware settings
#-     test_file field required
#-     if package field doesn't exist, 'name-firmware' is used

#- hash of package settings structure:
#- o package:
#-     name of the package to be installed for these device
#- o test_file:
#-     file used to test if the package is installed
#- o prefix:
#-     path of the files that are tested
#- o links:
#-     useful links for this device
#-     can be a single link or array ref
#- o user_install:
#-     function to call if the package installation fails
#- o explanations:
#-     additionnal text to display if the installation fails
#- o no_distro_package:
#-     1 if the package isn't available in the official distribution
#        (because of missing distribution rights for example)

our $firmware_directory = "/lib/firmware";
our @thirdparty_types = qw(kernel_module tools firmware);

sub device_get_packages {
    my ($settings, $component, $o_default) = @_;
    $settings->{$component} or return;
    my $package;
    if (ref $settings->{$component} eq 'HASH') {
	$package = $settings->{$component}{package} || 1;
    } else {
	$package = $settings->{$component};
    }
    $package == 1 ? $o_default || $settings->{name} : ref $package eq 'ARRAY' ? @$package : $package;
}

sub device_get_option {
    my ($settings, $option, $o_default) = @_;
    $settings->{$option} or return;
    my $value = $settings->{$option};
    $value == 1 ? $o_default || $settings->{name} : $value;
}

sub component_get_option {
    my ($settings, $component, $option) = @_;
    ref $settings->{$component} eq 'HASH' && $settings->{$component}{$option} || $settings->{$option};
}

sub find_settings {
    my ($settings_list, $driver) = @_;
    find {
        my $match = $_->{matching} || $_->{name};
        my $type = ref $match;
        $type eq 'Regexp' && $driver =~ $match ||
        $type eq 'CODE'   && $match->($driver) ||
        $type eq 'ARRAY'  && member($driver, @$match) ||
        $driver eq $match;
    } @$settings_list;
}

sub device_run_command {
    my ($settings, $driver, $component) = @_;
    my $command = $settings->{$component} or return;

    if (ref $command eq 'CODE') {
        $command->($driver);
    } else {
        log::explanations("Running $component command $command");
        run_program::rooted($::prefix, $command);
    }
}

sub warn_not_installed {
    my ($in, @packages) = @_;
    $in->ask_warn(N("Error"), N("Could not install the packages (%s)!", join(', ', @packages)));
}

sub get_checked_element {
    my ($settings, $driver, $component) = @_;
    $component eq 'firmware' ?
      get_firmware_path($settings) :
    $component eq 'kernel_module' ?
      $driver :
      ref $settings->{$component} eq 'HASH' && $settings->{$component}{test_file};
}

sub warn_not_found {
    my ($in, $settings, $driver, $component, @packages) = @_;
    my %opt;
    $opt{$_} = component_get_option($settings, $component, $_) foreach qw(url explanations no_distro_package no_package);
    my $checked = get_checked_element($settings, $driver, $component);
    my $component_name = ref $settings->{$component} eq 'HASH' && translate($settings->{$component}{component_name}) || $component;
    $in->ask_warn(N("Error"),
                  join(" ",
                       ($opt{no_package} ?
                          N("Some components (%s) are required but aren't available for %s hardware.", $component_name, $settings->{name}) :
                          N("Some packages (%s) are required but aren't available.", join(', ', @packages))),
                       join("\n\n",
                            if_(!$opt{no_distro_package} && !$opt{no_package},
                                #-PO: first argument is a list of Mageia distributions
                                #-PO: second argument is a package media name
                                N("These packages can be found in %s, or in the official %s package repository.", "non-free"),
                            ),
                            if_($checked, N("The following component is missing: %s", $checked)),
                            if_($opt{explanations}, translate($opt{explanations})),
                            if_($opt{url}, N("The required files can also be installed from this URL:
%s", $opt{url})),
                        )));
}

sub is_file_installed {
    my ($settings, $component) = @_;
    my $file = ref $settings->{$component} eq 'HASH' && $settings->{$component}{test_file};
    $file && -e "$::prefix$file";
}

sub is_module_installed {
    my ($settings, $driver) = @_;
    my $module = ref $settings->{kernel_module} eq 'HASH' && $settings->{kernel_module}{test_file} || $driver;
    #- reload modules.dep so that newly added dkms modules are recognized
    list_modules::load_default_moddeps();
    #- FIXME: modules::module_is_available() won't use the chroot modules.dep in installer
    modules::module_is_available($module);
}

sub get_firmware_path {
    my ($settings) = @_;
    my $wildcard = ref $settings->{firmware} eq 'HASH' && $settings->{firmware}{test_file} or return;
    my $path = $settings->{firmware}{prefix} || $firmware_directory;
    "$::prefix$path/$wildcard";
}

sub is_firmware_installed {
    my ($settings) = @_;
    my $pattern = get_firmware_path($settings) or return;
    scalar bsd_glob($pattern, undef);
}

sub extract_firmware {
    my ($settings, $in) = @_;
    my $choice;
    $in->ask_from('', N("Firmware files are required for this device."),
                  [ { type => "list", val => \$choice, format => \&translate,
                      list => [
                          if_(exists $settings->{firmware}{extract}{floppy_source}, N_("Use a floppy")),
                          if_(exists $settings->{firmware}{extract}{windows_source}, N_("Use my Windows partition")),
                          N_("Select file")
                      ] } ]) or return;
    my ($h, $source);
    if ($choice eq N_("Use a floppy")) {
        $source = $settings->{firmware}{extract}{floppy_source};
        $h = find_file_on_floppy($in, $source);
    } elsif ($choice eq N_("Use my Windows partition")) {
        $source = $settings->{firmware}{extract}{windows_source};
        $h = find_file_on_windows_system($in, $source);
    } else {
        $source = $settings->{firmware}{extract}{default_source};
        $h = { file => $in->ask_file(N("Please select the firmware file (for example: %s)", basename($source)), dirname($source)) };
    }
    if (!-e $h->{file}) {
        log::explanations("Unable to find firmware file (tried to find $source.");
        return;
    }

    if ($settings->{firmware}{extract}{name}) {
        $in->do_pkgs->ensure_is_installed($settings->{firmware}{extract}{name}, $settings->{firmware}{extract}{test_file}) or return;
    }
    $settings->{firmware}{extract}{run}->($h->{file});
    1;
}

sub find_file_on_windows_system {
    my ($in, $file) = @_;
    my $source;
    require fsedit;
    my $all_hds = fsedit::get_hds();
    fs::get_info_from_fstab($all_hds);
    if (my $part = find { $_->{device_windobe} eq 'C' } fs::get::fstab($all_hds)) {
	foreach (qw(windows/system winnt/system windows/system32/drivers winnt/system32/drivers)) {
	    -d $_ and $source = first(bsd_glob("$part->{mntpoint}/$_/$file", undef)) and last;
	}
	$source or $in->ask_warn(N("Error"), N("Unable to find \"%s\" on your Windows system!", $file));
    } else {
	$in->ask_warn(N("Error"), N("No Windows system has been detected!"));
    }
    { file => $source };
}

sub find_file_on_floppy {
    my ($in, $file) = @_;
    my $floppy = detect_devices::floppy();
    my $mountpoint = '/media/floppy';
    my $h;
    $in->ask_okcancel(N("Insert floppy"),
		      N("Insert a FAT formatted floppy in drive %s with %s in root directory and press %s", $floppy, $file, N("Next"))) or return;
    if (eval { fs::mount::mount(devices::make($floppy), $mountpoint, 'vfat', 'readonly'); 1 }) {
	log::explanations("Mounting floppy device $floppy in $mountpoint");
	$h = before_leaving { fs::mount::umount($mountpoint) };
	if ($h->{file} = first(bsd_glob("$mountpoint/$file", undef))) {
	    log::explanations("Found $h->{file} on floppy device");
	} else {
	    log::explanations("Unabled to find $file on floppy device");
	}
    } else {
	$in->ask_warn(N("Error"), N("Floppy access error, unable to mount device %s", $floppy));
	log::explanations("Unable to mount floppy device $floppy");
    }
    $h;
}

sub get_required_packages {
    my ($type, $settings) = @_;
    device_get_packages($settings, $type, if_($type eq 'firmware', "$settings->{name}-firmware"));
}

sub check_installed {
    my ($type, $settings, $driver) = @_;
    $type eq 'kernel_module' ?
      is_module_installed($settings, $driver) :
    $type eq 'firmware' ?
      is_firmware_installed($settings) :
      is_file_installed($settings, $type);
}

sub get_available_packages {
    my ($type, $do_pkgs, @names) = @_;
    if ($type eq 'kernel_module') {
        return map { my $l = $do_pkgs->check_kernel_module_packages($_); $l ? @$l : () } @names;
    } else {
        return $do_pkgs->is_available(@names);
    }
}

sub user_install {
    my ($type, $settings, $in) = @_;
    if ($type eq 'firmware') {
        ref $settings->{$type} eq 'HASH' or return;
        if ($settings->{$type}{extract}) {
            extract_firmware($settings, $in);
        } else {
            my $f = $settings->{$type}{user_install};
            $f && $f->($settings, $in);
        }
    } else {
        my $f = ref $settings->{$type} eq 'HASH' && $settings->{$type}{user_install};
        $f && $f->($settings, $in);
    }
}

sub install_packages {
    my ($in, $settings, $driver, $component, @packages) = @_;

    unless (@packages) {
        log::explanations(qq(No $component package for module "$driver" is required, skipping));
        return 1;
    }

    if (check_installed($component, $settings, $driver)) {
        $settings->{old_status}{$component} = 1;
        log::explanations(qq(Required $component package for module "$driver" is already installed, skipping));
        return 1;
    }

    my $optional = ref $settings->{$component} eq 'HASH' && $settings->{$component}{optional};
    if (my @available = get_available_packages($component, $in->do_pkgs, @packages)) {
        log::explanations("Installing thirdparty packages ($component) " . join(', ', @available));
        if ($in->do_pkgs->install(@available) && check_installed($component, $settings, $driver)) {
            return 1;
        } elsif (!$optional) {
            warn_not_installed($in, @available);
        }
    }
    return 1 if $optional;
    log::explanations("Thirdparty package @packages ($component) is required but not available");

    0;
}

sub install_components {
    my ($in, $settings, $driver, @components) = @_;

    foreach my $component (@components) {
	my @packages = get_required_packages($component, $settings);
        if (!component_get_option($settings, $component, 'no_package')) {
            install_packages($in, $settings, $driver, $component, @packages) and next;
        }

	unless (user_install($component, $settings, $in)) {
	    warn_not_found($in, $settings, $driver, $component, @packages);
	    return;
	}
    }

    1;
}

sub apply_settings {
    my ($in, $category, $settings_list, $driver) = @_;

    my $settings = find_settings($settings_list, $driver);
    if ($settings) {
	log::explanations(qq(Found settings for driver "$driver" in category "$category"));

	my $wait = $in->wait_message(N("Please wait"), N("Looking for required software and drivers..."));

	install_components($in, $settings, $driver, @thirdparty_types) or return;

        if (!$settings->{no_module_reload}) {
            if (exists $settings->{firmware} && !$settings->{old_status}{firmware}) {
                log::explanations("Reloading module $driver");
                eval { modules::unload($driver) };
            } else {
                log::explanations("Loading module $driver");
            }
            eval { modules::load($driver) };
        }

        undef $wait;
        $wait = $in->wait_message(N("Please wait"), N("Please wait, running device configuration commands..."));
        device_run_command($settings, $driver, 'post');

	if (my $service = device_get_option($settings, 'restart_service')) {
	    log::explanations("Restarting service $service");
	    services::restart_or_start($service);
	}

        $settings->{sleep} and sleep $settings->{sleep};

	log::explanations(qq(Settings for driver "$driver" applied));
    } else {
	log::explanations(qq(No settings found for driver "$driver" in category "$category"));
    }

    $settings || {};
}

1;
