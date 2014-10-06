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

    if [ -e "$startdir/src/CVESVP" ]
    then
        if [ "$BUILD_NO_UPDATE" == "1" ]
        then
            msg_warn 'Not updating CVESVP since $BUILD_NO_UPDATE=1'
        else
            msg_info 'git fetch CVESVP'
            cd "$startdir/src/CVESVP"
            git fetch --prune --progress origin master || msg_warn 'Failed to update CVESVP. You may be building an old version.'
        fi
    else
        msg_info 'git clone CVESVP'
        git clone --mirror --branch master --depth 1 --single-branch --progress https://github.com/Rocaloid/CVESVP.git "$startdir/src/CVESVP"
    fi

    if [ -e "$startdir/src/CVEDSP2" ]
    then
        if [ "$BUILD_NO_UPDATE" == "1" ]
        then
            msg_warn 'Not updating CVEDSP2 since $BUILD_NO_UPDATE=1'
        else
            msg_info 'git fetch CVEDSP2'
            cd "$startdir/src/CVEDSP2"
            git fetch --prune --progress origin master || msg_warn 'Failed to update CVEDSP2. You may be building an old version.'
        fi
    else
        msg_info 'git clone CVEDSP2'
        git clone --mirror --branch master --depth 1 --single-branch --progress https://github.com/Rocaloid/CVEDSP2.git "$startdir/src/CVEDSP2"
    fi

    if [ -e "$startdir/src/RFNL" ]
    then
        if [ "$BUILD_NO_UPDATE" == "1" ]
        then
            msg_warn 'Not updating RFNL since $BUILD_NO_UPDATE=1'
        else
            msg_info 'git fetch RFNL'
            cd "$startdir/src/RFNL"
            git fetch --prune --progress origin master || msg_warn 'Failed to update RFNL. You may be building an old version.'
        fi
    else
        msg_info 'git clone RFNL'
        git clone --mirror --branch master --depth 1 --single-branch --progress https://github.com/Rocaloid/RFNL.git "$startdir/src/RFNL"
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
    git clone "$startdir/src/CVESVP" "$startdir/build/CVESVP"
    git clone "$startdir/src/CVEDSP2" "$startdir/build/CVEDSP2"
    git clone "$startdir/src/RFNL" "$startdir/build/RFNL"

    msg_info 'Patching source code'
    sed -ie 's/\(add_library(\S\+\) SHARED /\1 STATIC /g' "$startdir/build/RFNL/src/CMakeLists.txt"
    sed -ie 's/\(add_library(\S\+\) SHARED /\1 STATIC /g' "$startdir/build/CVEDSP2/src/CMakeLists.txt"
    sed -ie 's/\(add_library(\S\+\) SHARED /\1 STATIC /g' "$startdir/build/CVESVP/src/CMakeLists.txt"
    sed -ie 's/\(add_library(\S\+\) SHARED /\1 STATIC /g' "$startdir/build/RUCE/src/CMakeLists.txt"

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

    cat >"$startdir/build/toolchain.cmake" <<EOM
SET(CMAKE_SYSTEM_NAME Windows)
SET(CMAKE_SYSTEM_PROCESSOR $HOSTARCH)
SET(CMAKE_C_COMPILER $HOSTARCH-gcc)
SET(CMAKE_CXX_COMPILER $HOSTARCH-g++)
SET(CMAKE_RC_COMPILER $HOSTARCH-windres)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

EOM

    msg_info 'Building RUtil2'
    cd "$startdir/build/RUtil2"
    cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_TOOLCHAIN_FILE="$startdir/build/toolchain.cmake" -DCMAKE_INSTALL_PREFIX="$startdir/lib/usr" .
    make
    make install

    msg_info 'Building RFNL'
    cd "$startdir/build/RFNL"
    cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_TOOLCHAIN_FILE="$startdir/build/toolchain.cmake" -DCMAKE_INSTALL_PREFIX="$startdir/lib/usr" .
    make
    make install
    cd "$startdir/lib/usr/lib"
    mv libRFNL.a libRFNL.fa
    "$AR" crsT libRFNL.a libRFNL.fa libRUtil2.a

    msg_info 'Building CVEDSP2'
    cd "$startdir/build/CVEDSP2"
    cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_TOOLCHAIN_FILE="$startdir/build/toolchain.cmake" -DCMAKE_INSTALL_PREFIX="$startdir/lib/usr" .
    make
    make install
    cd "$startdir/lib/usr/lib"
    mv libCVEDSP2.a libCVEDSP2.fa
    "$AR" crsT libCVEDSP2.a libCVEDSP2.fa libRFNL.fa libRUtil2.a

    msg_info 'Building CVESVP'
    cd "$startdir/build/CVESVP"
    cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_TOOLCHAIN_FILE="$startdir/build/toolchain.cmake" -DCMAKE_INSTALL_PREFIX="$startdir/lib/usr" .
    make VERBOSE=1
    make install
    cd "$startdir/lib/usr/lib"
    mv libCVESVP.a libCVESVP.fa
    "$AR" crsT libCVESVP.a libCVESVP.fa libCVEDSP2.fa libRFNL.fa libRUtil2.a

    msg_info 'Building RUCE'
    cd "$startdir/build/RUCE"
    cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_TOOLCHAIN_FILE="$startdir/build/toolchain.cmake" -DCMAKE_INSTALL_PREFIX="$startdir/lib/usr" .
    make
    make install
    cd "$startdir/lib/usr/lib"
    mv libRUCE.a libRUCE.fa
    "$AR" crsT libRUCE.a libRUCE.fa libCVESVP.fa libCVEDSP2.fa libRFNL.fa libRUtil2.a
    "$CC" -shared -o libRUCE.dll -static-libgcc -Wl,--whole-archive libRUCE.a -Wl,--no-whole-archive

    msg_info 'Compressing RUCE'
    cd "$startdir"
    "$HOSTARCH-strip" -s "$startdir/lib/usr/bin/RUCE_CLI.exe"
    rm -f "$startdir/RUCE_CLI.exe"
    if upx --best -o"$startdir/RUCE_CLI.exe" "$startdir/lib/usr/bin/RUCE_CLI.exe"
    then
        chmod 755 "$startdir/RUCE_CLI.exe" || true
    else
        msg_warn 'Failed to compress executable with UPX'
        install -Dm0755 "$startdir/lib/usr/bin/RUCE_CLI.exe" "$startdir/RUCE_CLI.exe"
    fi
    "$HOSTARCH-strip" --strip-debug --strip-unneeded "$startdir/lib/usr/lib/libRUCE.dll"
    rm -f "$startdir/libRUCE.dll"
    if upx --best -o"$startdir/libRUCE.dll" "$startdir/lib/usr/lib/libRUCE.dll"
    then
        chmod 755 "$startdir/libRUCE.dll" || true
    else
        msg_warn 'Failed to compress library with UPX'
        install -Dm0755 "$startdir/lib/usr/lib/libRUCE.dll" "$startdir/libRUCE.dll"
    fi

    msg_info 'Successfully built'
    cd "$startdir"
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
