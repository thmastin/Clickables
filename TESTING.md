# Testing

Run `luajit tests/run.lua`. The suite includes helper tests and loads `Clickables.lua` with a mocked client.

The mocked-client tests cover secure click phase filtering, queue deduplication and counts, saved-setting migration, scroll and elixir aura suppression, quest and food filtering, talent refreshes, event batching in and out of combat, item-info refresh filtering, tooltip reuse and bag-slot lock state, and the `/clickables clear` confirmation window.

## In-game checks

- Verify secure clicks with real client taint behavior.
- Verify battle and guardian elixir stacking on Forever.
- Verify the picked-lockbox tooltip in Forever.

## Mutation checks

Each mutation below was applied temporarily, `luajit tests/run.lua` failed at the named assertion, and the original source was restored immediately afterward.

| Mutation | Test that detected it |
| --- | --- |
| Removed the PreClick phase guard | Two-item click test: only the original current item is ignored for both `ActionButtonUseKeyDown` settings. |
| Removed the rebuild's `DedupeQueue` call | Three-slot same-item test: duplicate actions would show `+N queued`. |
| Replaced recursive default copying with a shallow identity copy | Future nested-default migration test. |
| Disabled scroll aura spell-ID lookup | Agility IV buff suppression test. |
| Disabled elixir aura suppression in the rebuild path | Matching Lion's Strength aura test. |
| Bypassed quest state in rebuild classification | Active and completed quest starter tests. |
| Disabled Well Fed/eating aura checks in the rebuild path | Food aura suppression test. |
| Dropped `CHARACTER_POINTS_CHANGED` rebuild handling | Hybrid talent re-ranking test. |
| Made `/clickables clear` always start a new confirmation | Second clear within five seconds test. |
