#!/bin/sh

# Fail as soon as a command fails
set -e

if [ `id -u` != 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

# Search for apt
apt=`which apt-get 2>/dev/null || echo "no"`

if [ $apt != "no" ]; then
	echo "apt package manager found."
	echo "Installing dependencies."

	apt-get update

	# TODO replace --yes with --allow
	apt-get install --no-install-recommends --yes --fix-missing \
		zsh iptables build-essential autoconf automake libhiredis-dev libkmod-dev libjemalloc-dev pkg-config libtool libltdl-dev libsodium-dev libldns-dev libnetfilter-queue-dev uuid-dev zlib1g-dev cmake liblo-dev nmap python3-flask python3-redis xmlstarlet wget libcap2-bin redis libhiredis-dev isc-dhcp-server stubby dnsmasq snooze netdata libwebsockets8 supervisor mosquitto kmod nodejs npm
fi

set +e
id dowse >/dev/null 2>/dev/null
if [ $? = 1 ]; then
	# Create dowse user if it does not exists
	useradd -d /var/lib/dowse -s /bin/nologin dowse
fi
set -e

# Install configurations
# It is needed before sourcing env script
if [ ! -d /etc/dowse ]; then
	mkdir -p /etc/dowse
	for i in conf/*.dist ; do
		cp $i /etc/dowse/$(basename ${i%.dist})
	done
	cp conf/whitelist.p2p /etc/dowse
fi

dowse_dir=`dirname $0`
if [ $dowse_dir = '.' ]; then
	dowse_dir=$(pwd)
fi
. $dowse_dir/env

cd src
make
cd ..

# Create folders needed
if [ ! -d /var/log/dowse ]; then
	mkdir -p /var/log/dowse
	chown dowse:dowse /var/log/dowse
	mkdir /var/log/dowse/supervisor
	chown dowse:dowse /var/log/dowse/supervisor
fi

