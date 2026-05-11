## Custom Guild Achievements (WoW Classic Era)

This addon is a fork of **HardcoreAchievements**.

### Important: incompatibility with HardcoreAchievements

For now, **Custom Guild Achievements and HardcoreAchievements are not compatible**.  
Do **not** run both at the same time: they share concepts and can conflict (UI). Pick one.

## What this addon does

Custom Guild Achievements adds an Achievements experience to WoW Classic Era:

- a dedicated Achievements UI (Character window tab),
- a Dashboard (with tracker and logs),
- achievements that can react to what you do in the world (quests, kills, exploration, items, NPC interactions…),
- optional “chains” where an achievement unlocks the next step.

Your progress is saved **per character**.

## Installation

1. Put the folder `CustomGuildAchievements` into:
   - `World of Warcraft/_classic_era_/Interface/AddOns/`
2. Restart WoW (or `/reload`).
3. In Character Select, click **AddOns** and ensure **CustomGuildAchievements** is enabled.

Optional: some features may use embedded libraries, but you do not need to install anything else for the basic experience.

## How to open the Achievements UI

- Open the Character window (`C`) and look for the **Achievements** tab (added by the addon), or
- Type: **`/cga show`**

## Useful commands

- **`/cga show`**: show the Achievements tab
- **`/cga reset tab`**: reset the tab position (if you moved it off-screen)
- **`/cga tracker show`**, **`/cga tracker hide`**, **`/cga tracker toggle`**: show/hide the Tracker
- **`/cga log`**: open the in‑game log (helpful if something looks wrong)

## Options

You’ll find options in the game Settings under AddOns:

- **Disable Screenshots**: stop automatic screenshots on completion
- **Announce achievements in guild chat**: announce completions in guild chat
- **Backup and Restore Database**: export/import your saved progress as a single text string

## How achievements can be triggered (no technical terms)

Depending on the achievement, it can complete when you:

- **Kill** a specific creature (or a set of creatures)
- **Accept / complete / turn in** a quest
- **Target** specific NPCs (sometimes “meet” lists)
- **Talk to** an NPC (opening their gossip / quest dialog)
- **Open / loot** an object in the world (chests, interactables)
- **Use an emote** (for example /wave or /bow), sometimes while targeting an NPC
- **Wear** a specific item (equipped)
- **Carry** a specific item in your bags
- **Use / consume** a specific item (right‑click it from your bags, or use it from an action button)
- **Spend gold** at a merchant (some achievements track purchases)
- **Explore** and discover locations (zone discovery)
- Complete a **multi‑step chain** (step 2 only appears after step 1 is done)

Some achievements can also be set up as “attempts / runs”, where you must start a run and then follow rules (for example: no mount, walk‑only, time limit, etc.).

## Troubleshooting

- If you completed something but it didn’t save, try **`/reload`** once.
- If UI looks weird or is missing, try **`/cga reset tab`**.
- Use **`/cga log`** to open the log and look for errors.
- Use **Backup and Restore Database** if you want to share your saved data for debugging.

## Support and tips

- https://github.com/JulioPotier/CustomGuildAchievements/issues
- Tip me gold at **Kirbybank-Soulseeker** ;)