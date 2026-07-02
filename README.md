# RVR - Remap Keys

Shortens action bar hotkey labels in World of Warcraft so keybind text is easier to read at a glance.

## What It Does

Watches common Blizzard action buttons and supported extra action bar buttons, then replaces long keybind labels with compact versions.

Examples include:

- Mouse Wheel Down becomes `MWD`
- Mouse Wheel Up becomes `MWU`
- Middle Mouse becomes `M3`
- Spacebar becomes `SP`
- Backspace becomes `BS`
- Delete becomes `DEL`
- Insert becomes `INS`
- Num Pad keys become shorter `N` prefixed labels
- Shift, Ctrl, and Alt modifiers become `S`, `C`, and `A`

The goal is to keep hotkey text readable on small action buttons without changing the actual keybinds.

## Supported Buttons

The addon refreshes labels on Blizzard action bars, multibars, pet buttons, stance buttons, possess buttons, override buttons, and the extra action button.

It also includes optional support for `EllesmereUIActionBars`. If that addon is loaded, we hook a keybind update function and refreshes those labels too.

## How It Works

This addon does not rebind keys. It only changes the visible hotkey text shown on action buttons.

The addon hooks hotkey text updates and reapplies shortened labels when action bars, bindings, or the world state refresh. It keeps the original keybind text internally so later updates can be shortened consistently.

## Notes

This addon is intentionally small and visual-only. It does not modify macros, spells, action slots, saved keybinds, or combat behavior.
