#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if cryptsetup is not installed, then we cannot support encrypted devices.
    type -P cryptsetup >/dev/null || return 1

    . $dracutfunctions

    [[ $hostonly ]] && {
        local _found
        for fs in $host_fs_types; do
            [[ "$fs" = "crypto_LUKS" ]] && _found="1"
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

installkernel() {
    instmods dm_crypt =crypto
}

install() {
    dracut_install cryptsetup rmdir readlink umount
    inst "$moddir"/cryptroot-ask.sh /sbin/cryptroot-ask
    inst "$moddir"/probe-keydev.sh /sbin/probe-keydev
    inst_hook cmdline 10 "$moddir/parse-keydev.sh"
    inst_hook cmdline 30 "$moddir/parse-crypt.sh"
    inst_hook pre-pivot 30 "$moddir/crypt-cleanup.sh"
    inst_simple /etc/crypttab
    inst "$moddir/crypt-lib.sh" "/lib/dracut-crypt-lib.sh"
}

