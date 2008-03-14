package network::drakconnect;

sub apply() {
    network::network::configure_network($net, $in, $modules_conf);
}

1;
