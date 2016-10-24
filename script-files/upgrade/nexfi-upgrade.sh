#!/bin/sh

. /etc/profile

UDHCPC="/sbin/udhcpc"
IFCONFIG="/sbin/ifconfig" 
VNCI="br-lan:vnci0"

$IFCONIFG $VNCI 0
$IFCONFIG $VNCI down
$IFCONFIG $VNCI 192.168.253.252 netmask 255.255.255.0

RET=$($UDHCPC -i $VNCI -t 3 -n | grep failing)
killall udhcpc

SERVER_PATH="http://download.nexfi.cn:8000"
# configuration version file name
CONF_VERSION="nexfi_version"
# configuration version file path
LOCAL_PATH="/root"
DOWNLOAD_PATH="/tmp"

# configuration file version number compare function.
version_gt() { test "$(echo "$@" | tr -s " " "\n" | sort -n | head -n 1)" != "$1"; }
version_le() { test "$(echo "$@" | tr -s " " "\n" | sort -n | head -n 1)" == "$1"; }
version_lt() { test "$(echo "$@" | tr -s " " "\n" | sort -nr | head -n 1)" != "$1"; }
version_ge() { test "$(echo "$@" | tr -s " " "\n" | sort -nr | head -n 1)" == "$1"; }

led_red_blink() {
    echo "tbled:red:blink:on:0" > /tmp/ledfifo
    sleep 3
    echo "tbled:red:blink:off" > /tmp/ledfifo
}

led_green_blink() {
    echo "tbled:green:blink:on:1" > /tmp/ledfifo
}

# download file function
nexfi_upgrade() {
    # remove previous version configuration file.
    rm -f $DOWNLOAD_PATH/$CONF_VERSION
    # download version configuration file from server.
    wget -c -P $DOWNLOAD_PATH $SERVER_PATH/$CONF_VERSION

    if [ ! -f $DOWNLOAD_PATH/$CONF_VERSION ]
    then
        echo "Download version configuration file : $CONF_VERSION failed."
	led_red_blink
        exit
    fi

    # major version number of download configuration file.
    major=`awk -F":" '{if ($1=="Major_Version_Number") print $2}' $DOWNLOAD_PATH/$CONF_VERSION`
    # minor version number of download configuration file.
    minor=`awk -F":" '{if ($1=="Minor_Version_Number") print $2}' $DOWNLOAD_PATH/$CONF_VERSION`
    nexfi_file=`awk -F":" '{if ($1=="File_Name") print $2}' $DOWNLOAD_PATH/$CONF_VERSION`
    # if local version configuration file not exist.
    # local major minor Re. version number.
    lmajor=""
    lminor=""

    if [ -f $LOCAL_PATH/$CONF_VERSION ]
    then
        lmajor=`awk -F":" '{if ($1=="Major_Version_Number") print $2}' $LOCAL_PATH/$CONF_VERSION`
        lminor=`awk -F":" '{if ($1=="Minor_Version_Number") print $2}' $LOCAL_PATH/$CONF_VERSION`
    fi

    if [ ! -f $LOCAL_PATH/$CONF_VERSION ] || version_gt "$major.$minor" "$lmajor.$lminor"
    then
        # download openwrt firm file.

        rm -f "$DOWNLOAD_PATH/$nexfi_file"

        wget -c -P $DOWNLOAD_PATH $SERVER_PATH/$nexfi_file
        if [ ! -f $DOWNLOAD_PATH/$nexfi_file ]
        then
            echo "$DOWNLOAD_PATH/$nexfi_file download failed."
	    led_red_blink
            exit
        fi
        
        nexfi_name=$(echo $nexfi_file | awk -F '.' '{print $1}')

        # uncompress nexfi-std program.
        rm -rf /$DOWNLOAD_PATH/$nexfi_name
	tar -zxvf /$DOWNLOAD_PATH/$nexfi_file -C /tmp/

	if [ -z "$NEXFI_ROOT" ];
	then
	    led_red_blink
	    exit
	fi
	led_green_blink
	
	echo "$(uci -c $NEXFI_ROOT/config show netconfig.@adhoc[0])" > /tmp/.netconfig

	while read LINE
	do
	    CFG_OPT=$(echo $LINE | awk -F '.' '{print $3}' | awk -F '=' '{print $1}')
	    if [ ! -z "$CFG_OPT" ];
	    then
		CFG_OPT_VAL=$(uci -c /tmp/$nexfi_name/config get netconfig.@adhoc[0].$CFG_OPT)
	        if [ ! -z "$CFG_OPT_VAL" ];
		then
		    CFG_OPT_VAL=$(uci -c $NEXFI_ROOT/config get netconfig.@adhoc[0].$CFG_OPT)
		    uci -c /$DOWNLOAD_PATH/$nexfi_name/config/ set netconfig.@adhoc[0].$CFG_OPT=$CFG_OPT_VAL
		    uci -c /$DOWNLOAD_PATH/$nexfi_name/config/ commit netconfig
		fi
	    fi
	done < /tmp/.netconfig

	cd $NEXFI_ROOT
	$NEXFI_ROOT/uninstall.sh
	rm -rf $NEXFI_ROOT/*

	cp -R /$DOWNLOAD_PATH/$nexfi_name $NEXFI_ROOT/../
	cd $NEXFI_ROOT
	$NEXFI_ROOT/install.sh
    else
        led_red_blink
    fi
}

if [ -z "$RET" ];
then
    nexfi_upgrade 
    $IFCONFIG $VNCI down
else
    $IFCONFIG $VNCI down
    led_red_blink
fi
