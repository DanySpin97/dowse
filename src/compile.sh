#!/usr/bin/env zsh

R=`pwd`
R=${R%/*}
[[ -r $R/src ]] || {
    print "error: compile.sh must be run from the source base dir"
    return 1
}

source $R/zuper/zuper
source $R/zuper/zuper.init

PREFIX=${PREFIX:-/usr/local/dowse}
DOWSE_HOME=${DOWSE_HOME:-$HOME}
CFLAGS="-Wall -fPIC -fPIE -O3"
LDFLAGS="-fPIC -fPIE -pie"

# 2nd argument when present is number of threads used building
THREADS=${2:-1}

[[ -x $R/build/bin/$1 ]] && {
    act "$1 found in $R/build/bin/$1"
    act "delete it from build/bin to force recompilation"
    return 0 }

notice "Compiling $1 using ${THREADS} threads"



case $1 in
	log)
		[[ -r $R/src/log/liblog.a ]] && return 0
		pushd $R/src/log
		CFLAGS="$CFLAGS" \
			  LDFLAGS="$LDFLAGS" \
			  make -j${THREADS}
		popd
		;;

    netdata)
        pushd $R/src/netdata
		git checkout -- web
		patch -NEp1 < $R/src/patches/netdata-dowse-integration.patch
        ./autogen.sh
        CFLAGS="$CFLAGS" \
              ./configure --prefix=${PREFIX}/netdata \
              --datarootdir=${PREFIX}/netdata \
              --with-webdir=${PREFIX}/netdata \
              --localstatedir=${DOWSE_HOME}/.dowse \
              --sysconfdir=/etc/dowse &&
            make -j${THREADS} &&
            install -s -p src/netdata $R/build/bin
        popd
        ;;

	netdata-plugins)
		pushd $R/src/netdata
		make -j${THREADS}
		popd
		;;

    *)
        act "usage: ./src/compile.sh [ clean ]"
        ;;
esac
