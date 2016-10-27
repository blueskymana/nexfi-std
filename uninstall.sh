#!/bin/sh

# killall nexfi deamon
killall nexfi-led.sh
rm -rf /tmp/ledfifo
rm -rf /tmp/msgfifo

# delete start script link.
rm -f /etc/rc.d/K89network
rm -f /etc/rc.d/S21nexfi

# remove nexfi-std version file 
rm -f /root/conf_version
rm -f /root/nexfi_version

# delete system button config
uci delete system.@button[0]
uci delete system.@button[0]
uci commit system
/etc/init.d/system reload

# delete button event support
rm -rf /etc/rc.button/BTN_0

# clean rc.local start script
cp $NEXFI_ROOT/backup-files/rc.local /etc/

# clean sysupgrade.conf
cp $NEXFI_ROOT/backup-files/sysupgrade.conf /etc/

# clean crontab timer
cp $NEXFI_ROOT/backup-files/root /etc/crontabs/
