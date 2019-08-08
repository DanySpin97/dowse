#!/bin/sh

. /opt/dowse/env

supervisorctl --configuration $dowse_install_dir/supervisord.conf stop all
