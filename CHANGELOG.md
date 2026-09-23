# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-09-23

### Added
- On a MacBook with a notch, Drawer tells you how many of the drawer's icons fit beside the notch, and suggests keeping your favorites right next to `]` so they stay visible.
- Drawer's right-click menu and tooltip show how many drawer icons fit, whether the drawer is open or closed.
- When the icons outside the drawer won't all fit beside the notch, Drawer warns you and suggests moving some into the drawer.
- It needs no special permissions, never pops up on its own, and changes nothing on Macs without a notched display.

### Fixed
- Fixed an issue where the drawer would reopen when starting Drawer again after quitting with the drawer open, so it now stays closed with its archive box in place.

## [0.1.1] - 2026-09-23

### Fixed
- Fixed a bug that could hide the archive box icon when launching Drawer with the drawer closed, trapping your menu bar icons.
- Drawer now automatically reopens if the archive icon goes missing, keeping your icons accessible.

## [0.1.0] - 2026-09-23

### Added
- A drawer in your menu bar, marked by `[` and `]`, that tidies away the menu bar icons you put inside it.
- Hold Command and drag icons to add them to or remove them from the drawer.
- Click the bracket icons to open or close the drawer and show or hide its contents.
- An archive icon appears when the drawer is closed; click it to open the drawer again.
- System icons like Wi-Fi, battery, and the clock always stay visible on the right side of the menu bar.
- The drawer's own icon gently bounces when you open or close it (the archive box on close, the `]` on open), unless Reduce Motion is enabled.
- Your drawer remembers whether it was open or closed the next time you open Drawer.
- Right-click the drawer for a menu with options to open or close it, learn how to use it, view app details, and quit.
- If the drawer can't close properly, Drawer alerts you with a sound and explains how to fix it; if the menu bar is too full to show the closed drawer, Drawer reopens it and tells you why.
- If macOS ever hides the archive icon, opening Drawer again (from Finder, Spotlight, or Launchpad) opens the drawer.
- Hovering over the drawer shows a tooltip saying what a click will do.
- Works with VoiceOver and keyboard navigation for accessibility.
- Menu bar icons are crisp on all displays and adapt to light and dark menu bars.
- Requires no special permissions, collects no data, and doesn't need an internet connection.
- All text is ready for translation into other languages.
- Requires macOS 26 Tahoe or later.
