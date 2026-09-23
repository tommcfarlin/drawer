# Future Features

Ideas not yet scheduled. Each becomes a GitHub issue in the `Future State` milestone.

## Opt-in drop-down for icons hidden by the notch (#29)

0.2.0 tells you how many drawer icons fit beside the notch, but can't show the hidden ones: that needs Accessibility permission. The plan:

- A `»` item appears when icons are hidden by the notch. Clicking it lists them with each app's icon and name (from `NSRunningApplication`, so no Screen Recording). Clicking one opens that app's real menu.
- Accessibility is requested once, the first time `»` is clicked, never before.
- It starts with a proof of concept on Tom's Mac: list hidden items, map them to apps, and open a menu whose icon is behind the notch (possibly by moving it into view briefly, as Ice does). If opening menus doesn't work, fall back to a list that opens each app.

## Other candidates (not committed)

- Launch at Login (`SMAppService.mainApp`)
- Auto-close the drawer after N seconds
- Global keyboard shortcut to toggle
- Automatic updates (Sparkle)
- A custom app icon to replace the emoji (before 1.0.0?)
