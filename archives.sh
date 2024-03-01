#!/bin/bash

xcodebuild archive \
-workspace YZSDK.xcworkspace \
-scheme YZSDK \
-sdk iphoneos \
-archivePath "./archives/ios_devices.xcarchive" \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
SKIP_INSTALL=NO

xcodebuild archive \
-workspace YZSDK.xcworkspace \
-scheme YZSDK \
-sdk iphonesimulator \
-archivePath "./archives/ios_simulators.xcarchive" \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
SKIP_INSTALL=NO

xcodebuild -create-xcframework \
-framework ./archives/ios_devices.xcarchive/Products/Library/Frameworks/YZSDK.framework \
-framework ./archives/ios_simulators.xcarchive/Products/Library/Frameworks/YZSDK.framework \
-output archives/YZSDK.xcframework
