#!/bin/bash
cd ~/Desktop/project/smash/frontend/app

flutter pub get

PACKAGE_SWIFT="ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

if [ -f "$PACKAGE_SWIFT" ]; then
    sed -i '' 's/.iOS("13.0")/.iOS("15.0")/g' "$PACKAGE_SWIFT"
    echo "Fixed Package.swift iOS version to 15.0"
fi

flutter run -d 00008140-000639C60146801C
