# MENU FLOW — Screen Inventory & Flow Specification

Project: Vajb Orbit (Dark Orbit–style top-down 2D sci-fi space shooter, Godot 4.7, desktop PC).
Tone reference: Dark Orbit browser game — utilitarian sci-fi fleet UI, corporate faction flavor, dense but readable panels, session-based accounts, persistent pilot progression.
Scope of this document: navigation flow, screen inventory, focus behavior, transitions, and persistent state. **Not** visual styling (colors, fonts, art direction are out of scope).

---

## 1. Global Flow Overview

```
BOOT / SPLASH
  └─> LOGIN
        ├─ (no session) ──────────────────> account create / connect flow (in-screen states)
        └─ (auth ok) ──> COMPANY SELECT (first launch only) ──> HANGAR
                             │ (returning pilot, company known) ─────> HANGAR
HANGAR (hub)
  ├─> SETTINGS (overlay, returns)
  ├─> STARMAP / SECTOR SELECT ──> LOADING ──> GAME (HUD handoff)
  ├─> CREDITS (overlay, returns)
  └─> QUIT CONFIRMATION ──> desktop

GAME (HUD)
  └─> PAUSE MENU
        ├─> RESUME ──> back to GAME
        ├─> SETTINGS (overlay, returns to pause)
        ├─> ABANDON / RETURN TO HANGAR ──> LOADING (return) ──> HANGAR
        └─> QUIT CONFIRMATION ──> desktop

GAME death ──> GAME OVER / RESPAWN
  ├─> RESPAWN (in-sector) ──> GAME
  └─> RETURN TO HANGAR ──> LOADING ──> HANGAR
```

Invariants:

- **Settings is reachable from every interactive screen** (login, company select, hangar, starmap, loading, pause, game over) as an overlay. It never replaces the underlying screen; closing it restores focus to the widget that opened it.
- **Loading is the only bridge into and out of the gameplay scene.** No screen other than Loading may directly open or close the game world scene.
- **Hangar is the persistent hub.** Every non-gameplay screen eventually routes back to Hangar (except quit).
- Quit confirmation is the only exit to desktop, and it can be triggered from Hangar, Pause, and OS window close.

---

## 2. Persistent State Model (cross-screen)

State that survives screen transitions, grouped by owner. Every screen below references these names.

| State | Owner | Contents | Persisted to disk? |
|---|---|---|---|
| `Session` | Session manager (autoload) | auth token, account id, session expiry, remember-me flag | token only, if remember-me |
| `PilotProfile` | Session (server-authoritative, cached) | callsign, company, level, credits/uridium/jackpot, rank | yes (cache; server is truth) |
| `CompanyChoice` | Session | chosen faction/company; immutable after confirm | yes |
| `Loadout` | Session | selected ship id, equipped equipment slots, ammo selection | yes |
| `Settings` | Settings autoload | audio buses (master/music/sfx), display mode/resolution/vsync, input bindings, UI scale, language | yes |
| `SectorSelection` | Session | last chosen sector, sector filters, bookmarked sectors | last sector: yes |
| `FlowState` | Screen router | current screen, overlay stack, return-focus target | no |
| `RunStats` | Session (in-run only) | current sector, hull/shield, cargo, kill feed, rewards pending | no (server reconciles on death/exit) |

Rules:

- Screens read; only the owning manager writes. Screens emit intents (signals) upward; managers and the router act on them (signals up, calls down).
- The screen router (a single autoload) owns scene transitions and the overlay stack. Screens never call `change_scene` themselves.
- Overlays (Settings, Credits, Quit confirm, dialog boxes) always push onto an overlay stack so nested returns are deterministic.

---

## 3. Screen Inventory

### 3.1 Boot / Splash

**Purpose:** Engine warm-up, license/branding flash, and preflight (version check against server, patch detection). Establishes that the client is alive before any interaction is required.

**Entry points:** Application launch. Only screen with no back path.

**Exits:** → Login (normal). → Maintenance/offline error panel (server unreachable or version mismatch) with "Retry" and "Quit" actions.

**Layout zones:**
- Center: game logo.
- Bottom strip: version string, build hash, progress line for preflight checks.
- Error state reuses the bottom strip as a message area with two focused buttons.

**Keyboard/gamepad focus:** None required; fully automatic. On error state, focus lands on "Retry" (gamepad A/Enter). B/Esc on error quits after confirmation dialog. Any key input during the normal splash is ignored (no skip-to-hold protection needed; splash is short).

**Transitions:** Automatic fade to Login when preflight passes. No user input needed for the happy path.

**Persistent state touched:** Reads version/build; writes nothing. Populates `FlowState.currentScreen = BOOT`.

**Failure states:** Version mismatch blocks Login and offers Quit. Server timeout offers Retry (re-runs preflight) or Offline-mode entry is **not** offered (Dark Orbit reference is server-authoritative; no offline play).

---

### 3.2 Login

**Purpose:** Authenticate the pilot. Gate all content behind a valid session. First-touch screen: the player learns input conventions here.

**Entry points:** From Boot. From Settings overlay close. From session-expiry bounce (any screen, with a "session expired" banner).

**Exits:** → Company Select (new account, no `CompanyChoice`). → Hangar (returning pilot). → Boot error panel (server lost mid-auth).

**Layout zones:**
- Left/main column: callsign and password fields, "Connect" primary action, "Create account" secondary toggle, remember-me checkbox.
- Right column: server status, news/announcement ticker, version. (Static info zone; never takes focus.)
- Top-right corner: Settings gear button.
- Banner slot (top, above form): contextual errors ("wrong password", "session expired", "maintenance").

**Keyboard/gamepad focus:**
- Focus order: callsign field → password field → remember-me → Connect → Create account → Settings gear. Tab / shoulder-cycle moves forward, Shift-Tab back.
- Enter in a text field commits that field (moves focus to next, not submit). Enter on Connect submits.
- Gamepad: A activates, B goes back (back from Login = quit confirmation). Virtual keyboard appears when a text field is activated by gamepad; gamepad-navigable.
- Default focus on entry: callsign field (empty) or Connect (if remember-me auto-filled the callsign).

**Transitions:** Submit → brief "authenticating" spinner state inside the Connect button (button becomes non-interactive) → route per `CompanyChoice` presence. Failure re-enables the form and shows the banner; focus returns to the offending field.

**Persistent state touched:** Writes `Session`, reads/writes remember-me. Auto-login attempt if a valid stored token exists: show the splash spinner overlaid, and route straight through to Hangar with a "connecting" toast; Esc cancels auto-login back to the manual form.

---

### 3.3 Main Menu

**Purpose:** In the Dark Orbit model the logged-in hub effectively **is** the Hangar; there is no separate traditional main menu. A thin "main menu" exists as the Hangar's persistent top-level action bar (Play/Enter space, Hangar tabs, Settings, Credits, Quit). It is inventoried here as a logical screen for flow clarity, implemented as a screen-level zone, not a separate scene.

**Entry points:** Implicitly active whenever Hangar is the current screen and no modal overlay is open.

**Exits:** → Starmap (Play), → Settings, → Credits, → Quit confirmation.

**Layout zones:**
- Top bar: callsign, company insignia, currency readouts, level/rank.
- Primary action zone: "Enter Space" (goes to Starmap) as the dominant CTA.
- Secondary actions: Settings, Credits, Quit.
- Content zone: Hangar panels (see 3.5).

**Keyboard/gamepad focus:** Focus starts on "Enter Space". Cycle order: Enter Space → Hangar tabs → ship/equipment panels (contextual) → Settings → Credits → Quit.

**Transitions:** Direct routes; overlays push on the stack.

**Persistent state touched:** Renders `PilotProfile`, `Loadout`.

---

### 3.4 Company / Faction Select

**Purpose:** One-time, irreversible choice of the pilot's company (three-way choice, Dark Orbit's MMO/MIC/VEN model). Shapes starting equipment, home sector, and cosmetic identity.

**Entry points:** First successful login with no `CompanyChoice`. **Never** reachable afterward (no re-select in v1; a "contact support" note may appear in hangar UI later — out of scope here).

**Exits:** → Hangar (on confirm). → Login (log out via user menu in the corner). → Settings overlay.

**Layout zones:**
- Full-width triptych: one panel per company. Each panel: company name, blurb, starting-ship summary, home sector name, "Select" button.
- Bottom bar: comparison hint line ("you can view details before committing"), Cancel/Logout (left), Confirm (right, disabled until a company is highlighted).
- Detail mode: selecting a company expands its panel (or opens a details overlay) with full starting loadout list before confirm.

**Keyboard/gamepad focus:**
- Focus order: company panels left→right (Select or "Details" on each) → Confirm → Cancel/logout.
- Choosing a panel arms it (visual armed state is allowed; this is flow, not styling). Confirm requires an armed company; activating Confirm opens the **double-confirmation dialog** ("This choice is permanent").
- Esc/B: if a details overlay is open, closes it; else focus Cancel (logout path must also confirm via quit-style dialog).

**Transitions:** Confirm → dialog → brief "founding your pilot" processing state → Hangar with first-time welcome toast. No back after processing begins.

**Persistent state touched:** Writes `CompanyChoice`, then `PilotProfile` defaults. Reads `Session`.

---

### 3.5 Hangar (Hub: Ship Select + Equipment Loadout)

**Purpose:** The pilot's persistent home. Choose a ship from the owned fleet, equip/unequip equipment into ship slots, select ammo, review profile, and launch into a sector.

**Entry points:** From Login (returning), Company Select (new), Loading (return from space, both via pause-exit and after death return), session-expiry bounce back after re-login.

**Exits:** → Starmap, → Settings, → Credits, → Quit confirmation, → Login (logout, with confirmation).

**Layout zones:**
- Top bar (see Main Menu, 3.3).
- Left zone: **ship list** — owned ships with hull class, condition, level requirement. One ship selectable at a time.
- Center zone: **ship preview** — selected ship with its slots; each slot (weapons, generators, engines, extras) shows equipped item or empty.
- Right zone: **inventory / equipment picker** — owned items filtered by selected slot type; activate to equip. Also ammo selection and quick stats (speed, shields, firepower, cargo).
- Bottom bar: "Enter Space" CTA, credits/uridium, Settings/Credits/Quit cluster.
- Modal-capable: sell/trade dialogs, "not enough credits" toasts, logout confirmation.

**Keyboard/gamepad focus:**
- Zone-locked navigation: left shoulder/right shoulder (or Tab groups) moves between ship list → slot grid → equipment picker → bottom bar. Up/down/left/right navigate within a zone. This mirrors Dark Orbit's panel-based browsing.
- In ship list: A selects ship (updates center preview live). In slot grid: A opens the equipment picker focused on the matching type. In picker: A equips (slot re-renders; focus stays in picker for multi-equip), X/Y opens item detail (sell/compare). B backs out one zone level.
- "Enter Space" requires a valid loadout (at least one ship with a working engine); invalid states disable the CTA with a reason tooltip/banner.
- Default focus on entry: "Enter Space" (fast path for returning players), except first visit after company select: focus the ship list.

**Transitions:** Equip actions are instant and optimistic (no scene change). Enter Space → Starmap. All overlays push/pop on the stack.

**Persistent state touched:** Reads/writes `Loadout`, reads `PilotProfile`. Sell/equip may write credits (server round-trip; UI optimistic with rollback on failure).

---

### 3.6 Starmap / Sector Select

**Purpose:** Choose the destination sector to launch into. Dark Orbit's map browser: a starmap of sectors with danger/pvp indicators, plus a list view with filters.

**Entry points:** From Hangar ("Enter Space").

**Exits:** → Loading (launch confirmed), → Hangar (back), → Settings overlay, → Quit confirmation.

**Layout zones:**
- Main zone: **starmap** — pan/zoom canvas of sector nodes (home sectors, neutral sectors, high-danger zones). Selected node shows a hover/held card: name, company ownership, recommended level, player count, PVP rules.
- Side zone (right): **sector list** — same data as rows, sortable (danger, population, distance from home), filter chips (PVP on/off, own company only).
- Bottom bar: sector summary of current selection, "Launch" CTA (disabled if sector locked/level-gated), Back.

**Keyboard/gamepad focus:**
- Map mode: left stick pans, right stick or triggers zoom, d-pad nudges node selection, A opens/locks selection card, Y toggles to list mode.
- List mode: standard row navigation; X toggles filters (filter chips are individually focusable too).
- B backs out (→ Hangar). Enter/A on Launch → confirmation is **not** required for normal sectors; required only for high-danger sectors (warning dialog with level-gap statement).
- Default focus: the last selected sector node (from `SectorSelection.lastSector`), or home sector if none.

**Transitions:** Launch → Loading with selected sector id. Back → Hangar, restoring Hangar's previous focus target.

**Persistent state touched:** Reads/writes `SectorSelection` (last sector, filters, bookmarks if present). Reads `PilotProfile` for level-gating.

---

### 3.7 Loading

**Purpose:** Bridge screen while the space scene streams in (or while returning to Hangar). Shows destination info and hides world instantiation cost.

**Entry points:** From Starmap (launch into sector), from Pause (abandon/return to hangar), from Game Over (return to hangar).

**Exits:** → Game/HUD (launch), → Hangar (return), → Login (session lost during load). → Abort possible only for the *return* direction ("Cancel" while still loading back), never mid-launch.

**Layout zones:**
- Center: destination name and company emblem (or "Returning to hangar").
- Lower third: progress bar, rotating tip lines (gameplay hints).
- Corner: cancel button, only when the direction is return-to-hangar.

**Keyboard/gamepad focus:** None on the happy path (non-interactive). Cancel button (return-direction only) takes focus if the player presses any key; B also activates it.

**Transitions:** Fade-in from source screen, fade-out to destination. Minimum display time (short, e.g. 0.8–1.5 s) so the screen doesn't strobe on fast loads.

**Persistent state touched:** Consumes `SectorSelection` for launch; writes `FlowState` route. On completion, hands `RunStats` initialization data to the game scene.

---

### 3.8 In-Game HUD (handoff note — not a menu)

**Purpose:** Gameplay view. This document only records the **handoff contract** between the menu flow and the HUD; full HUD spec is its own document.

**Handoff contract (menu-side responsibilities):**
- The game scene receives, at load: sector id, pilot loadout snapshot, `RunStats` (fresh or restored), and a callback route to open the Pause menu.
- Pause is triggered by Esc/Start **only**; the HUD never opens other menu screens directly — it asks the screen router (signals up), and the router decides (e.g. session-expiry forces Login regardless of HUD state).
- Death is routed by the game scene to the Game Over screen flow (3.9); the HUD stays mounted underneath if respawn is chosen (no scene reload on respawn — only on sector re-entry).
- Session expiry or server disconnect during play: force-route to Login with "session expired" banner, discarding unsaved run state per server reconciliation.

**Persistent state touched:** Reads `Loadout` snapshot, writes `RunStats`; on exit/death, RunStats reconcile to server, then `PilotProfile` cache updates.

---

### 3.9 Pause Menu

**Purpose:** Suspend gameplay access to navigation without unloading the world. Offers resume, settings, return to hangar, quit.

**Entry points:** Esc/Start during gameplay. Also auto-pauses on focus loss (optional setting, on by default for solo play).

**Exits:** → Game (resume), → Settings overlay (returns to pause), → Loading (return to hangar), → Quit confirmation (desktop).

**Layout zones:**
- Left column, vertical list: Resume, Settings, Return to Hangar, Quit Game.
- Right zone: contextual panel — current sector, run stats snapshot (time in sector, kills, cargo value), connection quality indicator.
- The game world remains visible, dimmed and frozen, behind the menu.

**Keyboard/gamepad focus:**
- Vertical list navigation; default focus on Resume. A activates, B/Esc/Resume all return to game.
- "Return to Hangar" opens a confirmation dialog (pending cargo/rewards may be lost — state the consequence explicitly in the dialog body).
- Quit opens the standard quit confirmation (3.11).
- Game is **suspended** (not merely paused-visual) while this menu or any child overlay is open.

**Transitions:** Push/pop overlay semantics; returning to hangar goes through Loading (return direction).

**Persistent state touched:** Reads `RunStats` for display; triggers server reconcile on abandon.

---

### 3.10 Game Over / Respawn

**Purpose:** Report destruction, show losses and salvage, and offer respawn in the same sector or retreat to hangar.

**Entry points:** Hull reaches zero during gameplay (game scene routes here; HUD stays mounted for respawn path).

**Exits:** → Game (respawn in-sector), → Loading → Hangar (retreat), → Settings overlay, → Quit confirmation.

**Layout zones:**
- Center column: destruction summary — destroyed ship, lost equipment per loss rules, cargo dropped, credits/uridium delta, killer info (name/company) in PVP.
- Action row: "Respawn" (primary, shows respawn cost/delay), "Return to Hangar", small cluster: Settings, Quit.
- Timer element: respawn has a countdown before the button enables (repair time flavor); retreat has no timer.

**Keyboard/gamepad focus:**
- During countdown, focus is on "Return to Hangar" (only enabled action). After countdown, focus moves to "Respawn".
- A activates focused action; B does nothing (no implicit retreat — retreat is a deliberate choice because it forfeits the sector position).
- Esc opens Settings overlay (consistent with global rule), not retreat.

**Transitions:** Respawn → countdown → camera/state reset back into the live HUD (no Loading screen — same scene). Retreat → Loading (return). If the pilot has no remaining ship in hangar, Respawn is disabled with an explanatory line and only retreat/quitting remains.

**Persistent state touched:** Server reconciles losses on death; updates `PilotProfile`, possibly `Loadout` (if current ship destroyed). `RunStats` ends on retreat; resets partially on respawn per rules.

---

### 3.11 Credits

**Purpose:** Attribution for team, third-party assets, and AI-generated asset usage terms (project rule: generator terms must be recorded and shipped with the game).

**Entry points:** From Hangar/main-menu cluster, from Login (secondary link), from Settings' "About" section, from Pause menu footer (during gameplay, credits are reachable but the game stays suspended).

**Exits:** Back to the screen that opened it (overlay semantics — remember origin via overlay stack).

**Layout zones:**
- Scrollable single column: sections (Team, Engine/Tools, Asset sources, AI-generation terms and log reference, Licenses).
- Bottom bar: "Back" button; scroll position persists while overlay is open.

**Keyboard/gamepad focus:** Left stick/d-pad scrolls; A does nothing (no links activated by pad unless a link row is focusable); Esc/B closes. If mouse is used, scroll wheel works and Back is clickable.

**Transitions:** Pure overlay push/pop. Never changes the underlying screen.

**Persistent state touched:** None (read-only, static content).

---

### 3.12 Settings (global overlay)

**Purpose:** Configure audio, display, input, and accessibility from anywhere. One implementation, reused everywhere.

**Entry points:** Gear buttons on Login, Hangar top bar, Starmap bottom bar, Pause menu list, Game Over action cluster, and the quit-confirmation dialog's corner. Esc on Login also opens it (Login has no gameplay context to cancel to).

**Exits:** Back to the opening screen/widget (overlay pop). Apply model: audio and gameplay toggles apply live; display changes (resolution/mode) apply on "Apply" with a 10-second revert-on-confirm timer dialog if the display enters a possibly-blank state.

**Layout zones:**
- Left column: category tabs — Audio, Display, Controls, Gameplay/Accessibility, About.
- Right zone: settings rows for the active category.
- Bottom bar: Apply (only when dirty), Revert changes, Back.
- Controls category: per-action binding list with rebind flow ("press a key…" capture state), gamepad and keyboard listed separately, reset-to-defaults per device.

**Keyboard/gamepad focus:**
- Tab groups: category tabs → rows → bottom bar. Rows: A/Enter toggles or opens value cycling (left/right adjusts sliders and option rows).
- Rebind capture: while capturing, all input is consumed by capture; Esc cancels capture, and Esc-as-a-binding is entered with a secondary confirm.
- Default focus: first row of the last-visited category (`Settings.lastCategory`, session-scoped, not persisted to disk).
- B/Esc closes only when nothing is dirty; if dirty, a small confirm dialog ("Discard changes?") intercepts.

**Persistent state touched:** Writes `Settings` on Apply (disk). Display revert-timer writes only after confirm. Reads nothing else.

---

### 3.13 Quit Confirmation (shared dialog)

**Purpose:** Guard the exit-to-desktop path. One shared dialog component, parameterized by origin context.

**Entry points:** Quit buttons on Hangar/main menu and Pause menu; B/Esc on Login (where "back" means quit); Alt+F4 / OS window close at any interactive screen; error panels on Boot.

**Exits:** Confirm → desktop (graceful: save settings, reconcile session, then exit). Cancel → back to originating screen with focus restored to the widget that requested quit.

**Layout zones:** Modal dialog centered over a dimmed parent: title ("Quit Vajb Orbit?"), context line (e.g. "You are docked in the hangar. Progress is saved." vs. in-game: "Unsaved sector progress will be lost. Rewards are reconciled on exit."), buttons: Quit / Cancel. Settings gear available in the corner (global rule).

**Keyboard/gamepad focus:** Default focus on **Cancel** (destructive-default-safe). A on Cancel pops back; A on Quit exits. Esc behaves as Cancel. During gameplay origin, the game remains suspended while the dialog is open.

**Persistent state touched:** On confirm: flush `Settings`, session logout (token kept only if remember-me), server reconcile if leaving gameplay, then quit.

---

## 4. Cross-Cutting Flow Rules

### 4.1 Overlay discipline
All overlays (Settings, Credits, confirm dialogs, rebind capture) live on a single overlay stack owned by the screen router. Rules:
- Only the top overlay is interactive; the stack below is dimmed and inert.
- Every push records the focused widget; every pop restores focus to it.
- Overlays may nest at most two deep (e.g. Pause → Settings → display-revert confirm). Deeper chains are a spec smell; flatten.

### 4.2 Focus restoration
Whenever a screen regains control after an overlay or a child route (Starmap → Hangar → Starmap), the previously focused widget regains focus. If that widget no longer exists (loadout changed), focus falls to the screen's documented default focus target.

### 4.3 Server-loss handling (applies to all screens)
If the session drops while on any screen: route to Login with the "session expired" banner, discarding overlay stack. If it happens mid-gameplay: reconcile what the server acknowledges, then same route. Boot-level failure (server down entirely) routes to Boot's error panel instead.

### 4.4 Input conventions (all screens)
- A/Enter: activate focused control. B/Esc: back/close (context-dependent; never destroys progress silently — always confirm).
- X/Y: contextual secondary actions (item details, filters) — documented per screen.
- Tab / shoulder buttons: move between focus zones where zone navigation is defined.
- Start: pause equivalent in gameplay; menu equivalent on menu screens (opens Settings).
- Mouse is fully supported everywhere (Dark Orbit heritage is mouse-first); keyboard/gamepad parity is a requirement, not an afterthought: every mouse-reachable action must be focusable.

### 4.5 Transition inventory
| Transition | Style | Notes |
|---|---|---|
| Boot → Login | Fade | Automatic |
| Login → Company Select / Hangar | Fade + toast | Toast announces welcome/expiry |
| Hangar ↔ Starmap | Slide/fade, short | Both directions restore focus |
| Any → Loading | Fade-in with min-duration | Cancel only on return direction |
| Loading → Game/HUD | Fade-out into world spawn | Spawn is server-confirmed |
| Game → Pause | Push overlay + freeze world | Esc/Start toggles |
| Death → Game Over | Non-fade, immediate | HUD stays mounted for respawn |
| Respawn → Game | Countdown → in-place reset | No Loading screen |
| Any → Settings/Credits/Quit | Overlay push/pop | Focus restore on pop |
| Quit → Desktop | Graceful shutdown sequence | Settings flush + reconcile |

### 4.6 Screen router contract (summary)
The router autoload exposes: `push_overlay(id)`, `pop_overlay()`, `route(screen_id, params)`, `current_screen`, and emits `screen_changed`, `overlay_changed`. Screens may only emit intent signals; the router and feature managers decide. This keeps every transition in this document testable and prevents screens from reaching into each other.

---

## 5. Inventory Summary Table

| # | Screen | Type | Reachable from | Exits to | Overlays allowed |
|---|---|---|---|---|---|
| 1 | Boot / Splash | Screen | Launch | Login, Boot error panel | Quit confirm (error state) |
| 2 | Login | Screen | Boot, session-expiry bounce | Company Select, Hangar, Quit | Settings, Quit confirm |
| 3 | Main Menu | Zone (of Hangar) | — (hangar top bar) | Starmap, Settings, Credits, Quit | — |
| 4 | Company Select | Screen | Login (first login only) | Hangar, Login (logout) | Settings, confirm dialogs |
| 5 | Hangar | Screen (hub) | Login, Company Select, Loading (return) | Starmap, Settings, Credits, Quit, Login (logout) | Settings, Credits, item/sell/logout confirms |
| 6 | Starmap | Screen | Hangar | Loading, Hangar, Settings, Quit | Settings, danger-launch confirm |
| 7 | Loading | Screen | Starmap, Pause, Game Over | Game/HUD, Hangar, Login | Cancel (return direction) |
| 8 | Game HUD | Screen (handoff) | Loading | Pause, Game Over, force-routes | Pause (via router) |
| 9 | Pause Menu | Overlay screen | Esc/Start in game | Game, Settings, Loading (hangar), Quit | Settings, abandon/quit confirms |
| 10 | Game Over / Respawn | Screen state | Death in game | Game (respawn), Loading (hangar), Settings, Quit | Settings, Quit confirm |
| 11 | Credits | Overlay | Hangar, Login, Settings, Pause | Origin screen | — |
| 12 | Settings | Overlay | Every interactive screen | Origin widget | Discard-confirm, display-revert confirm |
| 13 | Quit Confirmation | Dialog | Hangar, Pause, Login, OS close, Boot error | Desktop or origin | Settings (corner) |
