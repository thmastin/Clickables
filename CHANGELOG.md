# Changelog

All notable changes to Clickables are documented here.

## [1.2.0] - 2026-11-13

### Added
- Buff food queue with Well Fed and eating aura checks, class/spec filtering, and best bonus/stack selection.
- Food category option and queue priority after quest starters, openables, elixirs, and scrolls.
- Stat-weighted ranking for food, scrolls, and elixirs, plus total same-item counts across bags.
- GitHub Actions CI for the local test suite and Lua syntax checks.

## [1.1.0] - 2026-11-13

### Added
- Scroll and elixir queue categories with options toggles, buff checks, class/spec filtering, and a class override.
- Throttled safe-call error reporting, a ten-entry error history, `/clickables errors`, and debug stack output.
- Queue explanations in the button tooltip and tests for priorities, filters, buff ranks, elixir conflicts, and error handling.

## [1.0.0] - 2026-11-13

### Added
- One secure button for openables and quest starter items; items are used only by an explicit click.
- The **Use next Clickable** key binding.
- Alt+right-click on the Clickables button to ignore or unignore the current item.
- A native Options panel with an item ignore list, icons, names, and remove controls.
- Combat-safe queue refresh and secure item attribute updates, with refresh deferred until combat ends.
- Compatibility with GogoLoot; Clickables does not install bag-button hooks.
