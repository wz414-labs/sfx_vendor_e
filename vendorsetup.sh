#!/bin/bash
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
export DELTA_DIR=${SRC_DIR}/delta
export KEYS_DIR=${SRC_DIR}/keys
export LOGS_DIR=${SRC_DIR}/logs
export USERSCRIPTS_DIR=${SRC_DIR}/userscripts
export DEBIAN_FRONTEND=noninteractive
export BUILDSCRIPTSREPO="https://gitlab.e.foundation/steadfasterX/android_vendor_e.git"

# re-generate by outcomment the following big export line and:
# egrep '^\w+=' vendor/e/vendorsetup.sh |cut -d = -f1 |tr "\n" " "

EXPORTS="USE_CCACHE CCACHE_DIR CCACHE_SIZE BRANCH_NAME EOS_DEVICE RELEASE_TYPE REPO MIRROR OTA_URL USER_NAME USER_MAIL INCLUDE_PROPRIETARY BUILD_OVERLAY LOCAL_MIRROR CRONTAB_TIME CLEAN_AFTER_BUILD CLEAN_BEFORE_BUILD WITH_SU ANDROID_JACK_VM_ARGS CUSTOM_PACKAGES SIGN_BUILDS KEYS_SUBJECT KEYS_SUBJECT ZIP_SUBDIR LOGS_SUBDIR SIGNATURE_SPOOFING BUILD_DELTA DELETE_OLD_ZIPS DELETE_OLD_DELTAS DELETE_OLD_LOGS OPENDELTA_BUILDS_JSON EOS_BUILD_DATE TMP_DIR ZIP_DIR SYNC_RESET"

# special call for reset all variables to their default values
# just exec this script with the argument "--reset" and all related
# environment variables will be unset. next time you build the env
# vars are reset to their default (can be properly overwritten as usual ofc)
if [ "$1" == "reset" ];then
    for d in $EXPORTS;do unset $d ; export $d ;done
    unset DEBUG_LOG
else

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

# Environment for the LineageOS branches name
# See https://github.com/LineageOS/android_vendor_cm/branches for possible options
# define EOS_BRANCH_NAME in your device/<vendor>/<codename>/vendorsetup.sh.
BRANCH_NAME="$EOS_BRANCH_NAME"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${BRANCH_NAME:=v1-pie}"

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
CLEAN_OUTDIR_BEFORE="$EOS_CLEAN_BEFORE_BUILD"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${CLEAN_OUTDIR_BEFORE:=false}"

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

# Generate delta files
# define EOS_BUILD_DELTA in your device/<vendor>/<codename>/vendorsetup.sh.
BUILD_DELTA="$EOS_BUILD_DELTA"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${BUILD_DELTA:=false}"

# Delete old zips in $ZIP_DIR, keep only the N latest one (0 to disable)
# define EOS_DELETE_OLD_ZIPS in your device/<vendor>/<codename>/vendorsetup.sh.
DELETE_OLD_ZIPS="$EOS_DELETE_OLD_ZIPS"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${DELETE_OLD_ZIPS:=0}"

# Delete old deltas in $DELTA_DIR, keep only the N latest one (0 to disable)
# define EOS_DELETE_OLD_DELTAS in your device/<vendor>/<codename>/vendorsetup.sh.
DELETE_OLD_DELTAS="$EOS_DELETE_OLD_DELTAS"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${DELETE_OLD_DELTAS:=0}"

# Delete old logs in $LOGS_DIR, keep only the N latest one (0 to disable)
# define EOS_DELETE_OLD_LOGS in your device/<vendor>/<codename>/vendorsetup.sh.
DELETE_OLD_LOGS="$EOS_DELETE_OLD_LOGS"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${DELETE_OLD_LOGS:=0}"

# Create a JSON file that indexes the build zips at the end of the build process
# (for the updates in OpenDelta). The file will be created in $ZIP_DIR with the
# specified name; leave empty to skip it.
# Requires ZIP_SUBDIR.
# define EOS_OPENDELTA_BUILDS_JSON in your device/<vendor>/<codename>/vendorsetup.sh.
OPENDELTA_BUILDS_JSON="$OPENDELTA_BUILDS_JSON"
# if not defined in the device vendorsetup.sh the following will be used instead:
: "${OPENDELTA_BUILDS_JSON:=undefined}"

# set the build date
EOS_BUILD_DATE=$(date +%Y%m%d)

# Force a full sync including a reset of every repo to a clean state
# define EOS_SYNC_RESET in your device/<vendor>/<codename>/vendorsetup.sh.
# 0 means no sync/reset, 1 means everything will be hard reset and synced
SYNC_RESET="$EOS_SYNC_RESET"
: "${SYNC_RESET:=0}"

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
[ "$USE_CCACHE" == "1" ] && mkdir -p $CCACHE_DIR
mkdir -p $LMANIFEST_DIR
mkdir -p $DELTA_DIR
mkdir -p $KEYS_DIR
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

# Download and build delta tools
################################
if [ "$BUILD_DELTA" == "true" ];then
    cd $ROOT_DIR && \
        mkdir delta && \
        echo "cloning"
        git clone --depth=1 https://gitlab.e.foundation/e/os/android_packages_apps_OpenDelta.git OpenDelta && \
        gcc -o delta/zipadjust OpenDelta/jni/zipadjust.c OpenDelta/jni/zipadjust_run.c -lz && \
        cp OpenDelta/server/minsignapk.jar OpenDelta/server/opendelta.sh delta/ && \
        chmod +x delta/opendelta.sh && \
        rm -rf OpenDelta/ && \
        sed -i -e "s|^\s*HOME=.*|HOME=$ROOT_DIR|; \
                   s|^\s*BIN_XDELTA=.*|BIN_XDELTA=xdelta3|; \
                   s|^\s*FILE_MATCH=.*|FILE_MATCH=lineage-\*.zip|; \
                   s|^\s*PATH_CURRENT=.*|PATH_CURRENT=$ANDROIDTOP/out/target/product/$DEVICE|; \
                   s|^\s*PATH_LAST=.*|PATH_LAST=$SRC_DIR/delta_last/$DEVICE|; \
                   s|^\s*KEY_X509=.*|KEY_X509=$KEYS_DIR/releasekey.x509.pem|; \
                   s|^\s*KEY_PK8=.*|KEY_PK8=$KEYS_DIR/releasekey.pk8|; \
                   s|publish|$DELTA_DIR|g" $ROOT_DIR/delta/opendelta.sh
fi

# export all environment variables
##################################

for ex in $EXPORTS;do
    LERR=0
    # check if each variable is set
    [ -z "${!ex}" ] && echo "ERROR: required variable $ex is not set!" && LERR=1
    [ $LERR -ne 0 ] && break 9
    # empty those vars which are allowed to be empty (keyword: undefined is set)
    [ "${!ex}" == "undefined" ] && declare $ex='' && test -z "${!ex}" && echo "emptied $ex >${!ex}<"
    export $ex || echo "ERROR: failed to export $ex"
done

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


# sync/reset when requested
##################################

[ "$SYNC_RESET" -eq 1 ] && $VENDOR_DIR/sync.sh && export SYNC_RESET=0 EOS_SYNC_RESET=0


# postsync tasks
##################################

$VENDOR_DIR/post-sync.sh




fi # end "!= reset"


##################################
#end script
