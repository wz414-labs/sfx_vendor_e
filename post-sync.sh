#!/bin/bash
##################################################################################################

# get env vars
source build/envsetup.sh

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
        sed -i -E 's/^(\s*PRODUCT_VERSION_MINOR = )(.*)/\10/g1' "vendor/$vendor/config/common.mk"
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
	echo "writing new updater conf $updater_url_overlay_dir/strings.xml" >> $DEBUG_LOG
        sed "s|{name}|updater_server_url|g; s|{url}|$OTA_URL/v1/{device}/{type}/{incr}|g" ${VENDOR_DIR}/src/packages_updater_strings.xml > "$updater_url_overlay_dir/strings.xml" | tee -a $DEBUG_LOG
      elif [ -n "$(grep conf_update_server_url_def packages/apps/Updater/res/values/strings.xml)" ]; then
        # "Old" updater configuration: just the URL
	echo "writing old updater conf $updater_url_overlay_dir/strings.xml" >> $DEBUG_LOG
        sed "s|{name}|conf_update_server_url_def|g; s|{url}|$OTA_URL|g" ${VENDOR_DIR}/src/packages_updater_strings.xml > "$updater_url_overlay_dir/strings.xml" | tee -a $DEBUG_LOG
      else
        echo ">> [$(date)] ERROR: no known Updater URL property found" | tee -a $DEBUG_LOG
        exit 1
      fi
      cat "$updater_url_overlay_dir/strings.xml" >> $DEBUG_LOG
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


    if [ -f ${ROOT_DIR}/userscripts/before.sh ]; then
      echo ">> [$(date)] Running before.sh"
      ${ROOT_DIR}/userscripts/before.sh
    fi

    codename=$EOS_DEVICE
      build_device=true
      if ! [ -z "$codename" ]; then

        if [ "$BUILD_OVERLAY" = true ]; then
          mkdir -p "$TMP_DIR/device" "$TMP_DIR/workdir" "$TMP_DIR/merged"
          mount -t overlay overlay -o lowerdir="$ANDROIDTOP",upperdir="$TMP_DIR/device",workdir="$TMP_DIR/workdir" "$TMP_DIR/merged"
          source_dir="$TMP_DIR/merged"
        else
          source_dir="$ANDROIDTOP"
        fi
        cd "$source_dir"

        if [ -f ${ROOT_DIR}/userscripts/pre-build.sh ]; then
          echo ">> [$(date)] Running pre-build.sh for $codename" >> "$DEBUG_LOG"
          ${ROOT_DIR}/userscripts/pre-build.sh $codename &>> "$DEBUG_LOG"

          if [ $? != 0 ]; then
            export build_device=false
          fi
        fi

        if [ "$build_device" = false ]; then
          echo ">> [$(date)] No build for $codename" >> "$DEBUG_LOG"
          continue
        fi

        echo "Switch back to Python3"
        PYTHONBIN=/usr/bin/python3
      fi

# breakfast it
breakfast $EOS_DEVICE

# Let the Updater allow clear text traffic if explicitly set
if [ "$EOS_OTA_CLEARTEXT" == true ];then
    OTAMANF=$(grep "android:usesCleartextTraffic=" $ANDROIDTOP/packages/apps/Updater/AndroidManifest.xml)
    if [ $? -eq 0 ];then
	echo "$OTAMANF" | grep true >> /dev/null 2>&1
	if [ $? -eq 0 ];then
	    echo Skipping OTA modding as already set
	else
	    sed -i 's/android:usesCleartextTraffic=".*"/android:usesCleartextTraffic="true"/g' $ANDROIDTOP/packages/apps/Updater/AndroidManifest.xml
	fi
    else
	sed -i '/<application/a\\tandroid:usesCleartextTraffic="true"' $ANDROIDTOP/packages/apps/Updater/AndroidManifest.xml
    fi
fi


