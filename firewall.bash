#!/bin/sh
#  vi /bin/firewall

case $1 in

start)

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

;;

stop)

# POLITICAS 

iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
#iptables -P BLACKLIST ACCEPT

;;

states)

echo ""
iptables -vnL --line-numbers


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
