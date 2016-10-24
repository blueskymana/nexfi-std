#!/bin/sh

EBT=ebtables

LAN0=eth1
LAN0_MAC=`ifconfig $LAN0 | grep HWaddr | awk -F ' ' '{print $5}'`

WAN0=bat0
WAN0_MAC=`ifconfig $WAN0 | grep HWaddr | awk -F ' ' '{print $5}'`

BR=br-lan
BR_MAC=`ifconfig $BR | grep HWaddr | awk -F ' ' '{print $5}'`

ADHOC=adhoc0
ADHOC_MAC=`ifconfig $ADHOC | grep HWaddr | awk -F ' ' '{print $5}'`

WAN=bat0
WAN_MAC=`ifconfig $WAN | grep HWaddr | awk -F ' ' '{print $5}'`

BROADCAST=ff:ff:ff:ff:ff:ff/ff:ff:ff:ff:ff:ff
MULTICAST=01:00:00:00:00:00/01:00:00:00:00:00
UNICAST=00:00:00:00:00:00/01:00:00:00:00:00
LIMIT=2
BURST=3
DHCP_LIMIT=5
DHCP_BURST=7

$EBT -F
$EBT -t filter -F
$EBT -t broute -F

# filter表的INPUT/OUTPUT/FORWARD默认规则为DROP
$EBT -P INPUT DROP
$EBT -P OUTPUT DROP
$EBT -P FORWARD DROP

$EBT -t broute -P BROUTING ACCEPT


$EBT -A OUTPUT -o $LAN0 --protocol IPv4 --ip-protocol udp --ip-destination-port 67:68 --limit $DHCP_LIMIT/sec --limit-burst $DHCP_BURST -j ACCEPT
$EBT -A OUTPUT -o $LAN0 --protocol IPv4 --ip-protocol udp --ip-source-port 67:68 --limit $DHCP_LIMIT/sec --limit-burst $DHCP_BURST -j ACCEPT
$EBT -A OUTPUT -d $BROADCAST -o $LAN0 --limit $LIMIT/sec --limit-burst $BURST -j ACCEPT
$EBT -A OUTPUT -d $MULTICAST -o $LAN0 --limit $LIMIT/sec --limit-burst $BURST -j ACCEPT
$EBT -A OUTPUT -o $LAN0 -p arp --limit $LIMIT/sec --limit-burst $BURST -j ACCEPT
$EBT -A OUTPUT -d $UNICAST -o $LAN0 -j ACCEPT

$EBT -A INPUT -i $LAN0 --protocol IPv4 --ip-protocol udp --ip-source-port 67:68 --limit $DHCP_LIMIT/sec --limit-burst $DHCP_BURST -j ACCEPT
$EBT -A INPUT -d $BROADCAST -i $LAN0 --limit $LIMIT/sec --limit-burst $BURST -j ACCEPT
$EBT -A INPUT -d $MULTICAST -i $LAN0 --limit $LIMIT/sec --limit-burst $BURST -j ACCEPT
$EBT -A INPUT -i $LAN0 -p arp --limit $LIMIT/sec --limit-burst $BURST -j ACCEPT
$EBT -A INPUT -d $UNICAST -i $LAN0 -j ACCEPT

$EBT -A FORWARD -o $LAN0 --protocol IPv4 --ip-protocol udp --ip-destination-port 67:68 --limit $DHCP_LIMIT/sec --limit-burst $DHCP_BURST -j ACCEPT
$EBT -A FORWARD -o $LAN0 --protocol IPv4 --ip-protocol udp --ip-source-port 67:68 --limit $DHCP_LIMIT/sec --limit-burst $DHCP_BURST -j ACCEPT
$EBT -A FORWARD -d $BROADCAST -o $LAN0 --limit $LIMIT/sec --limit-burst $BURST -j ACCEPT
$EBT -A FORWARD -d $MULTICAST -o $LAN0 --limit $LIMIT/sec --limit-burst $BURST -j ACCEPT
$EBT -A FORWARD -o $LAN0 -p arp --limit $LIMIT/sec --limit-burst $BURST -j ACCEPT
$EBT -A FORWARD -d $UNICAST -o $LAN0 -j ACCEPT


$EBT -A OUTPUT -o $WAN0 -j ACCEPT
$EBT -A INPUT -i $WAN0 -j ACCEPT
$EBT -A FORWARD -o $WAN0 -j ACCEPT

$EBT -L

