# Drawer — Product Requirements Document

**Version:** 0.1.0 (personal build; 1.0.0 is the first public release)
**Author:** Tom McFarlin
**Status:** Draft
**Last updated:** 2026-09-23

## Summary

Drawer is a tiny macOS menu bar utility that tucks third-party menu bar icons out of sight with a single click, and brings them back with another. It is deliberately simple: one toggle, one divider, no preferences.

**Tagline:** Throw your menu bar icons into a drawer. Pull them out when you need them.

## Problem

Menu bars fill up. Every utility, sync client, and helper app adds an icon, and most of them don't need to be visible all the time. The result is a cluttered strip of icons that pushes against the notch and makes the icons people actually use harder to find.

Existing tools (Vanilla, Bartender, Ice) solve this, but most of them ship with more configuration than many people want, and some require Screen Recording or Accessibility permissions.

## Goals

- Hide all menu bar icons placed to the left of a divider with one click.
- Show them again with one click.
- Remember the last state across launches.
- Require no special permissions.
- Look and feel like a native part of macOS.

## Non-goals (0.1.0)

- Choosing which individual icons stay visible (beyond where the user drags them relative to the divider).
- Automatically detecting and hiding third-party icons with no setup.
- A preferences window.
- Launch at Login.
- Auto-hide timers.
- Global keyboard shortcuts.
- Hiding desktop icons.
- Handling icons hidden behind the MacBook notch (see [future-features.md](future-features.md)).
- An in-app onboarding flow (setup lives in the README).
- In-app purchases or a paid tier.
- Automatic updates (no Sparkle yet).

## Target user

Mac users who like a clean, orderly menu bar and want a "set it once, forget it" tool. They are comfortable with one small setup step: dragging icons with ⌘.

## User experience

### Menu bar items

Drawer adds two items to the menu bar:

| Item | Appearance | Purpose |
|------|------------|---------|
| Toggle | Chevron (SF Symbol) | Click to collapse or expand |
| Divider | Thin `\|` (shown only when expanded) | Marks the boundary; icons to its left are hidden when collapsed |

```
Expanded:   [Dropbox] [1Password] [Slack]  |  ›  [Wi-Fi] [Battery] [Control Center] [Clock]
Collapsed:                                    ‹  [Wi-Fi] [Battery] [Control Center] [Clock]
```

### States

| State | Toggle icon | Divider | Icons left of divider |
|-------|-------------|---------|-----------------------|
| Expanded | `chevron.right` | Visible `\|` | Visible |
| Collapsed | `chevron.left` | Invisible (stretched off-screen) | Hidden |

In both states the chevron points in the direction the click will move things: in the expanded state it points right (tuck icons away), and in the collapsed state it points left (pull them back out).

### Interactions

| Action | Result |
|--------|--------|
| Left-click toggle | Switches between collapsed and expanded |
| Right-click toggle | Opens a small menu: **About Drawer**, divider, **Quit Drawer** (⌘Q) |
| ⌘-drag any menu bar icon | Standard macOS rearranging; icons dragged left of the divider will be hidden when collapsed |

### First launch

1. Drawer launches in the **expanded** state so the divider is visible.
2. The user ⌘-drags the icons they want hidden to the left of the `|` divider (documented in the README).
3. The user clicks the chevron to collapse.

After this, macOS places most newly installed apps' icons at the far left of the menu bar, so they land on the hidden side automatically.

### State persistence

The collapsed/expanded state is saved and restored on the next launch. Divider and toggle positions are restored by macOS.

### Safety rule

If the divider ends up to the **right** of the toggle (for example, the user ⌘-dragged it there), collapsing would hide the toggle itself and strand the user. In this case Drawer refuses to collapse and stays expanded.

### About panel

Standard macOS About panel, matching Now Playing on Spotify:

- **Name:** Drawer
- **Icon:** 🗄️ (file cabinet emoji) rendered as the panel's icon
- **Credits:**
  - "Throw your menu bar icons into a drawer. Pull them out when you need them."
  - "Pressware" (links to `https://pressware.co?ref=drawer`) · "Contact" (links to `mailto:support@pressware.co`)
- **Version / copyright:** from the bundle

## Requirements

### Functional

| ID | Requirement |
|----|-------------|
| F1 | App runs as a menu bar agent with no Dock icon. |
| F2 | App shows a toggle item with a chevron icon reflecting the current state. |
| F3 | App shows a divider item to the left of the toggle; it displays `\|` when expanded. |
| F4 | Left-clicking the toggle collapses or expands. |
| F5 | Collapsing hides every status item positioned to the left of the divider. |
| F6 | Expanding restores those items. |
| F7 | Right-clicking the toggle shows a menu with About Drawer and Quit Drawer. |
| F8 | Collapsed/expanded state persists across launches. |
| F9 | Toggle and divider positions persist across launches. |
| F10 | App will not collapse if the divider is to the right of the toggle. |
| F11 | First launch starts expanded. |

### Non-functional

| ID | Requirement |
|----|-------------|
| N1 | Minimum macOS 26 Tahoe. |
| N2 | Universal binary (Apple silicon + Intel). |
| N3 | Requires no permissions (no Accessibility, Screen Recording, or Automation). |
| N4 | App Sandbox and Hardened Runtime enabled. |
| N5 | 0.1.x: built and run locally with an Apple Development certificate. 1.0.0+: distributed as a notarized, Developer ID–signed DMG. |
| N6 | Idle CPU usage effectively zero; no polling or timers. |
| N7 | VoiceOver labels on both menu bar items. |
| N8 | Collects no data; no network access. |

## Pricing and distribution

- Free.
- 0.1.x: local builds only.
- 1.0.0+: direct download only (no Mac App Store), as a notarized DMG on GitHub Releases.

## Success criteria

- A new user can go from download to a collapsed menu bar in under a minute using only the README.
- Toggling is instant with no visible lag.
- No crashes or stuck states across restarts, display changes, or sleep/wake.

## Resolved decisions

- **App icon:** the 🗄️ emoji is used for the About panel **and** as the Finder/DMG app icon (AppIcon set generated from the emoji).
- **Updates:** no Sparkle or automatic updates yet.
- **Download host:** DMGs are published on GitHub Releases, starting at 1.0.0.
- **Signing for 0.1.x:** Tom's Apple Development certificate, run locally.
- **Tooling:** command line only (XcodeGen + `xcodebuild` + `make`).
- **License:** Copyright Tom McFarlin, all rights reserved (same as Now Playing on Spotify).

## Release plan

- **0.1.x:** personal builds for Tom's own use.
- **1.0.0:** the first release to other people.
