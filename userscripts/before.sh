#!/bin/bash

cd /srv/src/MASTER
source build/envsetup.sh

repopick 195262 -f # https://review.lineageos.org/#/c/LineageOS/android_hardware_qcom_display/+/195262/
repopick 196045 -f # https://review.lineageos.org/#/c/LineageOS/android_hardware_qcom_audio/+/196045/ merged
repopick 194985 -f # https://review.lineageos.org/#/c/LineageOS/android_packages_apps_Snap/+/194985/
