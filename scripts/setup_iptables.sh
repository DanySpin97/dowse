#!/bin/sh

. /opt/dowse/env

if [ $firewall != "yes" ]; then
	exit 0
fi

### iptables-stop

iptables -F TCP     2> /dev/null
iptables -F ICMP    2> /dev/null

iptables -F
iptables -X

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

### loopback-on

# TODO Is this true ?
# rules that do not apply if we are running on the loopback device
iptables -A INPUT   -i lo -j ACCEPT
# iptables -A OUTPUT  -i lo -j ACCEPT
iptables -A FORWARD -i lo -j ACCEPT

iptables -A INPUT -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -d 127.0.0.1 -j ACCEPT
iptables -A INPUT -s 127.0.1.1 -j ACCEPT
iptables -A INPUT -d 127.0.1.1 -j ACCEPT

### iptables-start

iptables -P OUTPUT ACCEPT
iptables -P INPUT DROP
iptables -P FORWARD DROP

# Allow packets from private subnets
# iptables -A FORWARD -i ${interface} -s ${dowse_net} -j ACCEPT

# Allow DNS service
iptables -A INPUT -i ${interface} -p udp --dport 53 -j ACCEPT

# Allow DHCP service
iptables -A INPUT -i ${interface} -p udp --sport 67:68 --dport 67:68 -j ACCEPT

# Allow incoming pings (can be disabled)
iptables -A INPUT -i ${interface} -p icmp --icmp-type echo-request -j ACCEPT

# Allow services such as www and ssh (can be disabled)
iptables -A INPUT -p tcp --dport http -j ACCEPT
iptables -A INPUT -p tcp --dport ssh  -j ACCEPT
iptables -A INPUT -p tcp --dport 29999 -j ACCEPT

# Allow websockets (TODO: ACL)
iptables -A INPUT -p tcp --dport 1888 -j ACCEPT

# forward port 80 to webui's 8000
iptables -A PREROUTING -t nat -i ${interface} -p tcp --dport 80 \
		-j REDIRECT --to-port 8000 --destination ${address}

# Keep state of connections from local machine and private subnets
iptables -A OUTPUT  -m state --state NEW -o ${interface} -j ACCEPT
iptables -A FORWARD -m state --state NEW -o ${interface} -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT   -m state --state ESTABLISHED,RELATED -j ACCEPT


### iptables-base-protection

iptables -N TCP
iptables -F TCP

# Help to prevent sequence number prediction attacks. This rule
# must come before the NEW SYN rule below to be effective.
iptables -A TCP -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW \
		-j REJECT --reject-with tcp-reset

# Something overlooked by many firewalls is that if you use a
# matching rule with the NEW state but with the SYN bit unset, it
# will not match and thus get past the firewall rule. Simply making
# a match against the NEW state does not do what most people intend
# when they write the rule. The following rule takes care of that
# problem. The rule drops any NEW connection attempts that do not
# have the SYN bit set. After this rule is set, we can freely match
# new connection attempts with a match against the NEW state alone.
iptables -A TCP -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

# Rate limit the number of new connections from an individual IP
# address to help defend against SYN flood attacks.
iptables -A TCP -p tcp -m conntrack --ctstate NEW -m recent \
		--name blacklist --update --seconds 1 --hitcount 20 -j DROP

# Drop illegal, malformed, or potentially harmful tcp flag
# combinations.  This also helps prevent some port scans.
iptables -A TCP -p tcp --tcp-option 128                    -j DROP
iptables -A TCP -p tcp --tcp-option 64                     -j DROP
iptables -A TCP -p tcp --tcp-flags ACK,FIN FIN             -j DROP
iptables -A TCP -p tcp --tcp-flags ACK,PSH PSH             -j DROP
iptables -A TCP -p tcp --tcp-flags ACK,URG URG             -j DROP
iptables -A TCP -p tcp --tcp-flags FIN,RST FIN,RST         -j DROP
iptables -A TCP -p tcp --tcp-flags SYN,ACK,FIN,RST RST     -j DROP
iptables -A TCP -p tcp --tcp-flags SYN,FIN SYN,FIN         -j DROP
iptables -A TCP -p tcp --tcp-flags SYN,RST SYN,RST         -j DROP
iptables -A TCP -p tcp --tcp-flags ALL ALL                 -j DROP
iptables -A TCP -p tcp --tcp-flags ALL NONE                -j DROP
iptables -A TCP -p tcp --tcp-flags ALL FIN,PSH,URG         -j DROP
iptables -A TCP -p tcp --tcp-flags ALL SYN,FIN,PSH,URG     -j DROP
iptables -A TCP -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

# Limit potential Xmas scans.
iptables -A TCP -p tcp --tcp-flags ALL FIN,URG,PSH \
    -m limit --limit 3/min --limit-burst 3 -j RETURN
iptables -A TCP -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP

# Limit potential furtive port scans (scans that detect closed
# ports to deduce open ports).
iptables -A TCP -p tcp --tcp-flags SYN,ACK,FIN,RST RST \
    -m limit --limit 1/second --limit-burst 1 -j RETURN
iptables -A TCP -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j DROP

# Drop large numbers of RST packets.  This is to help avoid Smurf
# attacks by giving the real data packet in the sequence a better
# chance to arrive first.
iptables -A TCP -p tcp -m tcp --tcp-flags RST RST \
    -m limit --limit 2/second --limit-burst 2 -j RETURN
iptables -A TCP -p tcp -m tcp --tcp-flags RST RST -j DROP

# Set conditions in which the table will be traversed.
iptables -A INPUT -p tcp -j TCP
iptables -A FORWARD -p tcp -j TCP

# Create and flush the table.
iptables -N ICMP
iptables -F ICMP

#    0 = Echo Reply, what gets sent back after a type 8 is received here
#    3 = Destination Unreachable (inbound) or Fragmentation Needed (out) [RFC792]

#    4 = Source Quench tells sending IP to slow down its rate to destination
#    5 = Redirect [RFC792]
#    6 = Alternate Host Address
#    8 = Echo Request used for pinging hosts, but see the note above
#    9 = Router Advertisement [RFC1256]
#   10 = Router Selection [RFC1256]
#   11 = Time Exceeded used for traceroute (TTL) or sometimes frag packets
#   12 = Parameter Problem is some error or weirdness detected in header
#   13 = Timestamp Request  [RFC792]
#   14 = Timestamp Reply  [RFC792]
#   15 = Information Request  [RFC792]
#   16 = Information Reply  [RFC792]
#   17 = Address Mask Request  [RFC950]
#   18 = Address Mask Reply  [RFC950]
#   30 = Traceroute  [RFC1393]

# Allow certain icmp types.
iptables -A ICMP -p icmp --icmp-type 0  -j ACCEPT
iptables -A ICMP -p icmp --icmp-type 3  -j ACCEPT
iptables -A ICMP -p icmp --icmp-type 4  -j ACCEPT
iptables -A ICMP -p icmp --icmp-type 5  -j ACCEPT

# Limit echo reply traffic to protect against ping floods.
iptables -A ICMP -p icmp --icmp-type 8 -m limit --limit 1/second --limit-burst 2 -j ACCEPT
iptables -A ICMP -p icmp --icmp-type 8 -j DROP

# Allow more icmp types.
iptables -A ICMP -p icmp --icmp-type 9  -j ACCEPT
iptables -A ICMP -p icmp --icmp-type 11 -j ACCEPT
iptables -A ICMP -p icmp --icmp-type 12 -j ACCEPT

# Drop all other icmp traffic.
iptables -A ICMP -p icmp -j DROP

# Set conditions in which the table will be traversed.
iptables -A INPUT -p icmp -j ICMP

case "$wan" in
	localhost|127.0.0.1|127.0.1.1)
		# Do nothing
		echo -n ""
	*)
		iptables -A INPUT -i ${interface} -s ${dowse_net} -j ACCEPT
		iptables -A INPUT -i ${interface} -d 127.0.0.1 -j DROP
		iptables -A INPUT -i ${interface} -s 127.0.0.1 -j DROP
		iptables -A FORWARD -i ${interface} -s 127.0.0.1 -j DROP
		iptables -A FORWARD -i ${interface} -d 127.0.0.1 -j DROP

		ip -s -s neigh flush all
		ip addr add ${address}/${dowse_net#*/]} dev $interface
		ip link set $interface up

		[[ "$wan" = "" ]] || ip route add default via $wan

		sysctl net.netfilter.nf_conntrack_acct=1
		sysctl net.ipv4.ip_forward=1
		sysctl net.ipv4.conf.$interface.accept_redirects=0

		[[ -r /etc/resolv.conf.dowse-backup ]] ||
				mv /etc/resolv.conf /etc/resolv.conf.dowse-backup

		cat <<EOF > /etc/resolv.conf
nameserver $address
domain dowse.it
search dowse.it
EOF
esac

