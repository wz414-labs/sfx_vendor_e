#!/bin/bash

# cd to working directory
cd "$ANDROIDTOP"
codename=$EOS_DEVICE

        echo ">> [$(date)] finalizing build for $codename, $BRANCH_NAME branch" | tee -a "$DEBUG_LOG"
        build_successful=false
        echo "ANDROID_JACK_VM_ARGS=${ANDROID_JACK_VM_ARGS}"
        echo "Switch to Python2"
        PYTHONBIN=/usr/bin/python2
        currentdate=$(date +%Y%m%d)
	  echo "EOS_BUILD_DATE: $EOS_BUILD_DATE" >> $DEBUG_LOG
          if [ "$EOS_BUILD_DATE" != "$currentdate" ]; then
            find out/target/product/$codename -maxdepth 1 -name "e-*-$currentdate-*.zip*" -type f -exec sh ${VENDOR_DIR}/src/fix_build_date.sh {} $currentdate $EOS_BUILD_DATE \; &>> "$DEBUG_LOG"
          fi

          # Move produced ZIP files to the main OUT directory
          echo ">> [$(date)] Moving build artifacts for $codename to '$ZIP_DIR/$zipsubdir'" | tee -a "$DEBUG_LOG"
          cd out/target/product/$codename
          for build in e-*.zip; do
            sha256sum "$build" > "$ZIP_DIR/$zipsubdir/$build.sha256sum"
          done
          find . -maxdepth 1 -name 'e-*.zip*' -type f -exec mv {} "$ZIP_DIR/$zipsubdir/" \; &>> "$DEBUG_LOG"

if [ "$RECOVERY_IMG" = true ]; then
    if [ -f "recovery.img" ]; then
        cp -a recovery.img "$ZIP_DIR/$zipsubdir/recovery-${build%.*}.img"
    else
        cp -a boot.img "$ZIP_DIR/$zipsubdir/recovery-${build%.*}.img"
    fi
fi

          cd "$source_dir"
          build_successful=true

        # Remove old zips and logs
        if [ "$DELETE_OLD_ZIPS" -gt "0" ]; then
          if [ "$ZIP_SUBDIR" = true ]; then
            $PYTHONBIN ${VENDOR_DIR}/src/clean_up.py -n $DELETE_OLD_ZIPS -V $los_ver -N 1 "$ZIP_DIR/$zipsubdir"
          else
            $PYTHONBIN ${VENDOR_DIR}/src/clean_up.py -n $DELETE_OLD_ZIPS -V $los_ver -N 1 -c $codename "$ZIP_DIR"
          fi
        fi
        if [ "$DELETE_OLD_LOGS" -gt "0" ]; then
          if [ "$LOGS_SUBDIR" = true ]; then
            $PYTHONBIN ${VENDOR_DIR}/src/clean_up.py -n $DELETE_OLD_LOGS -V $los_ver -N 1 "$LOGS_DIR/$logsubdir"
          else
            $PYTHONBIN ${VENDOR_DIR}/src/clean_up.py -n $DELETE_OLD_LOGS -V $los_ver -N 1 -c $codename "$LOGS_DIR"
          fi
        fi
        if [ -f ${ROOT_DIR}/userscripts/post-build.sh ]; then
          echo ">> [$(date)] Running post-build.sh for $codename" >> "$DEBUG_LOG"
          ${ROOT_DIR}/userscripts/post-build.sh $codename $build_successful &>> "$DEBUG_LOG"
        fi
        echo ">> [$(date)] Finishing build for $codename" | tee -a "$DEBUG_LOG"

        if [ "$BUILD_OVERLAY" = true ]; then
          # The Jack server must be stopped manually, as we want to unmount $TMP_DIR/merged
          cd "$TMP_DIR"
          if [ -f "$TMP_DIR/merged/prebuilts/sdk/tools/jack-admin" ]; then
            "$TMP_DIR/merged/prebuilts/sdk/tools/jack-admin kill-server" &> /dev/null || true
          fi
          lsof | grep "$TMP_DIR/merged" | awk '{ print $2 }' | sort -u | xargs -r kill &> /dev/null

          while [ -n "$(lsof | grep $TMP_DIR/merged)" ]; do
            sleep 1
          done

          umount "$TMP_DIR/merged"
        fi

        if [ "$CLEAN_AFTER_BUILD" == "true" ]; then
	    echo -e '\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
	    echo      '********          /e/ - CLEAN OUT DIR (after)               ********'
	    echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'

          echo ">> [$(date)] Cleaning source dir for device $codename" | tee -a "$DEBUG_LOG"
          if [ "$BUILD_OVERLAY" = true ]; then
            cd "$TMP_DIR" && rm -rf ./*
          else
            cd "$source_dir" && mka clean &>> "$DEBUG_LOG"
          fi
        fi

        echo "Switch back to Python3"
        PYTHONBIN=/usr/bin/python3

if [ "$DELETE_OLD_LOGS" -gt "0" ]; then
  find "$LOGS_DIR" -maxdepth 1 -name repo-*.log | sort | head -n -$DELETE_OLD_LOGS | xargs -r rm
fi

if [ -f ${ROOT_DIR}/userscripts/end.sh ]; then
  echo ">> [$(date)] Running end.sh"
  ${ROOT_DIR}/userscripts/end.sh
fi

if [ "$build_successful" = false ] || [ "$sync_successful" = false ]; then
  exit 1
fi
