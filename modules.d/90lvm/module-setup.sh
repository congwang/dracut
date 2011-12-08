#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # No point trying to support lvm if the binaries are missing
    type -P lvm >/dev/null || return 1

    . $dracutfunctions
    [[ $debug ]] && set -x

    [[ $hostonly ]] && {
        local _found
        for fs in $host_fs_types; do
            [[ "$fs" = "LVM2_member" ]] && _found="1"
        done
        [[ $_found ]] || return 1
        unset _found
    }

    return 0
}

depends() {
    # We depend on dm_mod being loaded
    echo rootfs-block dm
    return 0
}

install() {
    local _i
    inst lvm

    inst_rules "$moddir/64-lvm.rules"

    if [[ $hostonly ]] || [[ $lvmconf = "yes" ]]; then
        if [ -f /etc/lvm/lvm.conf ]; then
            inst_simple /etc/lvm/lvm.conf
            # FIXME: near-term hack to establish read-only locking;
            # use command-line lvm.conf editor once it is available
            sed -i -e 's/\(^[[:space:]]*\)locking_type[[:space:]]*=[[:space:]]*[[:digit:]]/\1locking_type = 4/' ${initdir}/etc/lvm/lvm.conf
        fi
    fi

    inst_rules 11-dm-lvm.rules
    # Gentoo ebuild for LVM2 prior to 2.02.63-r1 doesn't install above rules
    # files, but provides the one below:
    inst_rules 64-device-mapper.rules

    inst "$moddir/lvm_scan.sh" /sbin/lvm_scan
    inst_hook cmdline 30 "$moddir/parse-lvm.sh"

    for _i in {"$libdir","$usrlibdir"}/libdevmapper-event-lvm*.so; do
        [ -e "$_i" ] && dracut_install "$_i"
    done
}

