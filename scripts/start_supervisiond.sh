#!/bin/sh

. /opt/dowse/env
. $dowse_install_dir/scripts/setup_dirs.sh

args=""
exec=""
# -f option is used for running supervisord in foreground
if [ "$1" = "-f" ]; then
	args="--nodaemon"
	exec="exec"
fi

$exec supervisord -c $dowse_install_dir/supervisord.conf $args

