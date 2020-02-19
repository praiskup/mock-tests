#! /bin/bash

: ${package=dummy-pkg-20200114_1928-0.src.rpm}

test -f "$package" || exit 1

info() { echo " * $*" >&2 ; }
error() { echo " ERROR $*" >&2 ; }
result_line() { echo "$*" >> results ; }

for config in /etc/mock/*.cfg ; do
    # skip symlinks
    test -L "$config" && continue

    # Skip some of the chroots that do not make sense to test ATM.
    case $(basename "$config") in
        # site-defaults.cfg doesn't make sense to test in isolation
        *site-defaults*)        continue ;;

        # for rhel and epel playground we only test x86_64, see
        # https://github.com/rpm-software-management/mock/issues/452
        rhel*-*-x86_64)         ;;
        epel-play*-x86_64)      ;;

        # amazon chroots don't work on Fedora
        amazon*)                continue ;;

        # the rest of rhel architectures do not work on x86_64 host, see
        # https://github.com/rpm-software-management/mock/issues/452
        rhel*-*)                continue ;;

        # TODO
        custom-*)               continue ;;
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
