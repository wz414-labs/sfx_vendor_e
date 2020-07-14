#!/bin/bash

# Environment variables
#######################

export SRC_DIR="$(pwd)/.srv"
export MIRROR_DIR=${SRC_DIR}/mirror
export ROOT_DIR=${SRC_DIR}/root

# general tmp path
export TMP_DIR=${SRC_DIR}/tmp
# mkdtemp (python) works with TMP (if not explicit set)
export TMP=${TMP_DIR}

export CCACHE_DIR=/ccache/jenkins
export ZIP_DIR=${SRC_DIR}/zips
export LMANIFEST_DIR=./.repo/local_manifests
export DELTA_DIR=${SRC_DIR}/delta
export KEYS_DIR=${SRC_DIR}/keys
export LOGS_DIR=${SRC_DIR}/logs
export USERSCRIPTS_DIR=${SRC_DIR}/userscripts
export DEBIAN_FRONTEND=noninteractive

#BUILDSCRIPTSREPO=https://gitlab.e.foundation/e/os/docker-lineage-cicd.git
BUILDSCRIPTSREPO=https://code.binbash.rocks:8443/efoundation/docker-lineage-cicd.git

# Configurable environment variables
####################################

# By default we want to use CCACHE, you can disable this
# WARNING: disabling this may slow down a lot your builds!
export USE_CCACHE=1

# ccache maximum size. It should be a number followed by an optional suffix: k,
# M, G, T (decimal), Ki, Mi, Gi or Ti (binary). The default suffix is G. Use 0
# for no limit.
export CCACHE_SIZE=12G

# Environment for the LineageOS branches name
# See https://github.com/LineageOS/android_vendor_cm/branches for possible options
export BRANCH_NAME='v0.9.3-pie'

# Environment for the device list (separate by comma if more than one)
# eg. DEVICE_LIST=hammerhead,bullhead,angler
export DEVICE_LIST=''

# Release type string
export RELEASE_TYPE='UNOFFICIAL'

# Repo use for build
export REPO='https://gitlab.e.foundation/e/os/android.git'

# Repo use for build
export MIRROR=''

# OTA URL that will be used inside CMUpdater
# Use this in combination with LineageOTA to make sure your device can auto-update itself from this buildbot
export OTA_URL=''

# User identity
export USER_NAME='user'
export USER_MAIL='user@email.edu'

# Include proprietary files, downloaded automatically from github.com/TheMuppets/
# Only some branches are supported
export INCLUDE_PROPRIETARY=false

# Mount an overlay filesystem over the source dir to do each build on a clean source
export BUILD_OVERLAY=false

# Clone the full LineageOS mirror (> 200 GB)
export LOCAL_MIRROR=false

# If you want to preserve old ZIPs set this to 'false'
export CLEAN_OUTDIR=false

# Change this cron rule to what fits best for you
# Use 'now' to start the build immediately
# For example, '0 10 * * *' means 'Every day at 10:00 UTC'
export CRONTAB_TIME='now'

# Clean artifacts output after each build
export CLEAN_AFTER_BUILD=true

# Provide root capabilities builtin inside the ROM (see http://lineageos.org/Update-and-Build-Prep/)
export WITH_SU=false

# Provide a default JACK configuration in order to avoid out-of-memory issues
# ensure you have enough RAM to fit the 8G or change accordingly:
export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx8G"

# Custom packages to be installed
export CUSTOM_PACKAGES='MuPDF GmsCore GsfProxy FakeStore com.google.android.maps.jar Telegram Signal Mail BlissLauncher BlissIconPack MozillaNlpBackend OpenWeatherMapWeatherProvider AccountManager MagicEarth OpenCamera eDrive Weather Notes Tasks NominatimNlpBackend Light DroidGuard OpenKeychain Message Browser BrowserWebView Apps LibreOfficeViewer'

# Sign the builds with the keys in $KEYS_DIR
export SIGN_BUILDS=false

# When SIGN_BUILDS = true but no keys have been provided, generate a new set with this subject
export KEYS_SUBJECT='/C=DE/ST=Somewhere/L=Somewhere/O=dev-name/OU=e/CN=eOS/emailAddress=android@android.local'

# Move the resulting zips to $ZIP_DIR/$codename instead of $ZIP_DIR/
export ZIP_SUBDIR=true

# Write the verbose logs to $LOGS_DIR/$codename instead of $LOGS_DIR/
export LOGS_SUBDIR=true

# Apply the MicroG's signature spoofing patch
# Valid values are "no", "yes" (for the original MicroG's patch) and
# "restricted" (to grant the permission only to the system privileged apps).
#
# The original ("yes") patch allows user apps to gain the ability to spoof
# themselves as other apps, which can be a major security threat. Using the
# restricted patch and embedding the apps that requires it as system privileged
# apps is a much secure option. See the README.md ("Custom mode") for an
# example.
export SIGNATURE_SPOOFING="restricted"

# Generate delta files
export BUILD_DELTA=false

# Delete old zips in $ZIP_DIR, keep only the N latest one (0 to disable)
export DELETE_OLD_ZIPS=0

# Delete old deltas in $DELTA_DIR, keep only the N latest one (0 to disable)
export DELETE_OLD_DELTAS=0

# Delete old logs in $LOGS_DIR, keep only the N latest one (0 to disable)
export DELETE_OLD_LOGS=0

# Create a JSON file that indexes the build zips at the end of the build process
# (for the updates in OpenDelta). The file will be created in $ZIP_DIR with the
# specified name; leave empty to skip it.
# Requires ZIP_SUBDIR.
export OPENDELTA_BUILDS_JSON=''

# You can optionally specify a USERSCRIPTS_DIR volume containing these scripts:
#  * begin.sh, run at the very beginning
#  * before.sh, run after the syncing and patching, before starting the builds
#  * pre-build.sh, run before the build of every device
#  * post-build.sh, run after the build of every device
#  * end.sh, run at the very end
# Each script will be run in $SRC_DIR and must be owned and writeable only by
# root

# Create Volume entry points
############################
# VOLUME $MIRROR_DIR
# VOLUME $SRC_DIR
# VOLUME $TMP_DIR
# VOLUME $CCACHE_DIR
# VOLUME $ZIP_DIR
# VOLUME $LMANIFEST_DIR
# VOLUME $DELTA_DIR
# VOLUME $KEYS_DIR
# VOLUME $LOGS_DIR
# VOLUME $USERSCRIPTS_DIR
# VOLUME /root/.ssh

# Create missing directories
############################
mkdir -p $MIRROR_DIR
mkdir -p $SRC_DIR
mkdir -p $ROOT_DIR
mkdir -p $TMP_DIR
mkdir -p $TMP
mkdir -p $CCACHE_DIR
mkdir -p $ZIP_DIR
mkdir -p $LMANIFEST_DIR
mkdir -p $DELTA_DIR
mkdir -p $KEYS_DIR
mkdir -p $LOGS_DIR
mkdir -p $USERSCRIPTS_DIR

# Copy build files
############################
rm -rf $TMP_DIR/buildscripts
git clone $BUILDSCRIPTSREPO $TMP_DIR/buildscripts

[ ! -z "$ROOT_DIR" ] && [ -d "$ROOT_DIR" ] && [ "$ROOT_DIR" != "/" ] && rm -rf ${ROOT_DIR}/*
cp -rf $TMP_DIR/buildscripts/src/* ${ROOT_DIR}/

# Download and build delta tools
################################
if [ "$BUILD_DELTA" == "true" ];then
    cd $ROOT_DIR && \
        mkdir delta && \
        echo "cloning"
        git clone --depth=1 https://github.com/omnirom/android_packages_apps_OpenDelta.git OpenDelta && \
        gcc -o delta/zipadjust OpenDelta/jni/zipadjust.c OpenDelta/jni/zipadjust_run.c -lz && \
        cp OpenDelta/server/minsignapk.jar OpenDelta/server/opendelta.sh delta/ && \
        chmod +x delta/opendelta.sh && \
        rm -rf OpenDelta/ && \
        sed -i -e "s|^\s*HOME=.*|HOME=$ROOT_DIR|; \
                   s|^\s*BIN_XDELTA=.*|BIN_XDELTA=xdelta3|; \
                   s|^\s*FILE_MATCH=.*|FILE_MATCH=lineage-\*.zip|; \
                   s|^\s*PATH_CURRENT=.*|PATH_CURRENT=$SRC_DIR/out/target/product/$DEVICE|; \
                   s|^\s*PATH_LAST=.*|PATH_LAST=$SRC_DIR/delta_last/$DEVICE|; \
                   s|^\s*KEY_X509=.*|KEY_X509=$KEYS_DIR/releasekey.x509.pem|; \
                   s|^\s*KEY_PK8=.*|KEY_PK8=$KEYS_DIR/releasekey.pk8|; \
                   s|publish|$DELTA_DIR|g" $ROOT_DIR/delta/opendelta.sh
fi

# Set the work directory
########################
cd $SRC_DIR

# start building
./root/init.sh

################################
#end script
