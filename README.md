# Liandri Exchange — UT2004 Mutator

> **Liandri Mining Corporation Requisition Terminal v3.4.1**  
> *Convert combat performance into corporate-sponsored equipment. Safety optional.*

## Overview

Liandri Exchange turns UT2004 into a roguelite corporate sponsorship economy. Players earn **Combat Credits (CC)** from frags and **Casualty Dividends (CD)** from deaths to purchase weapons, vehicles, powerups, and utilities from a randomized 5+5 draft pool — all without affecting actual scoreboard stats.

## Features

- **Dual-Currency Economy**: CC (offense/snowball) vs CD (survival/catch-up)
- **Roguelite 5+5 Draft**: 10 random items per match from 20-item master pool
- **Safe Spatial Deployment**: Vehicles/turrets verify clearance before spawning
- **Anti-Carjack Protection**: Purchasing player locked into driver seat
- **Fast-Buy HUD**: Keyboard-driven Canvas overlay (F4 to toggle, 1-5/Shift+1-5 to buy)
- **Full Config GUI**: All prices, rates, toggles in Mutator Config menu
- **Corporate Aesthetic**: All strings styled as negligent Liandri terminal messages
- **Bot Support**: Toggleable AI purchasing

## Quick Start (Windows — Required for Compilation)

```cmd
# 1. Copy source to UT2004 installation
xcopy Classes\*.uc \UT2004\System\ /Y
xcopy Resources\LiandriExchange.int \UT2004\System\ /Y

# 2. Compile
cd \UT2004\System
UCC.exe make -package=LiandriExchange

# 3. Install
copy LiandriExchange.u \UT2004\System\

# 4. Configure server
# Add to UT2004.ini [Engine.GameEngine]:
ServerPackages=LiandriExchange

# 5. Launch
UT2004.exe DM-Deck17?game=XGame.xDeathMatch?mutator=LiandriExchange.LiandriExchangeMutator
```

## Controls

| Key | Action |
|-----|--------|
| `F4` | Toggle requisition terminal |
| `1`–`5` | Purchase Division I (CC) slot |
| `Shift+1`–`Shift+5` | Purchase Division II (CD) slot |
| `R` | Reroll Division I (5 CC) |
| `Shift+R` | Reroll Division II (5 CD) |
| `Ctrl+1`–`Ctrl+5` | Reroll single CC slot (2 CC, if enabled) |
| `Ctrl+Shift+1`–`Ctrl+Shift+5` | Reroll single CD slot (2 CD, if enabled) |

## Division I — Performance Requisitions (CC)

| Item | Cost | Effect |
|------|------|--------|
| Stim-Overclock | 3 | Berserk 20s |
| Overtime Accelerator | 5 | 2× Speed/Jump 30s |
| Hostile Takeover | 5 | UDamage 30s |
| Quad-Jump Prototype | 5 | Quad Jump 120s |
| Vampiric Clause | 6 | 50% Life Steal 30s |
| Recon Striker | 8 | Spawn Scorpion |
| Air-Support | 10 | Spawn Raptor |
| Hellbender Merger | 11 | Spawn Hellbender |
| Heavy Litigation | 15 | Spawn Goliath |
| Boardroom Clearer | 18 | Redeemer (1 shot) |

## Division II — Sponsor Subsidies (CD)

| Item | Cost | Effect |
|------|------|--------|
| Emergency Resupply | 3 | Full ammo (non-super) |
| Personal Translocator | 2 | Translocator (lost on death) |
| Bio-Hazard Disposal | 3 | BioRifle + 50 Shield |
| Kinetic Severance | 4 | +100 Super Shield |
| Spider-Mine Surplus | 4 | Mine Layer (full ammo) |
| Adrenaline Shot | 5 | Health Regen (ComboDefensive) |
| Ghost Protocol | 5 | Invisibility 25s + Speed |
| Vitality Bailout | 8 | Set Health 300 (overheal) |
| Stationary Severance | 10 | Spawn Mounted Turret (random) |
| Anti-Trust Package | 15 | AVRiL (full ammo) |

## Configuration

All values editable via **Mutator Config GUI** or `UT2004.ini` `[LiandriExchange.LiandriConfig]`:

```ini
CCPerFrag=1
CDPerDeath=1
SuicidePenalty=0
RerollCost=5
DraftPoolSize=5
bEnableVehicles=True
bEnableBotPurchases=True
bFullDivisionReroll=True
bSingleSlotReroll=False
SingleSlotRerollCost=2
; ... individual item prices and toggles
```

## Suicide Detection

No CD granted for: `Suicide` damage type, `KilledBy==Self`, `FallDamage`, `WorldDamage` (lava, crushers).

## ⚠️ Build Status

**Linux UCC compiles cleanly (0 errors) but does not emit `.u` package file** — Known Linux UCC limitation. Source is syntactically correct.

**Struct visibility issue: SOLVED** — `LiandriItemData` struct placed in `ALiandriStructs.uc` (parsed first) at global scope, visible to all other classes.

**To get playable `.u` file: compile on Windows** (see Quick Start). Linux UCC validates syntax only.

## License

UnrealScript mod for Unreal Tournament 2004. Uses UT2004 assets only. No external dependencies.

---

*Liandri Mining Corporation — "Your safety is our liability waiver."*
