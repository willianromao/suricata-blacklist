#!/bin/bash
# /bin/suricata-blacklist

CHECK_FIREWALL=`iptables -vnL INPUT | grep -i policy | awk '{print $4}'`

if [ "$CHECK_FIREWALL" = "DROP" ] ; then

FILE_FAST=/var/log/suricata/fast.log
FILE_BLACKLIST=/var/log/suricata/blacklist.log
FILE_WHITELIST=/var/log/suricata/whitelist.log
FILE_TEMP=/var/log/suricata/temp.log
FILE_TEMP2=/var/log/suricata/temp2.log

rm $FILE_BLACKLIST &> /dev/null 

cat $FILE_FAST  | awk '{print $(NF-2)}' | awk -F ":" '{ print $1 }'  | sort | uniq > $FILE_TEMP

cat $FILE_FAST  | awk '{print $(NF)}' | awk -F ":" '{ print $1 }' | sort | uniq >> $FILE_TEMP

while read linha

do

IP=`echo $linha | awk -F "." '{ print $4 }'`

	if [ -n "$IP"  ] ;	then
	
	echo "$linha" >> $FILE_TEMP2
	
	fi
	
done < $FILE_TEMP

while read IP

do

grep -vx "$IP" $FILE_TEMP2 > $FILE_BLACKLIST
cp $FILE_BLACKLIST $FILE_TEMP2
	
done < $FILE_WHITELIST

BLACKLIST_RULE=`iptables -vnL INPUT --line-numbers | grep BLACKLIST | awk '{print $1}'`

iptables -R INPUT $BLACKLIST_RULE -j NFQUEUE
iptables -F BLACKLIST
iptables -A BLACKLIST -j RETURN
iptables -R INPUT $BLACKLIST_RULE -j BLACKLIST

while read BLACK_IP
do

iptables -I BLACKLIST -s $BLACK_IP -j DROP

done < $FILE_BLACKLIST

rm $FILE_TEMP $FILE_TEMP2 &> /dev/null

fi
