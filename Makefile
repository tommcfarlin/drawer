DERIVED := build
APP := $(DERIVED)/Build/Products/Release/Drawer.app
XCB := xcodebuild -project Drawer.xcodeproj -scheme Drawer -derivedDataPath $(DERIVED) -allowProvisioningUpdates

.PHONY: project build test run icon clean

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

clean:
	rm -rf $(DERIVED) Drawer.xcodeproj
