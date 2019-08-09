#!/bin/sh

cat <<EOF | sysctl -p -
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_fin_timeout = 4
vm.min_free_kbytes = 65536
net.netfilter.nf_conntrack_tcp_timeout_established = 7200
net.netfilter.nf_conntrack_checksum = 0
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 15
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.ip_local_port_range = 1025 65530
net.ipv4.tcp_timestamps = 0
vm.overcommit_memory = 1
EOF

