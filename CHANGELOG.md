# Changelog

## [1.2.6] - 2026-11-24
- Add a Weapon category for main-hand sharpening stones, weightstones, and oils, with hybrid talent role detection, manual role selection, weapon-type matching, and secure target-slot use.

All notable changes to Clickables are documented here.

## [1.2.5] - 2026-11-18

### Added
- Add an **Ignore current Clickable** key binding for keyboard and controller binding menus; it ignores the displayed item once and is unavailable in combat.

### Fixed
- Make **Use next Clickable** use an item once per binding press with either `ActionButtonUseKeyDown` setting, while retaining one use per mouse click.

## [1.2.4] - 2026-11-16

### Fixed
- Parse caster, healer, mana regeneration, critical, and armor stats from Well Fed food tooltips and apply class/spec weights.
- Keep useful-stat food in tier 1, allow unknown-stat Well Fed food as a tier 2 fallback, and include unknown stat phrases in debug output.
- Prefer Rainbow Fin Albacore for warlocks and healing food for priests while preserving Attack Power food ranking for warriors.
- Skip food, elixirs, and scrolls above the player's level; prefer the smallest carried stack with bag/slot order as a deterministic tie-break.
- Tune healer and caster food weights by class/spec and report each food stack once per debug scan, with its selection status on the same line.

## [1.2.3] - 2026-11-16

### Changed
- Rank Forever Well Fed XP food as a tier 2 fallback when its stat is filtered for the player's class/spec; useful stat food remains tier 1.
- Show tiered food debug lines only when the computed queue changes.

## [1.2.2] - 2026-11-15

### Fixed
- Recipes that teach food no longer show up as food.

## [1.2.1] - 2026-11-14

### Fixed
- Reuse one hidden bag-slot scan tooltip, cache parsed item properties, and refresh cached data when item information arrives.
- Make Alt+right-click ignore toggles run once, with secure item use limited to left-click; hide secure attributes from debug output.
- Match tracked elixir buffs by spell ID, remove battle/guardian exclusivity, and skip only an already active matching elixir buff. This stacking behavior needs an in-game check on Forever.
- Deduplicate queued items, suppress all lower carried scroll ranks, and use one score/count/stack comparator with saved priority order; ties prefer the smaller total, then the smaller stack, in every category.
- Batch queue refreshes from bags, player auras, quests, talents, and item-data events; keep combat counts live with burst batching.
- Deep-copy and validate saved settings, cap the error throttle map, and fix the `/clickables clear` confirmation timer.
- Correct Lion's Strength to Strength, Elixir of Wisdom to Intellect, and Greater Defense to Armor.
- Removed Strong Troll's Blood from the stat elixir ranking because its effect is health regeneration, not a tracked stat.

### Added
- Added tests and documentation for mocked client coverage and in-game-only checks.

## [1.2.0] - 2026-11-13

### Added
- Buff food queue with Well Fed and eating aura checks, class/spec filtering, and best bonus/stack selection.
- Food category option and queue priority after quest starters, openables, elixirs, and scrolls.
- Quest `!` badge for new quest starters; skip starters for quests already active or completed.
- Smaller-stack food ties and the `+N queued` queue indicator.
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
