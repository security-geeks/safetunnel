#!/bin/bash

#enter your vpn configuration here!
VPN_PORT=53
VPN_PROTOCOL=tcp
VPN_IP=0.0.0.0/0
DNS_SERVER=8.8.8.8

#check if iptables is in the path
if ! type "iptables" > /dev/null; then
  echo "Run this script as root or with sudo"
  exit 1
fi

#check if user wants to install
if [ "$#" -eq 1 ] && [ "$1" == "install" ]; then
  echo "Installing to /etc/rc.local and /usr/sbin/safetunnel.sh"
  sed -i "/^exit 0/i\/usr/sbin/safetunnel.sh &" /etc/rc.local
  cp "$0" /usr/sbin/safetunnel.sh && chmod +x /usr/sbin/safetunnel.sh
fi

echo "Flushing all rules and blocking all connections"
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

echo "Disabling ipv6"
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP
ip6tables -F

echo "Enable ipv4 forwarding"
sysctl -q -n -w net.ipv4.ip_forward=1 2>/dev/null

echo "Allowing tunnel traffic"
iptables -A INPUT -i eth0 -j ACCEPT
iptables -A INPUT -i tun+ -m comment --comment "accept all TUN connections" -j ACCEPT
iptables -A OUTPUT -o tun+ -m comment --comment "accept all TUN connections" -j ACCEPT

echo "Allowing tunnel forwarding"
iptables -A FORWARD -i tun+ -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o tun+ -j ACCEPT

echo "Allowing local traffic"
iptables -A INPUT -i lo -m comment --comment "allow loopback" -j ACCEPT
iptables -A OUTPUT -o lo -m comment --comment "allow loopback" -j ACCEPT
iptables -A INPUT -s 127.0.1.1/32 -m comment --comment "resolv" -j ACCEPT
iptables -A OUTPUT -d 127.0.1.1/32 -m comment --comment "resolv" -j ACCEPT
iptables -A INPUT -s 192.168.0.0/16 -m comment --comment "allow all local traffic" -j ACCEPT
iptables -A OUTPUT -d 192.168.0.0/16 -m comment --comment "allow all local traffic" -j ACCEPT
iptables -A INPUT -s 10.0.0.0/8 -m comment --comment "allow all local traffic" -j ACCEPT
iptables -A OUTPUT -d 10.0.0.0/8 -m comment --comment "allow all local traffic" -j ACCEPT
iptables -A INPUT -s 172.16.0.0/12  -m comment --comment "allow all local traffic" -j ACCEPT
iptables -A OUTPUT -d 172.16.0.0/12 -m comment --comment "allow all local traffic" -j ACCEPT

echo "Allowing DNS traffic to designated host"
iptables -A INPUT -p udp -m udp -s $DNS_SERVER --sport 53 -m comment --comment "allow all udp 53" -j ACCEPT
iptables -A OUTPUT -p udp -m udp -d $DNS_SERVER --dport 53 -m comment --comment "allow all udp 53" -j ACCEPT

echo "Allowing vpn traffic"
iptables -A INPUT -p $VPN_PROTOCOL -s $VPN_IP -m $VPN_PROTOCOL --sport $VPN_PORT -m comment --comment "allow $VPN_IP $VPN_PROTOCOL $VPN_PORT" -j ACCEPT
iptables -A OUTPUT -p $VPN_PROTOCOL -d $VPN_IP -m $VPN_PROTOCOL --dport $VPN_PORT -m comment --comment "allow $VPN_IP $VPN_PROTOCOL $VPN_PORT " -j ACCEPT

echo "Complete!"
