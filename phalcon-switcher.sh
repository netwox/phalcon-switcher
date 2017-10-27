#!/usr/bin/env bash

current_version='';
new_version='';

download_dir='/usr/local/bin/cphalcon/*';

function printOut()
{
    echo -e "$1"
}


function abort()
{
    printOut "Aborting"
    exit 0
}

function usage()
{
    printOut "Usage: $0 [option...]" >&2
    printOut $'   -h, --help        Print this information'
    printOut $"   -l, --list        List all the downloaded versions"
    printOut $"   -c, --current     Print active version"
    printOut $'   -s, --switch      Switch to the specified version'
    printOut ""
}

function list_versions()
{
    printOut "Currently downloaded versions"
    for d in ${download_dir} ; do
        printOut ${d#*'-v'}
    done
}

function switch_version()
{
    #Validate the provided version
    if [ -z $new_version ]; then
        printOut "Version not supplied"
        abort
    fi

    printOut "Current Version: ${current_version}"
    printOut "Attempting switch to version ${new_version}"

    if [ ${current_version} == ${new_version} ]; then
        printOut "Already on ${current_version}"
        exit
    fi

    #getDir
    if [[ ${new_version:0:1} == "3" ]]; then
        new_version="v${new_version}"
    elif [ ${new_version:0:1} == "1" ] || [ ${new_version:0:1} == "2" ]; then
        new_version="phalcon-v${new_version}"
    fi

    #Check if source exists
    if [ -d "/usr/local/bin/cphalcon/cphalcon-${new_version}" ]; then
        printOut "Source already exists... "
    else
        #Download
        if git ls-remote https://github.com/phalcon/cphalcon.git | grep -sw "${new_version}" 2>&1>/dev/null; then
            printOut "Attempting to download source ..."
        else
            printOut "Phalcon version does not exit. Please check https://github.com/phalcon/cphalcon/releases for valid versions"
            abort
        fi

        #Clone version from GitHub
        git clone -b "${new_version}" --single-branch --depth 1 https://github.com/phalcon/cphalcon.git "${download_dir}/cphalcon-${new_version}"
    fi


    cd "/usr/local/bin/cphalcon/cphalcon-${new_version}"

    printOut "Source download complete. Starting build..."
    cd build
    sudo ./install

    printOut "Installing extension..."
    extension_dir=`php-config --extension-dir`
    scan_dir=`php --ini | grep "Scan"`
    scan_dir=${scan_dir:35:${#scan_dir}}
echo "
[phalcon]
extension=${extension_dir}/phalcon.so
" | tee "${scan_dir}/ext-phalcon.ini" > /dev/null

    printOut "Install done!"
    current_version=`php -r "echo phpversion('phalcon');"`
    printOut "Phalcon Version is now: ${current_version}"

    printOut "Remember to restart your webserver"
    printOut "Thank you for using Phalcon Switcher!"
}

printOut "-------------------------------------"
printOut "Phalcon Switcher"
printOut "Version 1.0.1"
printOut "Author: Adeyemi Olaoye <yemexx1 at gmail dot com>"
printOut "Contributor: Olawale Lawal <lawalolawale at gmail dot com>"
printOut "-------------------------------------"
printOut ""

current_version=`php -r "echo phpversion('phalcon');"`

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help) #Help
            usage
            exit 0
            ;;
        -c | --current) #Current version
            printOut "${current_version}"
            ;;
        -l | --list) #List the downloaded versions
            list_versions
            ;;
        -s | --switch) #Switch the
            new_version=$2
            switch_version
            exit 0
            ;;
        *)
            printOut "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done
exit;
