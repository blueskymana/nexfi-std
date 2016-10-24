#!/bin/sh	

SLEEP="/bin/sleep"
IFCONFIG="/sbin/ifconfig"
IW="/usr/sbin/iw"
BRCTL="/usr/sbin/brctl"
BATCTL="/usr/sbin/batctl"

. /etc/profile

CFG_PATH="$NEXFI_ROOT/config"

$SLEEP 5

adhoc_mac=$(ifconfig adhoc0 | head -n 1 | awk -F ' ' '{print $5}')
adhoc_mac_2=$(echo $adhoc_mac | awk -F ':' '{print $2}')
adhoc_mac_3=$(echo $adhoc_mac | awk -F ':' '{print $3}')
adhoc_mac_4=$(echo $adhoc_mac | awk -F ':' '{print $4}')
adhoc_mac_5=$(echo $adhoc_mac | awk -F ':' '{print $5}')
adhoc_mac_6=$(echo $adhoc_mac | awk -F ':' '{print $6}')

mac_tail="$adhoc_mac_2:$adhoc_mac_3:$adhoc_mac_4:$adhoc_mac_5:$adhoc_mac_6"
br_mac_head="1E"

MAC=$(ifconfig eth0 | head -n 1 | awk -F ' ' '{print $5}')
BRMAC=$br_mac_head:$mac_tail

BSSID=$(uci -c $CFG_PATH get netconfig.@adhoc[-1].bssid)
MESHID=$(uci -c $CFG_PATH get netconfig.@adhoc[-1].meshid)
FREQ=$(uci -c $CFG_PATH get netconfig.@adhoc[-1].freq)


$IFCONFIG br-lan down
$IFCONFIG eth1 down
$IFCONFIG adhoc0 down
$IFCONFIG eth1 hw ether $MAC
$IFCONFIG br-lan hw ether $BRMAC
$IFCONFIG eth1 up
$IFCONFIG adhoc0 up
$SLEEP 2
$IW dev adhoc0 set type ibss
$IW dev adhoc0 ibss leave
$IW dev adhoc0 ibss join $MESHID $FREQ HT20 fixed-freq $BSSID
$SLEEP 5
$IFCONFIG bat0 up
$IFCONFIG br-lan up
$BRCTL addif br-lan bat0
$BATCTL dat 0

$NEXFI_ROOT/script-files/network/nexfi_ebtables.sh
