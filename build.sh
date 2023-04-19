#!/bin/sh
GREEN='\033[0;32m'
RED='\033[0;31m'
LCYAN='\033[1;36m'
NC='\033[0m'
ARCH="amd64"
BUILD_TYPE="Release"
BUILD_DIRECTORY_ROOT="build"
BIN_NAME="NamelessGame"
ROOT_DIR="$PWD"
usage() {
    cat <<USAGE
    Usage: $0 [-scrlh] [--debug] [--cmake-flags flags]

    Options:
        -h, --help             Show this message
        -r, --run              Run executable after compilation
        --force-compile-libs   Force the libraries to compile instead of using shared libraries
        --use-shared           Use shared libraries whenever possible (default)
        --run-now              Run the executable inside the build directory (temporary for now)
        -l --link              Link executable to this directory after building
        --link-now             Link executable to this directory
        --debug                Build in Debug mode
        --release              Build in Release mode (default)
        --android              Build for Android
        --amd64                Build for amd64 (x86_64) (default)
        --sync                 Force the sync of submodules
        -s --skip-all          Just run the cmake build command (Skip submodules and cmake configure command)
        --skip-submodules      Skip the submodules command
        --skip-configure       Skip the cmake configure command
        -c --clean             Clean the output directory 
        --cmake-flags flags    Set cmake flags

USAGE
}

run() {
    printf "%bRunning Game in %s/%s%b\n" "$LCYAN" "$ROOT_DIR" "$BIN_DIRECTORY" "$NC"
    cd "${ROOT_DIR}/${BIN_DIRECTORY}" || exit 1
    ./${BIN_NAME}
    return 0
}

link() {
    cd "${ROOT_DIR}" || exit 1
    printf "Linking executable to %b%s.%b\n" "$LCYAN" "$PWD" "$NC"
    ln -s $BIN_DIRECTORY/$BIN_NAME
    return 0
}

[ "$(uname)" = "Linux" ] && TEMP=$(getopt -n "$0" -o rhcsl \
--long run,sync,help,clean,skip-all,skip-submodules,skip-configure,link,link-now,run-now,debug,release,\
cmake-flags:,force-compile-libs,amd64,use-shared,android:: \
-- "$@")
eval set -- "$TEMP"

while [ -n "$1" ]; do
    case $1 in 
        -r | --run)
            RUN=true
            ;;
        --sync)
            SYNC=true
            ;;
        --debug)
            BUILD_TYPE="Debug"
            ;;
        --release)
            BUILD_TYPE="Release"
            ;;
        --android)
            ARCH="android"
            ANDROID=true
            case "$2" in 
                "") ANDROID_NDK_PATH=/opt/android-ndk ; shift ;;
                 *) ANDROID_NDK_PATH=$2 ; shift ;;
            esac
            ;; 
        --amd64)
            ARCH="amd64"
            ANDROID=false
            ;;
        --cmake-flags)
            shift
            FLAGS="$1"
            ;;
        --run-now)
            FAST_RUN=true
            ;;
        --link-now)
            FAST_LINK=true
            ;;
        -s | --skip-all)
            SKIP_CONFIGURE=true
            SKIP_SUBMODULES=true
            ;;
        --skip-configure)
            SKIP_CONFIGURE=true
            ;;
        --skip-submodules)
            SKIP_SUBMODULES=true
            ;;
        --force-compile-libs)
            COMPILE_LIBS=true
            ;;
        --use-shared)
            COMPILE_LIBS=false
            ;;
        -c | --clean)
            rm -rf "${ROOT_DIR:?}/${BUILD_DIRECTORY_ROOT:?}"
            exit 0
            ;;
        -l | --link)
            LINK=true
            ;;
        -h | --help)
            usage
            exit
            ;;
        --)
            break
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

BUILD_DIRECTORY="${BUILD_DIRECTORY_ROOT:?}/${ARCH:?}/${BUILD_TYPE:?}"
BIN_DIRECTORY="${BUILD_DIRECTORY:?}/bin"

[ $FAST_RUN ] && run && exit 0
[ $FAST_LINK ] && link && exit 0

if [ ! "$SKIP_SUBMODULES" ]; then
    printf "\nChecking if submodules were initialized and updated properly...\n"
    git submodule update --init --recursive --depth=1
    printf "Submodules are set up properly!\n"
fi

if [ $SYNC ]; then
    git submodule sync --recursive
    git pull --recurse-submodules
fi
if [ ! "$SKIP_CONFIGURE" ]; then
    printf "Configuring CMake Build Files...\n"
    cmake -E time cmake -S . -B ${BUILD_DIRECTORY} -DCOMPILE_LIBS="${COMPILE_LIBS}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
        -DCMAKE_BUILD_ANDROID=${ANDROID} -DCMAKE_ANDROID_NDK_PATH=${ANDROID_NDK_PATH}
fi

cd "${BUILD_DIRECTORY}" || exit 1

printf "Building the executable...\n"
if [ "$(uname)" = "Darwin" ]; then
    [ -z "$FLAGS" ] && FLAGS="--build . --target ${BIN_NAME} -j $(sysctl -n hw.ncpu)"
else
    [ -z "$FLAGS" ] && FLAGS="--build . --target ${BIN_NAME} -j $(nproc)"
fi
printf "cmake %s\n" "$FLAGS"
BUILD_START=$(date +%s.%3N)
eval cmake "${FLAGS}" || (printf "%bError while building.%b\nExiting...\n" "$RED" "$NC"; exit 3) || exit $?
BUILD_END=$(date +%s.%3N)
BUILD_TIME=$(echo "scale=3; $BUILD_END - $BUILD_START" | bc)
printf "\n%bSuccessfully built executable in %s! (%ss)%b\n" "$GREEN" "$BUILD_DIRECTORY" "$BUILD_TIME" "$NC"
printf "The executable %b%s%b is inside %b%s%b.\n" "$LCYAN" "$BIN_NAME" "$NC" "$LCYAN" "$BIN_DIRECTORY" "$NC"

[ $LINK ] && link
[ $RUN ] && run
exit 0
