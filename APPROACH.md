# LiandriExchange — Implementation Methods & Architecture

**Version:** 1.0 (clean rewrite)  
**Language:** UnrealScript (UT2004 / Engine build 3374)  
**Pattern:** Modular split across 10 single-responsibility classes

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      LiandriExchangeMutator                      │
│  (Mutator entry point, config bridge, wallet factory,           │
│   GameRules spawn, Mutate console command router)               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
┌────────────────┐ ┌───────────────┐ ┌───────────────┐
│ LiandriWallet  │ │LiandriGameRules│ │LiandriConfig  │
│ (LinkedRepInfo)│ │ (GameRules)    │ │ (config obj)  │
│  - CC/CD vars  │ │  - ScoreKill() │ │  - 50+ vars   │
│  - Draft arrays│ │  - CC/CD grant │ │  - FillPlayInfo│
│  - Server RPCs │ │                │ │                │
└───────┬────────┘ └───────────────┘ └───────┬───────┘
        │                                     │
        ▼                                     ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│  LiandriItemExecutor    │◄────────►│   LiandriDeployment     │
│  (static utility)       │  defs    │  (static spawn helpers) │
│  - 20 item definitions  │          │  - SafeSpawnVehicle()   │
│  - Cost/Name/Enabled    │          │  - SafeSpawnTurret()    │
│  - ExecuteCC/CDItem()   │          │                          │
└───────────┬─────────────┘          └─────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│  LiandriBotAI           │
│  (static tick)          │
│  - Random affordable    │
└─────────────────────────┘
```

---

## Class Responsibilities

### 1. `LiandriExchangeMutator` — Mutator Entry Point
- **Extends:** `Mutator`
- **Key duties:**
  - `PostBeginPlay()`: Instantiates `LiandriConfig` via `new(None)`, mirrors config vars, spawns `LiandriGameRules` into `GameRulesModifiers` chain, attaches wallets to existing PRI array.
  - `GetOrCreateWallet(PRI)`: Spawns `LiandriWallet` into `PRI.CustomReplicationInfo` linked list, calls `InitializeDraft()`.
  - `ModifyPlayer()` + `CheckReplacement()`: Wallet attachment for late joiners.
  - `Mutate(string, PlayerController)`: Console command router (`mutate LiandriBuyCC0`, `LiandriRerollCD`, etc.) — **the only client→server purchase path**.
  - `MutatorFillPlayInfo()`: Delegates to `LiandriConfig.FillPlayInfo()` for config GUI.

### 2. `LiandriWallet` — Per-Player State (`LinkedReplicationInfo`)
- **Extends:** `LinkedReplicationInfo` (native, abstract)
- **Replication:** `CombatCredits`, `CasualtyDividends`, `ActiveCCSlots[5]`, `ActiveCDSlots[5]`, `bDraftComplete`, `bDraftInitialized` — all `reliable if (Role==ROLE_Authority)`
- **Owner:** `PlayerReplicationInfo` (via `CustomReplicationInfo` chain)
- **Server-only RPCs (called via `mutate` → mutator → wallet):**
  - `ServerAddCC(int)`, `ServerAddCD(int)` — currency grants from GameRules
  - `ServerPurchaseCC(int SlotIndex)` / `ServerPurchaseCD(int)` — validate cost, deduct, call `LiandriItemExecutor.Execute*Item()`, send `ClientReceiveMessage`
  - `ServerRerollCC()` / `ServerRerollCD()` — Fisher-Yates reshuffle from master pool
  - `ServerSingleSlotRerollCC(int)` / `ServerSingleSlotRerollCD(int)` — single-slot reroll excluding current actives
- **Draft:** `InitializeDraft()` pulls `DraftPoolSize` from mutator, shuffles master pools 0–9, fills first N slots, rest = -1.
- **Bot timer:** `Timer()` → `LiandriBotAI.BotPurchaseTick(Self)` every 5–10s.

### 3. `LiandriItemExecutor` — Static Item Database & Execution
- **Extends:** `Object` (no replication, no instances)
- **Struct `LiandriItemData`**: Name, Cost, Division (0=CC/1=CD), MasterIndex, FlavorText, bIsVehicle, VehicleClassName, EffectClassName, ExecFunction
- **Static getters (all take `LiandriConfig` for toggle/cost lookup):**
  - `GetCCItemDef(int)`, `GetCDItemDef(int)` → full struct
  - `GetCCItemCost(int)`, `GetCDItemCost(int)` → int
  - `GetCCItemName(int)`, `GetCDItemName(int)` → string
  - `GetCCItemFlavorText(int)`, `GetCDItemFlavorText(int)` → string
  - `GetCCItemIsVehicle(int)`, `GetCDItemIsVehicle(int)` → bool
  - `IsCCItemEnabled(int)`, `IsCDItemEnabled(int)` → bool (checks toggle + vehicle gate)
- **Execution (server-only, called by Wallet):**
  - `ExecuteCCItem(Pawn, int, LiandriConfig)` — 10 cases: buffs, vehicles, Redeemer
  - `ExecuteCDItem(Pawn, int, LiandriConfig)` — 10 cases: weapons, shields, invisibility, turrets, AVRiL
  - `ResupplyAmmo(xPawn)` — loops `Pawn.Inventory`, `Weapon.MaxOutAmmo()` skipping Redeemer/IonPainter

**Division I (CC — Offensive)**
| Index | Item | Class / Effect | Vehicle? |
|-------|------|----------------|----------|
| 0 | Stim-Overclock | `Pawn.bBerserk=true`, `Weapon.StartBerserk()` | No |
| 1 | Overtime Accelerator | `GroundSpeed*2`, `AirControl*2`, `JumpZ*2` (30s) | No |
| 2 | Hostile Takeover | `EnableUDamage(30)` | No |
| 3 | Quad-Jump Prototype | `MaxMultiJump=3` | No |
| 4 | Vampiric Clause | `Health += 50` (cap at `HealthMax`) | No |
| 5 | Recon Striker | `ONSRV` (Scorpion) | **Yes** |
| 6 | Air-Support | `ONSAttackCraft` (Raptor) | **Yes** |
| 7 | Hellbender Merger | `ONSPRV` (Hellbender) | **Yes** |
| 8 | Heavy Litigation | `ONSHoverTank` (Goliath) | **Yes** |
| 9 | Boardroom Clearer | `Redeemer` (1 shot) | No |

**Division II (CD — Defensive / Utility)**
| Index | Item | Class / Effect | Vehicle? |
|-------|------|----------------|----------|
| 0 | Emergency Resupply | Full ammo (non-Redeemer/IonPainter) | No |
| 1 | Personal Translocator | `TransLauncher` give | No |
| 2 | Bio-Hazard Disposal | `BioRifle` + 50 Shield | No |
| 3 | Kinetic Severance | `AddShieldStrength(100)` | No |
| 4 | Spider-Mine Surplus | `ONSMineLayer` full ammo | No |
| 5 | Adrenaline Shot | `xPlayer.DoCombo(ComboDefensive)` | No |
| 6 | Ghost Protocol | `SetInvisibility(25)`, `GroundSpeed*1.3` | No |
| 7 | Vitality Bailout | `Health = 300` (cap at `HealthMax`) | No |
| 8 | Stationary Severance | Random turret (`ASTurret_Minigun` / `ONSManualGunPawn`) | **Turret** |
| 9 | Anti-Trust Package | `ONSAVRiL` full ammo | No |

### 4. `LiandriDeployment` — Spatial Spawn Helpers
- **Extends:** `Object`
- **`SafeSpawnVehicle(Pawn Owner, class<Vehicle> VClass, out Vehicle)`**
  - `Owner.Spawn(VClass, Owner, 'LiandriVehicle', Loc, Rot)`
  - `V.TryToDrive(Owner)` — native vehicle entry
- **`SafeSpawnTurret(Pawn Owner, class<Pawn> TurretClass, out Pawn)`**
  - Same pattern, no `TryToDrive`
- **Location:** `Owner.Location + Vector(Owner.Rotation)*300 + (0,0,50)` — 300 UU forward, 50 UU up.

### 5. `LiandriGameRules` — Currency Hooks
- **Extends:** `GameRules` (chained via `GameRulesModifiers`)
- **`ScoreKill(Controller Killer, Controller Killed)`**
  - Suicide detection: `Killer == Killed` OR `Killer == None` (world kill)
  - Killed: `ServerAddCD(CDPerDeath)` unless suicide → `ServerAddCD(SuicidePenalty)` (0 = none, negative = penalty)
  - Killer (if different): `ServerAddCC(CCPerFrag)`
  - Wallet lookup via `FindWallet(PRI)` helper (walks `CustomReplicationInfo` chain).

### 6. `LiandriConfig` / `ALiandriConfig` — Configuration
- **`ALiandriConfig`**: `class ALiandriConfig extends Object config(LiandriExchange) perObjectConfig` — **`A*` prefix ensures early parse order** so `LiandriWallet`/`Mutator` can reference it before `LiandriConfig` is parsed.
- **`LiandriConfig`**: Identical vars, no `perObjectConfig`, holds `static FillPlayInfo(PlayInfo)` for Mutator Config GUI.
- **50+ `var config` fields:** Currency rates, draft size, 20 prices, 20 toggles, reroll costs, vehicle/bot flags.
- **Defaults** match `DESIGN.md` catalog.

### 7. `LiandriHUDInteraction` — Client Terminal (Interaction)
- **Extends:** `Interaction` (per-viewport, receives `KeyEvent` + `PostRender`)
- **Installed by:** `LiandriHUDMessage.ClientReceive(Switch=1)` → `InteractionMaster.AddInteraction("LiandriExchange.LiandriHUDInteraction")`
- **Input (`KeyEvent`):**
  - `F4` — toggle `bShowHUD`
  - `1–5` — `mutate LiandriBuyCC<slot>`
  - `Shift+1–5` — `mutate LiandriBuyCD<slot>`
  - `R` / `Shift+R` — `mutate LiandriRerollCC` / `LiandriRerollCD`
  - `Ctrl+1–5` / `Ctrl+Shift+1–5` — `mutate LiandriSlotCC<slot>` / `LiandriSlotCD<slot>`
- **Render (`PostRender`):**
  - Resolution-independent scaling: `Scale = Canvas.ClipY / 768.0`, clamped ≥ 0.75
  - Draws: header, CC/CD balances, Division I (5 CC items), Division II (5 CD items), reroll hints, flavor text
  - Affordability = green/red, vehicle tag = amber "[DEPLOY]"
- **Data refresh:** `RefreshItemData()` calls `LiandriItemExecutor` static getters via class-literal `class'LiandriExchange.LiandriItemExecutor'.static.`

### 8. `LiandriHUDMessage` — Client Hook
- **Extends:** `LocalMessage`
- **`ClientReceive(PlayerController, Switch, ...)`**
  - `Switch <= 0` → remove existing interaction (cleanup)
  - `Switch > 0` → add/enable interaction if not present
- **Triggered by:** `PlayerController.ReceiveLocalizedMessage(class'LiandriExchange.LiandriHUDMessage', 1)` from `Mutator.ModifyPlayer()` and `PostBeginPlay()` wallet attachment.

### 9. `LiandriBotAI` — Bot Purchasing
- **Extends:** `Object`
- **`BotPurchaseTick(LiandriWallet)`** — called from `Wallet.Timer()`
- Scans 5 CC + 5 CD slots, finds affordable items, 30% chance to buy one via `ServerPurchaseCC/CD()`.

---

## Critical Implementation Patterns

### 1. Config Object Instantiation
```unrealscript
// CORRECT: non-Actor config objects use 'new(None)', not Spawn()
ConfigObj = new(None) class'LiandriExchange.LiandriConfig';
```

### 2. Cross-Class Static Calls (Parse Order Safety)
Classes parsed later cannot be called directly. Use class-literal syntax:
```unrealscript
class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemCost(Idx, Cfg)
class'LiandriExchange.LiandriDeployment'.static.SafeSpawnVehicle(...)
```

### 3. LinkedReplicationInfo Chain Walk
```unrealscript
function LiandriWallet FindWallet(PlayerReplicationInfo PRI) {
    local LinkedReplicationInfo L;
    L = PRI.CustomReplicationInfo;
    while (L != None) {
        if (LiandriWallet(L) != None) return LiandriWallet(L);
        L = L.NextReplicationInfo;
    }
    return None;
}
```

### 4. Server RPC via Mutate Console Command
Client cannot call server functions directly on `LinkedReplicationInfo`. Route:
```
Client key press → HUDInteraction.KeyEvent() → PC.ConsoleCommand("mutate LiandriBuyCC0")
  → PlayerController.ServerMutate() → Game.BaseMutator.Mutate()
  → LiandriExchangeMutator.Mutate() → Wallet.ServerPurchaseCC(0)
```

### 5. Vehicle Spawn Uses Owner.Spawn()
```unrealscript
V = Owner.Spawn(VClass, Owner, 'LiandriVehicle', Loc, Rot);
V.TryToDrive(Owner);
```
`Owner` (the Pawn) is the spawn owner; `TryToDrive` is native vehicle entry.

### 6. Weapon Give Pattern
```unrealscript
Inv = P.Spawn(class'XWeapons.TransLauncher');  // Pawn.Spawn returns Actor
if (Inv != None) Inv.GiveTo(P);                // Inventory.GiveTo(Pawn)
```
For ammo: `Weapon(Inv).MaxOutAmmo()`.

### 7. xPawn Buffs (Verified APIs)
| Effect | API |
|--------|-----|
| UDamage | `EnableUDamage(float Duration)` |
| Invisibility | `SetInvisibility(float Duration)` |
| Shield | `AddShieldStrength(int Amount)` / `ShieldStrength += X` |
| Health | `Health = Value` (cap at `HealthMax`) |
| Speed/Jump | `GroundSpeed *= Mult`, `AirControl *= Mult`, `JumpZ *= Mult` |
| Multi-jump | `MaxMultiJump = 3` (quad jump) |
| Berserk | `bBerserk = true`, `Weapon.StartBerserk()` |
| Adrenaline combo | `xPlayer(Controller).DoCombo(class'XGame.ComboDefensive')` |

---

## Replication Summary

| Class | Replicated Vars | Notes |
|-------|-----------------|-------|
| `LiandriWallet` | `CombatCredits`, `CasualtyDividends`, `ActiveCCSlots[5]`, `ActiveCDSlots[5]`, `bDraftComplete`, `bDraftInitialized` | `reliable if (Role==ROLE_Authority)` |
| `LiandriExchangeMutator` | `ConfigObj`, `GameRulesObj`, `MasterCCPool[10]`, `MasterCDPool[10]` | Server→client for HUD config access |
| `LiandriGameRules` | None (server-only actor) | Chained in `GameRulesModifiers` |
| `LiandriConfig` | None (config object, not Actor) | Client constructs own copy via `new(None)` |
| `LiandriHUDInteraction` | None (client-side `Interaction`) | Per-viewport, not replicated |

---

## Build System

```bash
# make.sh (project root)
GAME_DIR="${UT2004_DIR:-$HOME/Juegos/UT2004}"
SYS="$GAME_DIR/System"
SRC_CLASSES="$PWD/Classes"
cd "$SYS"
rm -f LiandriExchange.u
./UCC.bin make -nohomedir -package=LiandriExchange -path="$SRC_CLASSES;."
# Deploy .int/.ucl, refresh prebuilt/
```

**Key flags:**
- `-nohomedir` — prevents `~/.ut2004` interference, writes `.u` to `System/`
- `-path="src;."` — source dir first, then `System/` for engine packages
- `-package=LiandriExchange` — package name must match `.ucl` and `ServerPackages`

---

## Testing Checklist (Manual)

- [ ] Dedicated server start with `?mutator=LiandriExchange.LiandriExchangeMutator`
- [ ] Client join → F4 opens terminal, shows 5+5 items with costs
- [ ] 1–5 purchases CC item → CC deducted, effect applied, message shown
- [ ] Shift+1–5 purchases CD item → CD deducted, effect applied
- [ ] R / Shift+R rerolls full division → cost deducted, new items
- [ ] Ctrl+1–5 / Ctrl+Shift+1–5 rerolls single slot → cost deducted
- [ ] Vehicle spawns (Scorpion, Raptor, Hellbender, Goliath) enterable
- [ ] Turret spawns (Minigun, Plasma) functional
- [ ] Weapon gives (Translocator, BioRifle, MineLayer, AVRiL, Redeemer) usable
- [ ] Buffs (UDamage, Invis, Speed, Jump, Shield, Health, Regen) visible
- [ ] Suicide (fall/self-kill) grants no CD (or penalty if configured)
- [ ] Bot purchases occur periodically in botmatch
- [ ] Mutator Config GUI in UT2004 shows all 50+ settings
- [ ] Map change / server travel preserves mutator registration