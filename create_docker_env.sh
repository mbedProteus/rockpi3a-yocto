#!/bin/sh
PID=$$
TOPDIR="$(pwd)"
PROG="$(basename $0)"

usage() {
    cat <<EOF
$PROG [options]
Options:
-d          : download directory
-h          : show this help
EOF
}


if [ $# -eq 0 ]; then
    setup_error='true'
else
    count=0
    while getopts "d:l:b:m:t:h" setup_flag
    do
        case $setup_flag in
            d) download_direct="$OPTARG";
                if [ -z "$download_direct" ]; then
                    printf "Download directory is required. "
                    setup_error='true'
                elif [ ! -d "$download_direct" ]; then
                    printf "Download directory ($download_direct) doesn't exist. "
                    setup_error='true'
                else
                    download_direct="$(realpath $download_direct)"
                    echo "Donwload directory is" $download_direct
                fi
                ;;
            h)  setup_show_help='true';
                ;;
            \?) setup_error='true';
                ;;
        esac
    done
    shift $((OPTIND-1));
fi

if test $setup_show_help; then
    usage
    exit 0
fi

if test $setup_error; then
    echo "Invalid arguments !!!!"
    usage
    exit 1
fi

download_direct=${download_direct:-$download_dir}

cat > .env <<EOF
SRC_DIR=$TOPDIR
HOME_DIR=/home/$(id -un)
DOWNLOAD_DIR=${download_direct}
LANG=en_US.UTF-8
MACHINE=rockpi-3a
TEMPLATECONF=../meta-rockpi3/conf
USER="$(id -un)"
GROUP="$(id -gn)"
EOF