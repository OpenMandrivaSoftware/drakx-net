package network::connection::providers::cellular;

use common;
use utf8;

# http://www.reqwireless.com/apns.html
# http://wiki.mig33.com/mig33/show/apn
# http://www.unlocks.co.uk/gprs_settings.php
# http://www.opera.com/products/smartphone/docs/connect/
# http://www.taniwha.org.uk/gprs.html
# https://rip.psg.com/~randy/gprs-ppp.html
# http://computer.cocus.co.il/Setup/V3X/MPT/Addons/GPRSope.inf

our %data = (
    N("France") . "|Orange Web" => {
        apn => "orange.fr",
        login => "orange",
        password => "orange",
    },
    # http://www.actua-mobiles.com/p800/viewtopic.php?p=12184#12184
    # http://www.planete-se.net/index.php?showtopic=18184&st=0&p=186768&#entry186768
    N("France") . "|Orange WAP" => {
        apn => "orange",
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
    N("Italy") . "|TIM" => {
        apn => "ibox.internet.it",
        login => "tim",
        password => "tim",
    },
    N("Italy") . "|Vodafone" => {
        apn => "web.omnitel.it",
        login => "vodafone",
        password => "vodafone",
    },
    N("Italy") . "|Wind" => {
        apn => "internet.wind.it",
        login => "wind",
        password => "wind",
    },
    N("Italy") . "|Tre" => {
        apn => "tre.it",
        login => "tre",
        password => "tre",
    },
);

1;
