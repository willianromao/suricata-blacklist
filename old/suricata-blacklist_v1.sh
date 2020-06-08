#!/bin/bash
# /bin/suricata-blacklist
# exit 0 sucesso
# exit 1 erro

FILE_FAST=/var/log/suricata/fast.log
FILE_BLACKLIST=/var/log/suricata/blacklist.log
FILE_WHITELIST=/var/log/suricata/whitelist.log
FILE_TEMP=/var/log/suricata/temp.log
FILE_TEMP2=/var/log/suricata/temp2.log
FILE_CHAIN=/var/log/suricata/chain.log

blacklist_start()
{
CHECK_FIREWALL=`iptables -vnL INPUT | grep -i policy | awk '{print $4}'`
if [ "$CHECK_FIREWALL" = "ACCEPT" ] ; then
	echo firewall stopped >&2
	exit 1
fi

i=1

tail -f $FILE_FAST | while read log
do
	if [ "$log" = "stop" ] ; then
	grep -axn stop $FILE_FAST | awk -F ":" '{print $1}' | tac | while read stop
	do
        sed -i "$stop d" $FILE_FAST
	done
	exit 0
	fi
	
	if [ "$i" = "1" ] ; then
		blacklist_gerar
		blacklist_comparacao
		i=2
	fi
	
ip_source=`echo $log | awk '{print $(NF-2)}' | awk -F ":" '{ print $1 }'`
ip_whitelist=`grep -x $ip_source $FILE_WHITELIST`
ip_blacklist=`grep -x $ip_source $FILE_BLACKLIST`

if [ -z $ip_whitelist ] ; then

	#olhou e esta vazia, va para blacklist

	if [ -z $ip_blacklist ] ; then
	
		# olhou e esta vazia, bloqueia
		echo $ip_source >> $FILE_BLACKLIST
		iptables -I BLACKLIST -s $ip_source -j DROP
		continue
	
	fi
	
fi	

ip_dest=`echo $log | awk '{print $(NF)}' | awk -F ":" '{ print $1 }'`
ip_whitelist=`grep -x $ip_dest $FILE_WHITELIST`
ip_blacklist=`grep -x $ip_dest $FILE_BLACKLIST`	

if [ -z $ip_whitelist ] ; then

	#olhou e esta vazia, va para blacklist

	if [ -z $ip_blacklist ] ; then
	
		# olhou e esta vazia, bloqueia
		echo $ip_dest >> $FILE_BLACKLIST
		iptables -I BLACKLIST -s $ip_dest -j DROP 
	
	fi
	
fi

done	

}

stop()
{
echo stop >> $FILE_FAST
}

blacklist_comparacao()
{
iptables -vnL BLACKLIST | sed /RETURN/d | sed /source/d | sed /Chain/d | awk '{print $8}' > $FILE_CHAIN
cat $FILE_BLACKLIST $FILE_CHAIN | sort | uniq -u | while read BLACK_IP

do

iptables -I BLACKLIST -s $BLACK_IP -j DROP

done

}

blacklist_gerar()
{

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

rm $FILE_TEMP $FILE_TEMP2 &> /dev/null

}