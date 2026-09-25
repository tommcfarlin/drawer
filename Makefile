DERIVED := build
APP := $(DERIVED)/Build/Products/Release/Drawer.app
XCB := xcodebuild -project Drawer.xcodeproj -scheme Drawer -derivedDataPath $(DERIVED) -allowProvisioningUpdates

ARCHIVE := $(DERIVED)/Drawer.xcarchive
EXPORT := $(DERIVED)/export
DMG := $(DERIVED)/Drawer.dmg
DMG_STAGE := $(DERIVED)/dmg
NOTARY_PROFILE ?= drawer-notary
DEVELOPER_ID := Developer ID Application: Tom McFarlin (V9DL4KN44P)

.PHONY: project build test run icon clean release

project:
	xcodegen generate --quiet

build: project
	$(XCB) -configuration Release build

test: project
	$(XCB) -destination 'platform=macOS,arch=arm64' test

run: build
	-pkill -x Drawer
	open $(APP)

ICONSET := Drawer/Assets.xcassets/AppIcon.appiconset

icon:
	mkdir -p $(DERIVED)
	swift scripts/make-icon.swift $(DERIVED)/icon-1024.png
	for s in 16 32 128 256 512; do \
		sips -z $$s $$s $(DERIVED)/icon-1024.png --out $(ICONSET)/icon_$${s}x$${s}.png >/dev/null; \
		d=$$((s * 2)); \
		sips -z $$d $$d $(DERIVED)/icon-1024.png --out $(ICONSET)/icon_$${s}x$${s}@2x.png >/dev/null; \
	done
	cp scripts/AppIcon.Contents.json $(ICONSET)/Contents.json

# Developer ID-signed, notarized, stapled DMG at build/Drawer.dmg.
# One-time setup: xcrun notarytool store-credentials drawer-notary --apple-id <email> --team-id V9DL4KN44P
release: project
	rm -rf $(ARCHIVE) $(EXPORT) $(DMG_STAGE) $(DMG)
	$(XCB) -quiet -configuration Release archive -archivePath $(ARCHIVE)
	xcodebuild -exportArchive -archivePath $(ARCHIVE) -exportPath $(EXPORT) -exportOptionsPlist scripts/ExportOptions.plist
	# Staple the app too, so it passes Gatekeeper offline once it's copied out of the DMG.
	ditto -c -k --keepParent $(EXPORT)/Drawer.app $(EXPORT)/Drawer.zip
	xcrun notarytool submit $(EXPORT)/Drawer.zip --keychain-profile $(NOTARY_PROFILE) --wait
	xcrun stapler staple $(EXPORT)/Drawer.app
	mkdir -p $(DMG_STAGE)
	cp -R $(EXPORT)/Drawer.app $(DMG_STAGE)/
	ln -s /Applications $(DMG_STAGE)/Applications
	hdiutil create -volname Drawer -srcfolder $(DMG_STAGE) -fs HFS+ -format UDZO -ov $(DMG)
	codesign --sign "$(DEVELOPER_ID)" --timestamp $(DMG)
	xcrun notarytool submit $(DMG) --keychain-profile $(NOTARY_PROFILE) --wait
	xcrun stapler staple $(DMG)
	xcrun stapler validate $(DMG)
	spctl --assess --type open --context context:primary-signature --verbose $(DMG)

clean:
	rm -rf $(DERIVED) Drawer.xcodeproj
