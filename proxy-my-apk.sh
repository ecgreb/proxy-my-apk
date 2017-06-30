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
#  * Add Android SDK build tools to your executable path (zipalign, apksigner)
#
#        export PATH="$PATH:$ANDROID_HOME/build-tools/25.0.3"
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

APK=$1
APK_NAME="${APK:0:${#APK}-4}"
APK_NAME_FINAL=$APK_NAME-debug
LOG_FILE=/usr/local/code/proxy-my-apk/proxy-my-apk.log

echo "Decompiling $APK into $APK_NAME"
/usr/local/bin/apktool d -s $APK -o $APK_NAME >> $LOG_FILE

echo "Editing $APK_NAME/AndroidManifest.xml"
sed -i .bak 's/<application /<application android:networkSecurityConfig="@xml\/network_security_config" /' $APK_NAME/AndroidManifest.xml >> $LOG_FILE

echo "Copying assets/network_security_config.xml into $APK_NAME/res/xml/network_security_config.xml"
cp $APK_NAME/../assets/network_security_config.xml $APK_NAME/res/xml/network_security_config.xml >> $LOG_FILE

echo "Recompiling $APK_NAME into $APK_NAME_FINAL-unsigned-unaligned.apk"
/usr/local/bin/apktool b -d $APK_NAME -o $APK_NAME_FINAL-unsigned-unaligned.apk >> $LOG_FILE
rm -rf $APK_NAME

echo "Zipaligning $APK_NAME_FINAL-unsigned-unaligned.apk into $APK_NAME_FINAL-unsigned.apk"
/Users/ecgreb/Library/Android/sdk/build-tools/25.0.3/zipalign -v -p 4 $APK_NAME_FINAL-unsigned-unaligned.apk $APK_NAME_FINAL-unsigned.apk >> $LOG_FILE
rm $APK_NAME_FINAL-unsigned-unaligned.apk

echo "Signing $APK_NAME_FINAL-unsigned.apk into $APK_NAME_FINAL.apk"
echo android | /Users/ecgreb/Library/Android/sdk/build-tools/25.0.3/apksigner sign -ks ~/.android/debug.keystore --out $APK_NAME_FINAL.apk $APK_NAME_FINAL-unsigned.apk >> $LOG_FILE
rm $APK_NAME_FINAL-unsigned.apk

echo Done
