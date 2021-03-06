#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# pxelinux provides macaddr '-' separated, but we need ':'
fix_bootif() {
    local macaddr=${1}
    local IFS='-'
    macaddr=$(for i in ${macaddr} ; do echo -n $i:; done)
    macaddr=${macaddr%:}
    # strip hardware type field from pxelinux
    [ -n "${macaddr%??:??:??:??:??:??}" ] && macaddr=${macaddr#??:}
    echo $macaddr
}

# Don't continue if we don't need network
[ -z "$netroot" ] && return;

# Write udev rules
{
    # bridge: attempt only the defined interface
    if [ -e /tmp/bridge.info ]; then
        . /tmp/bridge.info
        IFACES=$ethname
    fi

    # bond: attempt only the defined interface (override bridge defines)
    if [ -e /tmp/bond.info ]; then
        . /tmp/bond.info
        # It is enough to fire up only one
        IFACES=${bondslaves%% *}
    fi

    # BOOTIF says everything, use only that one
    BOOTIF=$(getarg 'BOOTIF=')
    if [ -n "$BOOTIF" ] ; then
        BOOTIF=$(fix_bootif "$BOOTIF")
        printf 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="%s", RUN+="/sbin/ifup $env{INTERFACE}"\n' "$BOOTIF"

    # If we have to handle multiple interfaces, handle only them.
    elif [ -n "$IFACES" ] ; then
        for iface in $IFACES ; do
            printf 'SUBSYSTEM=="net", ENV{INTERFACE}=="%s", RUN+="/sbin/ifup $env{INTERFACE}"\n' "$iface"
        done

    # Default: We don't know the interface to use, handle all
    else
        printf 'SUBSYSTEM=="net", RUN+="/sbin/ifup $env{INTERFACE}"\n'
    fi

} > /etc/udev/rules.d/60-net.rules
