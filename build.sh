#!/bin/bash

set -e
msg_info() {
    echo -e "\e[1;32m[I]\e[1;39m \e[1;30m$(date '+%Y-%m-%d %H:%M:%S')\e[1;39m $*\e[22m" >&2
}
msg_error() {
    echo -e "\e[1;31m[E]\e[1;39m \e[1;30m$(date '+%Y-%m-%d %H:%M:%S')\e[1;39m $*\e[22m" >&2
}
msg_warn() {
    echo -e "\e[1;33m[W]\e[1;39m \e[1;30m$(date '+%Y-%m-%d %H:%M:%S')\e[1;39m $*\e[22m" >&2
}
build_envcheck() {
    startdir="$(pwd)"
    if echo -n "$startdir" | grep -q ' '
    then
        msg_error 'Your working directory contains space'
        exit 1
    fi
    msg_info "Working directory is $startdir"

    msg_info 'Checking cross compile toolchain'
    [ -z "$HOSTARCH" ] && export HOSTARCH=i686-w64-mingw32
    [ -z "$CXX" ] && export CXX="$HOSTARCH-g++"
    if [ -z "$(which "$CXX")" ]
    then
        msg_error "Cannot find cross compile toolchain for $HOSTARCH"
        exit 2
    fi

    build_envcheck_ok=1
}
build_fetch() {
    [ "$build_envcheck_ok" != "1" ] && build_envcheck
    cd "$startdir"
    msg_info 'Fetching source code'
    mkdir -p "$startdir/src"

    if [ -e "$startdir/src/RUCE" ]
    then
        if [ "$BUILD_NO_UPDATE" == "1" ]
        then
            msg_warn 'Not updating RUCE since $BUILD_NO_UPDATE=1'
        else
            msg_info 'git fetch RUCE'
            cd "$startdir/src/RUCE"
            git fetch --prune --progress origin master || msg_warn 'Failed to update RUCE. You may be building an old version.'
        fi
    else
        msg_info 'git clone RUCE'
        git clone --mirror --branch master --depth 1 --single-branch --progress https://github.com/Rocaloid/RUCE.git "$startdir/src/RUCE"
    fi

    if [ -e "$startdir/src/RUtil2" ]
    then
        if [ "$BUILD_NO_UPDATE" == "1" ]
        then
            msg_warn 'Not updating RUtil2 since $BUILD_NO_UPDATE=1'
        else
            msg_info 'git fetch RUtil2'
            cd "$startdir/src/RUtil2"
            git fetch --prune --progress origin master || msg_warn 'Failed to update RUtil2. You may be building an old version.'
        fi
    else
        msg_info 'git clone RUtil2'
        git clone --mirror --branch master --depth 1 --single-branch --progress https://github.com/Rocaloid/RUtil2.git "$startdir/src/RUtil2"
    fi

    cd "$startdir"
}
build_prepare() {
    [ "$build_envcheck_ok" != "1" ] && build_envcheck
    cd "$startdir"
    msg_info 'Extracting source code'
    rm -rf "$startdir/build"
    mkdir -p "$startdir/build"
    git clone "$startdir/src/RUCE" "$startdir/build/RUCE"
    git clone "$startdir/src/RUtil2" "$startdir/build/RUtil2"

    cd "$startdir"
}
build_compile() {
    [ "$build_envcheck_ok" != "1" ] && build_envcheck
    cd "$startdir"
    msg_info 'Start building'
    export AR="$HOSTARCH-ar"
    export CC="$HOSTARCH-gcc"
    export CXX="$HOSTARCH-g++"
    export CFLAGS="-I$startdir/lib/usr/include -L$startdir/lib/usr/lib $CFLAGS"
    export CXXLAGS="-I$startdir/lib/usr/include -L$startdir/lib/usr/lib $CXXFLAGS"
    export CPPFLAGS="-I$startdir/lib/usr/include $CPPFLAGS"
    export LDFLAGS="-L$startdir/lib/usr/lib $LDFLAGS"
    export MAKEFLAGS="-j$(nproc || echo 1) $MAKEFLAGS"
    export PKG_CONFIG_PATH="$startdir/lib/usr/lib/pkgconfig"

    msg_info 'Building RUtil2'
}
main() {
    build_envcheck
    build_fetch
    build_prepare
    build_compile
}
if [ "$BASH_SOURCE" == "$0" ]
then
    main 2>&1 | tee build.log
fi
