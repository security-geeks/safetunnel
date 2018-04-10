# safetunnel
block untunnelled traffic in debian

## known issues
  - tor gets routed through the vpn 

## features:
  - implements an outbound firewall to prevent packet leakage if your vpn goes down
  - disables ipv6 by default

## usage:
edit the safetunnel.sh file:
````
VPN_PORT=53
VPN_PROTOCOL=tcp
VPN_IP=0.0.0.0/0
DNS_SERVER=1.1.1.1
````

## run the script:
````
sudo ./safetunnel.sh - this applies firewall rules
sudo ./safetunnel.sh install - adds reference in /etc/rc.local, copies to /usr/sbin, and applies firewall rules
````
