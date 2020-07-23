#!/bin/bash

# Copyright (c) 2017 Julian Xhokaxhiu
# Copyright (C) 2017-2018 Nicola Corna <nicola@corna.info>
# Copyright (C) 2020 eCorp Romain HUNAULT <romain.hunaul@e.email>
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

# get env vars
source build/envsetup.sh

repo_log="$LOGS_DIR/repo-$(date +%Y%m%d).log"

# cd to working directory
cd "$ANDROIDTOP"

if [ -f ${ROOT_DIR}/userscripts/begin.sh ]; then
  echo ">> [$(date)] Running begin.sh"
  ${ROOT_DIR}/userscripts/begin.sh
fi

# If requested, clean the OUT dir in order to avoid clutter
if [ "$CLEAN_OUTDIR" = true ]; then
  echo ">> [$(date)] Cleaning '$ZIP_DIR'"
  rm -rf "$ZIP_DIR/"*
fi

sync_successful=true

if [ "$LOCAL_MIRROR" = true ]; then

  cd "$MIRROR_DIR"

  if [ ! -d .repo ]; then
    echo ">> [$(date)] Initializing mirror repository" | tee -a "$repo_log"
    yes | repo init -u "$MIRROR" --mirror --no-clone-bundle -p linux &>> "$repo_log"
  fi

  # Copy local manifests to the appropriate folder in order take them into consideration
  echo ">> [$(date)] Copying '$LMANIFEST_DIR/*.xml' to '.repo/local_manifests/'"
  mkdir -p .repo/local_manifests
  rsync -a --delete --include '*.xml' --exclude '*' "$LMANIFEST_DIR/" .repo/local_manifests/

  rm -f .repo/local_manifests/proprietary.xml
  if [ "$INCLUDE_PROPRIETARY" = true ]; then
    wget -q -O .repo/local_manifests/proprietary.xml "https://raw.githubusercontent.com/TheMuppets/manifests/mirror/default.xml"
  fi

  echo ">> [$(date)] Syncing mirror repository" | tee -a "$repo_log"
  repo sync --force-sync --no-clone-bundle &>> "$repo_log"

  if [ $? != 0 ]; then
    sync_successful=false
  fi
fi

  if [ -n "$BRANCH_NAME" ] && [ -n "$EOS_DEVICE" ]; then

    cd "$ANDROIDTOP"

    echo ">> [$(date)] Branch:  $BRANCH_NAME"
    echo ">> [$(date)] Devices: $EOS_DEVICE"

    # Remove previous changes of vendor/cm, vendor/lineage and frameworks/base (if they exist)
    for path in "vendor/cm" "vendor/lineage" "frameworks/base"; do
      if [ -d "$path" ]; then
        cd "$path"
        git reset -q --hard
        git clean -q -fd
        cd "$ANDROIDTOP"
      fi
    done

    echo ">> [$(date)] (Re)initializing branch repository" | tee -a "$repo_log"
    if [ "$LOCAL_MIRROR" = true ]; then
      yes | repo init -u "$REPO" --reference "$MIRROR_DIR" -b "$BRANCH_NAME" &>> "$repo_log"
    else
      TAG_PREFIX=""
      curl https://gitlab.e.foundation/api/v4/projects/659/repository/tags | grep "\"name\":\"$BRANCH_NAME\""
      if [ $? == 0 ]
      then
        echo "Branch name $BRANCH_NAME is a tag on e/os/releases, prefix with refs/tags/ for 'repo init'"
        TAG_PREFIX="refs/tags/"
      fi

      yes | repo init -u "$REPO" -b "${TAG_PREFIX}$BRANCH_NAME" &>> "$repo_log"
    fi

    rm -f .repo/local_manifests/proprietary.xml
    if [ "$INCLUDE_PROPRIETARY" = true ]; then
      if [[ $BRANCH_NAME =~ nougat$ ]]; then
        themuppets_branch=cm-14.1
        echo ">> [$(date)] Use branch $themuppets_branch on github.com/TheMuppets"
      elif [[ $BRANCH_NAME =~ oreo$ ]]; then
        themuppets_branch=lineage-15.1
        echo ">> [$(date)] Use branch $themuppets_branch on github.com/TheMuppets"
      elif [[ $BRANCH_NAME =~ pie$ ]]; then
        themuppets_branch=lineage-16.0
        echo ">> [$(date)] Use branch $themuppets_branch on github.com/TheMuppets"
      else
        themuppets_branch=cm-14.1
        echo ">> [$(date)] Can't find a matching branch on github.com/TheMuppets, using $themuppets_branch"
      fi
      wget -q -O .repo/local_manifests/proprietary.xml "https://raw.githubusercontent.com/TheMuppets/manifests/$themuppets_branch/muppets.xml"
    fi

    echo ">> [$(date)] Syncing branch repository" | tee -a "$repo_log"
    builddate=$(date +%Y%m%d)
    repo sync -c --force-sync &>> "$repo_log"

    if [ $? != 0 ]; then
      sync_successful=false
    fi

    android_version=$(sed -n -e 's/^\s*PLATFORM_VERSION\.OPM1 := //p' build/core/version_defaults.mk)
    if [ -z $android_version ]; then
      android_version=$(sed -n -e 's/^\s*PLATFORM_VERSION\.PPR1 := //p' build/core/version_defaults.mk)
      if [ -z $android_version ]; then
        android_version=$(sed -n -e 's/^\s*PLATFORM_VERSION := //p' build/core/version_defaults.mk)
        if [ -z $android_version ]; then
          echo ">> [$(date)] Can't detect the android version"
          exit 1
        fi
      fi
    fi
    android_version_major=$(cut -d '.' -f 1 <<< $android_version)

    if [ "$android_version_major" -ge "8" ]; then
      vendor="lineage"
    else
      vendor="cm"
    fi

    if [ ! -d "vendor/$vendor" ]; then
      echo ">> [$(date)] Missing \"vendor/$vendor\", aborting"
      exit 1
    fi

    # Set up our overlay
    mkdir -p "vendor/$vendor/overlay/microg/"
    sed -i "1s;^;PRODUCT_PACKAGE_OVERLAYS := vendor/$vendor/overlay/microg\n;" "vendor/$vendor/config/common.mk"

    # change version on the dynamic branch
    if [ "$BRANCH_NAME" == "v1-pie" ];then
        sed -i -E 's/^(\s*PRODUCT_VERSION_MAJOR = )([0-9]+)/\11/g1' "vendor/$vendor/config/common.mk"
        sed -i -E 's/^(\s*PRODUCT_VERSION_MINOR = )([0-9]+)/\1BETA/g1' "vendor/$vendor/config/common.mk"
        sed -i -E 's/^(\s*PRODUCT_VERSION_MAINTENANCE = )([0-9]+)/\1x/g1' "vendor/$vendor/config/common.mk"
    fi

    # parse ROM version
    los_ver_major=$(sed -n -e 's/^\s*PRODUCT_VERSION_MAJOR = //p' "vendor/$vendor/config/common.mk")
    los_ver_minor=$(sed -n -e 's/^\s*PRODUCT_VERSION_MINOR = //p' "vendor/$vendor/config/common.mk")
    los_ver="$los_ver_major.$los_ver_minor"

    echo ">> [$(date)] Setting \"$RELEASE_TYPE\" as release type"
    sed -i "/\$(filter .*\$(${vendor^^}_BUILDTYPE)/,+2d" "vendor/$vendor/config/common.mk"

    # Set a custom updater URI if a OTA URL is provided
    echo ">> [$(date)] Adding OTA URL overlay (for custom URL $OTA_URL)"
    if ! [ -z "$OTA_URL" ]; then
      updater_url_overlay_dir="vendor/$vendor/overlay/microg/packages/apps/Updater/res/values/"
      mkdir -p "$updater_url_overlay_dir"

      if [ -n "$(grep updater_server_url packages/apps/Updater/res/values/strings.xml)" ]; then
        # "New" updater configuration: full URL (with placeholders {device}, {type} and {incr})
        sed "s|{name}|updater_server_url|g; s|{url}|$OTA_URL/v1/{device}/{type}/{incr}|g" ${VENDOR_DIR}/src/packages_updater_strings.xml > "$updater_url_overlay_dir/strings.xml"
      elif [ -n "$(grep conf_update_server_url_def packages/apps/Updater/res/values/strings.xml)" ]; then
        # "Old" updater configuration: just the URL
        sed "s|{name}|conf_update_server_url_def|g; s|{url}|$OTA_URL|g" ${VENDOR_DIR}/src/packages_updater_strings.xml > "$updater_url_overlay_dir/strings.xml"
      else
        echo ">> [$(date)] ERROR: no known Updater URL property found"
        exit 1
      fi
    fi

    if [ "$SIGN_BUILDS" = true ]; then
      echo ">> [$(date)] Adding keys path ($KEYS_DIR)"
      # Soong (Android 9+) complains if the signing keys are outside the build path
      ln -sf "$KEYS_DIR" user-keys
      sed -i "1s;^;PRODUCT_DEFAULT_DEV_CERTIFICATE := user-keys/releasekey\nPRODUCT_OTA_PUBLIC_KEYS := user-keys/releasekey\nPRODUCT_EXTRA_RECOVERY_KEYS := user-keys/releasekey\n\n;" "vendor/$vendor/config/common.mk"
    fi

    if [ "$android_version_major" -ge "7" ]; then
      jdk_version=8
    elif [ "$android_version_major" -ge "5" ]; then
      jdk_version=7
    else
      echo ">> [$(date)] ERROR: $BRANCH_NAME requires a JDK version too old (< 7); aborting"
      exit 1
    fi

    echo ">> [$(date)] Using OpenJDK $jdk_version"
    update-java-alternatives -s java-1.$jdk_version.0-openjdk-amd64 &> /dev/null

    # Prepare the environment
    echo ">> [$(date)] Preparing build environment"
    $VENDOR_DIR/vendorsetup.sh --reset > /dev/null
    source build/envsetup.sh > /dev/null

    if [ -f ${ROOT_DIR}/userscripts/before.sh ]; then
      echo ">> [$(date)] Running before.sh"
      ${ROOT_DIR}/userscripts/before.sh
    fi

    for codename in $EOS_DEVICE; do
      build_device=true
      if ! [ -z "$codename" ]; then

        currentdate=$(date +%Y%m%d)
        if [ "$builddate" != "$currentdate" ]; then
          # Sync the source code
          builddate=$currentdate

          if [ "$LOCAL_MIRROR" = true ]; then
            echo ">> [$(date)] Syncing mirror repository" | tee -a "$repo_log"
            cd "$MIRROR_DIR"
            repo sync --force-sync --no-clone-bundle &>> "$repo_log"

            if [ $? != 0 ]; then
              sync_successful=false
              build_device=false
            fi
          fi

          echo ">> [$(date)] Syncing branch repository" | tee -a "$repo_log"
          cd "$ANDROIDTOP"
          repo sync -c --force-sync &>> "$repo_log"

          if [ $? != 0 ]; then
            sync_successful=false
            build_device=false
          fi
        fi

        if [ "$BUILD_OVERLAY" = true ]; then
          mkdir -p "$TMP_DIR/device" "$TMP_DIR/workdir" "$TMP_DIR/merged"
          mount -t overlay overlay -o lowerdir="$ANDROIDTOP",upperdir="$TMP_DIR/device",workdir="$TMP_DIR/workdir" "$TMP_DIR/merged"
          source_dir="$TMP_DIR/merged"
        else
          source_dir="$ANDROIDTOP"
        fi
        cd "$source_dir"

        if [ "$ZIP_SUBDIR" = true ]; then
          zipsubdir=$codename
          mkdir -p "$ZIP_DIR/$zipsubdir"
        else
          zipsubdir=
        fi
        if [ "$LOGS_SUBDIR" = true ]; then
          logsubdir=$codename
          mkdir -p "$LOGS_DIR/$logsubdir"
        else
          logsubdir=
        fi

        DEBUG_LOG="$LOGS_DIR/$logsubdir/e-$los_ver-$builddate-$RELEASE_TYPE-$codename.log"

        if [ -f ${ROOT_DIR}/userscripts/pre-build.sh ]; then
          echo ">> [$(date)] Running pre-build.sh for $codename" >> "$DEBUG_LOG"
          ${ROOT_DIR}/userscripts/pre-build.sh $codename &>> "$DEBUG_LOG"

          if [ $? != 0 ]; then
            build_device=false
          fi
        fi

        if [ "$build_device" = false ]; then
          echo ">> [$(date)] No build for $codename" >> "$DEBUG_LOG"
          continue
        fi

        echo "Switch back to Python3"
        PYTHONBIN=/usr/bin/python3
      fi
    done
  fi
