package network::signal_strength;

use common;
use ugtk2;

my %pixbufs;

sub get_strength_icon {
    my ($network) = @_;
    my $approx = 20 + min(80, int($network->{signal_strength}/20)*20);
    return $pixbufs{$approx} ||= ugtk2::gtkcreate_pixbuf('wifi-' . sprintf('%03d', $approx) . '.png');
}

1;
