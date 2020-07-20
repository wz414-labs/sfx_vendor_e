#!/bin/bash
##################################################################################################

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


