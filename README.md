# Drawer

**Throw your menu bar icons into a drawer. Pull them out when you need them.**

A tiny macOS menu bar app that hides your menu bar icons with one click and brings them back with another. There are no preferences and no permissions to grant.

> Drawer is in early development (0.1.x) and isn't available to download yet.

## How it works

Drawer adds two things to your menu bar:

- a **chevron** you click to collapse or expand, and
- a thin **`|` divider** that marks where the drawer starts.

Every icon to the **left** of the divider goes into the drawer when you collapse it. Your system icons (Wi-Fi, battery, Control Center, the clock) stay put.

```
Expanded:   [Dropbox] [1Password] [Slack]  |  ›  [Wi-Fi] [Battery] [Control Center] [Clock]
Collapsed:                                    ‹  [Wi-Fi] [Battery] [Control Center] [Clock]
```

## Setup

1. Open Drawer. The chevron and the `|` divider appear in your menu bar.
2. Hold **⌘ (Command)** and drag each icon you want hidden to the **left** of the `|` divider.
3. Click the chevron. Everything left of the divider is tucked away.

Click the chevron again whenever you need those icons back. Drawer remembers whether it was open or closed the next time you launch it.

New apps usually add their icons at the far left of the menu bar, so they end up in the drawer automatically.

**Tip:** Keep the divider to the left of the chevron. If the divider ends up on the right, Drawer won't collapse, so that the chevron can't hide itself.

## Menu

Right-click the chevron for **About Drawer** and **Quit Drawer**.

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
