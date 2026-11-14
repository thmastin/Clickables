# Clickables

Clickables provides one secure button for the next quest starter, openable, elixir, scroll, or buff food in your bags. It never uses an item automatically; click the button or use the **Use next Clickable** key binding.

## Install

Copy the `Clickables` folder into your Forever client's `Interface\AddOns` directory and enable it in the AddOns list.

## Options

Find **Clickables** under Game Menu > Options > AddOns. Lock or drag the button, set scale, choose hide or dim when empty, and toggle each supported item type. Food, elixirs, and scrolls are on by default. Food is offered only when its `Use:` tooltip indicates a Well Fed buff and no Well Fed or eating aura is active. Food, scrolls, and elixirs are ranked with per-class/spec stat weights; equal scores prefer the item with the larger total count across bags. The button count shows that total. Scrolls require the best carried rank, and an elixir is skipped only when its matching buff is active. Hybrids use the talent tree with the most points when available; before talent points are spent, class defaults apply. Enable the class override to allow normally filtered stats. Alt+right-click toggles the current item on the ignore list. Bag item clicks are left to your bag addons to avoid modifier conflicts. The ignore list shows item icons and names when available.

Slash commands include `/clickables errors` to show the last ten errors, `/clickables errors clear` to clear them, and `/clickables debug` to toggle immediate stack output, plus `/clickables lock`, `/clickables unlock`, `/clickables scale <number>`, `/clickables list`, and `/clickables clear` (run twice within five seconds).

The addon targets WoW Forever (`_forever_`, Interface 16001). Locked items are skipped unless a Rogue's Lockpicking skill can be confirmed sufficient; when the requirement cannot be determined, the item is skipped. Equal scores prefer the smaller total item count and then the smaller stack. The button shows `+N queued` when more items are available. Elixir buffs are checked individually; elixir stacking should be confirmed in-game on Forever.

## Tests

Run `luajit tests/run.lua` from this folder. CI also parses every Lua file with `luac -p`.

## Versioning

Clickables uses Semantic Versioning (`MAJOR.MINOR.PATCH`):

- **PATCH (1.0.x):** bug fixes and polish, with no new behavior.
- **MINOR (1.x.0):** new features that do not break existing setups.
- **MAJOR (x.0.0):** breaking changes, such as resetting saved settings or dropping a supported client.

Releases are tagged only after in-game checks. GitHub Actions builds releases with the BigWigs packager on `v*` tags.

## Planned

- Later: low-health bandage and healthstone suggestions (off by default).

Initial implementation details are tracked in the feature branch.
