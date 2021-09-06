#!/bin/bash
R='\e[91m'
G='\e[92m'
N='\e[0m'
clear
echo -e "${G}installing DHCP server${N}"
apt-get install -y isc-dhcp-server && echo -e "${G}INSTALLED${N}" && sleep 3 || echo -e "${R}Failed${N}" && sleep 3
echo -e "${G}installing Net-Tools${N}"
apt-get install -y net-tools && echo -e "${G}INSTALLED${N}" && sleep 3 || echo -e "${R}Failed${N}" && sleep 3
echo -e "${G}Set Ip address for DHCP interface${N}"
ifconfig eth1 192.168.11.1 netmask 255.255.255.0 && echo -e "${G}done${N}" && sleep 3 || echo -e "${R}Failed${N}" && sleep 3

echo -e "${G}Disabling IPv6${N}"
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1



echo -e "${G}Editing dhcpd.conf${N}"
sudo bash -c "cat > /etc/dhcp/dhcpd.conf << EOF
default-lease-time 60000;
max-lease-time 720000;

subnet 192.168.11.0 netmask 255.255.255.0 {
    range 192.168.11.150 192.168.11.200;
    option routers 192.168.11.1;
    option domain-name-servers 192.168.1.1, 192.168.1.1;
}
host k8s-master {
    hardware ethernet 00:15:5D:00:C2:4A;
    fixed-address 192.168.11.100;
}
host k8s-slave-1 {
    hardware ethernet 00:15:5D:00:C2:4B;
    fixed-address 192.168.11.111;
}
host k8s-slave-2 {
    hardware ethernet 00:15:5D:00:C2:4C;
    fixed-address 192.168.11.112;
}
EOF"

echo -e "${G}Binding DHCP to eth1${N}"
sudo bash -c "cat > /etc/default/isc-dhcp-server << EOF
INTERFACESv4=\"eth1\"
EOF"
echo -e "${G}Enabling ISC-DHCP${N}"
sudo systemctl enable isc-dhcp-server
echo -e "${G}Restarting ISC-DHCP${N}"
sudo systemctl restart isc-dhcp-server.service

# to check logs use
# journalctl -u isc-dhcp-server | grep DHCPACK