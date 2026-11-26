# LiandriExchange — UT2004 Mutator

**Version:** 1.0 (clean rewrite)  
**Build Status:** ✅ Clean compile (0 errors, 0 warnings)  
**Package:** `LiandriExchange.u` (113,586 bytes)  
**Engine:** Unreal Tournament 2004 (build 3374)  
**Language:** UnrealScript

---

## Overview

LiandriExchange implements a **dual-currency corporate sponsorship economy** for UT2004. Players earn:

- **Combat Credits (CC)** — per frag
- **Casualty Dividends (CD)** — per non-suicide death

Currency is spent on a **randomized 5+5 draft** of offensive (CC) and defensive (CD) requisitions via a **keyboard-driven HUD terminal (F4)**. The mutator includes vehicles, turrets, weapons, buffs, full configuration GUI, and bot AI support.

---

## Features

| Category | Details |
|----------|---------|
| **Dual Currency** | CC on frag, CD on death (suicide excluded/penalized) |
| **5+5 Draft** | Randomized per match from 10-item master pools |
| **Division I (CC)** | 5 offensive: berserk, speed, UDamage, quad-jump, vampirism, 4 vehicles, Redeemer |
| **Division II (CD)** | 5 defensive: resupply, translocator, BioRifle+shield, shield, mines, adrenaline, invis+speed, health, turret, AVRiL |
| **HUD Terminal** | F4 toggle, 1-5/Shift+1-5 buy, R/Shift+R reroll, Ctrl+1-5/Ctrl+Shift+1-5 single-slot reroll |
| **Vehicles** | Scorpion (ONSRV), Raptor (ONSAttackCraft), Hellbender (ONSPRV), Goliath (ONSHoverTank) |
| **Turrets** | Minigun (ASTurret_Minigun), Plasma (ONSManualGunPawn) |
| **Config GUI** | 50+ tunables in UT2004 Mutator Config dialog |
| **Bot AI** | Periodic random affordable purchases |

---

## Quick Start

```bash
# Build (from project root)
./make.sh

# Or manually:
cd /home/jdmr/Juegos/UT2004/System
rm -f LiandriExchange.u
./UCC.bin make -nohomedir -package=LiandriExchange -path="/home/jdmr/Juegos/UT2004/LiandriExchange/Classes;."

# Run dedicated server
./UCC.bin server DM-Rankin?mutator=LiandriExchange.LiandriExchangeMutator -nohomedir

# In-game: press F4 to open requisition terminal
```

---

## Artifacts

| File | Location | Purpose |
|------|----------|---------|
| `LiandriExchange.u` | `System/` | Compiled package |
| `LiandriExchange.int` | `System/` | Localization + mutator metadata |
| `LiandriExchange.ucl` | `System/` | Package registration |
| `prebuilt/System/` | Project root | Release copy with build metadata |

---

## Source Structure

```
Classes/
├── ALiandriConfig.uc       # Parse-order anchor (A* prefix)
├── LiandriConfig.uc        # Config object + FillPlayInfo GUI
├── LiandriExchangeMutator.uc  # Mutator entry, wallet factory, GameRules spawn, Mutate router
├── LiandriWallet.uc        # LinkedReplicationInfo on PRI: CC/CD, draft, purchases
├── LiandriItemExecutor.uc  # 20 static item defs + execution logic
├── LiandriDeployment.uc    # Vehicle/turret spawn helpers
├── LiandriGameRules.uc     # ScoreKill → currency grants
├── LiandriHUDMessage.uc    # LocalMessage client hook
├── LiandriHUDInteraction.uc # Interaction subclass: Canvas HUD + keyboard
└── LiandriBotAI.uc         # Bot purchase tick
```

**Total:** ~2,100 lines across 10 classes.

---

## Verified Runtime Behavior

- ✅ Clean UCC compile (Linux native `UCC.bin`)
- ✅ Package loads on dedicated server
- ✅ `ServerPackages=LiandriExchange` registered in `UT2004.ini`
- ✅ Wallet attaches to PRI on join via `LinkedReplicationInfo` chain
- ✅ Draft pools randomized 5+5 per match
- ✅ CC granted on frag, CD on death (no suicide)
- ✅ F4 terminal opens, draws 5+5 list with costs
- ✅ All purchase/reroll keys functional
- ✅ Vehicle/turret spawns enterable/functional
- ✅ Weapon gives + buffs apply visibly
- ✅ Bot AI purchases every 5–10s
- ✅ Config GUI exposes all 50+ settings

---

## Documentation

| File | Purpose |
|------|---------|
| `ROADMAP.md` | Phase-by-phase project history (all ✅) |
| `FINDINGS.md` | Engine quirks, UnrealScript constraints, compile fixes |
| `APPROACH.md` | Architecture, class responsibilities, critical patterns |

---

## License

Internal project — no license specified.