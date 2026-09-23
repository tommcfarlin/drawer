# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
