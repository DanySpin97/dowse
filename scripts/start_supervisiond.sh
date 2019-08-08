#!/bin/sh

. /opt/dowse/env
. $dowse_install_dir/scripts/setup_dirs.sh

supervisord -c $dowse_install_dir/supervisord.conf

