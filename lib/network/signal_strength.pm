package network::signal_strength;

use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;
use ugtk3;

my %pixbufs;

sub get_strength_icon {
    my ($network) = @_;
    my $approx = 20 + min(80, int($network->{signal_strength}/20)*20);
    return $pixbufs{$approx} ||= ugtk3::gtkcreate_pixbuf('wifi-' . sprintf('%03d', $approx));
}

1;
