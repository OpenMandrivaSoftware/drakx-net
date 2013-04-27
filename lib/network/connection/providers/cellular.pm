package network::connection::providers::cellular;

use lib qw(/usr/lib/libDrakX);   # helps perl_checker
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
    N("Brazil") . "|Vivo" => {
        apn => "zap.vivo.com.br",
        login => "vivo",
        password => "vivo",
    },
    N("Estonia") . "|Bravocom" => {
        apn => "internet",
    },
    N("Estonia") . "|Elisa" => {
        apn => "internet",
    },
    N("Estonia") . "|EMT" => {
        apn => "internet.emt.ee",
    },
    N("Estonia") . "|Simpel/POP!" => {
        apn => "internet2.emt.ee",
    },
    N("Estonia") . "|Tele2" => {
        apn => "internet.tele2.ee",
    },
    N("Estonia") . "|TeleYks" => {
        apn => "internet",
    },
    N("Estonia") . "|Zorro" => {
        apn => "internet",
    },
    # http://www.cubio.fi/fi/cubio_gsm/mms_ja_gprs_asetukset
    N("Finland") . "|Cubio" => {
        apn => "internet.cubio.net",
    },
    # http://www.dnaoy.fi/Yksityisille/Matkaviestinta/Asiakaspalvelu/Documents/Ohjeet/asetukset_yleiset_wxp.pdf
    N("Finland") . "|DNA" => {
        apn => "internet",
    },
    # http://matkaviestinta.elisa.fi/public/elisa.do?id=hen_liit_palvelut_gprs,ds_muut_0054.htm
    # http://tuki.elisa.fi/asiakastuki/elisa.do?id=hen_as_matkaviest_ohjeet,as_help_page_0025.htm
    # Official pages have inconsistent information on whether login and
    # password are used. Presumably they are ignored, but we set them just to
    # be sure.
    N("Finland") . "|Elisa" => {
        apn => "internet",
        login => "rlnet",
        password => "internet",
    },
    # http://koti.mbnet.fi/simopot/asetukset/index.php?operaattori=globetel
    N("Finland") . "|Globetel" => {
        apn => "internet",
    },
    # http://www.kolumbus.com/asiakaspalvelu_asetukset.html
    # Redirects to Elisa automatic setup, presumably same settings apply.
    N("Finland") . "|Kolumbus" => {
        apn => "internet",
        login => "rlnet",
        password => "internet",
    },
    # http://saunalahti.fi/tuki/gsm/vo/ohjeemail.php
    N("Finland") . "|Saunalahti" => {
        apn => "internet.saunalahti",
    },
    # http://koti.mbnet.fi/simopot/asetukset/index.php?operaattori=sonera
    N("Finland") . "|Sonera" => {
        apn => "internet",
    },
    # http://tdc.fi/publish.php?dogtag=songfi_at_ojl_int
    N("Finland") . "|Song" => {
        apn => "internet.song.fi",
        login => "song@internet",
        password => "songnet",
    },
    # http://www.tele.fi/Asiakaspalvelu/Ohjeet/K%E4nnyk%E4ll%E4+nettiin+ja+tiedonsiirto/Asetukset/
    N("Finland") . "|Tele Finland" => {
        apn => "internet",
    },
    # http://www.gsm.aland.fi/tjanster/wap/wap.htm
    N("Finland") . "|Ålands Mobiltelefon" => {
        apn => "internet",
    },
    N("France") . "|BouygTel" => {
        apn => "ebouygtel.com",
    },
    N("France") . "|BouygTel Pro" => {
        apn => "a2bouygtel.com",
        login => "a2b",
        password => "acces",
    },
    N("France") . "|BouygTel Pro GPRS" => {
        apn => "b2bouygtel.com",
        login => "B2B",
        password => "NET",
    },
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
    N("France") . "|SFR EeePC (Clé Internet 3G+)" => {
        apn => "slsfr",
    },
    N("France") . "|SFR WAP (Illimythics / Pass Surf)" => {
        apn => "wapsfr",
    },
    N("France") . "|SFR Web (Clé Internet / Data)" => {
        apn => "websfr",
    },
    N("Germany") . "|Vodafone Live! WAP" => {
        apn => "wap.vodafone.de",
    },
    N("Germany") . "|Vodafone Web" => {
        apn => "web.vodafone.de",
    },
    N("Italy") . "|TIM" => {
        apn => "ibox.tim.it",
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
    N("Poland") . "|Era GSM" => {
        apn => "erainternet",
        login => "erainternet",
        password => "erainternet",
    },
    N("Poland") . "|Orange" => {
        apn => "internet",
        login => "internet",
        password => "internet",
    },
    N("Poland") . "|Play" => {
        apn => "INTERNET",
    },
    N("Poland") . "|Plus GSM" => {
        apn => "internet",
    },
    N("United Kingdom") . "|O2" => {
        apn => "mobile.o2.co.uk",
        login => "mobileweb",
        password => "password",
    },
    N("United States") . "|Cingular" => {
        apn => "isp.cingular",
    },
);

1;
