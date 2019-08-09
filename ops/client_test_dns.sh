#!/bin/sh

# /etc/resolv.conf cannot be moved in docker containers
# Retrieve DHCP server address and point the DNS request

dhcp_server=`cat /var/lib/dhcp/dhclient.leases | \
		sed '/dhcp-server-identifier/!d' | \
		sed 's/[^0-9]*//'`

drill -I ${dhcp_server%;} dyne.org
