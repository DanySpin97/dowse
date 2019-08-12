#!/bin/sh

container=`docker ps | grep dowse_server | cut -d" " -f1`
if [ -z "$container" ]; then
	echo "dowse_server container is not running."
	exit 1
fi

# Privileged is needed to flush the ip
docker run -t --privileged dowse_client

