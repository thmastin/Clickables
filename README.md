# Clickables

Clickables provides one secure button for the next quest starter or openable item in your bags. It never uses an item automatically; click the button or use the **Use next Clickable** key binding.

## Install

Copy the `Clickables` folder into your Forever client's `Interface\AddOns` directory and enable it in the AddOns list.

## Options

Find **Clickables** under Game Menu > Options > AddOns. Lock or drag the button, set scale, choose hide or dim when empty, and toggle each supported item type. Alt+right-click an item in Blizzard or EllesmereUI bags, or the current button item, to toggle it on the ignore list. Slash fallback: `/clickables lock`, `/clickables unlock`, `/clickables scale <number>`, `/clickables list`, `/clickables clear` (run twice within five seconds).

The addon targets WoW Forever (`_forever_`, Interface 16001). Locked items are skipped unless a Rogue's Lockpicking skill can be confirmed sufficient; when the requirement cannot be determined, the item is skipped.

## Tests

Run `luajit tests/run.lua` from this folder.

## Versioning

Clickables uses Semantic Versioning (`MAJOR.MINOR.PATCH`):

- **PATCH (1.0.x):** bug fixes and polish, with no new behavior.
- **MINOR (1.x.0):** new features that do not break existing setups.
- **MAJOR (x.0.0):** breaking changes, such as resetting saved settings or dropping a supported client.

Releases are tagged only after in-game checks. GitHub Actions builds releases with the BigWigs packager on `v*` tags.

## Planned

- **v1.1:** scrolls and elixirs with buff-rank checks.
- **v1.2:** food, with a Well Fed check through Shift-click.
- Later: low-health bandage and healthstone suggestions (off by default).
