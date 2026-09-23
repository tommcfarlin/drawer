# Drawer

**Throw your menu bar icons into a drawer. Pull them out when you need them.**

A tiny macOS menu bar app that hides your menu bar icons with one click and brings them back with another. There are no preferences and no permissions to grant.

> Drawer is in early development (0.1.x) and isn't available to download yet.

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

Drawer remembers whether the drawer was open or closed the next time you launch it.

To keep an icon visible all the time, ⌘-drag it to the right of the `]`.

Before you start, read [Good to know](#good-to-know): closing the drawer also hides anything to the left of `[`.

## Good to know

- **Keep the `[` at the far left of your icons.** Closing the drawer also hides anything to the left of `[`. New apps usually add their icons at the far left, so if one shows up outside the drawer, drag it in (or to the right of `]`).
- **Keep `[` to the left of `]`.** If they get swapped, Drawer won't close; it beeps and tells you how to fix it.
- **Can't find the archive box?** macOS sometimes hides menu bar icons when the menu bar is crowded. Open Drawer again (from Finder, Spotlight, or Launchpad) and the drawer opens.

## Menu

Right-click (or Control-click) `[`, `]`, or the archive box for:

- **Close Drawer** / **Open Drawer**
- **How to Use Drawer…** (opens this page)
- **About Drawer**
- **Quit Drawer**

Hover over any of them to see what a click will do.

## Requirements

- macOS 26 Tahoe or later

## Building

Everything builds from the command line; you never need to open Xcode.

Requirements: Xcode 27 command line tools and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
make build   # generate the project and build
make test    # run the unit tests
make run     # build and launch
```

## Support

Having issues or feedback? Email [support@pressware.co](mailto:support@pressware.co).

## Author

Made by [Tom McFarlin](https://tommcfarlin.com)

## License

Copyright 2026 Tom McFarlin. All rights reserved.
