# Future Features

Ideas deferred from 0.1.0. Each should become a GitHub issue once the repo exists.

## Notch awareness

On MacBooks with a notch, macOS silently hides status items that don't fit between the app menus and the notch. Users may think Drawer hid them, or that Drawer is broken.

Possible directions:

- Detect a notched display (`NSScreen.safeAreaInsets` / `auxiliaryTopLeftArea`) and document the behavior.
- Warn when the visible side of the divider is likely to overflow into the notch.

## Other candidates (not committed)

- Launch at Login (`SMAppService.mainApp`)
- Auto-collapse after N seconds
- Global keyboard shortcut to toggle
- Automatic updates (Sparkle)
- A custom app icon to replace the emoji (before 1.0.0?)
