package network::invictus;

use MDK::Common;

my $ucarp_d = "/etc/ucarp.d";
my $ct_sync_config = "/etc/sysconfig/ct_sync";

sub read_config {
    my ($invictus) = @_;
    foreach (all($::prefix . $ucarp_d)) {
        $invictus->{ucarp}{$_} = +{ getVarsFromSh($::prefix . $ucarp_d . '/' . $_) };
    }
    $invictus->{ct_sync} = +{ getVarsFromSh($::prefix . $ct_sync_config) };
    $invictus->{ct_sync}{CMARKBIT} ||= 30;
}

sub write_config {
    my ($invictus) = @_;
    mkdir_p($::prefix . $ucarp_d);
    foreach (keys %{$invictus->{ucarp}}) {
        $invictus->{ucarp}{$_}{UPSCRIPT} ||= '/usr/share/invictus-firewall/ucarp-up.sh';
        $invictus->{ucarp}{$_}{DOWNSCRIPT} ||= '/usr/share/invictus-firewall/ucarp-down.sh';
        setVarsInShMode($::prefix . $ucarp_d . '/' . $_, 0600, $invictus->{ucarp}{$_},
                    qw(INTERFACE SRCIP VIRTIP VHID PASSWORD TAKEOVER UPSCRIPT DOWNSCRIPT));
    }
    setVarsInSh($::prefix . $ct_sync_config, $invictus->{ct_sync},
                qw(ENABLE INTERFACE CMARKBIT));
}

1;
