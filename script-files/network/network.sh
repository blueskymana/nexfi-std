#!/bin/sh

MV="/bin/mv"

. /etc/profile

MESHID=$(uci get netconfig.@adhoc[0].meshid)
IPADDR=$(uci get netconfig.@adhoc[0].ipaddr)
DNS=$(uci get netconfig.@adhoc[0].dns)

# create network configuration
echo "# configuration for /etc/config/network

config interface 'loopback'
    option ifname 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config interface 'lan'
    option ifname 'eth1'
    option force_link '1'
    option type 'bridge'
    option proto 'static'
    option ipaddr '$IPADDR'
    option netmask '255.255.255.0'
    option ip6assign '60'
    option dns '$DNS'

config interface 'batnet'
    option mtu '1532'
    option proto 'batadv'
    option mesh 'bat0'
    
" > /tmp/network


# create wireless configuration  
echo "# configuraion for /ect/config/wireless

config wifi-device 'radio0'
    option type 'mac80211'
    option channel '6'
    option hwmode '11g'
    option path 'platform/ar933x_wmac'
    option htmode 'HT40'
    option txpower '30'
    option country 'US'

config wifi-iface
    option device 'radio0'
    option encryption 'none'
    option ssid '$MESHID'
    option mode 'adhoc'
    option ifname 'adhoc0'
    option network 'batnet'

" > /tmp/wireless

uci set wireless@wifi-iface[0].device=radio0
uci set wireless@wifi-iface[0].encryption=none
uci set wireless@wifi-iface[0].ssid='$MESHID'
uci set wireless@wifi-iface[0].mode=adhoc
uci set wireless@wifi-iface[0].ifname=adhoc0
uci set wireless@wifi-iface[0].network=batnet
uci commit system

$MV /tmp/network /etc/config/
#$MV /tmp/wireless /etc/config/
