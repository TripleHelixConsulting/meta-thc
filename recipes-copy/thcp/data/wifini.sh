#!/bin/ash
# wifini.sh
# wifi connection requirements:

# wpa_passphrase, wpa_supplicant, ip, iw, grep, awk 
# designed by kaloyansen at gmail dot com
# copyleft triplehelix-consulting.com
# # # # # # # # # # # # # # # # # # # # # # # #

# files
WPACONF=/etc/wpa_supplicant.conf
WPASOCKET=/run/wpa_supplicant/$WIFACE
UDHCPID=/run/udhcpc.$WIFACE.pid
IFCONF=/etc/network/interfaces

# command-line tools
WPAPASS=/usr/bin/wpa_passphrase
IW=/usr/sbin/iw
WPASUPP=/usr/sbin/wpa_supplicant
DHCP=/sbin/udhcpc
IP=/sbin/ip

erreur() { echo $* && exit 1; }

# get wifi interface and network id
WIFACE=`$IW dev|grep Interface|awk '{print $2}'`
SSID=$(getopt s: $* | awk '{print $2}')
[ -n "$SSID" ] &&
    echo $0: $SSID ||
        erreur $0: specify SSID

# enable interface connexion on boot
[ -f $IFCONF ] &&
    [[ grep "auto $WIFACE" $IFCONF > /dev/null &&
        printf "auto $WIFACE\n" >> $IFCONF ]] ||
        erreur $0: $IFCONF not found

exit 0 || kill $$

grep "auto $WIFACE" $IFCONF > /dev/null ||
    printf "auto $WIFACE\n" >> $IFCONF

# verify connexion
$IW dev|grep $SSID > /dev/null &&
    erreur $0 info: $WIFACE $SSID ||
        echo $0 connecting to $SSID

# up interface
$IP link show $WIFACE | grep UP ||
    $IP link set $WIFACE up

# search network
$IW $WIFACE scan|grep $SSID ||
    erreur $0 warning: cannot find network $SSID;

# save network 
grep $SSID $WPACONF ||
    $WPAPASS $SSID >> $WPACONF

# load network
[ -S "$WPASOCKET" ] ||
    $WPASUPP -B -D wext -i $WIFACE -c $WPACONF

# start a dhcp client
$DHCP -i $WIFACE ||
    erreur $0 warning: $?

# [ -f "$UDHCPID" ] ||
# ip addr show $WIFACE
# iw $WIFACE link
# ip route show



