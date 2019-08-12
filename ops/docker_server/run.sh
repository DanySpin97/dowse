#!/bin/sh

usage() {
	echo "Usage: $0 [ -i ]"
}

if [ "$#" -ge 1 ]; then
	if [ "$1" = "-h" ]; then
		usage
		exit 1
	elif [ "$1" != "-i" ]; then
		usage
		exit 1
	fi
	docker run -it dowse_server /bin/sh scripts/start_supervisiond.sh \
			&& scripts/start.sh && /bin/bash
else
	docker run -d dowse_server
fi

