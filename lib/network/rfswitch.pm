package network::rfswitch;


use MDK::Common;
use detect_devices;

my $conf_file = "/etc/modprobe.d/rfswitch.conf";

my @settings = (
  {
      match => sub {
          # CL56, with buggy BIOS
          detect_devices::dmidecode_category('BIOS')->{Vendor} eq 'COMPAL' &&
          detect_devices::dmidecode_category('System')->{'Product Name'} eq '<BAD INDEX>';
      },
      module => 'acerhk',
      options => 'usedritek=1 autowlan=1 force_series=290',
      install => 'echo 1 > /proc/driver/acerhk/wirelessled',
      remove => 'echo 0 > /proc/driver/acerhk/wirelessled',
  },
);

sub configure() {
    my $setting = find { $_->{match}->() } @settings;
    if ($setting) {
        output_p($::prefix . $conf_file,
                 join("\n",
                      if_($setting->{options}, "options $setting->{module} $setting->{options}"),
                      if_($setting->{install}, "install $setting->{module} /sbin/modprobe --first-time --ignore-install $setting->{module} && $setting->{install}"),
                      if_($setting->{remove}, "remove $setting->{module} $setting->{remove}; /sbin/modprobe -r --ignore-remove $setting->{module}"),
                      "",
                  ));
        require modules;
        modules::set_preload_modules('rfswitch', $setting->{module});
    }
}

1;
