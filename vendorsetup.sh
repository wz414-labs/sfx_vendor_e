#!/bin/bash
#######################################################################################
#
# Copyright (C) 2020 steadfasterX <steadfasterX@binbash.rocks>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################################

# Static environment variables
#################################
export ANDROIDTOP="$(pwd)"
export SRC_DIR="${ANDROIDTOP}/.e"
export VENDOR_DIR="${ANDROIDTOP}/vendor/e"
export MIRROR_DIR=${SRC_DIR}/mirror
export ROOT_DIR=${SRC_DIR}/root

# general tmp path
TMP_DIR="$EOS_TMP_DIR"
: "${TMP_DIR:=${SRC_DIR}/tmp}"
# mkdtemp (python) works with TMP (if dir is not explicit set in the functions)
export TMP=${TMP_DIR}

ZIP_DIR="$EOS_ZIP_DIR"
: "${ZIP_DIR:=${SRC_DIR}/zips}"

export LMANIFEST_DIR=./.repo/local_manifests
export LOGS_DIR=${SRC_DIR}/logs
export USERSCRIPTS_DIR=${SRC_DIR}/userscripts
export DEBIAN_FRONTEND=noninteractive
export BUILDSCRIPTSREPO="https://gitlab.e.foundation/steadfasterX/android_vendor_e.git"

# re-generate by outcomment the following big export line and:
# EXPORTS_KEYS) egrep '^\w+=' vendor/e/vendorsetup.sh |cut -d = -f1 |tr "\n" " "
# EXPORTS_VALS) egrep '^\w+="\$' vendor/e/vendorsetup.sh |cut -d = -f2 | tr -d '"' |tr -d '$' |tr "\n" ' '

# internal variables which are used in all internal scripts
EXPORTS_KEYS="USE_CCACHE CCACHE_DIR CCACHE_SIZE CCACHE_COMPRESS CCACHE_COMPRESSLEVEL BRANCH_NAME RELEASE_TYPE REPO MIRROR OTA_URL USER_NAME USER_MAIL INCLUDE_PROPRIETARY BUILD_OVERLAY LOCAL_MIRROR CRONTAB_TIME CLEAN_AFTER_BUILD CLEAN_BEFORE_BUILD WITH_SU ANDROID_JACK_VM_ARGS CUSTOM_PACKAGES SIGN_BUILDS KEYS_SUBJECT KEYS_SUBJECT ZIP_SUBDIR LOGS_SUBDIR SIGNATURE_SPOOFING DELETE_OLD_ZIPS DELETE_OLD_LOGS EOS_BUILD_DATE TMP_DIR ZIP_DIR SYNC_RESET KEYS_DIR MINIMAL_APPS"

# user configurable variables usually set in vendorsetup.sh or exported in the current environment
EXPORTS_VALS="EOS_TMP_DIR EOS_ZIP_DIR EOS_USE_CCACHE EOS_CCACHE_DIR EOS_CCACHE_SIZE EOS_BRANCH_NAME EOS_RELEASE_TYPE EOS_REPO EOS_MIRROR EOS_OTA_URL EOS_INCLUDE_PROPRIETARY EOS_BUILD_OVERLAY EOS_LOCAL_MIRROR EOS_CLEAN_ZIPDIR EOS_CRONTAB_TIME EOS_CLEAN_AFTER_BUILD EOS_CLEAN_BEFORE_BUILD EOS_WITH_SU EOS_ANDROID_JACK_VM_ARGS EOS_CUSTOM_PACKAGES EOS_SIGN_BUILDS EOS_KEYS_SUBJECT EOS_ZIP_SUBDIR EOS_LOGS_SUBDIR EOS_SIGNATURE_SPOOFING EOS_DELETE_OLD_ZIPS EOS_DELETE_OLD_LOGS EOS_SYNC_RESET EOS_MINI_APPS EOS_BUILD_USER CCACHE_COMPRESS EOS_CCACHE_COMPRESSLEVEL"

# merge all exports
EXPORTS="$EXPORTS_KEYS $EXPORTS_VALS"

# reset build time (req for OTA + dirty builds)
find $ANDROIDTOP/out/target/product -name build.prop -delete || true

# special call for reset all variables to their default values
# just exec this script with the argument "--reset" and all related
# environment variables will be unset. next time you build the env
# vars are reset to their default (can be properly overwritten as usual ofc)
if [ "$1" == "reset" ];then
    for d in $EXPORTS;do unset $d ; export $d ;done
    unset DEBUG_LOG
    export RESET_DONE=true
    echo ">> [$(date)] Reset variables finished"
else

# reset build env
[ "$RESET_DONE" != "true" ] && source $VENDOR_DIR/vendorsetup.sh reset && source build/envsetup.sh && break

# Configurable environment variables
####################################

# By default we want to use CCACHE, you can disable this
# WARNING: disabling this may slow down a lot your builds!
# define EOS_USE_CCACHE in your device/<vendor>/<codename>/vendorsetup.sh.
USE_CCACHE="$EOS_USE_CCACHE"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${USE_CCACHE:=1}"

# the ccache directory (e.g. a tmpfs ramdisk)
# define EOS_CCACHE_DIR in your device/<vendor>/<codename>/vendorsetup.sh.
CCACHE_DIR="$EOS_CCACHE_DIR"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CCACHE_DIR:=/ccache/e-os}"

# ccache maximum size. It should be a number followed by an optional suffix: k,
# M, G, T (decimal), Ki, Mi, Gi or Ti (binary). The default suffix is G. Use 0
# for no limit.
# define EOS_CCACHE_SIZE in your device/<vendor>/<codename>/vendorsetup.sh.
CCACHE_SIZE="$EOS_CCACHE_SIZE"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CCACHE_SIZE:=12G}"

# ccache compression might be used to save a lot of disk space.
# This cuts ccache disk usage down to about 5GB per device, but may incur some performance penalty.
# define EOS_CCACHE_COMPRESS in your device/<vendor>/<codename>/vendorsetup.sh.
CCACHE_COMPRESS="$EOS_CCACHE_COMPRESS"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CCACHE_COMPRESS:=0}"

# ccache compression is using by default a level of 6 which can be adjusted here
# it must be set between 1 (fastest, worst compression) and 9 (slowest, best compression)
# define EOS_CCACHE_COMPRESSLEVEL in your device/<vendor>/<codename>/vendorsetup.sh.
CCACHE_COMPRESSLEVEL="$EOS_CCACHE_COMPRESSLEVEL"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CCACHE_COMPRESSLEVEL:=6}"

# Environment for the LineageOS branches name
# See https://github.com/LineageOS/android_vendor_cm/branches for possible options
# define EOS_BRANCH_NAME in your device/<vendor>/<codename>/vendorsetup.sh.
BRANCH_NAME="$EOS_BRANCH_NAME"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${BRANCH_NAME:=v1-q}"

# Environment for the device name
# if not set as an environment variable the following will be used instead:
# define EOS_DEVICE_TARGET in your device/<vendor>/<codename>/vendorsetup.sh.
EOS_DEVICE="$EOS_DEVICE"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${EOS_DEVICE:=}"

# Release type string
# define EOS_RELEASE_TYPE in your device/<vendor>/<codename>/vendorsetup.sh.
RELEASE_TYPE="$EOS_RELEASE_TYPE"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${RELEASE_TYPE:=UNOFFICIAL}"

# Repo use for build
# define EOS_REPO in your device/<vendor>/<codename>/vendorsetup.sh.
REPO="$EOS_REPO"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${REPO:=https://gitlab.e.foundation/e/os/releases.git}"

# Repo use for build
# define EOS_MIRROR in your device/<vendor>/<codename>/vendorsetup.sh.
MIRROR="$EOS_MIRROR"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${MIRROR:=undefined}"

# OTA URL that will be used inside CMUpdater
# Use this in combination with LineageOTA to make sure your device can auto-update itself from this buildbot
# define EOS_OTA_URL in your device/<vendor>/<codename>/vendorsetup.sh.
OTA_URL="$EOS_OTA_URL"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${OTA_URL:=undefined}"

# User identity
# define EOS_GIT_USER_NAME in your device/<vendor>/<codename>/vendorsetup.sh otherwise
# the global git conf will be used
[ -z "$EOS_GIT_USER_NAME" ] && \
USER_NAME=$(git config --global --get user.name)

# define EOS_GIT_USER_MAIL in your device/<vendor>/<codename>/vendorsetup.sh otherwise
# the global git conf will be used
[ -z "$EOS_GIT_USER_MAIL" ] && \
USER_MAIL=$(git config --global --get user.email)

# verify git config
if [ -z "$USER_NAME" ]||[ -z "$USER_MAIL" ];then echo "ERROR: Please set EOS_GIT_USER_NAME and EOS_GIT_USER_MAIL in device/<vendor>/<codename>/vendorsetup.sh or use 'git config --global' to set it once"; exit 4;fi

# set build username
# define EOS_BUILD_USER in your device/<vendor>/<codename>/vendorsetup.sh.
BUILD_USERNAME="$EOS_BUILD_USER"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${BUILD_USERNAME:=$USER_NAME}"

# Include proprietary files, downloaded automatically from github.com/TheMuppets/
# Only some branches are supported
# define EOS_INCLUDE_PROPRIETARY in your device/<vendor>/<codename>/vendorsetup.sh.
INCLUDE_PROPRIETARY="$EOS_INCLUDE_PROPRIETARY"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${INCLUDE_PROPRIETARY:=false}"

# Mount an overlay filesystem over the source dir to do each build on a clean source
# define EOS_BUILD_OVERLAY in your device/<vendor>/<codename>/vendorsetup.sh.
BUILD_OVERLAY="$EOS_BUILD_OVERLAY"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${BUILD_OVERLAY:=false}"

# Clone the full LineageOS mirror (> 200 GB)
# define EOS_LOCAL_MIRROR in your device/<vendor>/<codename>/vendorsetup.sh.
LOCAL_MIRROR="$EOS_LOCAL_MIRROR"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${LOCAL_MIRROR:=false}"

# If you want to preserve old ZIPs set this to 'false'
# define EOS_CLEAN_ZIPDIR in your device/<vendor>/<codename>/vendorsetup.sh.
CLEAN_ZIPDIR="$EOS_CLEAN_ZIPDIR"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CLEAN_ZIPDIR:=false}"

# Change this cron rule to what fits best for you
# Use 'now' to start the build immediately
# For example, '0 10 * * *' means 'Every day at 10:00 UTC'
# define EOS_CRONTAB_TIME in your device/<vendor>/<codename>/vendorsetup.sh.
CRONTAB_TIME="$EOS_CRONTAB_TIME"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CRONTAB_TIME:=now}"

# Clean artifacts output after each build
# define EOS_CLEAN_AFTER_BUILD in your device/<vendor>/<codename>/vendorsetup.sh.
CLEAN_AFTER_BUILD="$EOS_CLEAN_AFTER_BUILD"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CLEAN_AFTER_BUILD:=false}"

# Clean artifacts output after each build
# define EOS_CLEAN_BEFORE_BUILD in your device/<vendor>/<codename>/vendorsetup.sh.
CLEAN_BEFORE_BUILD="$EOS_CLEAN_BEFORE_BUILD"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CLEAN_BEFORE_BUILD:=false}"

# Provide root capabilities builtin inside the ROM (see http://lineageos.org/Update-and-Build-Prep/)
# define EOS_WITH_SU in your device/<vendor>/<codename>/vendorsetup.sh.
WITH_SU="$EOS_WITH_SU"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${WITH_SU:=false}"

# Provide a default JACK configuration in order to avoid out-of-memory issues
# ensure you have enough RAM to fit the 8G or change accordingly:
# define EOS_ANDROID_JACK_VM_ARGS in your device/<vendor>/<codename>/vendorsetup.sh.
ANDROID_JACK_VM_ARGS="$EOS_ANDROID_JACK_VM_ARGS"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${ANDROID_JACK_VM_ARGS:=-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx8G}"

# Custom packages to be installed
# define EOS_CUSTOM_PACKAGES in your device/<vendor>/<codename>/vendorsetup.sh.
CUSTOM_PACKAGES="$EOS_CUSTOM_PACKAGES"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CUSTOM_PACKAGES:=MuPDF GmsCore GsfProxy FakeStore com.google.android.maps.jar Telegram Signal Mail BlissLauncher BlissIconPack MozillaNlpBackend OpenWeatherMapWeatherProvider AccountManager MagicEarth OpenCamera eDrive Weather Notes Tasks NominatimNlpBackend Light DroidGuard OpenKeychain Message Browser BrowserWebView Apps LibreOfficeViewer}"

# Sign the builds with the keys in $KEYS_DIR
# define EOS_SIGN_BUILDS in your device/<vendor>/<codename>/vendorsetup.sh.
SIGN_BUILDS="$EOS_SIGN_BUILDS"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${SIGN_BUILDS:=true}"

# Directory where signing keys will be stored
# define EOS_KEYS_DIR in your device/<vendor>/<codename>/vendorsetup.sh.
KEYS_DIR="$EOS_KEYS_DIR"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${KEYS_DIR:=${SRC_DIR}/keys}"

# When SIGN_BUILDS = true but no keys have been provided, generate a new set with this subject
# define EOS_KEYS_SUBJECT in your device/<vendor>/<codename>/vendorsetup.sh.
KEYS_SUBJECT="$EOS_KEYS_SUBJECT"
# if not defined in the device vendorsetup.sh the following will be used instead:
[ -z "$KEYS_SUBJECT" ] && \
KEYS_SUBJECT='/C=DE/ST=Somewhere/L=Somewhere/O='${USER_NAME}'/OU=e/CN=eOS/emailAddress=android@android.local'

# Move the resulting zips to $ZIP_DIR/$codename instead of $ZIP_DIR/
# define EOS_ZIP_SUBDIR in your device/<vendor>/<codename>/vendorsetup.sh.
ZIP_SUBDIR="$EOS_ZIP_SUBDIR"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${ZIP_SUBDIR:=true}"

# Write the verbose logs to $LOGS_DIR/$codename instead of $LOGS_DIR/
# define EOS_LOGS_SUBDIR in your device/<vendor>/<codename>/vendorsetup.sh.
LOGS_SUBDIR="$EOS_LOGS_SUBDIR"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${LOGS_SUBDIR:=true}"

# Apply the MicroG's signature spoofing patch
# Valid values are "no", "yes" (for the original MicroG's patch) and
# "restricted" (to grant the permission only to the system privileged apps).
#
# The original ("yes") patch allows user apps to gain the ability to spoof
# themselves as other apps, which can be a major security threat. Using the
# restricted patch and embedding the apps that requires it as system privileged
# apps is a much secure option. See the README.md ("Custom mode") for an
# example.
# define EOS_SIGNATURE_SPOOFING in your device/<vendor>/<codename>/vendorsetup.sh.
SIGNATURE_SPOOFING="$EOS_SIGNATURE_SPOOFING"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${SIGNATURE_SPOOFING:=restricted}"

# Delete old zips in $ZIP_DIR, keep only the N latest one (0 to disable)
# define EOS_DELETE_OLD_ZIPS in your device/<vendor>/<codename>/vendorsetup.sh.
DELETE_OLD_ZIPS="$EOS_DELETE_OLD_ZIPS"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${DELETE_OLD_ZIPS:=0}"

# Delete old logs in $LOGS_DIR, keep only the N latest one (0 to disable)
# define EOS_DELETE_OLD_LOGS in your device/<vendor>/<codename>/vendorsetup.sh.
DELETE_OLD_LOGS="$EOS_DELETE_OLD_LOGS"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${DELETE_OLD_LOGS:=0}"

# set the build date
EOS_BUILD_DATE=$(date +%Y%m%d)

# Force a full sync including a reset of every repo to a clean state
# define EOS_SYNC_RESET in your device/<vendor>/<codename>/vendorsetup.sh.
# 0 means no sync/reset, 1 means everything will be hard reset and synced
SYNC_RESET="$EOS_SYNC_RESET"
: "${SYNC_RESET:=0}"

# Save recovery image
# define EOS_SAVE_RECOVERY in your device/<vendor>/<codename>/vendorsetup.sh.
RECOVERY_IMG="$EOS_SAVE_RECOVERY"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${RECOVERY_IMG=:=false}"

# Ship with Minimal Apps
# define EOS_MINI_APPS in your device/<vendor>/<codename>/vendorsetup.sh.
MINIMAL_APPS="$EOS_MINI_APPS"
# if not defined in the device vendorsetup.sh the following will be used by default:
: "${MINIMAL_APPS:=false}"


#############################################################################################
# END OF USER VARS
#############################################################################################

# set debug log
############################
export DEBUG_LOG="$LOGS_DIR/e-${BRANCH_NAME}-${EOS_BUILD_DATE}-${RELEASE_TYPE}-${EOS_DEVICE}.log"

# Create missing directories
############################
mkdir -p $MIRROR_DIR
mkdir -p $SRC_DIR
mkdir -p $ROOT_DIR
mkdir -p $TMP_DIR
mkdir -p $TMP
[ "$USE_CCACHE" == "1" ] && mkdir -p $CCACHE_DIR  && export CCACHE_EXEC=/usr/bin/ccache
mkdir -p $LMANIFEST_DIR
[ ${SIGN_BUILDS} == "true" ] && mkdir -p $KEYS_DIR
mkdir -p $USERSCRIPTS_DIR

if [ "$ZIP_SUBDIR" = true ]; then
    ZIP_DIR=$ZIP_DIR/$EOS_DEVICE
fi
mkdir -p $ZIP_DIR

if [ "$LOGS_SUBDIR" = true ]; then
    LOGS_DIR="$LOGS_DIR/$EOS_DEVICE"
fi
mkdir -p $LOGS_DIR

# Copy build files
############################
[ ! -z "$ROOT_DIR" ] && [ -d "$ROOT_DIR" ] && [ "$ROOT_DIR" != "/" ] && rm -rf ${ROOT_DIR}/*
cp -rf ${VENDOR_DIR}/src/* ${ROOT_DIR}/

# export all environment variables
##################################

for ex in $EXPORTS_KEYS;do
    LERR=0
    # check if each variable is set
    [ -z "${!ex}" ] && echo "ERROR: required variable $ex is not set!" && LERR=1
    [ $LERR -ne 0 ] && break 9
    # empty those vars which are allowed to be empty (keyword: undefined is set)
    [ "${!ex}" == "undefined" ] && declare $ex='' && test -z "${!ex}" && echo "emptied $ex >${!ex}<"
    export $ex || echo "ERROR: failed to export $ex"
done
for ex in $EXPORTS_VALS;do
    # empty those vars which are allowed to be empty (keyword: undefined is set)
    [ "${!ex}" == "undefined" ] && declare $ex='' && test -z "${!ex}" && echo "emptied $ex >${!ex}<"
    export $ex || echo "ERROR: failed to export $ex"
done

# set Java version
##################################
echo -e '\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo      '********                   /e/ - set JAVA                   ********'
echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'
echo ">> [$(date)] Determining correct OpenJDK version for $BRANCH_NAME"

case $BRANCH_NAME in
    *-pie|*-q)	JAVABASE="$ANDROIDTOP/prebuilts/jdk/jdk9/linux-x86" ; NEEDEDJAVA=shipped ;;
    *-oreo) 	NEEDEDJAVA=java-1.8.0-openjdk-amd64 ; JAVABASE=/usr/lib/jvm/$NEEDEDJAVA ;;
    *-nougat)	NEEDEDJAVA=java-7-oracle; JAVABASE=/usr/lib/jvm/$NEEDEDJAVA;;
    *)
	echo "WARNING: cannot determine best java version for $BRANCH_NAME!"
    ;;
esac
JAVACBIN=$JAVABASE/bin/javac

echo "... checking if we need to switch Java version"
if [ "$NEEDEDJAVA" == "shipped" ];then
    echo "... skipping touching java as we use a shipped one ($JAVABASE)"
else
    CURRENTJ=$(java -version 2>&1|grep version)
    NEWJBIN=$($JAVABASE/bin/java -version 2>&1|grep version)
    if [ "x$CURRENTJ" == "x$NEWJBIN" ];then
	echo "... skipping java switch because we already have the wanted version ($CURRENTJ == $NEWJBIN)"
    else
	echo "($CURRENTJ vs. $NEWJBIN)"
	echo "... switching to $NEEDEDJAVA..."
	sudo update-java-alternatives -v -s $NEEDEDJAVA --jre-headless
	echo -e "IF THE ABOVE FAILS, CHECK YOUR 'PATH' VARIABLE. PATH is currently set to:\n$PATH"
    fi

    CURRENTC=$(javac -version 2>&1)
    NEWJCBIN=$($JAVACBIN -version 2>&1)
    if [ "x$CURRENTC" == "x$NEWJCBIN" ];then
	echo "... skipping javaC switch because we already have the wanted version ($CURRENTC == $NEWJCBIN)"
    else
	echo "($CURRENTC vs. $NEWJCBIN)"
	echo "... switching to $JAVACBIN..."
	sudo update-alternatives --set javac $JAVACBIN
    fi
fi
echo ">> [$(date)] Using Java JDK $JAVABASE"


# clean when requested
##################################

if [ "$CLEAN_ZIPDIR" == "true" ]; then
    echo -e '\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    echo      '********                /e/ - CLEAN ZIPDIR                 ********'
    echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'
    echo ">> [$(date)] Cleaning '$ZIP_DIR'"
    rm -rf "$ZIP_DIR/"*
    export CLEAN_ZIPDIR=false
fi

if [ "$CLEAN_BEFORE_BUILD" == "true" ]; then
    echo -e '\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    echo      '********          /e/ - CLEAN OUT DIR (before)              ********'
    echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'
    echo ">> [$(date)] Cleaning source dir for device $EOS_DEVICE" | tee -a "$DEBUG_LOG"
    mka clean
    export CLEAN_BEFORE_BUILD=false
fi

# init
##################################

$VENDOR_DIR/init.sh


# set global version vars
##################################

vendor=lineage
case "$BRANCH_NAME" in
  *nougat*)
    vendor="cm"
    themuppets_branch="cm-14.1"
    android_version="7.1.2"
    ;;
  *oreo*)
    themuppets_branch="lineage-15.1"
    android_version="8.1"
    ;;
  *pie*)
    themuppets_branch="lineage-16.0"
    android_version="9"
    ;;
  *q*)
    themuppets_branch="lineage-17.1"
    android_version="10"
    ;;
  *)
    echo ">> [$(date)] Building branch $branch is not (yet/anymore) suppported"
    exit 1
    ;;
esac

android_version_major=$(cut -d '.' -f 1 <<< $android_version)

export android_version_major android_version themuppets_branch vendor

# sync/reset when requested
##################################

[ "$SYNC_RESET" -eq 1 ] && $VENDOR_DIR/sync.sh && export SYNC_RESET=0 EOS_SYNC_RESET=0


# postsync tasks
##################################

$VENDOR_DIR/post-sync.sh



# ensure next run reset will work
##################################

export RESET_DONE=false

fi # end "!= reset"


##################################
#end script
