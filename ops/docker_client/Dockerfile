FROM dyne/devuan:beowulf

RUN apt-get update && \
		apt-get install --yes --fix-missing --no-install-recommends \
		isc-dhcp-client ldnsutils

COPY ops/client_test_dns.sh test.sh

CMD ip addr flush dev eth0 && dhclient && ping 1.1.1.1 && ./test.sh

