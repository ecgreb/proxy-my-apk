#!/bin/bash
#
# This script decompiles a release APK and modifies the contents to make the app debuggable
# and adds the required network configuration to allow HTTP proxying on Android N and above.
#
# It the recompiles, runs zip align, and signs the new APK using the local debug keystore.
#
# Prerequisites:
#  * Android SDK https://developer.android.com/studio/
#  * Apktool https://ibotpeaches.github.io/Apktool/
#
# Usage:
#   proxy-my-app.sh <app-name-release.apk>
#
# Example:
#   proxy-my-app.sh gallery-production-release-0.1.0.apk

if [[ $# -eq 0 ]]; then
    echo "Usage: ${0} <app-name-release.apk>"
    exit 1
fi

CURRENT_TOOLS=`ls /Users/$USER/Library/Android/sdk/build-tools | egrep '^([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?$' | sort -rn | head -1`

export PATH="$PATH:/usr/local/bin/"
export PATH="$PATH:/Users/$USER/Library/Android/sdk/platform-tools"
export PATH="$PATH:/Users/$USER/Library/Android/sdk/build-tools/$CURRENT_TOOLS"

APK=$1
APK_NAME="${APK:0:${#APK}-4}"
APK_NAME_FINAL=$APK_NAME-debug
LOG_FILE=./proxy-log.log

echo "Decompiling $APK into $APK_NAME"
mkdir -p /Users/$USER/Library/apktool/framework >> $LOG_FILE
apktool d -s $APK -o $APK_NAME >> $LOG_FILE

echo "Editing $APK_NAME/AndroidManifest.xml"
sed -i .bak 's/<application /<application android:networkSecurityConfig="@xml\/network_security_config" /' $APK_NAME/AndroidManifest.xml >> $LOG_FILE

echo "Copying assets/network_security_config.xml into $APK_NAME/res/xml/network_security_config.xml"
mkdir -p $APK_NAME/res/xml >> $LOG_FILE
cp $APK_NAME/../assets/network_security_config.xml $APK_NAME/res/xml/network_security_config.xml >> $LOG_FILE

echo "Recompiling $APK_NAME into $APK_NAME_FINAL-unsigned-unaligned.apk"
apktool b -d $APK_NAME -o $APK_NAME_FINAL-unsigned-unaligned.apk >> $LOG_FILE
rm -rf $APK_NAME

echo "Zipaligning $APK_NAME_FINAL-unsigned-unaligned.apk into $APK_NAME_FINAL-unsigned.apk"
zipalign -v -p 4 $APK_NAME_FINAL-unsigned-unaligned.apk $APK_NAME_FINAL-unsigned.apk >> $LOG_FILE
rm $APK_NAME_FINAL-unsigned-unaligned.apk

echo "Signing $APK_NAME_FINAL-unsigned.apk into $APK_NAME_FINAL.apk"
apksigner sign -ks-pass pass:android -ks ~/.android/debug.keystore --out $APK_NAME_FINAL.apk $APK_NAME_FINAL-unsigned.apk >> $LOG_FILE
rm $APK_NAME_FINAL-unsigned.apk

echo Done
apktool empty-framework-dir >> $LOG_FILE