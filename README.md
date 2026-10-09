# Drawer

**Throw your menu bar icons into a drawer. Pull them out when you need them.**

A tiny macOS menu bar app that hides your menu bar icons with one click and brings them back with another. There are no preferences. On macOS 27, Drawer asks once for Accessibility access; on macOS 26 it needs no permissions at all.

## Download

[Download Drawer for Mac](https://github.com/tommcfarlin/drawer/releases/latest/download/Drawer.dmg) (macOS 26 Tahoe or later).

Open the DMG and drag Drawer into Applications. Drawer is signed with Developer ID and notarized by Apple.

> Drawer is in early development (0.x). Expect rough edges, and email [support@pressware.co](mailto:support@pressware.co) if you find one.

## How it works

Drawer adds a pair of brackets to your menu bar: `[` on the left, `]` on the right. Anything you put between them is **in the drawer**.

```
Open:    [ Dropbox 1Password Slack ]  Wi-Fi Battery Control-Center Clock
Closed:                     (archive box)  Wi-Fi Battery Control-Center Clock
```

Click the drawer to close it, and everything inside disappears, leaving a small archive box. Click the box to open it again.

## Setup

1. Open Drawer. A `[` and a `]` appear side by side in your menu bar.
2. Hold **⌘ (Command)** and drag each icon you want to hide into the drawer, between `[` and `]`.
3. Click `[` or `]` to close the drawer.
4. On macOS 27, the first time you close it, macOS asks you to allow Drawer in **System Settings → Privacy & Security → Accessibility**. Turn Drawer on, then click again. Drawer uses this only to see which icons are between `[` and `]`.

Drawer remembers whether the drawer was open or closed the next time you launch it.

To keep an icon visible all the time, ⌘-drag it to the right of the `]`.

Before you start, read [Good to know](#good-to-know): on macOS 26, closing the drawer also hides anything to the left of `[`.

## Good to know

- **Keep `[` to the left of `]`.** If they get swapped, Drawer won't close; it beeps and tells you how to fix it.
- **Can't find the archive box?** macOS sometimes hides menu bar icons when the menu bar is crowded. Open Drawer again (from Finder, Spotlight, or Launchpad) and the drawer opens.
- **Quitting Drawer always brings your icons back.**

### On macOS 27

- **Drawer hides whole apps.** If an app has one icon inside the drawer and another outside it, both hide while the drawer is closed.
- **System icons stay visible.** Icons that belong to macOS itself (like Bluetooth or the clock) don't hide, even inside the drawer. AirDrop, Focus, and Now Playing are hidden while the drawer is closed, wherever they are.
- **Run Drawer from your Applications folder.** Otherwise macOS doesn't show the archive box while the drawer is closed.
- **Icons left of `[` stay visible**, and new apps show their icons even while the drawer is closed.

### On macOS 26

- **Keep the `[` at the far left of your icons.** Closing the drawer also hides anything to the left of `[`. New apps usually add their icons at the far left, so if one shows up outside the drawer, drag it in (or to the right of `]`).
- **On a MacBook with a notch,** icons that don't fit beside the notch are hidden by macOS, starting with the drawer's leftmost ones. Keep your favorites right next to `]`: Drawer's menu tells you how many fit.

## Menu

Right-click (or Control-click) `[`, `]`, or the archive box for:

- **Close Drawer** / **Open Drawer**
- **How to Use Drawer…** (opens this page)
- **About Drawer**
- **Quit Drawer**

Hover over any of them to see what a click will do.

## Requirements

- macOS 26 Tahoe or later
- On macOS 27: Accessibility access (Drawer asks the first time you close it)

## Building

Everything builds from the command line; you never need to open Xcode.

Requirements: Xcode 27 command line tools and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
make build   # generate the project and build
make test    # run the unit tests
make run     # build and launch
```

### Releasing

`make release` builds a Developer ID-signed, notarized, and stapled `build/Drawer.dmg`. It needs the Developer ID Application certificate in your keychain and a one-time notary profile:

```bash
xcrun notarytool store-credentials drawer-notary --apple-id <email> --team-id V9DL4KN44P
```

Upload the DMG to the GitHub Release as `Drawer.dmg` (no version in the name) so the download link always gets the latest version.

## Support

Having issues or feedback? Email [support@pressware.co](mailto:support@pressware.co).

## Author

Made by [Tom McFarlin](https://tommcfarlin.com)

## License

Copyright 2026 Tom McFarlin. All rights reserved.
