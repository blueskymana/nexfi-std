#!/bin/sh

MV="/bin/mv"

. /etc/profile

CFG_PATH="$NEXFI_ROOT/config"

MESHID=$(uci -c $CFG_PATH get netconfig.@adhoc[-1].meshid)
IPADDR=$(uci -c $CFG_PATH get netconfig.@adhoc[-1].ipaddr)
DNS=$(uci -c $CFG_PATH get netconfig.@adhoc[-1].dns)

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
    
" > $CFG_PATH/network


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

" > $CFG_PATH/wireless

$MV $CFG_PATH/network /etc/config/
$MV $CFG_PATH/wireless /etc/config/
