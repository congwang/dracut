#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if we don't have dmraid installed on the host system, no point
    # in trying to support it in the initramfs.
    type -P dmraid >/dev/null || return 1

    . $dracutfunctions
    [[ $debug ]] && set -x

    [[ $hostonly ]] && {
        local _found
        for fs in $host_fs_types; do
            [[ "$fs" = "linux_raid_member" ]] && continue
            [[ "$fs" != "${fs%%_raid_member}" ]] && _found="1"
        done
        [[ $_found ]] || return 1
        unset _found
    }

    return 0
}

depends() {
    echo dm rootfs-block
    return 0
}

install() {
    local _i
    dracut_install dmraid partx kpartx

    inst "$moddir/dmraid.sh" /sbin/dmraid_scan

    if [ ! -x /lib/udev/vol_id ]; then
        inst_rules 64-md-raid.rules
    fi

    for _i in {"$libdir","$usrlibdir"}/libdmraid-events*.so*; do
        [ -e "$_i" ] && dracut_install "$_i"
    done

    inst_rules "$moddir/61-dmraid-imsm.rules"
    #inst "$moddir/dmraid-cleanup.sh" /sbin/dmraid-cleanup
    inst_hook pre-trigger 30 "$moddir/parse-dm.sh"
}
