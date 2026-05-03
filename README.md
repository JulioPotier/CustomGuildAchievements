# CustomGuildAchievements (WoW Classic Era)

WoW addon (Classic Era / Vanilla) that adds a “Hardcore / Guild” achievements system **and** a small engine to create custom achievements using catalog definitions (`def`).

## Installation

- **Folder**: place this project in `Interface/AddOns/CustomGuildAchievements`.
- **Optional dependencies**: Ace3 (the addon can run without some libs, but several modules expect the Ace ecosystem).
- **Key files**:
  - `CustomGuildAchievements.lua`: engine + triggers + UI
  - `Achievements/*.lua`: achievement catalogs (guild, dungeons, raids, exploration, etc.)
  - `Achievements/CustomCatalog.lua`: **your custom achievements**

## Usage (player side)

### Commandes

Commands are defined in `Utils/CommandHandler.lua`.

- **`/cga show`**: enables and shows the Achievements tab (Character Panel).
- **`/cga reset tab`**: resets the tab position.
- **`/cga tracker show|hide|toggle`**: shows/hides the **tracker** (tracked achievements list).
- **`/cga debug [on|off]`**: toggles debug logs.
- **`/cga log`** (or `log show`): opens the **event log** (dashboard → “Log” tab).

### Options

Options panel: `Utils/OptionsPanel.lua`.

- **Disable Screenshots**: prevents screenshots on completion.
- **Announce achievements in guild chat**: announces completions in guild chat.
- **Backup and Restore Database**: full export/import of the database (all characters + progress + settings).

### Backup / Restore

The “Backup and Restore Database” button exports an encoded string (compress + encode) containing the whole `CustomGuildAchievementsDB` SavedVariables.  
The Restore panel replaces the database and then calls `ReloadUI()`.

### Tracker

The tracker (`Utils/AchievementTracker.lua`) is used to:

- track achievements (added via UI: “Shift click to link in chat or add to tracking list”),
- display objectives (kills / targets / talk-to / items / attempts… depending on the definition),
- display counters, timers, and sub-text (e.g., attempts, best fall, etc.).
- **Chains (`unlockedBy`)**: when a prerequisite completes, it is removed from the tracker; successors that just became eligible are **auto-tracked** (same idea as auto-tracking when an attempt starts via `AttemptActivate` / start NPC). A refresh also runs when the achievement list is filtered and shortly after login so chains stay in sync even without opening the panel.

## Triggers (full reference)

The engine listens to (see `CustomGuildAchievements.lua`):

- **Combat / kills**: `COMBAT_LOG_EVENT_UNFILTERED`, `BOSS_KILL`
- **Quests**: `QUEST_ACCEPTED`, `QUEST_TURNED_IN`, `QUEST_REMOVED` (+ dialogs: `QUEST_*`)
- **Targeting / mouseover**: `PLAYER_TARGET_CHANGED`, `UPDATE_MOUSEOVER_UNIT`
- **Emotes**: `CHAT_MSG_TEXT_EMOTE` (+ locale-proof emote hook for `onEmote`)
- **Items & inventory**: `UNIT_INVENTORY_CHANGED`, `BAG_UPDATE_DELAYED`, `LOOT_OPENED`, `CHAT_MSG_LOOT`  
  Secure hooks used by triggers: **`PickupContainerItem`** (drop-item-on NPC), **`UseContainerItem` / `UseInventoryItem` / `UseItemByName`** (consume / use-item achievements)
- **NPC**: `GOSSIP_SHOW`, `GOSSIP_CLOSED`, `MERCHANT_SHOW`, `MERCHANT_CLOSED`
- **Auras / mounts / forms**: `UNIT_AURA`, `PLAYER_MOUNT_DISPLAY_CHANGED`, `UPDATE_SHAPESHIFT_FORM`
- **Movement**: `PLAYER_STARTED_MOVING` (“walk-only” rule for attempts)
- **Exploration**: `MAP_EXPLORATION_UPDATED` (plus helper in `Functions/CheckMapDiscovery.lua`)
- **Reputation**: `UPDATE_FACTION`

### 1) Quest + kill (standard achievements)

Implemented in `Achievements/Common.lua` (`registerQuestAchievement`).

Main fields:

- **`requiredQuestId`**: quest ID (accepted / completed / turn-in depending on the tracker implementation).
- **`targetNpcId`**: NPC ID (number) **or** list `{...}` **or** player name (string) to complete on target.
- **`requiredKills`**: NPC kill counts table: `{ [npcId] = count, ... }` (also supports “any-of” entries depending on UI helpers).
- **`allowKillsBeforeQuest`**: if `true`, kills can count before the quest is accepted.
- **`level` / `maxLevel`**: level cap (above it → the achievement becomes “missed/failed”).
- **`zoneAccurate`**: required UiMapID (more reliable zone constraint).
- **`faction` / `race` / `class`**: eligibility constraints.
- **`allowSoloDouble`**: enables solo logic (double points if solo + hardcore/SSF conditions).

### 2) Target (“requiredTarget”)

Completes when **all** targets have been met (progress stored in `progress.metTargets` / legacy `metKings`).

- **`requiredTarget`**: targets table, same “shape” as kills:
  - simple: `{ [1747] = "Anduin Wrynn", [2784] = "King Magni", ... }`
  - any-of (1 slot = plusieurs IDs): `{ [1] = {1747, 9999}, [2] = {2784, 8888} }`
- **`targetOrder`** (optional): display order (tooltip/tracker only).
- **`trackTargetOnChange`** (optional): UI-side auto tracking (useful if you want the engine to mark targets via `PLAYER_TARGET_CHANGED`/mouseover).

### 3) Talk-to (“requiredTalkTo”)

Completes when **all** required NPCs have been “talked to” (detected on gossip/quest dialog open).  
Progress is stored in `progress.talkedTo`.

- **`requiredTalkTo`**: table `{ [npcId] = "Name", ... }` (also supports `any-of` like `requiredTarget`)
- **`talkToOrder`** (optional): display order (tooltip/tracker)

### 4) Open object (“requiredOpenObject”)

Completes when GameObjects have been opened (detected via `LOOT_OPENED`).  
Progress is stored in `progress.openedObjects`.

- **`requiredOpenObject`**: table `{ [objectId] = 1, ... }` (also supports `any-of`)

### 5) Items (dungeon sets + custom items)

There are two approaches:

- **Dungeon sets / requiredItems**: some catalogs (e.g., dungeon sets) use an `IsCompleted` function associated with the achId, evaluated on `UNIT_INVENTORY_CHANGED`.
- **Custom item tracker**: via **`customItem = function() ... end`** (see `Achievements/CustomCatalog.lua`).
- **Use item (consume)**: **`useItem`** completes when the player **actually uses** the item (see **6.2**).

### 6) Auras / Spellcast / Emotes / Chat

Definitions can rely on “function trackers” attached to the row:

- **Aura**: `row.auraTracker()` evaluated on `UNIT_AURA`
- **Spellcast**: `row.spellTracker(spellId, targetName)` evaluated on `UNIT_SPELLCAST_SENT`
- **Emote**:
  - `def.onEmote = "hello"` (ex: `/wave` ou `/hello`) + `def.targetNpcId` pour exiger une cible
  - optionnel: `checkInteractDistance = true` pour exiger la proximité
- **Chat emote**: `row.chatTracker(msg)` evaluated on `CHAT_MSG_TEXT_EMOTE`

### 6.1) Drop an item on an NPC (“dropItemOn”)

This trigger detects the *intent* of “giving” an item to an NPC (WoW has no real NPC trade window):

- the player **picks up** an item from their **bags** (hooked via `PickupContainerItem`),
- the item is still on the **cursor** (`GetCursorInfo()`),
- the player is **targeting** the specified NPC,
- and the player is within **trade distance** (`CheckInteractDistance("target", 2)`).

Definition field (required keys):

```lua
dropItemOn = { itemId = 4540, nbItem = 1, npcId = 6174 }
```

Behavior:

- when it matches, the addon **cancels the cursor pickup** (`ClearCursor()`) so the item is not lost,
- then completes the achievement using the normal completion flow (toast animation included).

### 6.2) Use / consume an item (“useItem”)

Completes when the player **invokes item use**, e.g. **right‑click from bags** (`UseContainerItem`).  
Implementation hooks (see `Utils/SharedUtils.lua` → `SetupUseItemTrigger`): `UseContainerItem`, `UseInventoryItem`, `UseItemByName`; definitions are rebuilt on `PLAYER_LOGIN` and `BAG_UPDATE_DELAYED`.

**Definition**

- Prefer a **table**:

```lua
useItem = { itemId = 4536 }, -- numeric item ID
```

- Shorthand **`useItem = 4536`** is also accepted (parsed as `{ itemId = 4536 }` internally).

Behavior:

- compares the **resolved item ID** after the hooked call completes the trigger when it matches **`itemId`**;
- respects **`unlockedBy`** chains: `CompleteAchievementById` skips completion until prerequisites are satisfied (same as other triggers).

Example chain (inventory then consume): keep an apple in bags first, then a second achievement with `useItem` and `unlockedBy` — see `Achievements/CustomCatalog.lua` (`CUSTOM-ITEM-7723-INBAG-001`, `CUSTOM-ITEM-4536-USE-001`).

Limits:

- triggering via **macros** still calls the hooked APIs — generally OK — but addons cannot hook every obscure path; unsupported cases are rare.

### 7) Exploration / zone discovery

`Functions/CheckMapDiscovery.lua` exposes:

- `addon.CheckZoneDiscovery(zoneNameOrMapID[, threshold])`
- `addon.GetZoneDiscoveryDetails(zoneNameOrMapID)`

Achievements can use these helpers via `customIsCompleted` (or a dedicated trigger in the engine for some IDs).

### 8) Reputation

Achievements with `def.isReputation` are evaluated on `UPDATE_FACTION` via an `IsCompleted` function associated with the `achId`.

### 9) Spending at a merchant (merchant spend)

Generic trigger:

- **`spendAtNpcId`**: merchant NPC ID
- **`spendCopper`**: minimum amount (copper) spent between `MERCHANT_SHOW` and `MERCHANT_CLOSED`

### 10) Attempts (Attempt / run gating)

Opt-in system to prevent “pre-doing” objectives before starting a run.

Main fields:

- **`attemptEnabled = true`**: enables gating (progress is blocked unless the attempt is active).
- **`attemptsAllowed = N`**: maximum number of starts.
- **`repeatable = true`** (or `isRepeatable = true`): allows re-toasts; **requires `attemptsAllowed > 0`**.
- **`timerSet = seconds`**: optional timer shown in the tracker.

Activation:

- via custom UI (e.g., `startNpc.window`), or internal logic depending on your catalog.
- internal API: `addon.AttemptActivate(achId, startedBy, timerSetOverride)`.

Auto-fail (transport rules) if you enable them in the definition:

- **`failOnMount = true`**
- **`failOnDruidCatForm = true`**
- **`failOnDruidTravelForm = true`**
- **`failOnHunterAspect = true`** (Aspect of the Cheetah/Pack)
- **`failOnShamanGhostWolf = true`**
- **`walkOnly = true`**: fails if the player is running (with a short grace window after activation).

### 11) startNpc (pins + interaction)

Definition field:

```lua
startNpc = {
  npcId = 466,
  coords = { mapId = 1453, x = 0.64, y = 0.75 }, -- normalized coordinates 0..1 (coords => map pin)
  raidMark = true,        -- optional: force “diamond” raid marker
  window = {              -- optional: interactive window
    title = "Title",
    text = "Text",
    buttonLabel = "Start attempt",
    buttonSound = "accept", -- internal alias (optional)
    callback = function(def, npcId) ... end,
  },
}
```

Behavior:

- if `coords` is present, the engine displays a “diamond” pin on the map plus a minimap direction marker.
- the engine can also mark the nearest eligible NPC via nameplates (raid target diamond) if opted-in.
- if `window` is present, the addon can open a start window on interaction / targeting (based on internal rules + distance).

### 12) Achievement chains (`unlockedBy`)

Sequential unlocks: an achievement stays **hidden** and its completion logic stays **gated** until the prerequisite achievement(s) are completed.

**Definition fields**

- **`unlockedBy`**: either a **string** (one prerequisite achievement id) or a **table** `{ "ID-1", "ID-2", ... }` — **all** ids must be completed (logical **AND**) before this achievement is shown and can complete.

**Engine behavior** (`CustomGuildAchievements.lua`, `ApplyFilter`, kill pipeline)

- **Visibility**: rows with `unlockedBy` are hidden from the main list until `addon.IsUnlockedBy(def)` is true (prerequisites completed in DB / row state).
- **Evaluation**: while locked, the row is skipped for kill/quest/emote/etc. completion checks so you cannot finish step B before step A.
- **Chain hygiene**: when a prerequisite completes, kill-style progress on **direct** successors that referenced it in `unlockedBy` may be reset so progress cannot be applied retroactively across the chain boundary.

**Tracker behavior** (`Utils/AchievementTracker.lua`)

- Completions go through `addon.MarkRowCompleted` so the tracker can react: the completed achievement is **untracked** immediately, then any successor definition whose `unlockedBy` now passes **`IsUnlockedBy`** is **auto-tracked** (freeing a slot before tracking the next step avoids hitting the 10-track limit).
- Additionally, a **full scan** of all definitions that declare `unlockedBy` runs when **`ApplyFilter`** runs (list visibility refresh) and once shortly after **`PLAYER_LOGIN`**, so successors are tracked even if prerequisites were already done earlier or the window was not opened.

**Example** (`Achievements/CustomCatalog.lua`)

```lua
-- Step 2 unlocks after step 1
{ achId = "CUSTOM-KILL-RAT-CHAIN-TEST-0002", unlockedBy = "CUSTOM-KILL-RAT-CHAIN-TEST-0001", ... }

-- Step 3 requires both previous ids (AND)
{ achId = "META-EXAMPLE", unlockedBy = { "CUSTOM-KILL-RAT-CHAIN-TEST-0001", "CUSTOM-KILL-RAT-CHAIN-TEST-0002" }, ... }
```

**Note:** `unlockedBy` is **not** the same as **`achiIds`** / **`nbAchis`**: those are meta rules that **auto-complete** an achievement when other achievements are done; `unlockedBy` only **unlocks visibility and eligibility** for a separate achievement row.

## Creating custom achievements

Edit `Achievements/CustomCatalog.lua`. This file already contains examples (targeted emote, simple kill, items in bag/equipped, attempts, merchant spend, meta achievements…).

### “Base” fields (common)

- **`achId`** (string, unique): internal identifier.
- **`title`**, **`tooltip`**: UI text.
- **`icon`**: texture ID.
- **`points`**: awarded points.
- **`level`**: level cap (above it → “missed/failed” for relevant achievements).
- **`staticPoints`**: prevents some recalculations (multipliers / solo preview).
- **`hiddenUntilComplete`**: hidden until completed.
- **`secret = true`** (+ optional `secretTitle`, `secretTooltip`, `secretIcon`, `secretPoints`): hides details until completed.
- **`isGuild = true`**: (often used in the guild catalog).

### Most commonly used trigger fields

- **Kills / quests**: `requiredQuestId`, `targetNpcId`, `requiredKills`, `allowKillsBeforeQuest`, `zoneAccurate`
- **Target**: `requiredTarget`, `targetOrder`, `trackTargetOnChange`
- **Talk-to**: `requiredTalkTo`, `talkToOrder`
- **Open object**: `requiredOpenObject`
- **Items**: `customItem = function() ... end`
- **Drop item on NPC**: `dropItemOn = { itemId = …, nbItem = …, npcId = … }`
- **Use / consume item**: `useItem = { itemId = … }` (or shorthand `useItem = itemId`)
- **Meta / dependencies**:
  - `achiIds = { "ACH-1", "ACH-2", ... }` → completes when all are completed; fails if any dependency fails
  - `nbAchis = N` → completes when at least N achievements (from this addon) are completed
  - **`unlockedBy`**: chain gate — hide and block completion until prerequisite id(s) are done (string or AND-table); see **12) Achievement chains** above and tracker auto-tracking
- **Attempts**: `attemptEnabled`, `attemptsAllowed`, `timerSet`, `failOn*` rules, `walkOnly`, `startNpc`
- **Merchant spend**: `spendAtNpcId`, `spendCopper`

### Callbacks: `onSuccess` / `onFail`

You can attach optional callbacks to any achievement definition (`def`) to run custom logic on completion/failure.

- **`def.onSuccess`**: called when the achievement is completed.
- **`def.onFail`**: called when the achievement enters a **terminal failed** state (e.g. attempt runs exhausted, dependency failure, outleveled/missed).

Signature:

```lua
onSuccess = function(def, ctx) end,
onFail = function(def, ctx) end,
```

The `ctx` table contains (best effort):

- **`ctx.achId`**: achievement id
- **`ctx.row`**: achievement row (if available)
- **`ctx.def`**: the definition table
- **`ctx.reason`**: failure reason for `onFail` (e.g. `"timer"`, `"mount"`, `"dependency"`, `"outleveled"`, etc.)
- **`ctx.at`**: timestamp
- **`ctx.rec`**: `cdb.achievements[achId]` record (SavedVariables)
- **`ctx.progress`**: `cdb.progress[achId]` table when available (note: progress may be cleared after completion)

## Communication “Precious” (Fellowship)

How it works (see `Utils/CommandHandler.lua`):

- When a player completes “Precious”, the addon sends an AceComm message on `SAY` (`CGA_Fellowship`).
- Other clients can subscribe via `addon.RegisterPreciousCompletionCallback(cb)` to react (e.g., complete a nearby “Fellowship” achievement).

## Admin (secure commands)

`Utils/CommandHandler.lua` implements an AceComm channel for admin commands with authentication:

- Prefixes: `CGA_Admin_Cmd` (command), `CGA_Admin_Resp` (response)
- Protection: timestamp (max 5 min) + anti-replay nonce + hash based on a **local secret key**.

Player-side command:

- **`/cga adminkey set <key>`**: sets the key (min 16 chars)
- **`/cga adminkey check`**: checks whether a key is set
- **`/cga adminkey clear`**: clears the key

## Troubleshooting

- Open the **Log** via `/cga log`.
- Export your DB via Options → “Backup and Restore Database” to share a reproducible state.

