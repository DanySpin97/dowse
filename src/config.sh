#!/usr/bin/env zsh

# This are the schemes of dowse databases and lists in redis.

# This information is used to generate code that is then included at
# compile time, so any change of it requires a recompilation.

S=${$(pwd)%/*}
[[ -r $S/src ]] || {
    print "error: config.sh must be run from the src"
    return 1
}


zkv=1
source $S/zuper/zuper
vars=(dbindex thingindex)
maps=(db execmap execrules)
source $S/zuper/zuper.init

fn config $*

PREFIX="$1"
req=(PREFIX)
ckreq || return 1


#########
dbindex='
0 dynamic
1 runtime
2 storage
'
# for the db keys namespace see doc/HACKING.md
#########

mkdir -p $S/build/db

# index of all database fields for a thing in the index
# fields to the right of semicolon are for parsing the nmap xml output
# TODO: perhaps no need to write this as a file, just print and pipe

# id     SQL                       NMAP
thingindex='
macaddr  ; /nmaprun/host[\$i]/address[@addrtype=\"mac\"]/@addr
ip4      ; /nmaprun/host[\$i]/address[@addrtype=\"ipv4\"]/@addr
hostname ; /nmaprun/host[\$i]/hostnames/hostname[0]/@name
os       ; /nmaprun/host[\$i]/os/osmatch[1]/@name
vendor   ; /nmaprun/host[\$i]/address[@addrtype=\"mac\"]/@vendor
'
print - "$thingindex" > $S/build/db/thing.idx

# index of all database fields for an event occured in the network
eventindex='
id int auto_increment primary key
recognized boolean default 0 COMMENT "'" the administrator has recognized this event? "'"
level enum("'"danger"'","'"success"'","'"info"'","'"warning"'") not null
age      DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "'" when is it happened ? "'"
macaddr  varchar(18)  COMMENT "'" who ? "'"
ip4  text  COMMENT "'" who ? "'"
description    text   COMMENT "'" what ? "'"
'

#--- If the event it's refered to a tuple not insert in the found column
#--- that column shall be created by a trigger
print - "$eventindex" > $S/build/db/event.idx


# A table to contain configuration parameter
parameterindex='
variable varchar(32) PRIMARY KEY
value  varchar(32) 
'

#--- 
print - "$parameterindex" > $S/build/db/parameter.idx



#
#print - "ALTER TABLE event ADD CONSTRAINT fk_macaddr FOREIGN KEY (macaddr) REFERENCES found(macaddr) ON DELETE CASCADE" > $S/build/db/constraint.idx
#print - "ALTER TABLE event ADD CONSTRAINT fk_macaddr FOREIGN KEY (macaddr) REFERENCES found(macaddr) " > $S/build/db/constraint.idx

print - "" > $S/build/db/constraint.idx

# map of permissions
execrules=(
    redis-cli    user
    redis-server user
    nmap         user
    arp          user
    ip           user
    netdata      user
	seccrond     user
	omshell      user
	mosquitto    user
	nodejs       user
	webui2       user

	# springs
	dowse-to-mqtt  user
	dowse-cmd-fifo user

	nmap          root
	dhcpd         root
    dnscrypt-proxy root
    ip            root
    iptables      root
    xtables-multi root
    # ebtables      root
    # TODO: sup list of authorized /proc and /sys paths to write
    sysctl        root
    # TODO: sup list of authorized modules to load (using libkmod)
    modprobe      root
    # TODO: sup list of authorized signals to emit (using killall)
    kill          root
    # pgld          root
)
zkv.save execrules $S/build/db/execrules.zkv



# paths for Devuan
execmap=(
    ip            /bin/ip
    dnscrypt-proxy $PREFIX/bin/dnscrypt-proxy
    redis-cli     $PREFIX/bin/redis-cli
    redis-server  $PREFIX/bin/redis-server
	tinyproxy     $PREFIX/bin/tinyproxy
    netdata       $PREFIX/bin/netdata
	seccrond      $PREFIX/bin/seccrond
	mosquitto     $PREFIX/bin/mosquitto
	dhcpd         $PREFIX/bin/dhcpd
	omshell       $PREFIX/bin/omshell
	nodejs        $PREFIX/nodejs/node_dir/bin/node
	webui2        $PREFIX/webui2/webui.py

	dowse-to-mqtt  $PREFIX/bin/dowse-to-mqtt
	dowse-to-osc   $PREFIX/bin/dowse-to-osc
	dowse-cmd-fifo $PREFIX/bin/dowse-cmd-fifo

    kill          /bin/kill
    xtables-multi /sbin/xtables-legacy-multi
    # ebtables      /sbin/ebtables
    sysctl        /sbin/sysctl
    arp           /usr/sbin/arp
    # TODO: sup list of authorized modules (using libkmod)
    modprobe      $PREFIX/bin/modprobe
    # pgld          $PREFIX/bin/pgld
    libjemalloc   /usr/lib/x86_64-linux-gnu/libjemalloc.so
    nmap          /usr/bin/nmap
)

# check if on Gentoo
command -v emerge >/dev/null && {
    execmap=(
        dnscrypt      /usr/sbin/dnscrypt-proxy
        redis-cli     /usr/bin/redis-cli
        redis-server  /usr/sbin/redis-server
        iptables      /sbin/iptables
        ebtables      /sbin/ebtables
        sysctl        /usr/sbin/sysctl
        pgl           $PREFIX/bin/pgld
        libjemalloc   /usr/lib64/libjemalloc.so.2
    )
}

case `uname -m` in
    arm*)
        execmap[libjemalloc]=/usr/lib/arm-linux-gnueabihf/libjemalloc.so
        ;;
esac

zkv.save execmap $S/build/db/execmap.zkv


### Database index

# save databases for the shell scripts
for i in ${(f)dbindex}; do
    # this is reverse order: names are the indexes
    db+=( ${i[(w)2]} ${i[(w)1]} )
done
zkv.save db $S/build/db/database.zkv

# save databases for the C code
rm -rf $S/src/database.h
touch  $S/src/database.h
for i in ${(k)db}; do
    print "#define db_$i ${db[$i]}" >> $S/src/database.h
done

# db=()
# for i in ${(f)thingindex}; do
#     db+=( ${i[(w)1]} ${i[(w)1]} )
# done

rm -rf $S/src/thingsdb.h
touch $S/src/thingsdb.h
c=1
#print "#define THINGS_DB \"$db[things]\"" > $S/src/thingsdb.h

# for i in "${(f)thingindex}"; do
#     [[ "$i" = "" ]] && continue
#     print "#define ${i[(w)1]} $c" >> $S/src/thingsdb.h
#     c=$(( $c + 1 ))
# done

print "#define all_things_fields $(( $c - 1 ))" >> $S/src/thingsdb.h

# print "static char *get[] = {" >> $S/src/thingsdb.h
# for i in "${(f)thingindex}"; do
#     [[ "$i" = "" ]] && continue
#     print "\"${i[(w)1]}\"," >> $S/src/thingsdb.h
# done
# print " NULL };" >> $S/src/thingsdb.h

notice "Database indexes generated"

#####
_id=`id -un`
_gid=`id -gn`
cat <<EOF > privileges
dowse_uid=$_id
dowse_gid=$_gid
EOF
notice "Configured privileges for caller: $_id $_gid"
######
