package network::connection::providers::cellular;

use common;
use utf8;

# http://www.reqwireless.com/apns.html
# http://wiki.mig33.com/mig33/show/apn
# http://www.unlocks.co.uk/gprs_settings.php
# http://www.opera.com/products/smartphone/docs/connect/
# http://www.taniwha.org.uk/gprs.html

our %data = (
    N("France") . "|Orange Web" => {
        apn => "orange.fr",
        login => "orange",
        password => "orange",
    },
    N("France") . "|Orange Entreprises" => {
        apn => "internet-entreprise",
        login => "orange",
        password => "orange",
    },
    N("France") . "|SFR" => {
        apn => "websfr",
    },
);

1;
