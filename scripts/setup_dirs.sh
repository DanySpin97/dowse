#!/bin/sh
# Create required directories for dowse

. /opt/dowse/env

if [ ! -d $dowse_livedir ]; then
	mkdir -p $dowse_livedir
	chown dowse:dowse $dowse_livedir
fi

if [ ! -d $dowse_generated_conf ]; then
	mkdir -p $dowse_generated_conf
	chown dowse:dowse $dowse_generated_conf
	chmod 775 $dowse_generated_conf
fi

