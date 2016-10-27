#!/bin/sh

######### Config Openwrt OS for nexfi ######################

# add environment variable
sed -i '/NEXFI_ROOT/d' /etc/profile
echo "export NEXFI_ROOT=$(pwd)" >> /etc/profile
. /etc/profile

# disable dns and firewall.
/etc/init.d/firewall disable
/etc/init.d/dnsmasq disable

# remove and create openwrt start script.
rm -f /etc/rc.d/K89network
rm -f /etc/rc.d/S21nexfi

ln -s $NEXFI_ROOT/script-files/network/network.sh /etc/rc.d/K89network
ln -s $NEXFI_ROOT/script-files/network/nexfi.sh /etc/rc.d/S21nexfi

# add start configuration.
cp $NEXFI_ROOT/install-files/rc.local /etc/
chmod +x /etc/rc.local

# button configuration.
cp $NEXFI_ROOT/install-files/BTN_0 /etc/rc.button/

# delete system button config
uci delete system.@button[0]
uci delete system.@button[1]
uci commit system

uci add system button
uci set system.@button[-1].button=BTN_0
uci set system.@button[-1].action=released
uci set system.@button[-1].handler="flock -xn /tmp/nexfi-upgrade.lock -c \"$NEXFI_ROOT/script-files/upgrade/nexfi-upgrade.sh\""
uci set system.@button[-1].min=1
uci set system.@button[-1].max=6
uci -c /etc/config commit system

# button configuration.
uci add system button
uci set system.@button[-1].button=BTN_0
uci set system.@button[-1].action=released
uci set system.@button[-1].handler="flock -xn /tmp/channel-sw.lcok -c \"$NEXFI_ROOT/script-files/channel/channel-sw.sh\""
uci set system.@button[-1].min=0
uci set system.@button[-1].max=1
uci -c /etc/config commit system

# upgrade configuration.
[ ! -f $NEXFI_ROOT/config/conf_version ] && cp $NEXFI_ROOT/config/conf_version /root/
cp $NEXFI_ROOT/config/nexfi_version /root/

# crontabs configuration.
echo "0 */12 * * * flock -xn /tmp/upgrade.lock -c \"$NEXFI_ROOT/script-files/upgrade/upgrade.sh\"" >> /etc/crontabs/root

# sysupgrade configuration. 
cp $NEXFI_ROOT/install-files/sysupgrade.conf /etc/

# override the kmod.
cp $NEXFI_ROOT/install-files/batman-adv /lib/modules/3.18.36/batman-adv.ko

# update the configuration
echo "
config adhoc
    option    meshid    'nexfi-v3'
    option    freq      '2462'
    option    bssid     '00:0B:27:E8:E4:3D'
    option    ipaddr    '192.168.100.111'
    option    dns       '202.96.209.133'
" > /tmp/netconfig

if [ -f $NEXFI_ROOT/config/netconfig ];
then
    echo "$(uci -c $NEXFI_ROOT/config show netconfig.@adhoc[0])" > /tmp/.netconfig
    while read LINE
    do
	CFG_OPT=$(echo $LINE | awk -F '.' '{print $3}' | awk -F '=' '{print $1}')
	if [ ! -z "$CFG_OPT" ];
	then
	    CFG_OPT_VAL=$(uci -c /tmp/ get netconfig.@adhoc[0].$CFG_OPT)
	    if [ ! -z "$CFG_OPT_VAL" ];
	    then
		CFG_OPT_VAL=$(uci -c $NEXFI_ROOT/config get netconfig.@adhoc[0].$CFG_OPT)
		uci -c /tmp/ set netconfig.@adhoc[0].$CFG_OPT=$CFG_OPT_VAL
		uci -c /tmp/ commit netconfig
	    fi
	fi
    done < /tmp/.netconfig
fi
mkdir -p $NEXFI_ROOT/config/
cp /tmp/netconfig $NEXFI_ROOT/config/

# start nexfi-std
$NEXFI_ROOT/script-files/network/network.sh
/etc/init.d/network restart
sleep 2
$NEXFI_ROOT/script-files/network/nexfi.sh
/etc/rc.local

