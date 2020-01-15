#! /bin/bash

package=dummy-pkg-20200114_1928-0.src.rpm

test -f "$package" || exit 1

info() { echo " * $*" >&2 ; }
error() { echo " ERROR $*" >&2 ; }
result_line() { echo "$*" >> results ; }

for config in /etc/mock/*.cfg ; do
    # skip symlinks
    test -L "$config" && continue

    case $config in
        *site-defaults*) continue ;;
    esac

    chroot=$(basename "$config")
    chroot=${chroot%%.cfg}

    if ! mock -r "$chroot" --scrub all; then
        result_line "$chroot - cleanup failed"
        continue
    fi

    if ! mock -r "$chroot" --rebuild "$package"; then
        result_line "$chroot - build failed"
    else
        result_line "$chroot - OK"
    fi

    mock -r "$chroot" --scrub all
done
