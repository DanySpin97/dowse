#!/bin/sh

usage() {
	echo "Usage: $0 [ -i ]"
}

interactive=""
sync=""
if [ "$#" -ge 1 ]; then
	if [ "$1" = "-h" ]; then
		usage
		exit 1
	fi
	for i in seq 2 ; do
		if [ "$1" = "-i" ]; then
			interactive="on"
		elif [ "$1" = "-s" ]; then
			sync="on"
		fi
		# FIX ME
		shift
	done
fi

if [ "$sync" = "on" ]; then
	args="-v $(pwd):/opt/dowse/"
fi

if [ "$interactive" = "on" ]; then
	docker run $args --privileged -p 8000:8000 -it dowse_server /bin/bash
else
	docker run $args --privileged -d -p 8000:8000 dowse_server
fi

