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
    grep -q "PRODUCT_PACKAGE_OVERLAYS := vendor/$vendor/overlay/microg" vendor/$vendor/config/common.mk
    [ $? -ne 0 ] && sed -i "1s;^;PRODUCT_PACKAGE_OVERLAYS := vendor/$vendor/overlay/microg\n;" "vendor/$vendor/config/common.mk"

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

    if [ "$SIGN_BUILDS" = true ]; then
      echo ">> [$(date)] Adding keys path ($KEYS_DIR)"
      # Soong (Android 9+) complains if the signing keys are outside the build path
      ln -sf "$KEYS_DIR" user-keys
      grep -q "PRODUCT_DEFAULT_DEV_CERTIFICATE := user-keys/releasekey" vendor/$vendor/config/common.mk
      [ $? -ne 0 ] && sed -i "1s;^;PRODUCT_DEFAULT_DEV_CERTIFICATE := user-keys/releasekey\n;" vendor/$vendor/config/common.mk
      grep -q "PRODUCT_OTA_PUBLIC_KEYS := user-keys/releasekey" vendor/$vendor/config/common.mk
      [ $? -ne 0 ] && sed -i "1s;^;PRODUCT_OTA_PUBLIC_KEYS := user-keys/releasekey\n;" vendor/$vendor/config/common.mk
      grep -q "PRODUCT_EXTRA_RECOVERY_KEYS := user-keys/releasekey" vendor/$vendor/config/common.mk
      [ $? -ne 0 ] && sed -i "1s;^;PRODUCT_EXTRA_RECOVERY_KEYS := user-keys/releasekey\n;" vendor/$vendor/config/common.mk
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
echo BREAKFAST $EOS_DEVICE ...
breakfast $EOS_DEVICE >> $DEBUG_LOG 2>&1

# Let the Updater allow clear text traffic if explicitly set
if [ "$EOS_OTA_CLEARTEXT" == true ];then
    OTAMANF=$(grep "android:usesCleartextTraffic=" $ANDROIDTOP/packages/apps/Updater/AndroidManifest.xml)
    if [ $? -eq 0 ];then
	echo "$OTAMANF" | grep true >> /dev/null 2>&1
	if [ $? -eq 0 ];then
	    echo Skipping setting OTA to cleartext as already set >> $DEBUG_LOG
	else
	    sed -i 's/android:usesCleartextTraffic=".*"/android:usesCleartextTraffic="true"/g' $ANDROIDTOP/packages/apps/Updater/AndroidManifest.xml 2>> $DEBUG_LOG
	fi
    else
	sed -i '/<application/a\\tandroid:usesCleartextTraffic="true"' $ANDROIDTOP/packages/apps/Updater/AndroidManifest.xml 2>> $DEBUG_LOG
    fi
fi


