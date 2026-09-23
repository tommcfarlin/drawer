DERIVED := build
APP := $(DERIVED)/Build/Products/Release/Drawer.app
XCB := xcodebuild -project Drawer.xcodeproj -scheme Drawer -derivedDataPath $(DERIVED) -allowProvisioningUpdates

.PHONY: project build test run clean

project:
	xcodegen generate --quiet

build: project
	$(XCB) -configuration Release build

test: project
	$(XCB) -destination 'platform=macOS,arch=arm64' test

run: build
	-pkill -x Drawer
	open $(APP)

clean:
	rm -rf $(DERIVED) Drawer.xcodeproj
