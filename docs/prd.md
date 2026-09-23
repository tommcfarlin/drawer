# Drawer — Product Requirements Document

**Version:** 0.2.0 (personal build; 1.0.0 is the first public release)
**Author:** Tom McFarlin
**Status:** Draft
**Last updated:** 2026-09-23

## Summary

Drawer is a tiny macOS menu bar utility that works like a real drawer. Put menu bar icons inside it, close it with one click, and they're gone. Open it again and they're back. It is deliberately simple: two brackets, one archive box, no preferences.

**Tagline:** Throw your menu bar icons into a drawer. Pull them out when you need them.

## Problem

Menu bars fill up. Every utility, sync client, and helper app adds an icon, and most of them don't need to be visible all the time. The result is a cluttered strip of icons that pushes against the notch and makes the icons people actually use harder to find.

Existing tools (Vanilla, Bartender, Ice) solve this, but most of them ship with more configuration than many people want, and some require Screen Recording or Accessibility permissions.

## Goals

- Hide every icon inside the drawer (between `[` and `]`) with one click.
- Show them again with one click.
- Remember whether the drawer was open or closed across launches.
- Require no special permissions.
- Look and feel like a native part of macOS.
- (0.2.0) On a MacBook with a notch, tell people how many drawer icons fit beside it, so they can keep their favorites where they stay visible.

## Non-goals (0.1.0)

- Choosing which individual icons stay visible, beyond dragging them in or out of the drawer.
- Automatically detecting and hiding third-party icons with no setup.
- A preferences window.
- Launch at Login.
- Auto-hide timers.
- Global keyboard shortcuts.
- Hiding desktop icons.
- Handling icons hidden behind the MacBook notch (added in 0.2.0; see **Notch** below).
- An in-app onboarding flow (setup lives in the README).
- In-app purchases or a paid tier.
- Automatic updates (no Sparkle yet).

## Non-goals (0.2.0)

- Showing or opening icons hidden by the notch. That needs Accessibility permission; it's planned as an opt-in drop-down (#29).
- Opening or closing the drawer automatically. Closing on its own would fight a manual open, and open/closed is shared across displays.
- Any new permission.

## Target user

Mac users who like a clean, orderly menu bar and want a "set it once, forget it" tool. They are comfortable with one small setup step: dragging icons with ⌘.

## User experience

### The drawer

Drawer adds a pair of brackets to the menu bar. Everything between them is **in the drawer**:

| Item | Open | Closed | Purpose |
|------|------|--------|---------|
| Handle | `[` | (hidden) | The drawer's left edge |
| Wall | `]` | (hidden) | The drawer's right edge |
| Front | (not in the menu bar) | Archive box (SF Symbols `archivebox`) | The shut drawer; it echoes the 🗄️ app icon |

```
Open:    [ Dropbox 1Password Slack ]  Wi-Fi Battery Control-Center Clock
Closed:                     (archive box)  Wi-Fi Battery Control-Center Clock
```

Icons to the right of `]` are never hidden.

All three are **template images**, drawn at the same weight as the icons around them, so macOS tints them for light, dark, and tinted menu bars (per Apple's Human Interface Guidelines for menu bar extras). Earlier builds used the text characters `[`, `|`, and `[|`, which didn't match the size, weight, or baseline of neighboring icons.

### States

| State | Handle and wall | Front | Icons in the drawer |
|-------|-----------------|-------|---------------------|
| Open | `[` … `]` | Not in the menu bar | Visible |
| Closed | Pushed off-screen | Archive box | Hidden |

### Interactions

| Action | Result |
|--------|--------|
| Left-click `[`, `]`, or the archive box | Opens or closes the drawer |
| Right-click (or Control-click) any of them | Opens a small menu: **Close Drawer** / **Open Drawer**, separator, **How to Use Drawer…**, **About Drawer**, separator, **Quit Drawer** (⌘Q) |
| Hover any of them | Tooltip: "Close Drawer" or "Open Drawer" |
| Open Drawer again (Finder, Spotlight, Launchpad) while it's running | Opens the drawer, which is the way back if macOS ever hides the archive box |
| ⌘-drag any menu bar icon | Standard macOS rearranging. Drop an icon between `[` and `]` to put it in the drawer. Drop it right of `]` to keep it always visible. |

### First launch

1. Drawer launches **open**, with `[` and `]` next to each other at the left end of the status icons.
2. The user ⌘-drags the icons they want hidden in between `[` and `]` (documented in the README).
3. The user clicks `[` or `]` to close the drawer.

### Known limitation: left of the handle

Closing the drawer works by stretching the wall so everything to its left is pushed off-screen. macOS offers no way to hide icons from the middle of the menu bar without extra permissions, so **anything left of `[` is hidden when the drawer closes, too**. Most new apps add their icons at the far left of the menu bar, so while the drawer is open their icons can appear just left of `[`. Drag them into the drawer or to the right of `]`.

### Notch (0.2.0)

On a MacBook with a notch, the menu bar only has the space to the right of the notch for icons (790pt on Tom's MacBook at its current resolution). When icons don't fit, macOS hides them from the **left**. With the drawer open, the first to go are `[` and the drawer's leftmost icons. `]` and everything to its right stay visible.

**Why Drawer can't bring them back without permission:** every permission-free trick, including Drawer's own wall, hides a leftmost run of icons, and so does the notch. So what's visible is always the rightmost run. Revealing a hidden drawer icon would mean hiding icons to its right or moving it, and both need Accessibility.

**What Drawer does instead: the ordering hint.** The drawer icons that survive are the ones **nearest `]`**. Drawer measures how many fit and says so, passively:

| Situation | Dimmed lines at the top of Drawer's menu | `]` tooltip |
|-----------|------------------------------------------|-------------|
| Some drawer icons hidden (open) | "Only the 4 Icons Nearest ] Fit Beside the Notch" / "⌘-Drag Your Favorites Next to ]" | "Close Drawer" + the first line |
| One fits | "Only the Icon Nearest ] Fits Beside the Notch" / … | same pattern |
| None fit | "No Drawer Icons Fit Beside the Notch" / … | same pattern |
| Icons outside the drawer don't fit (open or closed) | "Too Many Icons Outside the Drawer to Fit Beside the Notch" / "⌘-Drag Some Icons Into the Drawer" | the visible item's tooltip + the first line |
| Drawer closed, and some drawer icons were hidden the last time it was open | "When Open, Only the 8 Icons Nearest ] Fit Beside the Notch" / "Open the Drawer and ⌘-Drag Your Favorites Next to ]" (same one/none forms) | archive box: "Open Drawer" + the first line |
| Everything fits, or no notched display | *(nothing)* | unchanged |

- The hint is shown whenever a notched display is present, whether the drawer is open or closed, and never otherwise (decided 2026-09-23). While closed, the drawer's icons are off-screen and can't be measured, so it uses the last measurement from when the drawer was open. That measurement is remembered across launches but forgotten if the notched displays change.
- The hint never pops up; it's only in the menu and tooltip.
- A notice about a refused or failed close takes priority in the menu.
- It's measured without permissions, and refreshed when the drawer changes, when the menu opens, and when displays change.

### State persistence

Whether the drawer is open or closed is saved and restored on the next launch. macOS restores the positions of `[` and `]`.

### Safety rule

If `[` ends up to the **right** of `]` (for example, the user ⌘-dragged it there), the drawer is inside out and closing it wouldn't make sense. In this case Drawer refuses to close, beeps, and opens its menu with a dimmed first line explaining the fix: "Move [ to the Left of ] to Use the Drawer". If the archive box ever fails to appear after closing, Drawer reopens the drawer and explains: "The Menu Bar Is Too Full to Close the Drawer".

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
| F2 | App shows a handle (`[`) and, to its right, a wall (`]`), both as template images. |
| F3 | Left-clicking the handle or the wall opens or closes the drawer. |
| F4 | Closing hides every status item between the handle and the wall. |
| F5 | While closed, an archive box appears where the drawer was; icons right of it are unaffected. |
| F6 | Opening restores the handle and every icon in the drawer. |
| F7 | Right-clicking (or Control-clicking) any drawer item shows a menu with Close/Open Drawer, How to Use Drawer…, About Drawer, and Quit Drawer. |
| F8 | Open/closed state persists across launches. |
| F9 | Handle and wall positions persist across launches. |
| F10 | App will not close the drawer if the handle is to the right of the wall. |
| F11 | First launch starts open. |
| F12 | While open, Drawer adds nothing to the menu bar besides `[` and `]` (no empty space or hover highlight). |
| F13 | Opening Drawer again while it's running opens the drawer (and does nothing if it's already open). |
| F14 | A refused or failed close is explained in the menu, not only with a beep. |
| F15 | Each drawer item has a tooltip naming what a click will do. |
| F17 | (0.2.0) On a notched display, the menu and `]` tooltip say how many drawer icons fit beside the notch and suggest keeping favorites next to `]`. |
| F18 | (0.2.0) If the icons outside the drawer don't fit beside the notch, the menu and tooltip warn about it, whether the drawer is open or closed. |
| F16 | Opening and closing are instant, with a quick bounce on the drawer's own icon (the archive box on close, `]` on open); no bounce when Reduce Motion is on. |

### Non-functional

| ID | Requirement |
|----|-------------|
| N1 | Minimum macOS 26 Tahoe. |
| N2 | Universal binary (Apple silicon + Intel). |
| N3 | Requires no permissions (no Accessibility, Screen Recording, or Automation). |
| N4 | App Sandbox and Hardened Runtime enabled. |
| N5 | 0.1.x: built and run locally with an Apple Development certificate. 1.0.0+: distributed as a notarized, Developer ID–signed DMG. |
| N6 | Idle CPU usage effectively zero; no polling or timers (a bounded check at launch is allowed). |
| N7 | VoiceOver: each item has its own label ("Drawer, left edge", "Drawer, right edge", "Closed drawer") and help ("Click to close/open the drawer."); any press that isn't a right-click toggles; a "Show Menu" action reaches the menu. |
| N9 | Bracket images are pixel-aligned at every display scale (1px strokes at 1x, 1.5pt at Retina). |
| N10 | All user-facing text lives in a String Catalog (English only for now). |
| N8 | Collects no data; no network access. |

## Pricing and distribution

- Free.
- 0.1.x: local builds only.
- 1.0.0+: direct download only (no Mac App Store), as a notarized DMG on GitHub Releases.

## Success criteria

- A new user can go from download to a closed drawer in under a minute using only the README.
- Toggling is instant with no visible lag.
- No crashes or stuck states across restarts, display changes, or sleep/wake.

## Resolved decisions

- **Drawer design:** the drawer is the space between a `[` handle and a `]` wall; closed, it shows an archive box (SF Symbols `archivebox`, echoing the 🗄️ icon). All drawn as template images per Apple's HIG. Decided 2026-09-23, replacing the original chevron-and-divider design and a text-based `[ … |` / `[|` version.
- **App icon:** the 🗄️ emoji is used for the About panel **and** as the Finder/DMG app icon (AppIcon set generated from the emoji).
- **Updates:** no Sparkle or automatic updates yet.
- **Download host:** DMGs are published on GitHub Releases, starting at 1.0.0.
- **Signing for 0.1.x:** Tom's Apple Development certificate, run locally.
- **Tooling:** command line only (XcodeGen + `xcodebuild` + `make`).
- **License:** Copyright Tom McFarlin, all rights reserved (same as Now Playing on Spotify).

- **Notch (0.2.0):** a permission-free ordering hint and an outside-doesn't-fit warning, both passive. No automatic opening or closing. An opt-in Accessibility drop-down for hidden icons comes later (#29). Decided 2026-09-23.

## Release plan

- **0.1.x:** personal builds for Tom's own use.
- **0.2.0:** notch awareness (personal build).
- **1.0.0:** the first release to other people.
