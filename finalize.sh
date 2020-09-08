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

          if [ "$BUILD_DELTA" = true ]; then
            if [ -d "delta_last/$codename/" ]; then
              # If not the first build, create delta files
              echo ">> [$(date)] Generating delta files for $codename" | tee -a "$DEBUG_LOG"
              cd ${ROOT_DIR}/delta
              if ./opendelta.sh $codename &>> "$DEBUG_LOG"; then
                echo ">> [$(date)] Delta generation for $codename completed" | tee -a "$DEBUG_LOG"
              else
                echo ">> [$(date)] Delta generation for $codename failed" | tee -a "$DEBUG_LOG"
              fi
              if [ "$DELETE_OLD_DELTAS" -gt "0" ]; then
                $PYTHONBIN ${VENDOR_DIR}/src/clean_up.py -n $DELETE_OLD_DELTAS -V $los_ver -N 1 "$DELTA_DIR/$codename" &>> $DEBUG_LOG
              fi
              cd "$source_dir"
            else
              # If the first build, copy the current full zip in $source_dir/delta_last/$codename/
              echo ">> [$(date)] No previous build for $codename; using current build as base for the next delta" | tee -a "$DEBUG_LOG"
              mkdir -p $SRC_DIR/delta_last/$codename/ &>> "$DEBUG_LOG"
              find out/target/product/$codename -maxdepth 1 -name 'e-*.zip' -type f -exec cp {} "$SRC_DIR/delta_last/$codename/" \; &>> "$DEBUG_LOG"
            fi
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

# Create the OpenDelta's builds JSON file
if ! [ -z "$OPENDELTA_BUILDS_JSON" ]; then
  echo ">> [$(date)] Creating OpenDelta's builds JSON file (ZIP_DIR/$OPENDELTA_BUILDS_JSON)"
  if [ "$ZIP_SUBDIR" != true ]; then
    echo ">> [$(date)] WARNING: OpenDelta requires zip builds separated per device! You should set ZIP_SUBDIR to true"
  fi
  $PYTHONBIN ${VENDOR_DIR}/src/opendelta_builds_json.py "$ZIP_DIR" -o "$ZIP_DIR/$OPENDELTA_BUILDS_JSON"
fi

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
