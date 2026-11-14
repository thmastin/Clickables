# Changelog

All notable changes to Clickables are documented here.

## [1.2.1] - 2026-11-14

### Fixed
- Reuse one hidden bag-slot scan tooltip, cache parsed item properties, and refresh cached data when item information arrives.
- Make Alt+right-click ignore toggles run once, with secure item use limited to left-click.
- Match tracked elixir buffs by spell ID, remove battle/guardian exclusivity, and skip only an already active matching elixir buff. This stacking behavior needs an in-game check on Forever.
- Deduplicate queued items, suppress all lower carried scroll ranks, and use one score/count/stack comparator with saved priority order.
- Batch queue refreshes from bags, player auras, quests, talents, and item-data events; keep combat counts live with burst batching.
- Deep-copy and validate saved settings, cap the error throttle map, and fix the `/clickables clear` confirmation timer.
- Correct Lion's Strength to Strength, Elixir of Wisdom to Intellect, and Greater Defense to Armor.
- Removed Strong Troll's Blood from the stat elixir ranking because its effect is health regeneration, not a tracked stat.

### Added
- Added the quest `!` badge for new quest starters, skipped quest starters already active in the quest log, preferred smaller stacks on ties, and displayed `+N queued`.

## [1.2.0] - 2026-11-13

### Added
- Buff food queue with Well Fed and eating aura checks, class/spec filtering, and best bonus/stack selection.
- Food category option and queue priority after quest starters, openables, elixirs, and scrolls.
- Quest `!` badge for quest starters and skipping starters for quests already active.
- Smaller-stack tie breaking and the `+N queued` queue indicator.
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
