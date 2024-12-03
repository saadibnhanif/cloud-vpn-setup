#!/bin/bash
hostnamectl set-hostname ${var.openvpn_name}
apt-get update && apt-get -y upgrade

# AWS Inspector Agent
# curl -O https://inspector-agent.amazonaws.com/linux/latest/install
# chmod +x install && ./install

# OpenVPN
apt-get -y remove openvpn-as || true
wget -qO - https://as-repository.openvpn.net/as-repo-public.gpg | apt-key add -
echo "deb http://as-repository.openvpn.net/as/debian jammy main" > /etc/apt/sources.list.d/openvpn-as-repo.list
apt-get update
apt-get -y install openvpn-as

echo "export PATH=$PATH:/usr/local/openvpn_as/scripts" > /etc/profile.d/openvpn.sh
source /etc/profile.d/openvpn.sh
sacli stop
echo -e "LOG_ROTATE_LENGTH=1000000\n" >> /usr/local/openvpn_as/etc/as.conf
(crontab -l 2>/dev/null; echo "0 4 * * * rm /var/log/openvpnas.log.{15..1000} >/dev/null 2>&1") | crontab -
sacli --key "host.name" --value "${var.openvpn_name}" ConfigPut
sacli --key "vpn.client.routing.reroute_dns" --value "false" ConfigPut
sacli --key "vpn.client.routing.reroute_gw" --value "true" ConfigPut
sacli --key "vpn.server.routing.private_network.0" --value "${var.openvpn_vpc_cidr}" ConfigPut
sacli start
sacli ConfigQuery