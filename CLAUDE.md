# Drawer

A macOS menu bar app with a `[ … ]` drawer: icons inside it hide when the drawer closes, leaving an archive box. The product is described in `docs/prd.md` and the technical design in `docs/spec.md`; read both before starting an issue.

## Command line only

- Never require opening Xcode. Use XcodeGen, `xcodebuild`, and `make`.
- `project.yml` is the source of truth for the Xcode project. `Drawer.xcodeproj` is generated and git-ignored; never hand-edit it.
- `make project` regenerates the project; `make build`, `make test`, and `make run` regenerate it first.

## Branching & Release Workflow

- **Default branch**: `main`
- **Release branches**: `release/X.Y.Z` off `main` (current: `release/0.1.0`)
- **Issue branches**: `feature/<issue>-<slug>` off the release branch, merged back into the release branch
- **Merge flow**: issue branch -> release branch -> `main`
- **Commit format**: commitlint (e.g., `feat:`, `fix:`, `refactor:`, `docs:`, `build:`, `test:`, `chore:`)
- **Test before commit**: `make test` must pass before committing
- **Milestones**: every issue belongs to a release milestone (e.g., `v0.1.0`) or `Future State`

## Issues

Every issue has:

- a commitlint title (`feat: add toggle status item`),
- the matching commitlint label (`feat`, `fix`, `docs`, `build`, `test`, `chore`, `refactor`, `perf`, `ci`, `style`, `revert`),
- a one-to-two-sentence human summary,
- agent-ready implementation notes (files, spec sections, constraints),
- acceptance criteria as a checklist. An issue is done when every box is checked.

## Changelog

- Delegate changelog writing to a Claude Haiku subagent (`Agent` with `model: haiku`).
- Keep a Changelog format, under `## [Unreleased]` until release.
- One sentence per line, written for users, not developers: plain words, no class or function names.

## Testing

- Tests run via `make test` (`xcodebuild test -scheme Drawer -destination 'platform=macOS,arch=arm64'`)
- The test target is standalone (non-hosted); source files with pure logic are compiled directly into it
- No `@testable import` needed; test files use `import XCTest` only
- Keep decision logic in pure functions (see `DrawerState.swift`) so it's testable

## Architecture

- SwiftUI `App` entry point with `NSApplicationDelegateAdaptor`; no windows, `LSUIElement = YES`
- AppKit `NSStatusItem`s (not `MenuBarExtra`), left to right: `[` handle, `]` wall, front (SF Symbols `archivebox`, only in the menu bar while closed). All template images, never text
- Icons between the handle and the wall are in the drawer. Closing shows the front, then sets the wall's length to 10,000pt, which pushes it, the handle, and everything left of it off-screen
- A stretched item is moved entirely off-screen by macOS, and an empty item still takes 16pt and gets a hover highlight. That's why the front is separate and hidden while open; see `docs/spec.md` → How hiding works
- Before showing the front, Drawer writes `NSStatusItem Preferred Position DrawerFront` (undocumented) = the wall's saved position − 1, so it lands just right of the wall; a safety net reopens the drawer if it doesn't. Positions are the distance from the screen's right edge to the item's right edge
- Always test layout changes both on a fresh install and with dragged (saved) bracket positions; they behave differently
- The menu bar reports placeholder frames for ~250 ms after launch; restoring a closed drawer waits for positions to settle
- State is persisted in `UserDefaults` under `drawerState` (`open` / `closed`)
- The menu bar can't be clicked from the command line (no Accessibility access); verify layout with `CGWindowListCopyWindowInfo` and ask Tom to click-test
- Opening Drawer again while it's running opens the drawer (`applicationShouldHandleReopen`)
- The right-click menu is rebuilt each time it opens (`makeMenu(notice:)`); refused or failed closes are explained with a dimmed notice line, never a beep alone
- All user-facing text goes through `String(localized:)` and `Drawer/Localizable.xcstrings`; add new strings to the catalog
- Menu bar images are template images; custom ones must be pixel-aligned (see `bracketRects`)
- Notch (0.2.0): measured without permissions from the window list per display; the hint is passive (menu and tooltip only). Never open or close the drawer automatically. Revealing hidden icons needs Accessibility (#29, opt-in)
- Minimum macOS 26; universal binary; sandboxed; no permissions; no network

## Signing

- 0.1.x: automatic signing with the Apple Development certificate, team `V9DL4KN44P`. No notarization or DMG.
- 1.0.0+: Developer ID, notarized DMG on GitHub Releases.
