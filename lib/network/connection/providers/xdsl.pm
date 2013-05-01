# -*- coding: utf-8 -*-
package network::connection::providers::xdsl; # $Id: xdsl.pm 59309 2006-09-01 12:08:15Z tv $

# This should probably be splitted out into ldetect-lst as some provider db

use lib qw(/usr/lib/libDrakX);   # helps perl_checker
use common;
use utf8;

# Originally from :
# http://www.eagle-usb.org/article.php3?id_article=23
# http://www.sagem.com/web-modems/download/support-fast1000-fr.htm
# http://perso.wanadoo.fr/michel-m/protocolesfai.htm
# Then other ISP found in :
# http://www.adslayuda.com/Comtrend500+file-16.html

# the output is provided in html at http://faq.eagle-usb.org/wakka.php?wiki=ListConfigADSL
# this file should be put in /usr/share/eagle-usb/ for eagle-usb driver
# or in /usr/lib/libDrakX/network/ as part of the drakxtools

our %data = (
                  ## format chosen is the following :
                  # country|provider => { VPI, VCI_hexa, ... } all parameters
                  # country is automagically translated into LANG with N function
                  # provider is kept "as-is", not translated
                  # provider_id is used by eagleconfig to identify an ISP (I use ISO_3166-1)
                  #      see http://en.wikipedia.org/wiki/ISO_3166-1
                  # url_tech : technical URL providing info about ISP
                  # vpi : virtual path identifier
                  # vci : virtual channel identifier (in hexa below !!)
                  # Encapsulation:
                  #     1=PPPoE LLC, 2=PPPoE VCmux (never used ?)
                  #     3=RFC1483/2684 Routed IP LLC,
                  #     4=RFC1483/2684 Routed IP (IPoA VCmux)
                  #     5 RFC2364 PPPoA LLC,
                  #     6 RFC2364 PPPoA VCmux
                  #      see http://faq.eagle-usb.org/wakka.php?wiki=AdslDescription
                  # dns are provided for when !usepeerdns in peers config file
                  #     dnsServers : array ref with any valid DNS (order matters)
                  # DOMAINNAME2 : used for search key in /etc/resolv.conf
                  # method : PPPoA, pppoe, static or dhcp
                  # login_format : e.g. fti/login for France Telecom
                  # encryption : for pppd connection, when encryption is supported
                  # modem : model of modem provided by ISP or tested with ISP
                  # please forward updates to http://forum.eagle-usb.org
                  # try to order alphabetically by country (in English) / ISP (local language)

                  N("Algeria") . "|Wanadoo" =>
                  {
                   provider_id => 'DZ01',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoe',
                   dnsServers => [ qw(82.101.136.29 82.101.136.206) ],
                  },

                  N("Algeria") . "|Algerie Telecom (FAWRI)" =>
                  {
		   provider_id => 'DZ02',
                   vpi => 0,
                   vci => 26,
                   Encapsulation => 1,
                   method => 'pppoe',
                   dnsServers => [ qw(61.88.88.88 205.252.144.228) ],
                  },

                  N("Argentina") . "|Speedy" =>
                  {
                   provider_id => 'AR01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoe',
                   dnsServers => [ qw(200.51.254.238 200.51.209.22) ],
                  },

                  N("Argentina") . "|Arnet" =>
                  {
		   provider_id => 'AR02',
                   vpi => 8,
                   vci => 21,
                   Encapsulation => 1,
                   method => 'pppoe',
                   dnsServers => [ qw(200.45.191.35 200.45.191.40) ],
                  },

                  N("Austria") . "|" . N("Any") =>
                  {
                   provider_id => 'AT00',
                   vpi => 8,
                   vci => 30,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Austria") . "|AON" =>
                  {
                   provider_id => 'AT01',
                   vpi => 1,
                   vci => 20,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Austria") . "|Telstra" =>
                  {
                   provider_id => 'AT02',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Australia") . "|Arachnet" =>
                  {
		   provider_id => 'AU01',
		   url_tech => "http://www.ains.com.au/consumer/support/technical.htm",
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
		   method => 'pppoa',
                  },

                  N("Australia") . "|Speedstream On net" =>
                  {
		   provider_id => 'AU02',
		   url_tech => "http://www.ains.com.au/consumer/support/technical.htm",
                   vpi => 8,
                   vci => 22,
                   Encapsulation => 6,
		   method => 'pppoa',
                  },

                  N("Australia") . "|Speedstream Off net" =>
                  {
		   provider_id => 'AU03',
		   url_tech => "http://www.ains.com.au/consumer/support/technical.htm",
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 1,
		   method => 'pppoe',
                  },

                  N("Belgium") . "|ADSL Office" =>
                  {
                   provider_id => 'BE04',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("Belgium") . "|Tiscali BE" =>
                  {
                   provider_id => 'BE01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   method => 'pppoa',
                   dnsServers => [ qw(212.35.2.1 212.35.2.2 212.233.1.34 212.233.2.34) ],
                   DOMAINNAME2 => 'tiscali.be',
                  },

                  N("Belgium") . "|Belgacom" =>
                  {
                   provider_id => 'BE03',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Belgium") . "|Turboline" =>
                  {
                   provider_id => 'BE02',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 5,
                   method => 'pppoa',
                  },

                  N("Belgium") . "|Scarlet ADSL" =>
                  {
		   provider_id => 'BE05',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Brazil") . "|Speedy/Telefonica" =>
                  {
                   provider_id => 'BR01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoe',
                   dnsServers => [ qw(200.204.0.10 200.204.0.138) ],
                  },

                  N("Brazil") . "|Velox/Telemar" =>
                  {
                   provider_id => 'BR02',
                   vpi => 0,
                   vci => 21,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Brazil") . "|Turbo/Brasil Telecom" =>
                  {
                   provider_id => 'BR03',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Brazil") . "|Rio Grande do Sul (RS)" =>
                  {
                   provider_id => 'BR04',
                   vpi => 1,
                   vci => 20,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Bulgaria") . "|BTK ISDN" =>
                  {
                   provider_id => 'BG02',
                   vpi => 1,
                   vci => 20,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Bulgaria") . "|BTK POTS" =>
                  {
                   provider_id => 'BG01',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("China") . "|China Netcom|Beijing" =>
                  {
                   provider_id => 'CN01',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Netcom|Changchun" =>
                  {
                   provider_id => 'CN02',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Netcom|Harbin" =>
                  {
                   provider_id => 'CN03',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Netcom|Jilin" =>
                  {
                   provider_id => 'CN04',
                   vpi => 0,
                   vci => 27,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Netcom|Lanzhou" =>
                  {
                   provider_id => 'CN05',
                   vpi => 0,
                   vci => 20,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Netcom|Tianjin" =>
                  {
                   provider_id => 'CN06',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Netcom|Xi'an" =>
                  {
                   provider_id => 'CN07',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Chongqing" =>
                  {
                   provider_id => 'CN08',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Fujian" =>
                  {
                   provider_id => 'CN09',
                   vpi => 0,
                   vci => 0xc8,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Guangxi" =>
                  {
                   provider_id => 'CN10',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Guangzhou" =>
                  {
                   provider_id => 'CN11',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Hangzhou" =>
                  {
                   provider_id => 'CN12',
                   vpi => 0,
                   vci => 20,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Netcom|Hunan" =>
                  {
                   provider_id => 'CN13',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Nanjing" =>
                  {
                   provider_id => 'CN14',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Shanghai" =>
                  {
                   provider_id => 'CN15',
                   vpi => 8,
                   vci => 51,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Shenzhen" =>
                  {
                   provider_id => 'CN16',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Urumqi" =>
                  {
                   provider_id => 'CN17',
                   vpi => 0,
                   vci => 20,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Wuhan" =>
                  {
                   provider_id => 'CN18',
                   vpi => 0,
                   vci => 20,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Yunnan" =>
                  {
                   provider_id => 'CN19',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("China") . "|China Telecom|Zhuhai" =>
                  {
                   provider_id => 'CN20',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("Czech Republic") . "|Cesky Telecom PPPoA" =>
                  {
                   provider_id => 'CZ01',
                   url_tech => 'http://www.telecom.cz/domacnosti/internet/pristupove_sluzby/broadband/vse_o_kz_a_moznostech_instalace.php',
                   vpi => 8,
                   vci => 30,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Czech Republic") . "|Cesky Telecom PPPoE" =>
                  {
		   provider_id => 'CZ02',
		   url_tech => 'http://www.telecom.cz/zakaznicka_podpora/dokumenty_ke_stazeni/internet_expres.php', 
                   vpi => 8,
                   vci => 30,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Denmark") . "|" . N("Any") =>
                  {
                   provider_id => 'DK01',
                   vpi => 0,
                   vci => 65,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("Denmark") . "|Cybercity" =>
                  {
		   provider_id => 'DK02',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 6,
		   method => 'pppoa',
                  },

                  N("Denmark") . "|Tiscali" =>
                  {
		   provider_id => 'DK03',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 6,
		   method => 'pppoa',
                  },

                  N("Egypt") . "|Raya Telecom" =>
                  {
		   provider_id => 'EG01',
                   vpi => 8,
                   vci => 50,
		   method => 'pppoa',
                   Encapsulation => 6,
                   dnsServers => [ qw(62.240.110.197 62.240.110.198) ],
                  },

                  N("Finland") . "|Sonera" =>
                  {
                   provider_id => 'FI01',
                   vpi => 0,
                   vci => 64,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("France") . "|French Data Network" =>
                  {
                   #provider_id => 'FR??',
                   vpi => 8,
                   vci => 35,
                   Encapsulation => 1,
                   CMVep => 'FR',
                   dnsServers => [ qw(80.67.169.12 80.67.169.40) ],
                   method => 'dhcp',
                   DOMAINNAME2 => 'fdn.fr',
                  },

                  N("France") . "|Free non dégroupé 512/128 & 1024/128" =>
                  {
                   provider_id => 'FR01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'FR',
                   dnsServers => [ qw(213.228.0.23 212.27.32.176) ],
                   method => 'pppoa',
                   DOMAINNAME2 => 'free.fr',
                  },

                  N("France") . "|Free non dégroupé ADSL Max" =>
                  { 
		   provider_id => 'FR11',
                   vpi => 8, 
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'FR04',
                   dnsServers => [ qw(213.228.0.23 212.27.32.176) ],
                   method => 'pppoa',
                   DOMAINNAME2 => 'free.fr',
                  },

                  N("France") . "|Free dégroupé 1024/256 (mini)" =>
                  {
                   provider_id => 'FR04',
                   vpi => 8,
                   vci => 24,
                   Encapsulation => 4,
                   CMVep => 'FR04',
                   dnsServers => [ qw(213.228.0.23 212.27.32.176 213.228.0.68 212.27.32.176 212.27.32.177 212.27.39.2 212.27.39.1) ],
                   method => 'dhcp',
                   DOMAINNAME2 => 'free.fr',
                  },

                  N("France") . "|n9uf tel9com 512 & dégroupé 1024" =>
                  {
                   provider_id => 'FR05',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'FR',
                   dnsServers => [ qw(212.30.93.108 212.203.124.146 62.62.156.12 62.62.156.13) ],
                   method => 'pppoa',
                  },

                  N("France") . "|Cegetel non dégroupé 512 IP/ADSL et dégroupé" =>
                  {
                   provider_id => 'FR08',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'FR',
                   dnsServers => [ qw(212.94.174.85 212.94.174.86) ],
                   method => 'pppoa',
                   login_format => 'login@cegetel.net',
                  },

                  N("France") . "|Cegetel ADSL Max 8 Mb" =>
                  {
		   provider_id => 'FR10',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'FR10',
                   dnsServers => [ qw(212.94.174.85 212.94.174.86) ],
                   method => 'pppoa',
                   login_format => 'login@cegetel.net',
                  },

                  N("France") . "|Club-Internet" =>
                  {
                   provider_id => 'FR06',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'FR',
                   dnsServers => [ qw(194.117.200.10 194.117.200.15) ],
                   method => 'pppoa',
                   DOMAINNAME2 => 'club-internet.fr',
                  },

                  N("France") . "|Orange" =>
                  {
                   provider_id => 'FR09',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'FR',
                   dnsServers => [ qw(80.10.246.2 80.10.246.129) ],
                   method => 'pppoa',
                   login_format => 'fti/login',
                   DOMAINNAME2 => 'orange.fr',
                  },

                  N("France") . "|Télé2" =>
                  {
                   provider_id => 'FR02',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'FR',
                   dnsServers => [ qw(212.151.136.242 130.244.127.162 212.151.136.246) ],
                   method => 'pppoa',
                  },

                  N("France") . "|Tiscali.fr 128k" =>
                  {
                   provider_id => 'FR03',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 5,
                   CMVep => 'FR',
                   dnsServers => [ qw(213.36.80.1 213.36.80.2) ],
                   method => 'pppoa',
                  },

                  N("France") . "|Tiscali.fr 512k" =>
                  {
                   provider_id => 'FR07',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'FR',
                   dnsServers => [ qw(213.36.80.1 213.36.80.2) ],
                   method => 'pppoa',
                  },

                  N("Germany") . "|Deutsche Telekom (DT)" =>
                  {
                   provider_id => 'DE01',
                   vpi => 1,
                   vci => 20,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Germany") . "|1&1" =>
                  {
                   provider_id => 'DE02',
                   vpi => 1,
                   vci => 20,
                   Encapsulation => 1,
                   dnsServers => [ qw(195.20.224.234 194.25.2.129) ],
                   method => 'pppoe',
                  },

                  N("Germany") . "|Alice DSL" =>
                  {
                   provider_id => 'DE03',
                   vpi => 1,
                   vci => 20,
                   Encapsulation => 1,
                   dnsServers => [ qw(213.191.73.65 213.191.74.20) ],
                   method => 'pppoe',
                  },

                  N("Greece") . "|" . N("Any") =>
                  {
                   provider_id => 'GR01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Hungary") . "|Matav" =>
                  {
                   provider_id => 'HU01',
                   vpi => 1,
                   vci => 20,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Ireland") . "|" . N("Any") =>
                  {
                   provider_id => 'IE01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Israel") . "|Barak 013" =>
                  {
                   provider_id => 'IL03',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(212.150.49.10 206.49.94.234 212.150.48.169) ],
                   method => 'pppoa'
                  },

                  N("Israel") . "|Bezeq 014" =>
                  {
                   provider_id => 'IL04',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(192.115.106.10 192.115.106.11 192.115.106.35) ],
                   method => 'pppoa'
                  },

                  N("Israel") . "|Bezeq" =>
                  {
                   provider_id => 'IL01',
                   vpi => 8,
                   vci => 30,
                   Encapsulation => 6,
                   dnsServers => [ qw(192.115.106.10 192.115.106.11 192.115.106.35) ],
                   method => 'pppoa',
                  },

                  N("Israel") . "|BGU" =>
                  {
                   provider_id => 'IL06',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(132.72.140.46 132.72.140.45) ],
                   method => 'pppoa'
                  },

                  N("Israel") . "|HaifaU" =>
                  {
                   provider_id => 'IL07',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(132.74.1.3 132.74.1.5) ],
                   method => 'pppoa'
                  },

                  N("Israel") . "|HUJI" =>
                  {
                   provider_id => 'IL08',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(128.139.6.1 128.139.4.3) ],
                   method => 'pppoa'
                  },

                  N("Israel") . "|Kavey Zahave 012" =>
                  {
                   provider_id => 'IL02',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(212.117.129.3 212.117.128.6) ],
                   method => 'pppoa'
                  },

                  N("Israel") . "|Netvision 017" =>
                  {
                   provider_id => 'IL01',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(212.143.212.143 194.90.1.5) ],
                   method => 'pppoa'
                  },

                  N("Israel") . "|Smile 015" =>
                  {
                   provider_id => 'IL05',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(192.116.202.222 213.8.172.83) ],
                   method => 'pppoa'
                  },

                  N("Israel") . "|TAU" =>
                  {
                   provider_id => 'IL09',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(132.66.32.10 132.66.16.2) ],
                   method => 'pppoa'
                  },

                  N("Israel") . "|Technion" =>
                  {
                   provider_id => 'IL10',
                   vpi => 8,
                   vci => 48,
                   Encapsulation => 6,
                   dnsServers => [ qw(132.68.1.2 132.68.1.9) ],
                   method => 'pppoa'
                  },

                  N("India") . "|" . N("Any") =>
                  {
		   provider_id => 'IN01',
                   vpi => 0,
                   vci => 20,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Iceland") . "|Islandssimi" =>
                  {
		   provider_id => 'IS01',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Iceland") . "|Landssimi" =>
                  {
		   provider_id => 'IS02',
                   vpi => 8,
                   vci => 30,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Italy") . "|Telecom Italia" =>
                  {
                   provider_id => 'IT01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'IT',
                   dnsServers => [ qw(195.20.224.234 194.25.2.129) ],
                   method => 'pppoa',
                  },

                  N("Italy") . "|Telecom Italia/Office Users (ADSL Smart X)" =>
                  {
                   provider_id => 'IT02',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 3,
                   CMVep => 'IT',
                   method => 'static',
                  },

                  N("Italy") . "|Tiscali.it, Alice" =>
                  {
                   provider_id => 'IT03',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'IT',
                   dnsServers => [ qw(195.20.224.234 194.25.2.129) ],
                   method => 'pppoa',
                  },

                  N("Italy") . "|Libero.it" =>
                  {
		   provider_id => 'IT04',
		   url_tech => 'http://internet.libero.it/assistenza/adsl/installazione_ass.phtml',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'IT',
                   dnsServers => [ qw(193.70.192.25 193.70.152.25) ],
                   method => 'pppoa',
                  },

                  N("Sri Lanka") . "|Srilanka Telecom" =>
                  {
		   provider_id => 'LK01',
		   url_tech => 'http://www.sltnet.lk',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   dnsServers => [ qw(203.115.0.1 203.115.0.18) ],
                   method => 'pppoa',
                   encryption => 1,
                  },

                  N("Lithuania") . "|Lietuvos Telekomas" =>
                  {
                   provider_id => 'LT01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Mauritius") . "|wanadoo.mu" =>
                  {
		   provider_id => 'MU01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   dnsServers => [ qw(202.123.2.6 202.123.2.11) ],
                   method => 'pppoa',
                  },

                  N("Mauritius") . "|Telecom Plus (Mauritius Telecom)" =>
                  {
		   provider_id => 'MU02',
		   url_tech => 'http://www.telecomplus.net',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   dnsServers => [ qw(202.123.1.6 202.123.1.11) ],
                   method => 'pppoa',
                  },

                  N("Morocco") . "|Maroc Telecom" =>
                  {
                   provider_id => 'MA01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   dnsServers => [ qw(212.217.0.1 212.217.0.12) ],
                   method => 'pppoa',
                  },

                  N("Netherlands") . "|KPN" =>
                  {
                   provider_id => 'NL01',
                   vpi => 8,
                   vci => 30,
                   Encapsulation => 6,
                   method => 'pppoa',
                  },

                  N("Netherlands") . "|Eager Telecom" =>
                  {
                   provider_id => 'NL02',
                   vpi => 0,
                   vci => 21,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("Netherlands") . "|Tiscali" =>
                  {
                   provider_id => 'NL03',
                   vpi => 0,
                   vci => 22,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Netherlands") . "|Versatel" =>
                  {
                   provider_id => 'NL04',
                   vpi => 0,
                   vci => 20,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("Norway") . "|Bluecom" =>
                    {
		   provider_id => 'NO01',
                        method => 'dhcp',
                    },

                  N("Norway") . "|Firstmile" =>
                    {
		   provider_id => 'NO02',
                        method => 'dhcp',
                    },

                  N("Norway") . "|NextGenTel" =>
                    {
		   provider_id => 'NO03',
                        method => 'dhcp',
                    },

                  N("Norway") . "|SSC" =>
                    {
		   provider_id => 'NO04',
                        method => 'dhcp',
                    },

                  N("Norway") . "|Tele2" =>
                    {
		   provider_id => 'NO05',
                        method => 'dhcp',
                    },

                  N("Norway") . "|Telenor ADSL" =>
                    {
		   provider_id => 'NO06',
                        method => 'PPPoE',
                    },

                  N("Norway") . "|Tiscali" =>
                    {
		   provider_id => 'NO07',
                        vpi => 8,
                        vci => 35,
                        method => 'dhcp',
                    },

                  N("Pakistan") . "|Micronet BroadBand" =>
                  {
		   provider_id => 'PK01',
                   vpi => 1,
                   vci => 20,
                   Encapsulation => 3,
                   dnsServers => [ qw(203.82.48.3 203.82.48.4) ],
                   method => 'pppoe',
                   encryption => 1,
                  },

                  N("Poland") . "|Telekomunikacja Polska (TPSA/neostrada)" =>
                  {
                   provider_id => 'PL01',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 6,
                   dnsServers => [ qw(194.204.152.34 217.98.63.164) ],
                   method => 'pppoa',
                  },

                  N("Poland") . "|Netia neostrada" =>
                  {
                   provider_id => 'PL02',
                   url_tech => 'http://www.netia.pl/?o=d&s=210',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 1,
                   dnsServers => [ qw(195.114.181.130 195.114.161.61) ],
                   method => 'pppoe',
                  },

                  N("Portugal") . "|PT" =>
                  {
                   provider_id => 'PT01',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoe',
                  },

                  N("Russia") . "|MTU-Intel" =>
                  {
                   provider_id => 'RU01',
                   url_tech => 'http://stream.ru/s-requirements',
                   vpi => 1,
                   vci => 32,
                   Encapsulation => 1,
                   dnsServers => [ qw(212.188.4.10 195.34.32.116) ],
                   method => 'pppoe',
                  },

                  N("Singapore") . "|Singnet" =>
                  {
		   provider_id => 'SG01',
                   vpi => 0,
                   vci => 64,
                   method => 'pppoa',
                   Encapsulation => 6,
                  },

		  N("Senegal") . "|Sonatel Multimedia Sentoo" =>
                  {
                   provider_id => 'SN01',
                   vpi => 0,
                   vci => 35,
                   Encapsulation => 6,
                   method => 'pppoa',
                   DOMAINNAME2 => 'sentoo.sn',
                  },

                  N("Slovenia") . "|SiOL" =>
                  {
                   provider_id => 'SL01',
                   vpi => 1,
                   vci => 20,
                   method => 'pppoe',
                   Encapsulation => 1,
                   dnsServers => [ qw(193.189.160.11 193.189.160.12) ],
                   DOMAINNAME2 => 'siol.net',
                  },

                  N("Spain") . "|Telefónica IP dinámica" =>
                  {
                   provider_id => 'ES01',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 1,
                   CMVep => 'ES',
                   dnsServers => [ qw(80.58.32.33 80.58.0.97) ],
                   method => 'pppoe',
                   login_format => 'adslppp@telefonicanetpa / adslppp',
                  },

                  N("Spain") . "|Telefónica ip fija" =>
                  {
                   provider_id => 'ES02',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 3,
                   CMVep => 'ES',
                   dnsServers => [ qw(80.58.32.33 80.58.0.97) ],
                   method => 'static',
                   login_format => 'adslppp@telefonicanetpa / adslppp',
                  },

                  N("Spain") . "|Wanadoo/Eresmas Retevision" =>
                  {
                   provider_id => 'ES03',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'ES',
                   dnsServers => [ qw(80.58.0.33 80.58.32.97) ],
                   method => 'pppoa',
                   login_format => 'rtxxxxx@wanadooadsl',
                   encryption => 1,
                  },

                  N("Spain") . "|Wanadoo PPPoE" =>
                  {
                   provider_id => 'ES04',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 1,
                   CMVep => 'ES',
                   method => 'pppoe',
                  },

                  N("Spain") . "|Wanadoo ip fija" =>
                  {
                   provider_id => 'ES05',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 3,
                   CMVep => 'ES',
                   method => 'static',
                  },

                  N("Spain") . "|Tiscali" =>
                  {
                   provider_id => 'ES06',
                   vpi => 1,
                   vci => 20,
                   Encapsulation => 6,
                   CMVep => 'ES',
                   method => 'pppoa',
                   login_format => 'login@tiscali.es',
                  },

                  N("Spain") . "|Arrakis" =>
                  {
                   provider_id => 'ES07',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'ES',
                   method => 'pppoa',
                  },

                  N("Spain") . "|Auna" =>
                  {
                   provider_id => 'ES08',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'ES',
                   method => 'pppoa',
                  },

                  N("Spain") . "|Communitel" =>
                  {
                   provider_id => 'ES09',
                   vpi => 0,
                   vci => 21,
                   Encapsulation => 6,
                   CMVep => 'ES',
                   method => 'pppoa',
                  },

                  N("Spain") . "|Euskatel" =>
                  {
                   provider_id => 'ES10',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 1,
                   CMVep => 'ES',
                   method => 'pppoe',
                  },

                  N("Spain") . "|Uni2" =>
                  {
                   provider_id => 'ES11',
                   vpi => 1,
                   vci => 21,
                   Encapsulation => 6,
                   CMVep => 'ES',
                   method => 'pppoa',
                  },

                  N("Spain") . "|Ya.com PPPoE" =>
                  {
                   provider_id => 'ES12',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 1,
                   CMVep => 'ES',
                   method => 'pppoe',
                   login_format => 'adXXXXXXXXX@yacomadsl',
                  },

                  N("Spain") . "|Ya.com static" =>
                  {
                   provider_id => 'ES13',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 3,
                   CMVep => 'ES',
                   method => 'static',
                   login_format => 'adXXXXXXXXX@yacomadsl',
                  },

                  N("Spain") . "|Arsys" =>
                  {
		   provider_id => 'ES14',
                   vpi => 1,
                   vci => 21,
                   Encapsulation => 1,
                   CMVep => 'ES',
                   dnsServers => [ qw(217.76.128.4 217.76.129.4) ],
                   method => 'pppoe',
                   login_format => 'login@arsystel',
                  },

                  N("Spain") . "|Terra" =>
                  {
		   provider_id => 'ES15',
                   vpi => 8,
                   vci => 20,
                   Encapsulation => 1,
                   CMVep => 'ES',
                   dnsServers => [ qw(213.4.132.1 213.4.141.1) ],
                   method => 'pppoe',
                   login_format => 'login@terraadsl',
                  },

                  N("Spain") . "|Jazztel" =>
                  {
		   provider_id => 'ES16',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 6,
                   CMVep => 'ES',
                   dnsServers => [ qw(62.14.63.145 62.14.2.1) ],
                   method => 'pppoa',
                   login_format => 'username@adsl',
                   encryption => 1,
                  },

                  N("Sweden") . "|Telia" =>
                  {
                   provider_id => 'SE01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("Switzerland") . "|" . N("Any") =>
                  {
                   provider_id => 'CH01',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 3,
                   method => 'pppoe',
                  },

                  N("Switzerland") . "|BlueWin / Swisscom" =>
                  {
                   provider_id => 'CH02',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 5,
                   dnsServers => [ qw(195.186.4.108 195.186.4.109) ],
                   method => 'pppoa',
                  },

                  N("Switzerland") . "|VTX Datacomm (ex-Tiscali)" =>
                  {
                   provider_id => 'CH03',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 1,
                   method => 'pppoa',
                  },

                  N("Thailand") . "|Asianet" =>
                  {
                   provider_id => 'TH01',
                   vpi => 0,
                   vci => 64,
                   Encapsulation => 1,
                   dnsServers => [ qw(203.144.225.242 203.144.225.72 203.144.223.66) ],
                   method => 'pppoe',
                  },

                  N("Tunisia") . "|Planet.tn" =>
                  {
		   provider_id => 'TU01',
                   url_tech => 'http://www.planet.tn/',
                   vpi => 0,
                   vci => 23,
                   Encapsulation => 5,
                   dnsServers => [ qw(193.95.93.77 193.95.66.10) ],
                   method => 'pppoe',
                  },

                  N("Turkey") . "|TTnet" =>
                  {
		   provider_id => 'TR01',
		   url_tech => 'http://www.ttnet.net.tr',
                   vpi => 8,
                   vci => 23,
                   Encapsulation => 1,
                   dnsServers => [ qw(195.175.37.14 195.175.37.69) ],
                   method => 'pppoe',
                   encryption => 1,
                   login_format => 'login@ttnet',
                  },

                  N("United Arab Emirates") . "|Etisalat" =>
                  {
                   provider_id => 'AE01',
                   vpi => 0,
                   vci => 32,
                   Encapsulation => 5,
                   dnsServers => [ qw(213.42.20.20 195.229.241.222) ],
                   method => 'pppoa',
                  },

                  N("United Kingdom") . "|Tiscali UK " =>
                  {
                   provider_id => 'UK01',
                   vpi => 0,
                   vci => 26,
                   Encapsulation => 6,
                   dnsServers => [ qw(212.74.112.66 212.74.112.67) ],
                   method => 'pppoa',
                  },

                  N("United Kingdom") . "|British Telecom " =>
                  {
                   provider_id => 'UK02',
                   vpi => 0,
                   vci => 26,
                   Encapsulation => 6,
                   dnsServers => [ qw(194.74.65.69 194.72.9.38) ],
                   method => 'pppoa',
                  },

                 );

1;
