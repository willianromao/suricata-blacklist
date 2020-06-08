#!/bin/bash
#  vi /bin/firewall

case $1 in

start)

FILE_FAST=/var/log/suricata/fast.log
FILE_BLACKLIST=/etc/suricata/blacklist/blacklist.conf
FILE_WHITELIST=/etc/suricata/blacklist/whitelist.conf
FILE_TEMP=/etc/suricata/blacklist/blacklist.tmp
FILE_TEMP2=/etc/suricata/blacklist/blacklist.tmp2
FILE_CHAIN=/etc/suricata/blacklist/chain.conf

blacklist_start()
{
if [ ! -e $FILE_WHITELIST ] ; then
        echo File $FILE_WHITELIST not found >&2
        exit 1
fi
CHECK_FIREWALL=`iptables -vnL INPUT | grep -i policy | awk '{print $4}'`
if [ "$CHECK_FIREWALL" = "ACCEPT" ] ; then
	echo firewall stopped >&2
	exit 1
fi
grep -axn stop $FILE_FAST | awk -F ":" '{print $1}' | tac | while read stop
do
    sed -i "$stop d" $FILE_FAST
done

i=1

tail -f $FILE_FAST | while read log
do
	if [ "$log" = "stop" ] ; then
	grep -axn stop $FILE_FAST | awk -F ":" '{print $1}' | tac | while read stop
	do
        sed -i "$stop d" $FILE_FAST
	done
	break
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

done &	

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

# POLITICAS

iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -N BLACKLIST


# BYPASS

#LOOPBACK
iptables -A INPUT -i lo -j ACCEPT
#Google DNS
iptables -A INPUT -s 8.8.8.8 -j ACCEPT
#Cloudflare DNS
iptables -A INPUT -s 1.1.1.1 -j ACCEPT

# CHECAR NA BLACKLIST
iptables -A BLACKLIST -j RETURN
iptables -A INPUT -j BLACKLIST

# TENTATIVA DE INVAÇÕES CONHECIDAS
iptables -A INPUT -p tcp --dport 22 -j NFQUEUE
iptables -A INPUT -p tcp --dport 1433 -j NFQUEUE
iptables -A INPUT -p tcp --dport 3306 -j NFQUEUE

# SSH
iptables -A INPUT -p tcp --dport 2010 -j NFQUEUE

# APACHE
iptables -A INPUT -p tcp --dport 80 -j NFQUEUE
iptables -A INPUT -p tcp --dport 443 -j NFQUEUE

# VSFTPD
iptables -A INPUT -p tcp --dport 21 -j NFQUEUE
iptables -A INPUT -p tcp --dport 30000:30100 -j NFQUEUE

# ZABBIX
iptables -A INPUT -p tcp --dport 10050:10051 -j NFQUEUE

# ACEITAR RESPOSTA DE CONEXÕES ATIVAS
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

blacklist_start

;;

stop)

FILE_FAST=/var/log/suricata/fast.log
echo stop >> $FILE_FAST

iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
exit 0

;;

states)

iptables -vnL --line-numbers
exit 0

;;

restart)

$0 stop
$0 start

;;

*)

echo "Suas opções são: service firewall start, stop, states, status ou restart"
exit 1

;;

esac

exit $?
