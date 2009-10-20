package network::connection::providers::cellular_extra;

use common;
use utf8;

# this list was imported from mobile-broadband-provider-info
# (http://svn.gnome.org/svn/mobile-broadband-provider-info/trunk) and converted
# to perl data using some black magick

our %data = (
    N("United Arab Emirates") . "|Etisalat" => {
        apn => "mnet",
        login => "mnet",
        password => "mnet",
        dns => "194.170.1.6",
        dns => "194.170.1.7",
    },
    N("United Arab Emirates") . "|Etisalat 3G" => {
        apn => "etisalat.ae",
        login => "etisalat.ae",
        password => "etisalat.ae",
    },
    N("Albania") . "|Vodafone" => {
        apn => "Twa",
    },
    N("Angola") . "|Movinet" => {
        cdma => 1,
        login => "uname",
    },
    N("Argentina") . "|Personal" => {
        apn => "gprs.personal.com",
        login => "gprs",
        password => "adgj",
        dns => "172.25.7.6",
        dns => "172.25.7.7",
    },
    N("Argentina") . "|CTI" => {
        apn => "internet.ctimovil.com.ar",
        login => "ctigprs",
        dns => "170.51.255.100",
        dns => "170.51.242.18",
    },
    N("Argentina") . "|Movistar" => {
        apn => "internet.gprs.unifon.com.ar",
        login => "wap",
        password => "wap",
    },
    N("Angola") . "|Unitel" => {
        apn => "internet.unitel.co.ao",
    },
    N("Austria") . "|Max Max Online Mobil" => {
        apn => "gprsinternet",
        login => "GPRS",
        dns => "213.162.64.1",
        dns => "213.162.64.2",
    },
    N("Austria") . "|Max Online" => {
        apn => "gprsinternet",
        login => "GPRS",
        dns => "213.162.64.1",
        dns => "213.162.64.2",
    },
    N("Austria") . "|Max Online (Business)" => {
        apn => "business.gprsinternet",
        login => "GPRS",
        dns => "213.162.64.1",
        dns => "213.162.64.2",
    },
    N("Austria") . "|Max Online (Metro)" => {
        apn => "gprsmetro",
        login => "GPRS",
        dns => "213.162.64.1",
        dns => "213.162.64.2",
    },
    N("Austria") . "|Mobilkom/A1" => {
        apn => "a1.net",
        login => "ppp@a1plus.at",
        password => "ppp",
        dns => "194.48.139.254",
        dns => "194.48.124.202",
    },
    N("Austria") . "|Orange" => {
        apn => "web.one.at",
        login => "web",
        password => "web",
        dns => "194.24.128.100",
        dns => "194.24.128.102",
    },
    N("Austria") . "|Tele.ring" => {
        apn => "web",
        login => "web@telering.at",
        password => "web",
        dns => "212.95.31.167 ",
        dns => "212.95.31.168",
    },
    N("Austria") . "|Telering" => {
        apn => "web",
        login => "web@telering.at",
        password => "web",
        dns => "212.95.31.167 ",
        dns => "212.95.31.168",
    },
    N("Austria") . "|Drei" => {
        apn => "drei.at",
    },
    N("Austria") . "|Yesss" => {
        apn => "web.yesss.at",
    },
    N("Australia") . "|Exetel" => {
        apn => "exetel1",
    },
    N("Australia") . "|Optus" => {
        apn => "internet",
        dns => "202.139.83.3",
        dns => "192.65.91.129",
    },
    N("Australia") . "|Optus 3G" => {
        apn => "CONNECT",
        dns => "202.139.83.3",
        dns => "192.65.91.129",
    },
    N("Australia") . "|Telstra" => {
        apn => "telstra.wap",
        dns => "139.130.4.4",
        dns => "203.50.2.71",
    },
    N("Australia") . "|Telstra (3G data pack)" => {
        apn => "telstra.datapack",
        password => "Telstra",
        dns => "139.130.4.4",
        dns => "203.50.2.71",
    },
    N("Australia") . "|Telstra (UMTS/HSDPA)" => {
        apn => "telstra.internet",
        dns => "139.130.4.4",
        dns => "203.50.170.2",
    },
    N("Australia") . "|Telstra (3G PC pack - pay by time)" => {
        apn => "telstra.pcpack",
        password => "Telstra",
        dns => "139.130.4.4",
        dns => "203.50.2.71",
    },
    N("Australia") . "|Telstra (Next G card)" => {
        dns => "139.130.4.4",
        dns => "203.50.2.71",
    },
    N("Australia") . "|Three" => {
        apn => "3netaccess",
        login => "a",
        password => "a",
        dns => "202.124.68.130",
        dns => "202.124.76.66",
    },
    N("Australia") . "|Three Prepaid" => {
        apn => "3services",
        login => "a",
        password => "a",
        dns => "202.124.68.130",
        dns => "202.124.76.66",
    },
    N("Australia") . "|Virgin Mobile" => {
        apn => "VirginInternet",
        login => "guest",
        password => "guest",
        dns => "61.88.88.88",
    },
    N("Australia") . "|Vodafone" => {
        apn => "vfinternet.au",
        dns => "192.189.54.33",
        dns => "210.80.58.3",
    },
    N("Azerbaijan") . "|Azercell" => {
        apn => "internet",
    },
    N("Azerbaijan") . "|Bakcell" => {
        apn => "mms",
    },
    N("Bosnia and Herzegovina") . "|BH GSM" => {
        apn => "mms.bhmobile.ba",
    },
    N("Bahamas") . "|Batelco" => {
        apn => "internet.btcbahamas.com",
    },
    N("Bangladesh") . "|AKTel" => {
        apn => "atmmms",
        dns => "192.168.023.007",
    },
    N("Bangladesh") . "|Banglalink" => {
        apn => "blweb",
    },
    N("Bangladesh") . "|Grameen Phone" => {
        apn => "gpinternet",
        dns => "202.56.4.120",
        dns => "202.56.4.121",
    },
    N("Barbados") . "|Digicel" => {
        apn => "isp.digicelbarbados.com",
    },
    N("Belgium") . "|Mobistar (business)" => {
        apn => "web.pro.be",
        login => "mobistar",
        password => "mobistar",
        dns => "212.65.63.10",
        dns => "212.65.63.145",
    },
    N("Belgium") . "|Orange" => {
        apn => "orangeinternet",
    },
    N("Belgium") . "|Proximus Inter" => {
        apn => "internet.proximus.be",
        dns => "195.238.2.21",
        dns => "195.238.2.22",
    },
    N("Belgium") . "|Proximus Intra" => {
        apn => "intraprox.be",
        dns => "195.238.2.21",
        dns => "195.238.2.22",
    },
    N("Belgium") . "|Base" => {
        apn => "gprs.base.be",
        login => "base",
        password => "base",
    },
    N("Belgium") . "|Mobistar (personal)" => {
        apn => "internet.be",
        login => "mobistar",
        password => "mobistar",
        dns => "212.65.63.10",
        dns => "212.65.63.145",
    },
    N("Bulgaria") . "|GloBul" => {
        apn => "internet.globul.bg",
        login => "globul",
        dns => "192.168.88.11",
    },
    N("Bulgaria") . "|M-Tel" => {
        apn => "inet-gprs.mtel.bg",
        login => "mtel",
        password => "mtel",
        dns => "213.226.7.34",
        dns => "213.226.7.35",
    },
    N("Bulgaria") . "|GloBul" => {
        apn => "internet.globul.bg",
        login => "globul",
        password => "[none]",
        dns => "192.168.88.11",
    },
    N("Brazil") . "|Claro" => {
        apn => "claro.com.br",
        login => "claro",
        password => "claro",
    },
    N("Brazil") . "|Oi" => {
        apn => "gprs.oi.com.br",
        password => "oioioi",
    },
    N("Brazil") . "|TIM" => {
        apn => "tim.br",
        login => "tim",
        password => "tim",
        dns => "10.223.246.102",
        dns => "10.223.246.103",
    },
    N("Brazil") . "|Oi (WAP)" => {
        apn => "wapgprs.oi.com.br",
        login => "oiwap",
        password => "oioioi",
    },
    N("Brazil") . "|Velox" => {
        apn => "wap.telcel.com",
        login => "iesgprs",
        password => "iesgprs2002",
        dns => "66.36.250.14",
    },
    N("Brazil") . "|Vivo" => {
        apn => "zap.vivo.com.br",
        login => "vivo",
        password => "vivo",
    },
    N("Belarus") . "|VELCOM" => {
        apn => "wap.velcom.by",
        login => "wap",
        password => "wap",
    },
    N("Belarus") . "|VELCOM (Simple GPRS)" => {
        apn => "web.velcom.by",
        login => "web",
        password => "web",
        dns => "212.98.162.154",
        dns => "193.232.248.2",
    },
    N("Belarus") . "|VELCOM (Web Plus)" => {
        apn => "plus.velcom.by",
        login => "plus",
        password => "plus",
    },
    N("Belarus") . "|VELCOM (Privet)" => {
        apn => "privet.velcom.by",
        login => "privet",
        password => "privet",
    },
    N("Belarus") . "|MTS" => {
        apn => "internet.mts.by",
        login => "mts",
        password => "mts",
    },
    N("Botswana") . "|Mascom Wireless" => {
        apn => "internet.mascom",
    },
    N("Canada") . "|Microcell Fido" => {
        apn => "internet.fido.ca",
        login => "fido",
        password => "fido",
        dns => "204.92.15.211",
        dns => "207.181.101.4",
    },
    N("Canada") . "|Rogers AT&T" => {
        apn => "internet.com",
        login => "wapuser1",
        password => "wap",
        dns => "207.181.101.4",
        dns => "207.181.101.5",
    },
    N("Congo (Kinshasa)") . "|Vodafone" => {
        apn => "vodanet",
        login => "vodalive",
        dns => "172.24.97.1",
    },
    N("Congo (Brazzaville)") . "|Vodafone" => {
        apn => "vodanet",
        login => "vodalive",
        dns => "172.24.97.1",
    },
    N("Switzerland") . "|Orange" => {
        apn => "mobileoffice3g",
        dns => "213.55.128.1 ",
        dns => "213.55.128.2",
    },
    N("Switzerland") . "|Sunrise" => {
        apn => "internet",
        login => "internet",
        password => "internet",
        dns => "212.35.35.35",
        dns => "212.35.35.5",
    },
    N("Switzerland") . "|Swisscom" => {
        apn => "gprs.swisscom.ch",
        login => "gprs",
        password => "gprs",
        dns => "164.128.36.34",
        dns => "164.128.76.39",
    },
    N("Cote d'Ivoire") . "|internet" => {
        apn => "172.16.100.5",
    },
    N("Chile") . "|Claro Chile" => {
        apn => "bam.clarochile.cl",
        login => "clarochile",
        password => "clarochile",
    },
    N("Chile") . "|Claro Chile - Prepago" => {
        apn => "bap.clarochile.cl",
        login => "clarochile",
        password => "clarochile",
    },
    N("Chile") . "|Claro Chile - WAP" => {
        apn => "wap.clarochile.cl",
        login => "clarochile",
        password => "clarochile",
    },
    N("Chile") . "|Entel PCS" => {
        apn => "imovil.entelpcs.cl",
        login => "entelpcs",
        password => "entelpcs",
    },
    N("Chile") . "|Entel PCS - WAP" => {
        apn => "bam.entelpcs.cl",
        login => "entelpcs",
        password => "entelpcs",
    },
    N("Chile") . "|Movistar" => {
        apn => "web.tmovil.cl",
        login => "web",
        password => "web",
    },
    N("Chile") . "|Movistar - WAP" => {
        apn => "wap.tmovil.cl",
        login => "wap",
        password => "wap",
    },
    N("Cameroon") . "|Orange" => {
        apn => "orangecmgprs",
        login => "orange",
        password => "orange",
    },
    N("Cameroon") . "|MTN" => {
        apn => "INTERNET",
        dns => "-",
    },
    N("China") . "|China Mobile" => {
        apn => "cmnet",
        dns => "211.136.20.203 ",
        dns => "211.136.20.203",
    },
    N("China") . "|China Unicom" => {
        apn => "none",
        dns => "211.136.20.203 ",
        dns => "211.136.20.203",
    },
    N("Costa Rica") . "|IceCelular" => {
        apn => "icecelular",
        dns => "208.133.206.44 ",
        dns => "208.133.206.44",
    },
    N("Colombia") . "|Comcel" => {
        apn => "internet.comcel.com.co",
        login => "COMCELWEB",
        password => "COMCELWEB",
    },
    N("Colombia") . "|Tigo" => {
        apn => "web.colombiamovil.com.co",
    },
    N("Colombia") . "|Movistar" => {
        apn => "internet.movistar.com.co",
        login => "movistar",
        password => "movistar",
    },
    N("Czech Republic") . "|Cesky Mobil (postpaid)" => {
        apn => "internet",
        dns => "212.67.64.2",
        dns => "217.77.161.131",
    },
    N("Czech Republic") . "|Cesky Mobil (prepaid)" => {
        apn => "Cinternet",
        dns => "212.67.64.2",
        dns => "217.77.161.131",
    },
    N("Czech Republic") . "|EuroTel (Go)" => {
        apn => "gointernet",
        dns => "160.218.10.200 ",
        dns => "160.218.43.200",
    },
    N("Czech Republic") . "|Oscar (Post p.)" => {
        apn => "internet",
        login => "wap",
        password => "wap",
        dns => "217.77.161.130",
        dns => "217.77.161.131",
    },
    N("Czech Republic") . "|Oscar (Pre p.)" => {
        apn => "internet",
        dns => "217.77.161.130",
        dns => "217.77.161.131",
    },
    N("Czech Republic") . "|Paegas Internet" => {
        apn => "internet.click.cz",
        dns => "62.141.0.1",
        dns => "62.141.0.2",
    },
    N("Czech Republic") . "|Paegas Profil" => {
        apn => "profil.click.cz",
        dns => "62.141.0.1",
        dns => "62.141.0.2",
    },
    N("Czech Republic") . "|Radiomibil" => {
        apn => "internet.click.cz",
    },
    N("Czech Republic") . "|T-Mobil" => {
        apn => "internet.t-mobile.cz",
        dns => "62.141.0.1",
        dns => "213.162.65.1",
    },
    N("Czech Republic") . "|Eurotel (contract)" => {
        apn => "internet",
        dns => "160.218.10.200",
        dns => "160.218.43.200",
    },
    N("Czech Republic") . "|Eurotel (contract - open)" => {
        apn => "internet.open",
        dns => "160.218.10.200 ",
        dns => "160.218.43.200",
    },
    N("Czech Republic") . "|Vodafone (contract)" => {
        apn => "internet",
        dns => "217.77.161.130",
        dns => "217.77.161.131",
    },
    N("Czech Republic") . "|Telefonica (contract)" => {
        apn => "internet",
        dns => "160.218.10.200",
        dns => "160.218.43.200",
    },
    N("Czech Republic") . "|Vodafone (pre-pay)" => {
        apn => "ointernet",
        dns => "217.77.161.130",
        dns => "217.77.161.131",
    },
    N("Czech Republic") . "|Telefonica (Go)" => {
        apn => "gointernet",
        dns => "160.218.10.201",
        dns => "194.228.2.1",
    },
    N("Germany") . "|AldiTalk/MedionMobile" => {
        apn => "internet.eplus.de",
        login => "eplus",
        password => "gprs",
        dns => "212.23.97.2",
        dns => "212.23.97.3",
    },
    N("Germany") . "|E-Plus (pre-pay)" => {
        apn => "internet.eplus.de",
        login => "eplus",
        password => "gprs",
        dns => "212.23.97.2",
        dns => "212.23.97.3",
    },
    N("Germany") . "|E-Plus (contract)" => {
        apn => "internet.eplus.de",
        login => "eplus",
        password => "gprs",
        dns => "212.23.97.2",
        dns => "212.23.97.3",
    },
    N("Germany") . "|o2 (pay-by-MB)" => {
        apn => "internet",
        dns => "195.182.110.132 ",
        dns => "62.134.11.4",
    },
    N("Germany") . "|o2 (pay-by-time)" => {
        apn => "surfo2",
        dns => "195.182.110.132 ",
        dns => "62.134.11.4",
    },
    N("Germany") . "|o2 Viag Interkom" => {
        apn => "internet",
        dns => "195.182.110.132",
        dns => "62.134.11.4",
    },
    N("Germany") . "|T-mobile (D1)" => {
        apn => "internet.t-d1.de",
        password => "t-d1",
        dns => "193.254.160.1 ",
        dns => "193.254.160.130",
    },
    N("Germany") . "|Vodafone (D2)" => {
        apn => "web.vodafone.de",
        login => "vodafone",
        password => "vodafone",
        dns => "139.7.30.125",
        dns => "139.7.30.126",
    },
    N("Germany") . "|Vodafone (D2) WebSessions" => {
        apn => "event.vodafone.de",
        login => "vodafone",
        password => "vodafone",
        dns => "139.7.30.125",
        dns => "139.7.30.126",
    },
    N("Germany") . "|FONIC" => {
        apn => "pinternet.interkom.de",
    },
    N("Denmark") . "|3 (Bredbånd)" => {
        apn => "bredband.tre.dk",
    },
    N("Denmark") . "|3 (Bredbånd Premium Kontant)" => {
        apn => "net.tre.dk",
    },
    N("Denmark") . "|3 (Mobil Abonnement)" => {
        apn => "data.tre.dk",
    },
    N("Denmark") . "|OiSTER" => {
        apn => "bredband.oister.dk",
    },
    N("Denmark") . "|ice.net (Nordisk Mobiltelefon)" => {
        cdma => 1,
        login => "cdma",
        password => "cdma",
    },
    N("Denmark") . "|Sonofon" => {
        apn => "internet",
        dns => "212.88.64.199",
        dns => "212.88.64.14",
    },
    N("Denmark") . "|TDC" => {
        apn => "internet",
        dns => "194.239.134.83",
        dns => "193.162.153.164",
    },
    N("Denmark") . "|Fullrate" => {
        apn => "internet",
        login => "Fullrate",
        password => "Fullrate",
    },
    N("Denmark") . "|Telia" => {
        apn => "www.internet.mtelia.dk",
    },
    N("Denmark") . "|BiBoB" => {
        apn => "internet.bibob.dk",
    },
    N("Dominican Republic") . "|Orange" => {
        apn => "orangenet.com.do",
    },
    N("Ecuador") . "|Porta 3G" => {
        apn => "internet.porta.com.ec",
    },
    N("Estonia") . "|EMT" => {
        apn => "internet.emt.ee",
        dns => "217.71.32.116",
        dns => "217.71.32.115",
    },
    N("Estonia") . "|Nordea" => {
        apn => "internet.emt.ee",
    },
    N("Estonia") . "|Radiolinja" => {
        apn => "internet",
        dns => "194.204.0.1",
    },
    N("Estonia") . "|RLE" => {
        apn => "internet",
    },
    N("Estonia") . "|Tele2" => {
        apn => "internet.tele2.ee",
        login => "wap",
        password => "wap",
    },
    N("Egypt") . "|Click Vodafone" => {
        apn => "internet.vodafone.net",
        login => "internet",
        password => "internet",
    },
    N("Egypt") . "|Etisalat" => {
        apn => "etisalat",
    },
    N("Egypt") . "|MobiNil" => {
        apn => "mobinilweb",
        dns => "80.75.166.250",
        dns => "163.121.163.201",
    },
    N("Spain") . "|Amena" => {
        apn => "internet",
        login => "CLIENTE",
        password => "AMENA",
        dns => "213.143.32.20 ",
        dns => "213.143.33.8",
    },
    N("Spain") . "|Orange" => {
        apn => "internet",
        login => "CLIENTE",
        password => "AMENA",
        dns => "213.143.32.20 ",
        dns => "213.143.33.8",
    },
    N("Spain") . "|Simyo" => {
        apn => "gprs-service.com",
    },
    N("Spain") . "|Telefonica" => {
        apn => "movistar.es",
        login => "movistar",
        password => "movistar",
        dns => "194.179.1.100",
        dns => "194.179.1.101",
    },
    N("Spain") . "|Vodafone (Airtel)" => {
        apn => "airtelnet.es",
        login => "vodafone",
        password => "vodafone",
        dns => "212.73.32.3",
        dns => "212.73.32.67",
    },
    N("Spain") . "|Vodafone" => {
        apn => "airtelnet.es",
        login => "vodafone",
        password => "vodafone",
        dns => "196.207.32.69",
        dns => "196.43.45.190",
    },
    N("Spain") . "|Yoigo" => {
        apn => "Internet",
    },
    N("Spain") . "|Jazztel" => {
        apn => "jazzinternet",
    },
    N("Finland") . "|Dna" => {
        apn => "internet",
        dns => "217.78.192.22 ",
        dns => "217.78.192.78",
    },
    N("Finland") . "|Elisa" => {
        apn => "internet",
    },
    N("Finland") . "|Saunalahti" => {
        apn => "internet.saunalahti",
    },
    N("Finland") . "|Sonera" => {
        apn => "internet",
        dns => "192.89.123.230",
        dns => "192.89.123.231",
    },
    N("Finland") . "|Sonera prointernet" => {
        apn => "prointernet",
        dns => "192.89.123.230",
        dns => "192.89.123.231",
    },
    N("Fiji") . "|Vodafone" => {
        apn => "vfinternet.fj",
    },
    N("France") . "|Bouygues Telecom (B2Bouygtel)" => {
        apn => "b2bouygtel.com",
        dns => "62.201.129.99",
    },
    N("France") . "|Bouygues Telecom" => {
        apn => "ebouygtel.com",
        dns => "62.201.129.99",
        dns => "62.201.159.99",
    },
    N("France") . "|France Telecom" => {
        apn => "orange.fr.mnc001.mcc208.gprs",
        login => "gprs",
    },
    N("France") . "|Orange (contract)" => {
        apn => "orange.fr",
        login => "orange",
        password => "orange",
        dns => "194.51.3.56",
        dns => "194.51.3.76",
    },
    N("France") . "|Orange (business contract)" => {
        apn => "internet-entreprise",
        login => "orange",
        password => "orange",
    },
    N("France") . "|Orange (no contact)" => {
        apn => "orange",
        login => "orange",
        password => "orange",
        dns => "194.51.3.56 ",
        dns => "194.51.3.76",
    },
    N("France") . "|Orange MIB" => {
        apn => "orange-mib",
        login => "mportail",
        password => "mib",
        dns => "172.17.0.2 ",
        dns => "172.17.0.4",
    },
    N("France") . "|Orange Mobicarte" => {
        apn => "orange",
        login => "orange",
        password => "orange",
    },
    N("France") . "|Orange Internet Everywhere 3G" => {
        apn => "orange.ie",
    },
    N("France") . "|SFR" => {
        apn => "websfr",
        dns => "172.20.2.10",
        dns => "172.20.2.39",
    },
    N("France") . "|Transatel Telecom" => {
        apn => "netgprs.com",
    },
    N("France") . "|TEN" => {
        apn => "ao.fr",
        login => "orange",
        password => "orange",
    },
    N("France") . "|TEN (pay-by-MB)" => {
        apn => "ofnew.fr",
        login => "orange",
        password => "orange",
    },
    N("France") . "|Orange (business)" => {
        apn => "internet-entreprise",
        login => "orange",
        password => "orange",
        dns => "194.51.3.56",
        dns => "194.51.3.76",
    },
    N("France") . "|Orange (contract)" => {
        apn => "orange.fr",
        login => "orange",
        password => "orange",
        dns => "194.51.3.56",
        dns => "194.51.3.76",
    },
    N("United Kingdom") . "|airtel vodaphone" => {
        apn => "airtel-ci-gprs.com",
    },
    N("United Kingdom") . "|Jersey Telecom" => {
        apn => "pepper",
        login => "abc",
        password => "abc",
        dns => "212.9.0.135",
        dns => "212.9.0.136",
    },
    N("United Kingdom") . "|o2 (contract)" => {
        apn => "mobile.o2.co.uk",
        login => "o2web",
        password => "password",
        dns => "193.113.200.200",
        dns => "193.113.200.201",
    },
    N("United Kingdom") . "|o2 (pre-pay)" => {
        apn => "payandgo.o2.co.uk",
        login => "payandgo",
        password => "payandgo",
    },
    N("United Kingdom") . "|Orange (contract)" => {
        apn => "orangeinternet",
        login => "orange",
        password => "orange",
        dns => "193.35.133.10 ",
        dns => "193.35.134.10",
    },
    N("United Kingdom") . "|Orange JustTalk" => {
        apn => "orangeinternet",
        dns => "193.35.133.10",
        dns => "193.35.134.10",
    },
    N("United Kingdom") . "|T-Mobile" => {
        apn => "general.t-mobile.uk",
        login => "User",
        password => "mms",
        dns => "149.254.201.126",
        dns => "149.254.192.126",
    },
    N("United Kingdom") . "|Virgin Mobile" => {
        apn => "vdata",
        dns => "196.7.0.138",
        dns => "196.7.142.132",
    },
    N("United Kingdom") . "|Vodafone (contract)" => {
        apn => "internet",
        login => "web",
        password => "web",
        dns => "10.206.65.68",
        dns => "10.203.65.68",
    },
    N("United Kingdom") . "|Vodafone (pre-pay)" => {
        apn => "pp.vodafone.co.uk",
        login => "wap",
        password => "wap",
        dns => "172.29.1.11 ",
        dns => "172.29.1.11",
    },
    N("United Kingdom") . "|Vodafone (TopUp and Go)" => {
        apn => "pp.internet",
    },
    N("United Kingdom") . "|o2 (contract-faster)" => {
        apn => "mobile.o2.co.uk",
        login => "faster",
        password => "password",
        dns => "193.113.200.200",
        dns => "193.113.200.201",
    },
    N("United Kingdom") . "|3" => {
        apn => "3internet",
    },
    N("United Kingdom") . "|3 (handsets)" => {
        apn => "three.co.uk",
    },
    N("United Kingdom") . "|Orange (Pay and Go)" => {
        apn => "orangewap",
        login => "Multimedia",
        password => "Orange",
        dns => "158.43.192.1",
        dns => "158.43.128.1",
    },
    N("United Kingdom") . "|Orange (Pay Monthly)" => {
        apn => "orangeinternet",
        login => "orange",
        password => "multimedia",
        dns => "158.43.192.1",
        dns => "158.43.128.1",
    },
    N("Georgia") . "|Geocell" => {
        apn => "Internet",
        dns => "212.72.130.20",
        dns => "212.72.152.001",
    },
    N("Ghana") . "|Areeba" => {
        apn => "internet.areeba.com.gh",
        dns => "196.201.34.5",
        dns => "213.137.131.3",
    },
    N("Ghana") . "|ONETouch" => {
        apn => "browse",
    },
    N("Ghana") . "|Tigo" => {
        apn => "web.tigo.com.gh",
        login => "web",
        password => 1,
    },
    N("Ghana") . "|Zain" => {
        apn => "internet",
    },
    N("Greece") . "|Cosmote" => {
        apn => "3g-internet",
        dns => "195.167.65.194",
    },
    N("Greece") . "|Telestet" => {
        apn => "gnet.b-online.gr",
        password => "24680",
        dns => "212.152.79.19",
        dns => "212.152.79.20",
    },
    N("Greece") . "|Vodafone" => {
        apn => "internet",
    },
    N("Greece") . "|TIM" => {
        apn => "gint.b-online.gr",
        login => "web",
        password => "web",
    },
    N("Guatemala") . "|Comcel" => {
        apn => "Wap.tigo.gt",
        login => "Wap",
        password => "Wap",
    },
    N("Guatemala") . "|PCS Digital" => {
        apn => "ideasalo",
    },
    N("Guyana") . "|GT&T Cellink Plus" => {
        apn => "wap.cellinkgy.com",
        login => "test",
        password => "test",
    },
    N("Hong Kong") . "|CSL" => {
        apn => "internet",
        dns => "202.84.255.1",
        dns => "203.116.254.150",
    },
    N("Hong Kong") . "|New World" => {
        apn => "internet",
    },
    N("Hong Kong") . "|People" => {
        apn => "internet",
    },
    N("Hong Kong") . "|SmarTone" => {
        apn => "internet",
        dns => "202.140.96.51",
        dns => "202.140.96.52",
    },
    N("Hong Kong") . "|Sunday" => {
        apn => "internet",
    },
    N("Hong Kong") . "|Orange" => {
        apn => "web.orangehk.com",
    },
    N("Hong Kong") . "|Three" => {
        apn => "mobile.three.com.hk",
    },
    N("Honduras") . "|Tigo" => {
        apn => "internet.tigo.hn",
    },
    N("Croatia") . "|HTmobile" => {
        apn => "www.htgprs.hr",
        dns => "10.12.0.1",
    },
    N("Croatia") . "|VIPNET" => {
        apn => "gprs5.vipnet.hr",
        login => "38591",
        password => "38591",
        dns => "195.29.159.15",
    },
    N("Croatia") . "|VIPNET" => {
        apn => "gprs0.vipnet.hr",
        login => "38591",
        password => "38591",
        dns => "195.29.159.15",
    },
    N("Croatia") . "|VIPNET" => {
        apn => "3g.vip.hr",
        login => "38591",
        password => "38591",
        dns => "212.91.97.3 ",
        dns => "212.91.97.4",
    },
    N("Hungary") . "|Pannon (átalánydíjas)" => {
        apn => "netx",
        dns => "193.225.155.254 ",
        dns => "194.149.0.157",
    },
    N("Hungary") . "|Pannon (normál)" => {
        apn => "net",
        dns => "193.225.153.17",
        dns => "195.56.172.113",
    },
    N("Hungary") . "|T-Mobile" => {
        apn => "internet",
        dns => "212.51.115.1 ",
        dns => "194.176.224.6",
    },
    N("Hungary") . "|Pannon (tömörített)" => {
        apn => "snet",
        dns => "193.225.153.17",
        dns => "194.149.0.157",
    },
    N("Hungary") . "|T-Mobile (mms)" => {
        apn => "mms-westel",
        login => "mms",
        dns => "212.51.115.1",
        dns => "194.176.224.3",
    },
    N("Hungary") . "|Vodafone (előf. norm.)" => {
        apn => "standardnet.vodafone.net",
        login => "vodawap",
        password => "vodawap",
        dns => "80.244.97.30",
        dns => "80.244.96.1",
    },
    N("Hungary") . "|Vodafone (előf. töm.)" => {
        apn => "internet.vodafone.net",
        login => "vodawap",
        password => "vodawap",
        dns => "80.244.97.30",
        dns => "80.244.96.1",
    },
    N("Hungary") . "|Vodafone (felt. norm.)" => {
        apn => "vitamax.snet.vodafone.net",
        dns => "80.244.97.30",
        dns => "80.244.96.1",
    },
    N("Hungary") . "|Vodafone (felt. töm.)" => {
        apn => "vitamax.internet.vodafone.net",
        dns => "80.244.97.30",
        dns => "80.244.96.1",
    },
    N("Indonesia") . "|AXIS" => {
        apn => "AXIS",
        login => "axis",
        password => "123456",
    },
    N("Indonesia") . "|IM3" => {
        apn => "www.imdosat-m3.net",
        login => "gprs",
        password => "im3",
        dns => "202.155.46.66 ",
        dns => "202.155.46.77",
    },
    N("Indonesia") . "|Indosat" => {
        apn => "satelindogprs.com",
        dns => "202.152.162.250",
    },
    N("Indonesia") . "|Telkomsel" => {
        apn => "internet",
        login => "wap",
        password => "wap123",
        dns => "202.152.0.2",
        dns => "202.155.14.251",
    },
    N("Indonesia") . "|Excelcomindo (XL)" => {
        apn => "www.xlgprs.net",
        login => "xlgprs",
        password => "proxl",
        dns => "202.152.254.245",
        dns => "202.152.254.246",
    },
    N("Indonesia") . "|Indosat (Matrix)" => {
        apn => "satelindogprs.com indosatgprs",
        dns => "202.155.46.66",
        dns => "202.155.46.77",
    },
    N("Ireland") . "|o2 (contract)" => {
        apn => "open.internet",
        login => "gprs",
        password => "gprs",
        dns => "62.40.32.33",
        dns => "62.40.32.34",
    },
    N("Ireland") . "|o2 (pre-pay)" => {
        apn => "pp.internet",
        login => "faster",
        password => "web",
        dns => "62.40.32.33",
        dns => "62.40.32.34",
    },
    N("Ireland") . "|Vodafone (HSDPA/GPRS/EDGE/UMTS)" => {
        apn => "hs.vodafone.ie",
        login => "vodafone",
        password => "vodafone",
    },
    N("Ireland") . "|Vodafone (GPRS/EDGE/UMTS) (old)" => {
        apn => "isp.vodafone.ie",
        login => "vodafone",
        password => "vodafone",
    },
    N("Ireland") . "|Meteor" => {
        apn => "isp.mymeteor.ie",
        login => "my",
        password => "meteor",
    },
    N("Ireland") . "|Vodafone (pre-pay)" => {
        apn => "live.vodafone.com",
        login => "vodafone",
        password => "vodafone",
        dns => "10.24.59.100",
    },
    N("Ireland") . "|Three Ireland" => {
        apn => "3ireland.ie",
        dns => "172.31.140.69",
        dns => "172.30.140.69",
    },
    N("Israel") . "|CellCom" => {
        apn => "etecsa",
        login => "etecsa",
        dns => "192.168.91.10",
        dns => "192.168.91.4",
    },
    N("Israel") . "|Orange" => {
        apn => "orangeinternet",
        dns => "158.43.192.1",
        dns => "158.43.128.1",
    },
    N("Israel") . "|Vodafone (MTC)" => {
        apn => "apn01",
        dns => "10.10.10.30",
    },
    N("India") . "|Airtel" => {
        apn => "airtelgprs.com",
        dns => "202.56.230.5 ",
        dns => "202.56.240.5",
    },
    N("India") . "|BPL" => {
        apn => "bplgprs.com",
        login => "bplmobile",
        dns => "202.169.145.34",
        dns => "202.169.129.40",
    },
    N("India") . "|BSNL" => {
        apn => "celloneportal",
        dns => "192.168.051.163",
    },
    N("India") . "|BSNL Prepaid (West Bengal)" => {
        apn => "www.e.pr",
        dns => "218.248.240.208",
        dns => "218.248.240.135",
    },
    N("India") . "|Hutch (normal)" => {
        apn => "www",
        dns => "10.11.206.51",
        dns => "10.11.206.50",
    },
    N("India") . "|Hutch (Gujarat)" => {
        apn => "web",
        dns => "10.11.206.51",
        dns => "10.11.206.50",
    },
    N("India") . "|Idea Cellular" => {
        apn => "internet",
        dns => "10.4.42.15",
    },
    N("India") . "|MTNL Delhi" => {
        apn => "gprsmtnldel",
        login => "mtnl",
        password => "mtnl123",
    },
    N("India") . "|MTNL Mumbai (pre-paid)" => {
        apn => "gprsppsmum",
        login => "mtnl",
        password => "mtnl123",
    },
    N("India") . "|MTNL Mumbai (post-paid)" => {
        apn => "gprsmtnlmum",
        login => "mtnl",
        password => "mtnl123",
    },
    N("India") . "|MTNL Mumbai (Plan 2)" => {
        apn => "gprsmtnlmum",
        login => "mtnl",
        password => "mtnl123",
    },
    N("India") . "|Orange" => {
        apn => "portalnmms",
        dns => "10.11.206.51",
        dns => "10.11.206.50",
    },
    N("India") . "|Spice telecom" => {
        apn => "Simplyenjoy",
        login => "Mobile number",
        password => "spice",
    },
    N("India") . "|Spice telecom (kar)" => {
        apn => "simplydownload",
    },
    N("India") . "|Tata Indicom (Plug2Surf)" => {
        cdma => 1,
        login => "internet",
        password => "internet",
    },
    N("India") . "|Telekomsel" => {
        apn => "internet",
        login => "wap",
        password => "wap123",
    },
    N("India") . "|Vodafone" => {
        apn => "www",
        login => "guest",
        password => "guest",
    },
    N("Iceland") . "|Islandssimi" => {
        apn => "gprs.islandssimi.is",
        dns => "213.176.128.51",
        dns => "213.176.128.50",
    },
    N("Iceland") . "|Nova" => {
        apn => "internet.nova.is",
        dns => "192.168.190.54",
        dns => "192.168.190.55",
    },
    N("Italy") . "|Vodafone" => {
        apn => "web.omnitel.it",
    },
    N("Italy") . "|TIM" => {
        apn => "ibox.tim.it",
    },
    N("Italy") . "|TIM (WAP)" => {
        apn => "wap.tim.it",
        login => "WAPTIM",
        dns => "213.230.155.94 ",
        dns => "213.230.130.222",
    },
    N("Italy") . "|Wind" => {
        apn => "internet.wind",
    },
    N("Italy") . "|Wind (business)" => {
        apn => "internet.wind.biz",
    },
    N("Italy") . "|3 (ricaricabile)" => {
        apn => "tre.it",
    },
    N("Italy") . "|3 (abbonamento)" => {
        apn => "datacard.tre.it",
    },
    N("Italy") . "|Fastweb (SIM voce/dati)" => {
        apn => "apn.fastweb.it",
    },
    N("Italy") . "|Fastweb (SIM solo dati)" => {
        apn => "datacard.fastweb.it",
    },
    N("Jamaica") . "|Cable & Wireless" => {
        apn => "wap",
    },
    N("Jamaica") . "|Digicel" => {
        apn => "web.digiceljamaica.com",
        login => "wapuser",
        password => "wap03jam",
        dns => "208.131.176.126",
        dns => "200.10.152.232",
    },
    N("Japan") . "|Vodafone (J-Phone)" => {
        apn => "vodafone",
        login => "ai@vodafone",
        password => "vodafone",
        dns => "61.195.195.153",
        dns => "61.195.194.26",
    },
    N("Japan") . "|Softbank Mobile" => {
        cdma => 1,
        login => "ai@softbank",
        password => "softbank",
    },
    N("Japan") . "|e-mobile" => {
        cdma => 1,
        login => "em",
        password => "em",
    },
    N("Japan") . "|NTTdocomo" => {
        cdma => 1,
    },
    N("Japan") . "|au(KDDI)" => {
        cdma => 1,
        login => "au@au-win.ne.jp",
        password => "au",
        dns => "210.196.3.183",
        dns => "210.141.112.163",
    },
    N("Kenya") . "|Celtel" => {
        apn => "ke.celtel.com",
    },
    N("Kenya") . "|Safaricom" => {
        apn => "web.safaricom.com",
        login => "web",
        password => "web",
    },
    N("Kenya") . "|Econet" => {
        apn => "internet.econet.co.ke",
    },
    N("Kuwait") . "|Vodafone" => {
        apn => "apn01",
        dns => "10.10.10.30",
    },
    N("Kuwait") . "|Wataniya" => {
        apn => "action.wataniya.com",
    },
    N("Kazakhstan") . "|Beeline" => {
        apn => "internet.beeline.kz",
        login => "@internet.beeline",
        dns => "212.19.149.53 ",
        dns => "194.226.128.1",
    },
    N("Laos") . "|ETL" => {
        apn => "etlnet",
        dns => "192.168.4.130",
    },
    N("Lebanon") . "|Cellis FTML" => {
        apn => "internet.ftml.com.lb",
        login => "plugged",
        password => "plugged",
    },
    N("Lebanon") . "|MTC Touch" => {
        apn => "gprs.mtctouch.com.lb",
    },
    N("Lebanon") . "|LibanCell" => {
        apn => "isurf.libancell.com.lb",
    },
    N("Saint Lucia") . "|Cable & Wireless" => {
        apn => "internet",
        dns => "-",
    },
    N("Sri Lanka") . "|Airtel" => {
        apn => "www.wap.airtel.lk",
    },
    N("Sri Lanka") . "|Dialog GSM (Post-Paid)" => {
        apn => "www.dialogsl.com",
    },
    N("Sri Lanka") . "|Dialog GSM (Pre-Paid)" => {
        apn => "ppinternet",
    },
    N("Sri Lanka") . "|Hutch" => {
        apn => "htwap",
    },
    N("Sri Lanka") . "|Mobitel" => {
        apn => "isp",
    },
    N("Sri Lanka") . "|Tigo" => {
        apn => "wap",
    },
    N("Lithuania") . "|Bite" => {
        apn => "banga",
        login => "bite",
        dns => "213.226.131.131",
        dns => "193.219.88.36",
    },
    N("Lithuania") . "|TELE2 GPRS" => {
        apn => "internet.tele2.lt",
        gateway => "130.244.196.90",
    },
    N("Lithuania") . "|Omnitel (contract)" => {
        apn => "gprs.omnitel.net",
        dns => "194.176.32.129",
        dns => "195.22.175.1",
    },
    N("Lithuania") . "|Omnitel (no contract)" => {
        apn => "gprs.startas.lt",
        login => "omni",
        password => "omni",
        dns => "194.176.32.129",
        dns => "195.22.175.1",
    },
    N("Luxembourg") . "|LUXGSM" => {
        apn => "webp.pt.lu",
        dns => "194.154.192.101",
        dns => "194.154.192.102",
    },
    N("Luxembourg") . "|Tango" => {
        apn => "internet",
        login => "tango",
        password => "tango",
    },
    N("Luxembourg") . "|VOXmobile" => {
        apn => "vox.lu",
    },
    N("Latvia") . "|LMT" => {
        apn => "internet.lmt.lv",
        dns => "212.93.96.2",
        dns => "212.93.96.4",
    },
    N("Latvia") . "|Tele2" => {
        apn => "internet.tele2.lv",
        login => "gprs",
        password => "internet",
    },
    N("Morocco") . "|Maroc Telecom" => {
        apn => "iam",
        login => "wac",
        password => "1987",
    },
    N("Morocco") . "|Medi Telecom" => {
        apn => "wap.meditel.ma",
        login => "MEDIWAP",
        password => "MEDIWAP",
    },
    N("Moldova") . "|Moldcell" => {
        apn => "internet",
        login => "gprs",
        password => "gprs",
    },
    N("Moldova") . "|Eventis" => {
        apn => "internet.md",
    },
    N("Montenegro") . "|Mobtel Srbija" => {
        apn => "internet",
        login => "mobtel",
        password => "gprs",
        dns => "217.65.192.1",
        dns => "217.65.192.52",
    },
    N("Montenegro") . "|Promonte GSM" => {
        apn => "gprs.promonte.com",
    },
    N("Montenegro") . "|T-Mobile" => {
        apn => "internet-postpaid",
        login => "38167",
        password => "38167",
    },
    N("Montenegro") . "|Telekom Srbija (default)" => {
        apn => "gprsinternet",
        login => "mts",
        password => "64",
        dns => "195.178.38.3",
    },
    N("Montenegro") . "|Telekom Srbija (via MMS)" => {
        apn => "mms",
        login => "mts",
        password => "64",
        dns => "195.178.38.3",
    },
    N("Montenegro") . "|Telekom Srbija (via wap)" => {
        apn => "gprswap",
        login => "mts",
        password => "64",
        dns => "195.178.38.3",
    },
    N("Mongolia") . "|MobiCom" => {
        apn => "internet",
    },
    N("Macao") . "|Macau Hutchison Telecom" => {
        apn => "ctm-mobile",
    },
    N("Macao") . "|Macau Hutchison Telecom (MMS)" => {
        apn => "mms.hutchisonmacau.com",
        login => "hutchison",
        password => "1234",
    },
    N("Macao") . "|CTM" => {
        apn => "ctm-mobile",
    },
    N("Macao") . "|Macau Hutchison Telecom (Internet)" => {
        apn => "web.hutchisonmacau.com",
        login => "hutchison",
        password => "1234",
    },
    N("Malta") . "|Go Mobile (Post-paid)" => {
        apn => "gosurfing",
    },
    N("Malta") . "|Go Mobile (Pre-paid)" => {
        apn => "rtgsurfing",
    },
    N("Malta") . "|Vodafone" => {
        apn => "Internet",
        login => "Internet",
        password => "Internet",
    },
    N("Mauritius") . "|Emtel" => {
        apn => "WEB",
    },
    N("Maldives") . "|Dhiraagu" => {
        apn => "internet.dhimobile",
    },
    N("Mexico") . "|TELCEL" => {
        apn => "internet.itelcel.com",
        login => "webgprs",
        password => "webgprs2002",
        dns => "148.233.151.245",
        dns => "148.233.151.245",
    },
    N("Mexico") . "|Iusacell" => {
        cdma => 1,
    },
    N("Malaysia") . "|DIGI" => {
        apn => "diginet",
        dns => "203.92.128.131",
        dns => "203.92.128.132",
    },
    N("Malaysia") . "|Maxis (contract)" => {
        apn => "internet.gprs.maxis",
        dns => "202.75.129.101",
        dns => "10.216.4.21",
    },
    N("Malaysia") . "|Maxis (pre-pay)" => {
        apn => "net",
        login => "maxis",
        password => "net",
    },
    N("Malaysia") . "|Timecel" => {
        apn => "timenett.com.my",
        dns => "203.121.16.85",
        dns => "203.121.16.120",
    },
    N("Malaysia") . "|TM Touch" => {
        apn => "internet",
        dns => "202.188.0.133",
    },
    N("Malaysia") . "|Celcom" => {
        apn => "celcom.net.my",
    },
    N("Malaysia") . "|Maxis 3G (contract)" => {
        apn => "unet",
        login => "maxis",
        password => "wap",
        dns => "10.213.17.1",
        dns => "10.213.17.2",
    },
    N("Mozambique") . "|MCel" => {
        apn => "isp.mcel.mz",
        login => "guest",
        password => "guest",
        dns => "212.96.24.2",
        dns => "212.96.24.1",
    },
    N("Nigeria") . "|Zain" => {
        apn => "wap",
        login => "wap",
        password => "wap",
    },
    N("Nigeria") . "|MTN" => {
        apn => "web.gprs.mtnnigeria.net",
        login => "web",
        password => "web",
    },
    N("Nigeria") . "|Glo-Ng" => {
        apn => "glosecure",
        login => "gprs",
        password => "gprs",
        dns => "-",
    },
    N("Nicaragua") . "|Alo Pcs" => {
        apn => "internet.ideasalo.ni",
        login => "internet",
        password => "internet",
    },
    N("Nicaragua") . "|Movistar" => {
        apn => "internet.movistar.ni",
        login => "internet",
        password => "internet",
    },
    N("Netherlands") . "|Hi" => {
        apn => "portalmmm.nl",
    },
    N("Netherlands") . "|KPN Mobile" => {
        apn => "internet",
        login => "KPN",
        password => "gprs",
        dns => "62.133.126.28",
        dns => "62.133.126.29",
    },
    N("Netherlands") . "|o2" => {
        apn => "internet",
        dns => "195.99.65.220",
        dns => "195.99.66.220",
    },
    N("Netherlands") . "|T-Mobile" => {
        apn => "internet",
        dns => "193.78.240.12",
        dns => "193.79.242.39",
    },
    N("Netherlands") . "|Telfort" => {
        apn => "internet",
        login => "telfortnl",
    },
    N("Netherlands") . "|Vodafone" => {
        apn => "live.vodafone.com",
        login => "vodafone",
        password => "vodafone",
    },
    N("Netherlands") . "|Vodafone (business)" => {
        apn => "office.vodafone.nl",
        login => "vodafone",
        password => "vodafone",
    },
    N("Netherlands") . "|XS4ALL Mobiel Internet" => {
        apn => "umts.xs4all.nl",
    },
    N("Norway") . "|Netcom" => {
        apn => "internet.netcom.no",
        login => "netcom",
        password => "netcom",
        dns => "212.169.123.67 ",
        dns => "212.45.188.254",
    },
    N("Norway") . "|ice.net (Nordisk Mobiltelefon)" => {
        cdma => 1,
        login => "cdma",
        password => "cdma",
    },
    N("Norway") . "|Telenor" => {
        apn => "internet",
        dns => "212.17.131.3",
        dns => "148.122.161.2",
    },
    N("Norway") . "|TDC" => {
        apn => "internet.no",
        dns => "80.232.41.10",
        dns => "80.232.41.20",
    },
    N("Norway") . "|NetworkNorway" => {
        apn => "internet",
    },
    N("Norway") . "|OneCall" => {
        apn => "internet",
    },
    N("Norway") . "|Lebara" => {
        apn => "internet",
    },
    N("Norway") . "|Altibox" => {
        apn => "internet",
    },
    N("Norway") . "|SheTalks" => {
        apn => "internet",
    },
    N("Norway") . "|Telipol" => {
        apn => "internet",
    },
    N("Nepal") . "|Mero Mobile" => {
        apn => "mero",
    },
    N("New Zealand") . "|Vodafone" => {
        apn => " live.vodafone.com",
        dns => "202.20.93.10",
        dns => "203.97.191.189",
    },
    N("New Zealand") . "|Vodafone (restricted)" => {
        apn => "www.vodafone.net.nz",
        dns => "202.20.93.10",
        dns => "203.97.191.189",
    },
    N("New Zealand") . "|Vodafone (unrestricted)" => {
        apn => "internet",
        dns => "202.20.93.10",
        dns => "203.97.191.189",
    },
    N("Panama") . "|Cable and Wireless" => {
        apn => "apn01.cwpanama.com.pa",
        login => "xxx",
        password => "xxx",
    },
    N("Panama") . "|Movistar" => {
        apn => "internet.movistar.pa",
        login => "movistarpa",
        password => "movistarpa",
    },
    N("Oman") . "|Nawras" => {
        apn => "isp.nawras.com.om",
    },
    N("Peru") . "|Claro" => {
        apn => "tim.pe",
        login => "tim",
        password => "tulibertad",
    },
    N("Philippines") . "|Globe Telecom" => {
        apn => "internet.globe.com.ph",
        login => "globe",
        password => "globe",
        dns => "203.127.225.10",
        dns => "203.127.225.11",
    },
    N("Philippines") . "|Smart" => {
        apn => "internet",
        login => "witsductoor",
        password => "banonoy",
        dns => "202.57.96.3",
        dns => "202.57.96.4",
    },
    N("Philippines") . "|Sun Cellular" => {
        apn => "minternet",
    },
    N("Philippines") . "|Globe Telecoms (WAP)" => {
        apn => "www.globe.com.ph",
        login => "globe",
        password => "globe",
        dns => "203.127.225.10",
        dns => "203.127.225.11",
    },
    N("Pakistan") . "|Djuice" => {
        apn => "172.18.19.11",
        login => "telenor",
        password => "telenor",
    },
    N("Pakistan") . "|Mobilink GSM" => {
        apn => "connect.mobilinkworld.com",
    },
    N("Pakistan") . "|Mobilink GSM (jazz)" => {
        apn => "jazzconnect.mobilinkworld.com",
    },
    N("Pakistan") . "|Telenor" => {
        apn => "internet",
        login => "telenor",
        password => "telenor",
    },
    N("Pakistan") . "|Ufone" => {
        apn => "ufone.internet",
        login => "ufone",
        password => "ufone",
    },
    N("Pakistan") . "|ZONG" => {
        apn => "zonginternet",
    },
    N("Poland") . "|ERA" => {
        apn => "erainternet",
        login => "erainternet",
        password => "erainternet",
        dns => "213.158.194.1 ",
        dns => "213.158.193.38",
    },
    N("Poland") . "|Idea" => {
        apn => "www.idea.pl",
        login => "idea",
        password => "idea",
        dns => "194.9.223.79",
        dns => "217.17.34.10",
    },
    N("Poland") . "|Play Online" => {
        apn => "Internet",
    },
    N("Poland") . "|Polkomtel" => {
        apn => "www.plusgsm.pl",
        dns => "212.2.96.51 ",
        dns => "212.2.96.52",
    },
    N("Poland") . "|Heyah" => {
        apn => "heyah.pl",
        login => "heyah",
        password => "heyah",
        dns => "213.158.194.1",
        dns => "213.158.193.38",
    },
    N("Poland") . "|Orange" => {
        apn => "internet",
        login => "internet",
        password => "internet",
        dns => "194.9.223.79",
        dns => "194.204.159.1",
    },
    N("Poland") . "|iPlus" => {
        apn => "www.plusgsm.pl",
        dns => "212.2.96.51",
        dns => "212.2.96.52",
    },
    N("Portugal") . "|Kanguru" => {
        apn => "myconnection",
        dns => "62.169.67.172",
        dns => "62.169.67.171",
    },
    N("Portugal") . "|Kanguru (fixo)" => {
        apn => "kangurufixo",
        dns => "62.169.67.172",
        dns => "62.169.67.171",
    },
    N("Portugal") . "|Optimus" => {
        apn => "internet",
        dns => "194.79.69.129",
    },
    N("Portugal") . "|TMN" => {
        apn => "internet",
        dns => "194.65.3.20",
        dns => "194.65.3.21",
    },
    N("Portugal") . "|Vodafone" => {
        apn => "internet.vodafone.pt",
        dns => "212.18.160.133",
        dns => "212.18.160.134",
    },
    N("Paraguay") . "|CTI" => {
        apn => "internet.ctimovil.com.py",
        login => "ctigprs",
        password => "ctigprs999",
    },
    N("Romania") . "|Orange" => {
        apn => "internet",
        dns => "172.22.7.21 ",
        dns => "172.22.7.20",
    },
    N("Romania") . "|Vodafone" => {
        apn => "internet.vodafone.ro",
        login => "internet.vodafone.ro",
        password => "vodafone",
        dns => "193.230.161.3",
        dns => "193.230.161.4",
    },
    N("Romania") . "|Zapp" => {
        cdma => 1,
        login => "zapp",
        password => "zapp",
    },
    N("Serbia") . "|Mobtel Srbija" => {
        apn => "internet",
        login => "mobtel",
        password => "gprs",
        dns => "217.65.192.1",
        dns => "217.65.192.52",
    },
    N("Serbia") . "|Telekom Srbija (default)" => {
        apn => "gprsinternet",
        login => "mts",
        password => "64",
        dns => "195.178.38.3",
    },
    N("Serbia") . "|Telekom Srbija (via MMS)" => {
        apn => "mms",
        login => "mts",
        password => "64",
        dns => "195.178.38.3",
    },
    N("Serbia") . "|Telekom Srbija (via wap)" => {
        apn => "gprswap",
        login => "mts",
        password => "64",
        dns => "195.178.38.3",
    },
    N("Russian Federation") . "|BaikalWestCom" => {
        apn => "inet.bwc.ru",
        login => "bwc",
        password => "bwc",
        dns => "81.18.113.2",
        dns => "81.18.112.50",
    },
    N("Russian Federation") . "|Beeline" => {
        apn => "internet.beeline.ru",
        login => "beeline",
        password => "beeline",
        dns => "217.118.66.243",
        dns => "217.118.66.244",
    },
    N("Russian Federation") . "|Megafon (nw)" => {
        apn => "internet.nw",
        dns => "10.140.142.42 ",
        dns => "10.140.142.45",
    },
    N("Russian Federation") . "|МТС" => {
        apn => "internet.mts.ru",
        login => "mts",
        password => "mts",
        dns => "213.87.0.1",
        dns => "213.87.1.1",
    },
    N("Russian Federation") . "|PrimTelephone" => {
        apn => "internet.primtel.ru",
    },
    N("Russian Federation") . "|Megafon (ugsm)" => {
        apn => "internet.ugsm",
        dns => "83.149.32.2 ",
        dns => "83.149.33.2",
    },
    N("Russian Federation") . "|Megafon (usi)" => {
        apn => "internet.usi.ru",
        dns => "212.120.160.130 ",
        dns => "212.120.160.130",
    },
    N("Russian Federation") . "|Megafon (dv)" => {
        apn => "internet.dv",
        dns => "83.149.52.77",
        dns => "194.186.112.18",
    },
    N("Russian Federation") . "|Megafon (kvk)" => {
        apn => "internet.kvk",
        dns => "83.149.24.244 ",
        dns => "62.183.50.230",
    },
    N("Russian Federation") . "|Megafon (ltmsk)" => {
        apn => "internet.ltmsk",
        dns => "10.22.10.20 ",
        dns => "10.22.10.21",
    },
    N("Russian Federation") . "|Megafon (sib)" => {
        apn => "internet.sib",
        dns => "83.149.51.65 ",
        dns => "83.149.50.65",
    },
    N("Russian Federation") . "|Megafon (volga)" => {
        apn => "internet.volga",
        dns => "83.149.16.7 ",
        dns => "195.128.128.1",
    },
    N("Russian Federation") . "|Megafon (mc)" => {
        apn => "internet.mc",
        dns => "81.18.129.252 ",
        dns => "217.150.34.1",
    },
    N("Russian Federation") . "|NCC" => {
        apn => "internet",
        login => "ncc",
        dns => "10.0.3.5 ",
        dns => "10.0.3.2",
    },
    N("Russian Federation") . "|NTC" => {
        apn => "internet.ntc",
        dns => "80.243.64.67 ",
        dns => "80.243.68.34",
    },
    N("Russian Federation") . "|Megafon (Moscow)" => {
        apn => "internet",
        login => "gdata",
        password => "gdata",
    },
    N("Russian Federation") . "|Enisey TeleCom" => {
        apn => "internet.etk.ru",
        login => "etk",
        dns => "10.10.30.3",
        dns => "10.10.30.4",
    },
    N("Russian Federation") . "|Motiv" => {
        apn => "inet.ycc.ru",
        login => "motiv",
        dns => "217.148.52.34",
        dns => "217.148.52.3",
    },
    N("Russian Federation") . "|Tatincom" => {
        apn => "internet.tatincom.ru",
        login => "tatincom",
        password => "tatincom",
        dns => "89.207.96.2",
        dns => "89.207.97.18",
    },
    N("Russian Federation") . "|Tele2" => {
        apn => "wap.tele2.ru",
        login => "gprs",
        dns => "130.244.127.161",
        dns => "130.244.127.169",
    },
    N("Russian Federation") . "|Skylink (Moscow)" => {
        cdma => 1,
        login => "mobile@skylink.msk.ru",
        password => "internet",
    },
    N("Saudi Arabia") . "|Mobily" => {
        apn => "web2",
    },
    N("Saudi Arabia") . "|STC" => {
        apn => "jawalnet.com.sa",
        dns => "212.118.133.101",
        dns => "212.118.133.102",
    },
    N("Sweden") . "|3 (Mobiltelefon)" => {
        apn => "data.tre.se",
    },
    N("Sweden") . "|3 (Bredband)" => {
        apn => "bredband.tre.se",
    },
    N("Sweden") . "|3 (Bredband Kontantkort)" => {
        apn => "net.tre.se",
    },
    N("Sweden") . "|Glocalnet" => {
        apn => "internet.glocalnet.se",
    },
    N("Sweden") . "|Halebop" => {
        apn => "halebop.telia.se",
    },
    N("Sweden") . "|ice.net (Nordisk Mobiltelefon)" => {
        cdma => 1,
        login => "cdma",
        password => "cdma",
    },
    N("Sweden") . "|Tele2/Comviq" => {
        apn => "internet.tele2.se",
    },
    N("Sweden") . "|Telenor" => {
        apn => "internet.telenor.se",
    },
    N("Sweden") . "|Telia" => {
        apn => "online.telia.se",
    },
    N("Singapore") . "|M1" => {
        apn => "sunsurf",
        login => "65",
        password => "user123",
        dns => "202.79.64.21",
        dns => "202.79.64.26",
    },
    N("Singapore") . "|SingTel" => {
        apn => "internet",
        dns => "165.21.100.88",
        dns => "165.21.83.88",
    },
    N("Singapore") . "|Starhub" => {
        apn => "shwap",
        login => "star",
        password => "hub",
        dns => "203.116.1.78",
    },
    N("Slovenia") . "|Mobitel (postpaid)" => {
        apn => "internet",
        login => "mobitel",
        password => "internet",
        dns => "213.229.248.161 ",
        dns => "193.189.160.11",
    },
    N("Slovenia") . "|Mobitel (prepaid)" => {
        apn => "internetpro",
        login => "mobitel",
        password => "internet",
        dns => "213.229.248.161 ",
        dns => "193.189.160.11",
    },
    N("Slovenia") . "|Simobil" => {
        apn => "none",
        dns => "121.30.86.130",
        dns => "193.189.160.11",
    },
    N("Slovakia") . "|T-Mobile (EuroTel)" => {
        apn => "internet",
        dns => "194.154.230.66 ",
        dns => "194.154.230.74",
    },
    N("Slovakia") . "|Globtel" => {
        apn => "internet",
        dns => "213.151.200.3",
        dns => "195.12.140.130",
    },
    N("Slovakia") . "|Orange" => {
        apn => "internet",
        login => "jusernejm",
        password => "pasvord",
        dns => "213.151.200.30 ",
        dns => "213.151.208.161",
    },
    N("Slovakia") . "|Eurotel" => {
        apn => "internet",
        dns => "194.154.230.64",
        dns => "194.154.230.74",
    },
    N("Senegal") . "|Tigo" => {
        apn => "internet.tigo.hn",
        dns => "200.85.0.104",
        dns => "200.85.0.107",
    },
    N("El Salvador") . "|movistar" => {
        apn => "movistar.sv",
        login => "movistarsv",
        password => "movistarsv",
    },
    N("Thailand") . "|AIS" => {
        apn => "internet",
        dns => "202.183.255.20",
        dns => "202.183.255.21",
    },
    N("Thailand") . "|DTAC" => {
        apn => "www.dtac.co.th",
        dns => "202.44.202.2",
        dns => "203.44.144.33",
    },
    N("Thailand") . "|True" => {
        apn => "internet",
        login => "true",
        password => "true",
    },
    N("Turkey") . "|Aria" => {
        apn => "internet",
        dns => "212.156.4.4",
        dns => "212.156.4.20",
    },
    N("Turkey") . "|Aycell" => {
        apn => "aycell",
        dns => "212.156.4.1",
        dns => "212.156.4.4",
    },
    N("Turkey") . "|Turkcell" => {
        apn => "internet",
        login => "gprs",
        password => "gprs",
        dns => "86.108.136.27",
        dns => "86.108.136.26",
    },
    N("Turkey") . "|Telsim (Post-paid)" => {
        apn => "telsim",
        login => "telsim",
        password => "telsim",
        dns => "212.65.128.20",
        dns => "212.156.4.7",
    },
    N("Turkey") . "|Telsim (pre-paid)" => {
        apn => "prepaidgprs",
        dns => "212.65.128.20",
        dns => "212.156.4.7",
    },
    N("Trinidad and Tobago") . "|Digicel" => {
        apn => "wap.digiceltt.com",
        login => "wap",
        password => "wap",
    },
    N("Trinidad and Tobago") . "|TSTT" => {
        apn => "internet",
        login => "wap",
        password => "wap",
    },
    N("Taiwan") . "|Chunghwa Telecom (emome)" => {
        apn => "internet",
    },
    N("Taiwan") . "|Far EasTone / KGT" => {
        apn => "internet",
    },
    N("Taiwan") . "|TW Mobile / TransAsia" => {
        apn => "internet",
    },
    N("Taiwan") . "|Vibo Telecom / Aurora" => {
        apn => "vibo",
    },
    N("Taiwan") . "|Asia Pacific Telecom (APBW)" => {
        cdma => 1,
    },
    N("Ukraine") . "|Jeans" => {
        apn => "www.jeans.ua",
        dns => "80.255.64.23",
        dns => "80.255.64.24",
    },
    N("Ukraine") . "|Djuice" => {
        apn => "www.djuice.com.ua",
        dns => "212.58.160.33",
        dns => "212.58.160.34",
    },
    N("Ukraine") . "|Mobi-GSM" => {
        apn => "internet.urs",
        dns => "213.186.192.254",
        dns => "193.239.128.5",
    },
    N("Ukraine") . "|Ace&Base" => {
        apn => "www.ab.kyivstar.net",
        login => "igprs",
        password => "internet",
    },
    N("Ukraine") . "|Life (standard)" => {
        apn => "internet",
        dns => "212.58.160.33",
        dns => "212.58.160.34",
    },
    N("Ukraine") . "|Beeline" => {
        apn => "internet.beeline.ua",
    },
    N("Ukraine") . "|Life (faster)" => {
        apn => "speed",
        dns => "212.58.160.33",
        dns => "212.58.160.34",
    },
    N("Ukraine") . "|Wellcome" => {
        apn => "internet.urs",
        dns => "213.186.192.254",
        dns => "193.239.128.5",
    },
    N("Ukraine") . "|Jeans (Hyper)" => {
        apn => "hyper.net",
        dns => "212.58.160.33",
        dns => "212.58.160.34",
    },
    N("Ukraine") . "|UMC (internet)" => {
        apn => "internet",
        login => "internet",
        dns => "212.58.160.33",
        dns => "212.58.160.34",
    },
    N("Ukraine") . "|UMC (umc.ua)" => {
        apn => "www.umc.ua",
        dns => "80.255.64.23",
        dns => "80.255.64.24",
    },
    N("Ukraine") . "|Utel" => {
        apn => "3g.utel.ua",
    },
    N("Uganda") . "|MTN" => {
        apn => "yellopix.mtn.co.ug",
        dns => "212.88.97.20",
        dns => "212.88.97.67",
    },
    N("United States") . "|AT&T" => {
        apn => "WAP.CINGULAR",
        login => "WAP@CINGULARGPRS.COM",
        password => "CINGULAR1",
    },
    N("United States") . "|AT&T (Tethering)" => {
        apn => "ISP.CINGULAR",
        login => "ISP@CINGULARGPRS.COM",
        password => "CINGULAR1",
    },
    N("United States") . "|AT&T (Tethering with data acceleration)" => {
        apn => "ISP.CINGULAR",
        login => "ISPDA@CINGULARGPRS.COM",
        password => "CINGULAR1",
    },
    N("United States") . "|T-Mobile (Web)" => {
        apn => "wap.voicestream.com",
    },
    N("United States") . "|T-Mobile (Internet)" => {
        apn => "internet2.voicestream.com",
    },
    N("United States") . "|T-Mobile (Internet with VPN)" => {
        apn => "internet3.voicestream.com",
    },
    N("United States") . "|Sprint" => {
        cdma => 1,
    },
    N("United States") . "|Boost Mobile (Prepaid)" => {
        cdma => 1,
    },
    N("United States") . "|Verizon" => {
        cdma => 1,
    },
    N("United States") . "|US Cellular" => {
        cdma => 1,
    },
    N("United States") . "|Alltel" => {
        cdma => 1,
    },
    N("United States") . "|Leap Wireless" => {
        cdma => 1,
    },
    N("United States") . "|Cricket Communications" => {
        cdma => 1,
    },
    N("United States") . "|Jump Mobile (Prepaid)" => {
        cdma => 1,
    },
    N("United States") . "|MetroPCS" => {
        cdma => 1,
    },
    N("Uruguay") . "|Ancel" => {
        apn => "gprs.ancel",
        dns => "200.40.30.245 ",
        dns => "200.40.220.245",
    },
    N("Uruguay") . "|CTI" => {
        apn => "internet.ctimovil.com.uy",
        login => "ctiweb",
        password => "ctiweb999",
    },
    N("Uruguay") . "|Movistar" => {
        apn => "webapn.movistar.com.uy",
        login => "movistar",
        password => "movistar",
    },
    N("Uzbekistan") . "|Uzdunrobita" => {
        apn => "net.urd.uz",
        login => "user",
        password => "pass",
    },
    N("Saint Vincent and the Grenadines") . "|Digicel" => {
        apn => "wap.digiceloecs.com",
        login => "wapoecs",
        password => "wap03oecs",
    },
    N("Venezuela") . "|Digitel TIM" => {
        apn => "gprsweb.digitel.ve",
        dns => "57.67.127.195",
    },
    N("South Africa") . "|Cell-c" => {
        apn => "internet",
        login => "Cellcis",
        password => "Crap",
        dns => "196.7.0.138",
        dns => "196.7.142.132",
    },
    N("South Africa") . "|MTN" => {
        apn => "internet",
        dns => "196.11.240.241",
        dns => "209.212.97.1",
    },
    N("South Africa") . "|Vodacom" => {
        apn => "internet",
        dns => "196.207.40.165",
        dns => "196.43.46.190",
    },
    N("South Africa") . "|Virgin Mobile" => {
        apn => "vdata",
        dns => "196.7.0.138",
        dns => "196.7.142.132",
    },
    N("South Africa") . "|Vodacom (unrestricted APN)" => {
        apn => "unrestricted",
        dns => "196.207.32.69",
        dns => "196.43.45.190",
    },
);

1;
