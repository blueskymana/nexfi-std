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

uci add system button
uci set system.@button[-1].button=BTN_0
uci set system.@button[-1].action=released
uci set system.@button[-1].handler="flock -xn /tmp/nexfi-upgrade.lock -c \"$NEXFI_ROOT/script-files/upgrade/nexfi-upgrade.sh\""
uci set system.@button[-1].min=1
uci set system.@button[-1].max=6
uci -c /etc/config commit system

# upgrade configuration.
cp $NEXFI_ROOT/config/conf_version /root
cp $NEXFI_ROOT/config/nexfi_version /root

# crontabs configuration.
echo "0 */12 * * *       flock -xn /tmp/upgrade.lock -c \"$NEXFI_ROOT/script-files/upgrade/upgrade.sh\"" >> /etc/crontabs/root

# sysupgrade configuration. 
cp $NEXFI_ROOT/install-files/sysupgrade.conf /etc/

# override the kmod.
cp $NEXFI_ROOT/install-files/batman-adv /lib/modules/3.18.36/batman-adv.ko

reboot
