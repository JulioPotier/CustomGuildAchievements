/* eslint-disable no-alert */
(function () {
  "use strict";

  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

  const out = $("#out");
  const outHint = $("#outHint");
  const btnCopy = $("#btnCopy");
  const btnReset = $("#btnReset");
  const btnLang = $("#btnLang");
  const stepTitle = $("#stepTitle");
  const stepsHost = $("#steps");
  const stepHost = $("#stepHost");
  const btnBack = $("#btnBack");
  const btnNext = $("#btnNext");
  const btnGenerate = $("#btnGenerate");

  let lang = "fr";

  const I18N = {
    fr: {
      appTitle: "Wizard d’achievement (CustomGuildAchievements)",
      appSubtitle:
        'Remplissez les infos étape par étape, puis copiez/collez le snippet Lua dans <span class="k">Achievements/CustomCatalog.lua</span> (dans la table <span class="k">CustomAchievements</span>).',
      outputBadge: "Sortie",
      outputText: "1 bloc Lua “def” prêt à coller",
      snippetBadge: "Snippet Lua",
      snippetSubtitle: 'Collez dans <span class="k">Achievements/CustomCatalog.lua</span>',
      langToggleTitle: "Basculer FR/EN",
      backBtn: "Retour",
      nextBtn: "Suivant",
      generateBtn: "Générer",
      copyBtn: "Copier",
      copiedBtn: "Copié",
      resetBtn: "Reset",
      resetConfirm: "Reset le formulaire ?",
      outEmpty: "(Remplissez le formulaire puis cliquez “Générer”.)",
      stepLabel: "Étape",
      sEligibility: "Éligibilité",
      sVisibility: "Secret / caché",
      sType: "Type d’achievement",
      sTypeDetails: "Détails",
      sNpcWindow: "NPC (fenêtre / coords)",
      sRunRules: "Timer / tentatives",
      sZone: "Zone",
      sFinalText: "Titre / tooltip / icône",
      sIds: "IDs",
      faction: "Faction",
      factionBoth: "Les 2",
      factionAlliance: "Alliance",
      factionHorde: "Horde",
      class: "Classe",
      classAny: "Toutes",
      race: "Race",
      raceAny: "Toutes",
      selfFoundOnly: "Réservé Self‑Found (caché pour non‑SF)",
      secret: "Secret",
      hiddenUntilComplete: "Caché jusqu’à complétion",
      typeTitle: "Quel est le type ?",
      tQuest: "Terminer une quête précise",
      tKillNpc: "Tuer 1 ou plusieurs NPC",
      tTargetNpc: "Cibler 1 ou plusieurs NPC",
      tTalkNpc: "Parler à un NPC",
      tBringItem: "Amener un objet à un NPC",
      tSpend: "Dépenser de l'argent chez un NPC",
      tCompleteAchis: "Compléter des achis précis",
      tCompleteN: "Compléter N achis",
      tItemBag: "Avoir un item précis dans son sac",
      tItemEquip: "Equiper un item précis sur soi",
      tFall: "Saut avec perte de PVs",
      questId: "Quest ID",
      npcHintIdOrPlayer:
        "Astuce: si vous mettez une chaîne au lieu d’un ID, ce sera un joueur (ex: Mavenrage).",
      listOnePerLine: "Une entrée par ligne.",
      npcId: "NPC ID (principal)",
      npcName: "NPC name (pour commentaire/tooltip)",
      npcX: "x (0..1)",
      npcY: "y (0..1)",
      npcText: "Texte de la fenêtre",
      npcButton: "Label du bouton",
      runMode: "Mode",
      runNone: "Aucun",
      runTimer: "Timer",
      timerSeconds: "Timer (secondes)",
      zoneSelect: "Zone (optionnel)",
      zoneNone: "(aucune)",
      zonePrecise: "Précis (zoneAccurate)",
      title: "Title",
      tooltip: "Tooltip",
      icon: "Icon",
      points: "Points (optionnel)",
      level: "Niveau max (optionnel)",
      achIdInput: "ID (achId) — auto-formaté",
      unlockedBy: "unlockedBy (optionnel)",
      required: "Requis.",
      // misc UI strings
      hintOptional: "Optionnel.",
      hintNpcCsvKill: "Format: npcId, npcName, count (count optionnel, défaut 1).",
      hintNpcCsvTarget: "Format: idOrPlayer, name (name optionnel).",
      hintNpcCsvTalk: "Format: npcId, npcName.",
      lblNpcList: "NPCs",
      lblTargets: "Targets",
      lblTalkToList: "Talk-to list",
      hintFallNeedsNpc: "Ce type nécessite un NPC de départ (étape suivante).",
      idsHint: "Format: majuscules, tirets, sans caractères spéciaux.",
      talkNpcNativeGossip: "Ce NPC a déjà une fenêtre de gossip native.",
      timerSecondsOnly: "Timer (secondes, optionnel)",
    },
    en: {
      appTitle: "Achievement wizard (CustomGuildAchievements)",
      appSubtitle:
        'Answer the questions step by step, then copy/paste the Lua snippet into <span class="k">Achievements/CustomCatalog.lua</span> (inside the <span class="k">CustomAchievements</span> table).',
      outputBadge: "Output",
      outputText: "1 Lua “def” block ready to paste",
      snippetBadge: "Lua snippet",
      snippetSubtitle: 'Paste into <span class="k">Achievements/CustomCatalog.lua</span>',
      langToggleTitle: "Toggle FR/EN",
      backBtn: "Back",
      nextBtn: "Next",
      generateBtn: "Generate",
      copyBtn: "Copy",
      copiedBtn: "Copied",
      resetBtn: "Reset",
      resetConfirm: "Reset the form?",
      outEmpty: '(Fill the form then click “Generate”.)',
      stepLabel: "Step",
      sEligibility: "Eligibility",
      sVisibility: "Secret / hidden",
      sType: "Achievement type",
      sTypeDetails: "Details",
      sNpcWindow: "NPC (window / coords)",
      sRunRules: "Timer / attempts",
      sZone: "Zone",
      sFinalText: "Title / tooltip / icon",
      sIds: "IDs",
      faction: "Faction",
      factionBoth: "Both",
      factionAlliance: "Alliance",
      factionHorde: "Horde",
      class: "Class",
      classAny: "Any",
      race: "Race",
      raceAny: "Any",
      selfFoundOnly: "SF only (hidden for non-SF)",
      secret: "Secret",
      hiddenUntilComplete: "Hidden until complete",
      typeTitle: "Pick a type",
      tQuest: "Complete a specific quest",
      tKillNpc: "Kill 1+ NPCs",
      tTargetNpc: "Target 1+ NPCs",
      tTalkNpc: "Talk to an NPC",
      tBringItem: "Bring an item to an NPC",
      tSpend: "Spend money at an NPC",
      tCompleteAchis: "Complete specific achievements",
      tCompleteN: "Complete N achievements",
      tItemBag: "Have a specific item in bags",
      tItemEquip: "Equip a specific item",
      tFall: "Fall with HP loss",
      questId: "Quest ID",
      npcHintIdOrPlayer:
        "Tip: if you enter a string instead of an ID, it will be treated as a player (e.g. Mavenrage).",
      listOnePerLine: "One entry per line.",
      npcId: "NPC ID (main)",
      npcName: "NPC name (comment/tooltip)",
      npcX: "x (0..1)",
      npcY: "y (0..1)",
      npcText: "Window text",
      npcButton: "Button label",
      runMode: "Mode",
      runNone: "None",
      runTimer: "Timer",
      timerSeconds: "Timer (seconds)",
      zoneSelect: "Zone (optional)",
      zoneNone: "(none)",
      zonePrecise: "Precise (zoneAccurate)",
      title: "Title",
      tooltip: "Tooltip",
      icon: "Icon",
      points: "Points (optional)",
      level: "Max level (optional)",
      achIdInput: "ID (achId) — auto-formatted",
      unlockedBy: "unlockedBy (optional)",
      required: "Required.",
      // misc UI strings
      hintOptional: "Optional.",
      hintNpcCsvKill: "Format: npcId, npcName, count (count optional, default 1).",
      hintNpcCsvTarget: "Format: idOrPlayer, name (name optional).",
      hintNpcCsvTalk: "Format: npcId, npcName.",
      lblNpcList: "NPCs",
      lblTargets: "Targets",
      lblTalkToList: "Talk-to list",
      hintFallNeedsNpc: "This type requires a start NPC (next step).",
      idsHint: "Format: uppercase, dashes, no special characters.",
      talkNpcNativeGossip: "This NPC already has a native gossip window.",
      timerSecondsOnly: "Timer (seconds, optional)",
    },
  };

  function t(key) {
    return I18N[lang]?.[key] ?? I18N.fr[key] ?? key;
  }

  function applyI18nStatic() {
    document.documentElement.lang = lang;
    if (btnLang) btnLang.textContent = lang.toUpperCase();
    for (const el of $$("[data-i18n]")) el.innerHTML = t(el.getAttribute("data-i18n"));
    for (const el of $$("[data-i18n-title]")) el.setAttribute("title", t(el.getAttribute("data-i18n-title")));
    if (btnBack) btnBack.textContent = t("backBtn");
    if (btnNext) btnNext.textContent = t("nextBtn");
    if (btnGenerate) btnGenerate.textContent = t("generateBtn");
    if (btnCopy) btnCopy.textContent = t("copyBtn");
    if (btnReset) btnReset.textContent = t("resetBtn");
  }

  function escLuaString(s) {
    return String(s ?? "")
      .replace(/\\/g, "\\\\")
      .replace(/"/g, '\\"')
      .replace(/\r\n/g, "\n")
      .replace(/\r/g, "\n");
  }

  function isBlank(v) {
    return v == null || String(v).trim() === "";
  }

  function asIntOrNull(v) {
    const raw = String(v ?? "").trim();
    if (!raw) return null;
    const n = Number(raw);
    if (!Number.isFinite(n)) return null;
    return Math.trunc(n);
  }

  function asNumberOrNull(v) {
    const raw = String(v ?? "").trim();
    if (!raw) return null;
    const n = Number(raw);
    return Number.isFinite(n) ? n : null;
  }

  function normalizeAchId(raw) {
    let s = String(raw ?? "");
    try {
      s = s.normalize("NFD").replace(/\p{Diacritic}/gu, "");
    } catch {
      // ignore
    }
    return s
      .toUpperCase()
      .trim()
      .replace(/[^A-Z0-9]+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-+/, "")
      .replace(/-+$/, "");
  }

  function parseUnlockedBy(raw) {
    const s = String(raw ?? "").trim();
    if (!s) return null;
    const parts = s.split(",").map((p) => p.trim()).filter(Boolean);
    if (!parts.length) return null;
    if (parts.length === 1) return `"${escLuaString(parts[0])}"`;
    return `{ ${parts.map((p) => `"${escLuaString(p)}"`).join(", ")} }`;
  }

  function readZones() {
    const el = $("#zonesClassic1132");
    if (!el) return [];
    try {
      const arr = JSON.parse(el.textContent || "[]");
      return Array.isArray(arr) ? arr : [];
    } catch {
      return [];
    }
  }

  const ZONES = readZones();

  const CLASSES = [
    "WARRIOR",
    "PALADIN",
    "HUNTER",
    "ROGUE",
    "PRIEST",
    "SHAMAN",
    "MAGE",
    "WARLOCK",
    "DRUID",
  ];

  const RACES = [
    "Human",
    "Dwarf",
    "Night Elf",
    "Gnome",
    "Orc",
    "Undead",
    "Tauren",
    "Troll",
  ];

  const TYPES = [
    { id: "quest", labelKey: "tQuest" },
    { id: "killNpc", labelKey: "tKillNpc" },
    { id: "targetNpc", labelKey: "tTargetNpc" },
    { id: "talkNpc", labelKey: "tTalkNpc" },
    { id: "bringItem", labelKey: "tBringItem" },
    { id: "spendNpc", labelKey: "tSpend" },
    { id: "completeAchis", labelKey: "tCompleteAchis" },
    { id: "completeN", labelKey: "tCompleteN" },
    { id: "itemBag", labelKey: "tItemBag" },
    { id: "itemEquip", labelKey: "tItemEquip" },
    { id: "fall", labelKey: "tFall" },
  ];

  const state = {
    faction: "both",
    class: "any",
    race: "any",
    selfFoundOnly: false,
    secret: false,
    hiddenUntilComplete: false,
    type: null,
    questId: null,
    killLines: "",
    targetLines: "",
    targetNpcName: "",
    talkLines: "",
    talkNpcNativeGossip: false,
    bringItemId: null,
    bringItemCount: 1,
    bringNpcId: null,
    bringNpcName: "",
    spendNpcId: null,
    spendNpcName: "",
    spendCopper: null,
    achiIdsLines: "",
    nbAchis: null,
    itemId: null,
    itemCount: 1,
    fallHpPct: null,
    startNpcId: null,
    startNpcName: "",
    startNpcX: null,
    startNpcY: null,
    startNpcText: "",
    startNpcButtonLabel: "",
    timerSet: null,
    zoneId: null,
    zonePrecise: false,
    title: "",
    tooltip: "",
    icon: "",
    points: null,
    level: null,
    achId: "",
    unlockedByRaw: "",
  };

  function needsStartNpc() {
    if (state.type === "talkNpc" && state.talkNpcNativeGossip) return false;
    return state.type === "talkNpc" || state.type === "bringItem" || state.type === "spendNpc" || state.type === "fall";
  }

  function forceInteractDistance() {
    if (state.type === "talkNpc" && state.talkNpcNativeGossip) return false;
    return needsStartNpc();
  }

  function parseLines(text) {
    return String(text ?? "")
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter((l) => l && !l.startsWith("--"));
  }

  function parseCsvLine(line) {
    return line.split(",").map((x) => x.trim());
  }

  function stepDefs() {
    const defs = [
      {
        id: "eligibility",
        titleKey: "sEligibility",
        render() {
          const classOptions =
            `<option value="any">${t("classAny")}</option>` +
            CLASSES.map((c) => `<option value="${c}">${c}</option>`).join("");
          const raceOptions =
            `<option value="any">${t("raceAny")}</option>` +
            RACES.map((r) => `<option value="${escLuaString(r)}">${escLuaString(r)}</option>`).join("");
          return `
            <div class="row cols2">
              <div>
                <label for="factionSel">${t("faction")}</label>
                <select id="factionSel">
                  <option value="both">${t("factionBoth")}</option>
                  <option value="alliance">${t("factionAlliance")}</option>
                  <option value="horde">${t("factionHorde")}</option>
                </select>
              </div>
              <div class="inline" style="align-items:flex-end;justify-content:flex-start">
                <div class="chk" style="margin-top:22px">
                  <input id="sfOnly" type="checkbox" />
                  <label for="sfOnly" style="margin:0">${t("selfFoundOnly")}</label>
                </div>
              </div>
            </div>
            <div class="row cols2" style="margin-top:10px">
              <div>
                <label for="classSel">${t("class")}</label>
                <select id="classSel">${classOptions}</select>
              </div>
              <div>
                <label for="raceSel">${t("race")}</label>
                <select id="raceSel">${raceOptions}</select>
              </div>
            </div>
          `;
        },
        hydrate() {
          $("#factionSel").value = state.faction;
          $("#classSel").value = state.class;
          $("#raceSel").value = state.race;
          $("#sfOnly").checked = state.selfFoundOnly;
          $("#factionSel").addEventListener("change", (e) => (state.faction = e.target.value));
          $("#classSel").addEventListener("change", (e) => (state.class = e.target.value));
          $("#raceSel").addEventListener("change", (e) => (state.race = e.target.value));
          $("#sfOnly").addEventListener("change", (e) => (state.selfFoundOnly = !!e.target.checked));
        },
      },
      {
        id: "visibility",
        titleKey: "sVisibility",
        render() {
          return `
            <div class="row cols2">
              <div class="inline" style="align-items:flex-end">
                <div class="chk">
                  <input id="secret" type="checkbox" />
                  <label for="secret" style="margin:0">${t("secret")}</label>
                </div>
              </div>
              <div class="inline" style="align-items:flex-end">
                <div class="chk">
                  <input id="hiddenUntilComplete" type="checkbox" />
                  <label for="hiddenUntilComplete" style="margin:0">${t("hiddenUntilComplete")}</label>
                </div>
              </div>
            </div>
          `;
        },
        hydrate() {
          $("#secret").checked = state.secret;
          $("#hiddenUntilComplete").checked = state.hiddenUntilComplete;
          $("#secret").addEventListener("change", (e) => (state.secret = !!e.target.checked));
          $("#hiddenUntilComplete").addEventListener("change", (e) => (state.hiddenUntilComplete = !!e.target.checked));
        },
      },
      {
        id: "type",
        titleKey: "sType",
        render() {
          const opts =
            `<option value="">—</option>` +
            TYPES.map((x) => `<option value="${x.id}">${t(x.labelKey)}</option>`).join("");
          return `
            <div class="row">
              <div>
                <label for="typeSel">${t("typeTitle")}</label>
                <select id="typeSel">${opts}</select>
              </div>
            </div>
          `;
        },
        hydrate() {
          $("#typeSel").value = state.type ?? "";
          $("#typeSel").addEventListener("change", (e) => {
            state.type = e.target.value || null;
          });
        },
        validate() {
          if (!state.type) return { ok: false, msg: t("required") };
          return { ok: true };
        },
      },
      {
        id: "typeDetails",
        titleKey: "sTypeDetails",
        render() {
          if (!state.type) return `<div class="hint">${t("required")}</div>`;

          if (state.type === "quest") {
            return `
              <div class="row cols2">
                <div>
                  <label for="questId">${t("questId")}</label>
                  <input id="questId" inputmode="numeric" placeholder="ex: 176" />
                </div>
              </div>
            `;
          }

          if (state.type === "killNpc") {
            return `
              <div class="row">
                <div class="hint">${t("listOnePerLine")} <span class="k">${t("hintNpcCsvKill")}</span></div>
                <div>
                  <label for="killLines">${t("lblNpcList")}</label>
                  <textarea id="killLines" placeholder="4075, Rat, 1\n12480, Melris Malagan, 1"></textarea>
                </div>
              </div>
            `;
          }

          if (state.type === "targetNpc") {
            return `
              <div class="row">
                <div class="hint">${t("npcHintIdOrPlayer")}</div>
                <div class="row cols2" style="margin-top:10px">
                  <div>
                    <label for="targetOneId">targetNpcId</label>
                    <input id="targetOneId" placeholder="ex: 4075 ou Mavenrage" />
                  </div>
                  <div>
                    <label for="targetOneName">${t("npcName")}</label>
                    <input id="targetOneName" placeholder="ex: Rat" />
                  </div>
                </div>
              </div>
            `;
          }

          if (state.type === "talkNpc") {
            return `
              <div class="row">
                <div class="hint">${t("listOnePerLine")} <span class="k">${t("hintNpcCsvTalk")}</span></div>
                <div>
                  <label for="talkLines">${t("lblTalkToList")}</label>
                  <textarea id="talkLines" placeholder="466, General Marcus Jonathan"></textarea>
                </div>
                <div class="inline" style="margin-top:10px">
                  <div class="chk">
                    <input id="talkNpcNativeGossip" type="checkbox" />
                    <label for="talkNpcNativeGossip" style="margin:0">${t("talkNpcNativeGossip")}</label>
                  </div>
                </div>
              </div>
            `;
          }

          if (state.type === "bringItem") {
            return `
              <div class="row cols2">
                <div>
                  <label for="itemId">itemId</label>
                  <input id="itemId" inputmode="numeric" placeholder="ex: 4540" />
                </div>
                <div>
                  <label for="itemCount">nbItem</label>
                  <input id="itemCount" inputmode="numeric" placeholder="ex: 1" />
                </div>
              </div>
              <div class="row cols2" style="margin-top:10px">
                <div>
                  <label for="bringNpcId">${t("npcId")}</label>
                  <input id="bringNpcId" inputmode="numeric" placeholder="ex: 6174" />
                </div>
                <div>
                  <label for="bringNpcName">${t("npcName")}</label>
                  <input id="bringNpcName" placeholder="ex: Stephanie Turner" />
                </div>
              </div>
            `;
          }

          if (state.type === "spendNpc") {
            return `
              <div class="row cols2">
                <div>
                  <label for="spendNpcId">${t("npcId")}</label>
                  <input id="spendNpcId" inputmode="numeric" placeholder="ex: 3518" />
                </div>
                <div>
                  <label for="spendNpcName">${t("npcName")}</label>
                  <input id="spendNpcName" placeholder="ex: Thomas Miller" />
                </div>
              </div>
              <div class="row cols2" style="margin-top:10px">
                <div>
                  <label for="spendCopper">spendCopper</label>
                  <input id="spendCopper" inputmode="numeric" placeholder="ex: 20" />
                </div>
              </div>
            `;
          }

          if (state.type === "completeAchis") {
            return `
              <div class="row">
                <div class="hint">${t("listOnePerLine")} (achId)</div>
                <div>
                  <label for="achiIdsLines">achiIds</label>
                  <textarea id="achiIdsLines" placeholder="CUSTOM-EMOTE-HELLO-GUARD\nCUSTOM-KILL-RAT-CHAIN-TEST-0001"></textarea>
                </div>
              </div>
            `;
          }

          if (state.type === "completeN") {
            return `
              <div class="row cols2">
                <div>
                  <label for="nbAchis">nbAchis</label>
                  <input id="nbAchis" inputmode="numeric" placeholder="ex: 5" />
                </div>
              </div>
            `;
          }

          if (state.type === "itemBag" || state.type === "itemEquip") {
            return `
              <div class="row cols2">
                <div>
                  <label for="itemId2">itemId</label>
                  <input id="itemId2" inputmode="numeric" placeholder="ex: 7723" />
                </div>
                <div>
                  <label for="itemCount2">count</label>
                  <input id="itemCount2" inputmode="numeric" placeholder="ex: 1" />
                </div>
              </div>
            `;
          }

          if (state.type === "fall") {
            return `
              <div class="row cols2">
                <div>
                  <label for="fallHpPct">requiredFallHpLossPct</label>
                  <input id="fallHpPct" inputmode="numeric" placeholder="ex: 5" />
                </div>
                <div class="hint" style="margin-top:22px">${t("hintFallNeedsNpc")}</div>
              </div>
            `;
          }

          return `<div class="hint">—</div>`;
        },
        hydrate() {
          if (state.type === "quest") {
            const el = $("#questId");
            el.value = state.questId ?? "";
            el.addEventListener("input", (e) => (state.questId = asIntOrNull(e.target.value)));
          }
          if (state.type === "killNpc") {
            const el = $("#killLines");
            el.value = state.killLines || "";
            el.addEventListener("input", (e) => (state.killLines = e.target.value));
          }
          if (state.type === "targetNpc") {
            $("#targetOneId").value = state.targetLines || "";
            $("#targetOneName").value = state.targetNpcName || "";
            $("#targetOneId").addEventListener("input", (e) => (state.targetLines = e.target.value));
            $("#targetOneName").addEventListener("input", (e) => (state.targetNpcName = e.target.value));
          }
          if (state.type === "talkNpc") {
            const el = $("#talkLines");
            el.value = state.talkLines || "";
            el.addEventListener("input", (e) => (state.talkLines = e.target.value));
            $("#talkNpcNativeGossip").checked = !!state.talkNpcNativeGossip;
            $("#talkNpcNativeGossip").addEventListener("change", (e) => {
              state.talkNpcNativeGossip = !!e.target.checked;
            });
          }
          if (state.type === "bringItem") {
            $("#itemId").value = state.bringItemId ?? "";
            $("#itemCount").value = state.bringItemCount ?? 1;
            $("#bringNpcId").value = state.bringNpcId ?? "";
            $("#bringNpcName").value = state.bringNpcName ?? "";
            $("#itemId").addEventListener("input", (e) => (state.bringItemId = asIntOrNull(e.target.value)));
            $("#itemCount").addEventListener("input", (e) => (state.bringItemCount = asIntOrNull(e.target.value) ?? 1));
            $("#bringNpcId").addEventListener("input", (e) => (state.bringNpcId = asIntOrNull(e.target.value)));
            $("#bringNpcName").addEventListener("input", (e) => (state.bringNpcName = e.target.value));
          }
          if (state.type === "spendNpc") {
            $("#spendNpcId").value = state.spendNpcId ?? "";
            $("#spendNpcName").value = state.spendNpcName ?? "";
            $("#spendCopper").value = state.spendCopper ?? "";
            $("#spendNpcId").addEventListener("input", (e) => (state.spendNpcId = asIntOrNull(e.target.value)));
            $("#spendNpcName").addEventListener("input", (e) => (state.spendNpcName = e.target.value));
            $("#spendCopper").addEventListener("input", (e) => (state.spendCopper = asIntOrNull(e.target.value)));
          }
          if (state.type === "completeAchis") {
            const el = $("#achiIdsLines");
            el.value = state.achiIdsLines || "";
            el.addEventListener("input", (e) => (state.achiIdsLines = e.target.value));
          }
          if (state.type === "completeN") {
            const el = $("#nbAchis");
            el.value = state.nbAchis ?? "";
            el.addEventListener("input", (e) => (state.nbAchis = asIntOrNull(e.target.value)));
          }
          if (state.type === "itemBag" || state.type === "itemEquip") {
            $("#itemId2").value = state.itemId ?? "";
            $("#itemCount2").value = state.itemCount ?? 1;
            $("#itemId2").addEventListener("input", (e) => (state.itemId = asIntOrNull(e.target.value)));
            $("#itemCount2").addEventListener("input", (e) => (state.itemCount = asIntOrNull(e.target.value) ?? 1));
          }
          if (state.type === "fall") {
            $("#fallHpPct").value = state.fallHpPct ?? "";
            $("#fallHpPct").addEventListener("input", (e) => (state.fallHpPct = asNumberOrNull(e.target.value)));
          }
        },
      },
      {
        id: "npc",
        titleKey: "sNpcWindow",
        when: () => needsStartNpc(),
        render() {
          return `
            <div class="row cols2">
              <div>
                <label for="startNpcId">${t("npcId")}</label>
                <input id="startNpcId" inputmode="numeric" placeholder="ex: 466" />
              </div>
              <div>
                <label for="startNpcName">${t("npcName")}</label>
                <input id="startNpcName" placeholder="ex: General Marcus Jonathan" />
              </div>
            </div>
            <div class="row cols2" style="margin-top:10px">
              <div>
                <label for="startNpcX">${t("npcX")}</label>
                <input id="startNpcX" placeholder="ex: 0.64" />
              </div>
              <div>
                <label for="startNpcY">${t("npcY")}</label>
                <input id="startNpcY" placeholder="ex: 0.75" />
              </div>
            </div>
            <div class="row cols2" style="margin-top:10px">
              <div>
                <label for="startNpcText">${t("npcText")}</label>
                <textarea id="startNpcText" placeholder="..."></textarea>
              </div>
              <div>
                <label for="startNpcButton">${t("npcButton")}</label>
                <input id="startNpcButton" placeholder="ex: Start attempt" />
                <div class="hint">${t("hintOptional")} (${t("tFall")})</div>
              </div>
            </div>
          `;
        },
        hydrate() {
          $("#startNpcId").value = state.startNpcId ?? "";
          $("#startNpcName").value = state.startNpcName ?? "";
          $("#startNpcX").value = state.startNpcX ?? "";
          $("#startNpcY").value = state.startNpcY ?? "";
          $("#startNpcText").value = state.startNpcText ?? "";
          $("#startNpcButton").value = state.startNpcButtonLabel ?? "";
          $("#startNpcId").addEventListener("input", (e) => (state.startNpcId = asIntOrNull(e.target.value)));
          $("#startNpcName").addEventListener("input", (e) => (state.startNpcName = e.target.value));
          $("#startNpcX").addEventListener("input", (e) => (state.startNpcX = asNumberOrNull(e.target.value)));
          $("#startNpcY").addEventListener("input", (e) => (state.startNpcY = asNumberOrNull(e.target.value)));
          $("#startNpcText").addEventListener("input", (e) => (state.startNpcText = e.target.value));
          $("#startNpcButton").addEventListener("input", (e) => (state.startNpcButtonLabel = e.target.value));
        },
        validate() {
          if (!needsStartNpc()) return { ok: true };
          if (!state.startNpcId) return { ok: false, msg: `${t("npcId")} ${t("required")}` };
          return { ok: true };
        },
      },
      {
        id: "runRules",
        titleKey: "sRunRules",
        when: () => state.type !== "completeAchis" && state.type !== "completeN",
        render() {
          return `
            <div class="row cols2">
              <div>
                <label for="timerSet">${t("timerSecondsOnly")}</label>
                <input id="timerSet" inputmode="numeric" placeholder="0" />
                <div class="hint">${t("hintOptional")}</div>
              </div>
            </div>
          `;
        },
        hydrate() {
          $("#timerSet").value = state.timerSet ?? 0;
          $("#timerSet").addEventListener("input", (e) => {
            const v = asIntOrNull(e.target.value);
            state.timerSet = v && v > 0 ? v : null;
          });
        },
      },
      {
        id: "zone",
        titleKey: "sZone",
        render() {
          const opts =
            `<option value="">${t("zoneNone")}</option>` +
            ZONES.map((z) => `<option value="${z.id}">${escLuaString(z.name)} (${z.id})</option>`).join("");
          return `
            <div class="row">
              <div>
                <label for="zoneSel">${t("zoneSelect")}</label>
                <select id="zoneSel">${opts}</select>
              </div>
              <div class="inline" id="zonePreciseWrap" style="margin-top:10px;display:none">
                <div class="chk">
                  <input id="zonePrecise" type="checkbox" />
                  <label for="zonePrecise" style="margin:0">${t("zonePrecise")}</label>
                </div>
              </div>
            </div>
          `;
        },
        hydrate() {
          const sel = $("#zoneSel");
          const wrap = $("#zonePreciseWrap");
          const cb = $("#zonePrecise");
          sel.value = state.zoneId ?? "";
          cb.checked = state.zonePrecise;

          function refresh() {
            const has = !!sel.value;
            wrap.style.display = has ? "flex" : "none";
            if (!has) {
              cb.checked = false;
              state.zonePrecise = false;
            }
          }

          refresh();
          sel.addEventListener("change", () => {
            state.zoneId = sel.value ? Number(sel.value) : null;
            refresh();
          });
          cb.addEventListener("change", () => (state.zonePrecise = !!cb.checked));
        },
      },
      {
        id: "final",
        titleKey: "sFinalText",
        render() {
          return `
            <div class="row cols2">
              <div>
                <label for="title">${t("title")}</label>
                <input id="title" placeholder="ex: Rat killer" />
              </div>
              <div>
                <label for="tooltip">${t("tooltip")}</label>
                <input id="tooltip" placeholder="ex: Kill a Rat in Stormwind City." />
              </div>
            </div>
            <div class="row cols3" style="margin-top:10px">
              <div>
                <label for="icon">${t("icon")}</label>
                <input id="icon" placeholder="ex: 132367" />
              </div>
              <div>
                <label for="points">${t("points")}</label>
                <input id="points" inputmode="numeric" placeholder="ex: 5" />
              </div>
              <div>
                <label for="level">${t("level")}</label>
                <input id="level" inputmode="numeric" placeholder="ex: 50" />
              </div>
            </div>
          `;
        },
        hydrate() {
          $("#title").value = state.title;
          $("#tooltip").value = state.tooltip;
          $("#icon").value = state.icon;
          $("#points").value = state.points ?? "";
          $("#level").value = state.level ?? "";
          $("#title").addEventListener("input", (e) => (state.title = e.target.value));
          $("#tooltip").addEventListener("input", (e) => (state.tooltip = e.target.value));
          $("#icon").addEventListener("input", (e) => (state.icon = e.target.value));
          $("#points").addEventListener("input", (e) => (state.points = asIntOrNull(e.target.value)));
          $("#level").addEventListener("input", (e) => (state.level = asIntOrNull(e.target.value)));
        },
        validate() {
          if (!state.title.trim()) return { ok: false, msg: `${t("title")} ${t("required")}` };
          if (!state.tooltip.trim()) return { ok: false, msg: `${t("tooltip")} ${t("required")}` };
          return { ok: true };
        },
      },
      {
        id: "ids",
        titleKey: "sIds",
        render() {
          return `
            <div class="row cols2">
              <div>
                <label for="achId">${t("achIdInput")}</label>
                <input id="achId" placeholder="ex: COURSE-A-PIED" />
                <div class="hint">${t("idsHint")}</div>
              </div>
              <div>
                <label for="unlockedBy">${t("unlockedBy")}</label>
                <input id="unlockedBy" placeholder="ex: CUSTOM-STEP-0001 ou CUSTOM-A,CUSTOM-B" />
              </div>
            </div>
          `;
        },
        hydrate() {
          const a = $("#achId");
          const u = $("#unlockedBy");
          a.value = state.achId || "";
          u.value = state.unlockedByRaw || "";
          a.addEventListener("input", () => {
            const norm = normalizeAchId(a.value);
            a.value = norm;
            state.achId = norm;
          });
          u.addEventListener("input", () => (state.unlockedByRaw = u.value));
        },
        validate() {
          if (!state.achId) return { ok: false, msg: `${t("achIdInput")} ${t("required")}` };
          return { ok: true };
        },
      },
    ];

    return defs.filter((d) => (typeof d.when === "function" ? d.when() : true));
  }

  let stepIndex = 0;

  function renderCurrentStep() {
    const defs = stepDefs();
    if (stepIndex < 0) stepIndex = 0;
    if (stepIndex >= defs.length) stepIndex = defs.length - 1;

    const current = defs[stepIndex];
    stepTitle.textContent = t(current.titleKey);

    stepsHost.innerHTML = "";
    defs.forEach((_, i) => {
      const el = document.createElement("div");
      el.className = "stepDot" + (i === stepIndex ? " active" : "");
      el.textContent = `${t("stepLabel")} ${i + 1}`;
      // Allow clicking on previous steps to go back.
      if (i < stepIndex) {
        el.style.cursor = "pointer";
        el.title = t("backBtn");
        el.addEventListener("click", () => {
          stepIndex = i;
          renderCurrentStep();
        });
      }
      stepsHost.appendChild(el);
    });

    stepHost.innerHTML = current.render();
    current.hydrate?.();

    btnBack.disabled = stepIndex === 0;
    const isLast = stepIndex === defs.length - 1;
    btnNext.hidden = isLast;
    btnGenerate.hidden = !isLast;
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function validateCurrentStep() {
    const defs = stepDefs();
    const current = defs[stepIndex];
    const res = current.validate?.() ?? { ok: true };
    if (!res.ok) {
      outHint.innerHTML = `<div class="dangerText">⚠ ${escLuaString(res.msg || t("required"))}</div>`;
      return false;
    }
    outHint.textContent = "";
    return true;
  }

  function luaIconValue(raw) {
    const s = String(raw ?? "").trim();
    if (!s) return null;
    const n = Number(s);
    if (Number.isFinite(n) && /^\d+$/.test(s)) return String(Math.trunc(n));
    return `"${escLuaString(s)}"`;
  }

  function generateLua() {
    const defs = stepDefs();
    for (let i = 0; i < defs.length; i++) {
      const res = defs[i].validate?.() ?? { ok: true };
      if (!res.ok) {
        stepIndex = i;
        renderCurrentStep();
        outHint.innerHTML = `<div class="dangerText">⚠ ${escLuaString(res.msg || t("required"))}</div>`;
        btnCopy.disabled = true;
        return;
      }
    }

    const zone = state.zoneId ? ZONES.find((z) => Number(z.id) === Number(state.zoneId)) : null;
    const attemptEnabled = false;

    const lines = [];
    lines.push("{");
    lines.push(`  achId = "${escLuaString(state.achId)}",`);
    lines.push(`  title = "${escLuaString(state.title.trim())}",`);
    lines.push(`  tooltip = "${escLuaString(state.tooltip.trim())}",`);

    const icon = luaIconValue(state.icon);
    if (icon) lines.push(`  icon = ${icon},`);
    if (state.points != null) lines.push(`  points = ${state.points},`);
    if (state.level != null) lines.push(`  level = ${state.level},`);
    else lines.push("  level = nil,");

    if (state.faction === "alliance") lines.push("  faction = FACTION_ALLIANCE,");
    else if (state.faction === "horde") lines.push("  faction = FACTION_HORDE,");
    if (state.class !== "any") lines.push(`  class = "${escLuaString(state.class)}",`);
    if (state.race !== "any") lines.push(`  race = "${escLuaString(state.race)}",`);
    if (state.selfFoundOnly) lines.push("  selfFoundOnly = true,");

    if (state.secret) lines.push("  secret = true,");
    if (state.hiddenUntilComplete) lines.push("  hiddenUntilComplete = true,");

    const unlockedBy = parseUnlockedBy(state.unlockedByRaw);
    if (unlockedBy) lines.push(`  unlockedBy = ${unlockedBy},`);

    if (zone) {
      lines.push(`  zone = "${escLuaString(zone.name)}",`);
      if (state.zonePrecise) lines.push(`  zoneAccurate = ${zone.id},`);
    }

    if (state.timerSet != null) lines.push(`  timerSet = ${state.timerSet},`);

    if (state.type === "quest") {
      if (state.questId != null) lines.push(`  requiredQuestId = ${state.questId},`);
    } else if (state.type === "killNpc") {
      const entries = parseLines(state.killLines)
        .map(parseCsvLine)
        .map((p) => ({ id: asIntOrNull(p[0]), name: p[1] || "", count: asIntOrNull(p[2]) ?? 1 }))
        .filter((e) => e.id != null);
      if (entries.length === 1 && entries[0].count === 1) {
        const e = entries[0];
        lines.push(`  targetNpcId = ${e.id},${e.name ? ` -- ${e.name}` : ""}`);
      } else if (entries.length) {
        lines.push("  requiredKills = {");
        for (const e of entries) lines.push(`    [${e.id}] = ${e.count},${e.name ? ` -- ${e.name}` : ""}`);
        lines.push("  },");
      }
    } else if (state.type === "targetNpc") {
      const raw = String(state.targetLines || "").trim();
      const name = String(state.targetNpcName || "").trim();
      if (raw) {
        if (/^\d+$/.test(raw)) {
          const id = asIntOrNull(raw);
          if (id != null) lines.push(`  targetNpcId = ${id},${name ? ` -- ${escLuaString(name)}` : ""}`);
        } else {
          lines.push(`  targetNpcId = "${escLuaString(raw)}",`);
        }
      }
    } else if (state.type === "talkNpc") {
      const entries = parseLines(state.talkLines).map(parseCsvLine).map((p) => ({ id: asIntOrNull(p[0]), name: p[1] || "" })).filter((e) => e.id != null);
      if (entries.length) {
        lines.push("  requiredTalkTo = {");
        for (const e of entries) lines.push(`    [${e.id}] = "${escLuaString(e.name || String(e.id))}",`);
        lines.push("  },");
      }
    } else if (state.type === "bringItem") {
      if (state.bringItemId != null && state.bringNpcId != null) {
        lines.push("  dropItemOn = {");
        lines.push(`    itemId = ${state.bringItemId},`);
        lines.push(`    nbItem = ${state.bringItemCount ?? 1},`);
        lines.push(`    npcId = ${state.bringNpcId},${state.bringNpcName ? ` -- ${escLuaString(state.bringNpcName)}` : ""}`);
        lines.push("  },");
      }
    } else if (state.type === "spendNpc") {
      if (state.spendNpcId != null) lines.push(`  spendAtNpcId = ${state.spendNpcId},${state.spendNpcName ? ` -- ${escLuaString(state.spendNpcName)}` : ""}`);
      if (state.spendCopper != null) lines.push(`  spendCopper = ${state.spendCopper},`);
    } else if (state.type === "completeAchis") {
      const ids = parseLines(state.achiIdsLines);
      if (ids.length) {
        lines.push("  achiIds = {");
        ids.forEach((id) => lines.push(`    "${escLuaString(id)}",`));
        lines.push("  },");
      }
    } else if (state.type === "completeN") {
      if (state.nbAchis != null) lines.push(`  nbAchis = ${state.nbAchis},`);
    } else if (state.type === "itemBag") {
      if (state.itemId != null) {
        const count = state.itemCount ?? 1;
        lines.push("  customItem = function()");
        lines.push(`    return GetItemCount(${state.itemId}, true) >= ${count}`);
        lines.push("  end,");
      }
    } else if (state.type === "itemEquip") {
      if (state.itemId != null) {
        lines.push("  customItem = function()");
        lines.push("    for slot = 1, 19 do");
        lines.push('      local id = GetInventoryItemID("player", slot)');
        lines.push(`      if id == ${state.itemId} then`);
        lines.push("        return true");
        lines.push("      end");
        lines.push("    end");
        lines.push("    return false");
        lines.push("  end,");
      }
    } else if (state.type === "fall") {
      if (state.fallHpPct != null) lines.push(`  requiredFallHpLossPct = ${state.fallHpPct},`);
    }

    if (needsStartNpc() && state.startNpcId != null) {
      lines.push("  startNpc = {");
      lines.push(`    npcId = ${state.startNpcId},${state.startNpcName ? ` -- ${escLuaString(state.startNpcName)}` : ""}`);
      if (state.startNpcX != null && state.startNpcY != null && zone) {
        lines.push(`    coords = { mapId = ${zone.id}, x = ${state.startNpcX}, y = ${state.startNpcY} }, -- ${escLuaString(zone.name)}`);
      }
      if (!isBlank(state.startNpcText) || !isBlank(state.startNpcButtonLabel) || state.type === "fall") {
        lines.push("    window = {");
        lines.push(`      title = "${escLuaString(state.title.trim())}",`);
        if (!isBlank(state.startNpcText)) lines.push(`      text = "${escLuaString(state.startNpcText)}",`);
        if (!isBlank(state.startNpcButtonLabel)) lines.push(`      buttonLabel = "${escLuaString(state.startNpcButtonLabel)}",`);
        // No attempt activation in this simplified wizard.
        lines.push("    },");
      }
      lines.push("  },");
    }

    if (forceInteractDistance()) lines.push("  checkInteractDistance = true,");

    lines.push("},");

    out.textContent = lines.join("\n");
    btnCopy.disabled = false;
    outHint.innerHTML = '<div class="ok">OK</div>';
  }

  function doCopy() {
    const text = out.textContent || "";
    if (!text || text === t("outEmpty")) return;
    navigator.clipboard
      .writeText(text)
      .then(() => {
        btnCopy.textContent = t("copiedBtn");
        setTimeout(() => (btnCopy.textContent = t("copyBtn")), 900);
      })
      .catch(() => {
        const ta = document.createElement("textarea");
        ta.value = text;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand("copy");
        document.body.removeChild(ta);
        btnCopy.textContent = t("copiedBtn");
        setTimeout(() => (btnCopy.textContent = t("copyBtn")), 900);
      });
  }

  function doReset() {
    if (!confirm(t("resetConfirm"))) return;
    Object.assign(state, {
      faction: "both",
      class: "any",
      race: "any",
      selfFoundOnly: false,
      secret: false,
      hiddenUntilComplete: false,
      type: null,
      questId: null,
      killLines: "",
      targetLines: "",
      targetNpcName: "",
      talkLines: "",
      talkNpcNativeGossip: false,
      bringItemId: null,
      bringItemCount: 1,
      bringNpcId: null,
      bringNpcName: "",
      spendNpcId: null,
      spendNpcName: "",
      spendCopper: null,
      achiIdsLines: "",
      nbAchis: null,
      itemId: null,
      itemCount: 1,
      fallHpPct: null,
      startNpcId: null,
      startNpcName: "",
      startNpcX: null,
      startNpcY: null,
      startNpcText: "",
      startNpcButtonLabel: "",
      timerSet: null,
      zoneId: null,
      zonePrecise: false,
      title: "",
      tooltip: "",
      icon: "",
      points: null,
      level: null,
      achId: "",
      unlockedByRaw: "",
    });
    stepIndex = 0;
    out.textContent = t("outEmpty");
    outHint.textContent = "";
    btnCopy.disabled = true;
    renderCurrentStep();
  }

  // Init
  applyI18nStatic();
  if (out.textContent.trim() === "") out.textContent = t("outEmpty");

  btnBack.addEventListener("click", () => {
    stepIndex = Math.max(0, stepIndex - 1);
    renderCurrentStep();
  });

  btnNext.addEventListener("click", () => {
    if (!validateCurrentStep()) return;
    stepIndex += 1;
    renderCurrentStep();
  });

  btnGenerate.addEventListener("click", () => generateLua());
  btnCopy.addEventListener("click", doCopy);
  btnReset.addEventListener("click", doReset);

  if (btnLang) {
    btnLang.addEventListener("click", () => {
      lang = lang === "fr" ? "en" : "fr";
      applyI18nStatic();
      renderCurrentStep();
    });
  }

  renderCurrentStep();
})();

