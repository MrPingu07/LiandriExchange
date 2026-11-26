# LiandriExchange — Engine Quirks & UnrealScript Findings

**Context:** Discovered during clean rewrite of LiandriExchange for UT2004 (build 3374) using native Linux `UCC.bin`. All findings are empirical — verified by compile error or runtime behavior.

---

## 1. UCC / Build System

| Quirk | Details |
|-------|---------|
| **`-nohomedir` is mandatory for clean output** | Without it, `UCC.bin` writes `.u` to `~/.ut2004/System/` instead of the game `System/`, causing "package not found" on server start. |
| **Parse order is lexical by filename** | `ALiandriConfig.uc` (`A*`) parses before `LiandriConfig.uc` (`L*`). Used to make config object available to `LiandriWallet`/`Mutator` during their parse phase. |
| **No forward references to later-parsed classes** | `LiandriWallet` (parsed early) cannot call `LiandriItemExecutor.GetCCItemCost()` directly — `class'Pkg.Class'.static.Func()` required. |
| **`UCC.log` only appears on failure** | Success produces no log file. Redirect stderr for build logs. |
| **Stale `.u` in `System/` blocks recompile** | Always `rm -f LiandriExchange.u` before `make`. |

---

## 2. UnrealScript Language Constraints

| Constraint | Workaround |
|------------|------------|
| **All `local` vars must precede statements** | Declare `local int i, j, Temp;` at function top, before any `if`/`for`. |
| **No `for (int i = 0; ...)` — `int` in loop header illegal** | `local int i; for (i = 0; ...)` |
| **No `break.` (dot) — just `break`** | `break` alone. |
| **No `continue` in `for` loops** | Use `if` + `goto`-style logic or restructure. |
| **No `++i` / `i++` as expressions** | `i = i + 1` only. |
| **No default parameters in function signatures** | Use `optional` keyword: `function Foo(optional int Bar)` |
| **No ternary `? :` operator** | Full `if/else` blocks. |
| **No `switch` on strings** | Only `byte`, `int`, `enum`, `name`. |
| **`name` literals use single quotes: `'ClassName'`** | String literals use double quotes: `"text"`. |
| **Concatenation is `@` not `+`** | `"Value: " @ Var @ " end"` |

---

## 3. Class System & Reflection

| Finding | Implication |
|---------|-------------|
| **`class'Package.ClassName'` works for static access** | `class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemCost(...)` bypasses parse-order. |
| **`DynamicLoadObject("Package.Class", class'Class')` for dynamic class load** | Used by `InteractionMaster.AddInteraction()`. |
| **`IsA('ClassName')` string check is runtime** | Safe for cross-package checks. |
| **`default.` prefix accesses class defaults** | `default.CCPerFrag` in `FillPlayInfo()`. |
| **`Super.Func()` calls parent implementation** | Required in `MutatorFillPlayInfo`, `PostBeginPlay`, etc. |
| **`config(className)` vars persist to `.ini`** | `var config int CCPerFrag;` → `[LiandriExchange.LiandriExchangeMutator] CCPerFrag=1` in `UT2004.ini`. |

---

## 4. Replication & Networking

| Rule | Verified Behavior |
|------|-------------------|
| **`LinkedReplicationInfo` chain on `PRI.CustomReplicationInfo`** | `NextReplicationInfo` is `reliable if (bNetInitial && Role==ROLE_Authority)`. Walk chain to find your wallet. |
| **`reliable if (Role == ROLE_Authority)` on non-Actor fails** | Only works on `Actor` subclasses. `LiandriWallet` extends `LinkedReplicationInfo` (native, abstract) — replication block works. |
| **`ClientReceiveMessage` must be `simulated`** | Called on server, executes on owning client via `PlayerController.ClientMessage()`. |
| **`PlayerController.ReceiveLocalizedMessage()` triggers `LocalMessage.ClientReceive()`** | Used by `LiandriHUDMessage` to install HUD interaction client-side. |
| **`Level.Game.MutatorList` / `BaseMutator` are server-only** | Not replicated. Client HUD must find mutator via `mutate` console command or cached reference. |
| **`GameRulesModifiers` chain is server-authoritative** | `ScoreKill` only runs on server. `GameRules` actor not replicated to clients. |

---

## 5. Mutator Lifecycle

| Hook | Called On | Notes |
|------|-----------|-------|
| `PostBeginPlay()` | Server + Client | First safe place to spawn actors (`GameRules`, wallet). |
| `ModifyPlayer(Pawn)` | Server | Late-joiner wallet attachment. Client gets `ModifyPlayer` too but `Role!=ROLE_Authority`. |
| `CheckReplacement(Actor, out byte)` | Server | PRI replacement → wallet attach. |
| `Mutate(string, PlayerController)` | Server (via `ServerMutate`) | **Only reliable client→server RPC for custom logic.** |
| `MutatorFillPlayInfo(PlayInfo)` | Client (config GUI) | Populates mutator settings dialog. |

---

## 6. Config Objects (Non-Actor)

| Rule | Example |
|------|---------|
| **Instantiate with `new(None) class'...'`** | `ConfigObj = new(None) class'LiandriExchange.LiandriConfig';` |
| **`Spawn()` is for Actors only** | `Spawn(class'Config')` → compile error: "type mismatch in parameter 1". |
| **`perObjectConfig` creates per-instance `.ini` section** | `ALiandriConfig` uses it; `LiandriConfig` (runtime mirror) does not. |
| **Client must construct own config copy** | `Cfg = new(None) class'LiandriExchange.LiandriConfig';` in `HUDInteraction.Initialized()`. |

---

## 7. Interaction / HUD System

| Component | Key Points |
|-----------|------------|
| **`Interaction`** | Per-viewport. `KeyEvent(out EInputKey, out EInputAction, float Delta)` + `PostRender(Canvas)`. |
| **`InteractionMaster.AddInteraction("Pkg.Class", Player)`** | Returns `Interaction` instance. Adds to `Player.LocalInteractions[]`. |
| **`LocalMessage.ClientReceive(PlayerController, Switch, ...)`** | `Switch > 0` = install, `Switch <= 0` = remove. Used for HUD install/cleanup. |
| **`Canvas` draw calls** | `SetPos(X,Y)`, `DrawColor = Color`, `DrawText("string")`, `Font = MedFont/SmallFont`. |
| **Resolution scaling** | `Scale = Canvas.ClipY / 768.0` (reference 1024×768). Clamp `≥ 0.75`. |
| **`EInputKey` enum** | `IK_1`–`IK_5`, `IK_F4`, `IK_Shift`, `IK_Ctrl`, `IK_R` — defined in `Engine.Interactions`. |
| **`EInputAction` enum** | `IST_Press`, `IST_Hold`, `IST_Release`, `IST_Axis`. |

---

## 8. xPawn / UT2004 Gameplay APIs (Verified)

| Feature | Working API | Notes |
|---------|-------------|-------|
| **UDamage** | `xPawn.EnableUDamage(float Duration)` | Native. |
| **Invisibility** | `xPawn.SetInvisibility(float Duration)` | Native. |
| **Shield** | `xPawn.AddShieldStrength(int)` / `ShieldStrength += X` | `AddShieldStrength` caps at `ShieldStrengthMax`. Direct add bypasses cap — clamp manually. |
| **Health** | `Health = Value` | Clamp at `HealthMax`. |
| **Speed/Jump** | `GroundSpeed *= Mult`, `AirControl *= Mult`, `JumpZ *= Mult` | Revert on timer expiry (not implemented — persistent until death). |
| **Multi-jump** | `MaxMultiJump = 3` | Quad jump = 3 extra air jumps. |
| **Berserk** | `bBerserk = true; Weapon.StartBerserk()` | `Weapon.bBerserk` mirrors pawn. |
| **Adrenaline combo** | `xPlayer(Controller).DoCombo(class'XGame.ComboDefensive')` | Requires `xPlayer` controller. |
| **Vehicle entry** | `Vehicle.TryToDrive(Pawn)` | Native. Spawn with `Owner.Spawn(VClass, Owner, Tag, Loc, Rot)`. |
| **Weapon give** | `Pawn.Spawn(class'Weapon')` → `Inv.GiveTo(Pawn)` | `Inventory.GiveTo()` handles pickup logic. |
| **Ammo fill** | `Weapon.MaxOutAmmo()` | Fires `AmmoCharge` to max. |
| **Drop weapon** | `Inventory.DropFrom(vector Loc)` | Used by Translocator replacement. |

---

## 9. Vehicle / Turret Classes (Verified in UT2004 3374)

| Logical Name | Actual Class | Package |
|--------------|--------------|---------|
| Scorpion (Manta) | `ONSRV` | `Onslaught` |
| Raptor | `ONSAttackCraft` | `Onslaught` |
| Hellbender | `ONSPRV` | `Onslaught` |
| Goliath | `ONSHoverTank` | `Onslaught` |
| Manta (HoverBike) | `ONSHoverBike` | `Onslaught` |
| AVRiL | `ONSAVRiL` | `Onslaught` |
| Mine Layer | `ONSMineLayer` | `Onslaught` |
| Minigun Turret | `ASTurret_Minigun` | `UT2k4Assault` |
| Plasma Turret | `ONSManualGunPawn` | `Onslaught` |

**Note:** `OnslaughtFull.u` contains `ONSAttackCraft` (Raptor) but `Onslaught.u` also has it. Use `Onslaught.ONSAttackCraft` for compatibility.

---

## 10. Common Compile Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Illegal character in name` | Stale `.u` / `.uc` mismatch, or invisible Unicode | `rm -f *.u Classes/*.u`; retype line; ensure ASCII only. |
| `Bad or missing expression in '='` | RHS is a static call to later-parsed class | Use `class'Pkg.Class'.static.Func()` syntax. |
| `Cast from 'X' to 'X' is unnecessary` | Redundant cast `X(Y)` where Y already X | Remove cast. |
| `Call to 'Spawn': type mismatch in parameter 1` | `Spawn(class'Config')` on non-Actor | Use `new(None) class'Config'`. |
| `Unknown Function 'FillPlayInfo' in 'Class Core.Object'` | `Super.FillPlayInfo()` on `Object` (no such func) | Remove `Super` call. |
| `Unrecognized member 'AmmoAmount' in class 'Weapon'` | `Weapon.AmmoAmount` deprecated | Use `Weapon(Inv).AmmoAmount` or `MaxOutAmmo()`. |
| `Can't find Class 'OnslaughtFull.ONSAttackCraft'` | Class not in loaded packages | Use `Onslaught.ONSAttackCraft` instead. |

---

## 11. Runtime Script Warnings (Suppressed / Fixed)

| Warning | Resolution |
|---------|------------|
| `'Temp' : unreferenced local variable` | Remove unused `local int Temp;` or use it. |
| `'ItemName' : unreferenced local variable` | Variable declared but assignment commented out. |
| `'j' / 'PoolIndex' : unreferenced local variable` | Loop vars declared but loop body commented out. |
| `'W' : unreferenced local variable` | `local Weapon W` declared but not used after refactor. |

---

## 12. Configuration Persistence

| File | Section | Example |
|------|---------|---------|
| `UT2004.ini` | `[LiandriExchange.LiandriExchangeMutator]` | `CCPerFrag=1`, `bEnableVehicles=True` |
| `User.ini` | `[LiandriExchange.LiandriConfig]` | Per-object config (if `perObjectConfig`) |
| `LiandriExchange.int` | `[Public]` + `[LiandriExchange.LiandriExchangeMutator]` | Localization + mutator metadata |

---

## 13. Packaging Metadata

**`LiandriExchange.ucl`**
```ini
[LiandriExchange.LiandriExchangeMutator]
Class=LiandriExchangeMutator
Description="Liandri Exchange: Corporate sponsorship economy mutator"
PerObjectConfig=True
```

**`LiandriExchange.int`** — Must contain:
- `[Public]` block with `Object=` + `Mutator=` entries
- `[LiandriExchange.LiandriExchangeMutator]` with `FriendlyName`, `Description`, and every `*Label`/`*Desc` referenced in `FillPlayInfo()`

---

## 14. Debugging Tips

```bash
# Watch script logs in real time
tail -f /home/jdmr/.ut2004/System/UCC.log   # client
tail -f /home/jdmr/Juegos/UT2004/System/UCC.log  # server (with -log=)

# Force script log flush
# In-game console: SET LOG Verbosity 5

# Dump package exports
./UCC.bin package info LiandriExchange.u
./UCC.bin package export LiandriExchange.u LiandriExchangeMutator

# List all ServerPackages
grep ^ServerPackages= UT2004.ini
```

---

## 15. Version-Specific Notes (UT2004 3374)

- `Core.Object` has no `FillPlayInfo` or `GetDescriptionText` — do not call `Super` on config objects.
- `Interaction` is in `Engine` package, not `Core`.
- `LocalMessage.ClientReceive` signature: `(PlayerController, optional int, optional PRI, optional PRI, optional Object)`.
- `Vehicle.TryToDrive(Pawn)` returns `bool`.
- `xPawn.MaxMultiJump` default = 1 (double jump). Set to 3 for quad jump.
- `Redeemer` default ammo = 3. Override `AmmoAmount=1` after spawn for single-shot.
- `ONSMineLayer` exists in `Onslaught.u` (verified by string dump).
- `UT2k4Assault.ASTurret_Minigun` and `Onslaught.ONSManualGunPawn` are placeable turret pawns.

---

## 16. Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails |
|--------------|--------------|
| `foreach AllActors(class'Config', C)` in `PostBeginPlay` | `AllActors` iterates *Actors*; config objects are not Actors. |
| `Spawn(class'Config')` | `Spawn` only works on `Actor` subclasses. |
| Direct static call `LiandriItemExecutor.Func()` from earlier-parsed class | Parse-order error: "Bad or missing expression". |
| `PlayerController.ClientMessage()` in server function without `simulated` | ClientMessage is client-side; must be `simulated function ClientReceiveMessage()`. |
| `Level.Game.MutatorList` in client `PostRender` | Not replicated; client sees `None`. |
| `bVehicleLocked` on `Vehicle` | Property doesn't exist in UT2004. |
| `Weapon.GiveTo(Pawn)` directly on class | Must spawn instance first: `Inv = Spawn(class'Weapon'); Inv.GiveTo(Pawn)`. |

---

*Document compiled from empirical testing during LiandriExchange clean rewrite, November 2025.*