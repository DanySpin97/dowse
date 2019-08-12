#!/bin/sh

if [ ! -d ops ]; then
	echo "Please, run this script in the project root folder."
	exit 1
fi

docker build -t dowse_client -f ops/docker_client/Dockerfile .

