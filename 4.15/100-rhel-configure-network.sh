sudo nmcli con add con-name ipsec ifname ipsec type tun mode tun
sudo nmcli con modify ipsec ipv4.addresses 172.16.110.8/24
sudo nmcli con modify ipsec ipv4.method manual
sudo nmcli con modify ipsec ipv6.method disabled
sudo nmcli conn up ipsec