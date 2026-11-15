/******************************************************************************
 * LiandriWallet — LinkedReplicationInfo attached to PlayerReplicationInfo
 * Tracks Combat Credits (CC), Casualty Dividends (CD), drafted item slots,
 * and handles purchase/replication logic.
 ******************************************************************************/

class LiandriWallet extends LinkedReplicationInfo
	config(LiandriExchange);

var int CombatCredits;
var int CasualtyDividends;
var int ActiveCCSlots[5];
var int ActiveCDSlots[5];
var bool bDraftComplete;
var bool bDraftInitialized;

// Config reference
var ALiandriConfig ConfigObj;

// Timer for bot purchases
var float BotPurchaseTimer;
var float BotPurchaseInterval;

replication
{
	reliable if (Role == ROLE_Authority)
		CombatCredits, CasualtyDividends,
		ActiveCCSlots, ActiveCDSlots,
		bDraftComplete, bDraftInitialized;
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Role == ROLE_Authority)
	{
		ConfigObj = Spawn(class'LiandriExchange.ALiandriConfig');
		BotPurchaseInterval = 5.0 + FRand() * 5.0; // 5-10s random interval
		SetTimer(BotPurchaseInterval, True);
	}
}

simulated function Timer()
{
	super.Timer();

	if (Role == ROLE_Authority && bEnableBotPurchases && Owner != None && Owner.IsA('Bot'))
	{
		BotPurchaseTick();
	}
}

function InitializeDraft()
{
	local LiandriExchangeMutator Mut;
	local int i, j, PoolIndex, RandomIndex, Temp;
	local int CCPool[10], CDPool[10];
	local int DraftSize;

	if (bDraftInitialized)
		return;

	Mut = LiandriExchangeMutator(Level.Game.MutatorList);
	while (Mut != None && !Mut.IsA('LiandriExchangeMutator'))
		Mut = LiandriExchangeMutator(Mut.NextMutator);

	if (Mut == None)
		return;

	DraftSize = Mut.DraftPoolSize;
	if (DraftSize > 5) DraftSize = 5;
	if (DraftSize < 1) DraftSize = 1;

	// Copy master pools
	for (i = 0; i < 10; i++)
	{
		CCPool[i] = Mut.MasterCCPool[i];
		CDPool[i] = Mut.MasterCDPool[i];
	}

	// Fisher-Yates shuffle for CC pool
	for (i = 9; i > 0; i--)
	{
		RandomIndex = Rand(i + 1);
		Temp = CCPool[i];
		CCPool[i] = CCPool[RandomIndex];
		CCPool[RandomIndex] = Temp;
	}

	// Fisher-Yates shuffle for CD pool
	for (i = 9; i > 0; i--)
	{
		RandomIndex = Rand(i + 1);
		Temp = CDPool[i];
		CDPool[i] = CDPool[RandomIndex];
		CDPool[RandomIndex] = Temp;
	}

	// Take first DraftSize items
	for (i = 0; i < DraftSize; i++)
	{
		ActiveCCSlots[i] = CCPool[i];
		ActiveCDSlots[i] = CDPool[i];
	}

	// Fill remaining with -1 (empty)
	for (i = DraftSize; i < 5; i++)
	{
		ActiveCCSlots[i] = -1;
		ActiveCDSlots[i] = -1;
	}

	bDraftComplete = True;
	bDraftInitialized = True;
}

reliable server function ServerAddCC(int Amount)
{
	if (Amount > 0)
		CombatCredits += Amount;
}

reliable server function ServerAddCD(int Amount)
{
	if (Amount > 0)
		CasualtyDividends += Amount;
	else if (Amount < 0)
		CasualtyDividends = Max(0, CasualtyDividends + Amount); // Penalty
}

reliable server function ServerPurchaseCC(int SlotIndex)
{
	local xPlayerReplicationInfo PRI;
	local Pawn P;
	local LiandriItemData Item;
	local int Cost;
	local string ItemName;

	if (SlotIndex < 0 || SlotIndex >= 5)
		return;

	PRI = xPlayerReplicationInfo(Owner);
	if (PRI == None || PRI.Pawn == None)
		return;

	P = PRI.Pawn;
	Item = GetCCItemDef(ActiveCCSlots[SlotIndex]);
	if (Item.MasterIndex == -1)
		return;

	Cost = GetCCItemCost(ActiveCCSlots[SlotIndex]);
	if (CombatCredits < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT CREDITS — REQUISITION DENIED", 'MenuSounds.Deny');
		return;
	}

	CombatCredits -= Cost;

	// Execute item effect
	ExecuteCCItem(P, ActiveCCSlots[SlotIndex]);

	// Log purchase
	ItemName = GetCCItemName(ActiveCCSlots[SlotIndex]);
	ClientReceiveMessage("REQUISITION CONFIRMED: " @ ItemName @ " (-" @ Cost @ " CC)", 'MenuSounds.Select3');
}

reliable server function ServerPurchaseCD(int SlotIndex)
{
	local xPlayerReplicationInfo PRI;
	local Pawn P;
	local LiandriItemData Item;
	local int Cost;
	local string ItemName;

	if (SlotIndex < 0 || SlotIndex >= 5)
		return;

	PRI = xPlayerReplicationInfo(Owner);
	if (PRI == None || PRI.Pawn == None)
		return;

	P = PRI.Pawn;
	Item = GetCDItemDef(ActiveCDSlots[SlotIndex]);
	if (Item.MasterIndex == -1)
		return;

	Cost = GetCDItemCost(ActiveCDSlots[SlotIndex]);
	if (CasualtyDividends < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT DIVIDENDS — SUBSIDY DENIED", 'MenuSounds.Deny');
		return;
	}

	CasualtyDividends -= Cost;

	// Execute item effect
	ExecuteCDItem(P, ActiveCDSlots[SlotIndex]);

	// Log purchase
	ItemName = GetCDItemName(ActiveCDSlots[SlotIndex]);
	ClientReceiveMessage("SUBSIDY GRANTED: " @ ItemName @ " (-" @ Cost @ " CD)", 'MenuSounds.Select3');
}

reliable server function ServerRerollCC()
{
	local LiandriExchangeMutator Mut;
	local int i, DraftSize, RandomIndex, Temp;
	local int CCPool[10];
	local int Cost;

	Cost = RerollCost;
	if (CombatCredits < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT CREDITS FOR REROLL — REQUEST DENIED", 'MenuSounds.Deny');
		return;
	}

	Mut = LiandriExchangeMutator(Level.Game.MutatorList);
	while (Mut != None && !Mut.IsA('LiandriExchangeMutator'))
		Mut = LiandriExchangeMutator(Mut.NextMutator);

	if (Mut == None)
		return.

	CombatCredits -= Cost.

	DraftSize = Mut.DraftPoolSize.
	if (DraftSize > 5) DraftSize = 5.

	// Copy and shuffle master pool
	for (i = 0; i < 10; i++)
		CCPool[i] = Mut.MasterCCPool[i].

	for (i = 9; i > 0; i--)
	{
		RandomIndex = Rand(i + 1).
		Temp = CCPool[i].
		CCPool[i] = CCPool[RandomIndex].
		CCPool[RandomIndex] = Temp.
	}

	for (i = 0; i < DraftSize; i++)
		ActiveCCSlots[i] = CCPool[i].
	for (i = DraftSize; i < 5; i++)
		ActiveCCSlots[i] = -1.

	ClientReceiveMessage("DIVISION I REQUISITION POOL REFRESHED (-" @ Cost @ " CC)", 'MenuSounds.Select3').
}

reliable server function ServerRerollCD()
{
	local LiandriExchangeMutator Mut.
	local int i, DraftSize, RandomIndex, Temp.
	local int CDPool[10].
	local int Cost.

	Cost = RerollCost.
	if (CasualtyDividends < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT DIVIDENDS FOR REROLL — REQUEST DENIED", 'MenuSounds.Deny').
		return.
	}

	Mut = LiandriExchangeMutator(Level.Game.MutatorList).
	while (Mut != None && !Mut.IsA('LiandriExchangeMutator'))
		Mut = LiandriExchangeMutator(Mut.NextMutator).

	if (Mut == None)
		return.

	CasualtyDividends -= Cost.

	DraftSize = Mut.DraftPoolSize.
	if (DraftSize > 5) DraftSize = 5.

	for (i = 0; i < 10; i++)
		CDPool[i] = Mut.MasterCDPool[i].

	for (i = 9; i > 0; i--)
	{
		RandomIndex = Rand(i + 1).
		Temp = CDPool[i].
		CDPool[i] = CDPool[RandomIndex].
		CDPool[RandomIndex] = Temp.
	}

	for (i = 0; i < DraftSize; i++)
		ActiveCDSlots[i] = CDPool[i].
	for (i = DraftSize; i < 5; i++)
		ActiveCDSlots[i] = -1.

	ClientReceiveMessage("DIVISION II SUBSIDY POOL REFRESHED (-" @ Cost @ " CD)", 'MenuSounds.Select3').
}

reliable server function ServerSingleSlotRerollCC(int SlotIndex)
{
	local LiandriExchangeMutator Mut.
	local int i, RandomIndex, Temp.
	local int CCPool[10].
	local int Cost.
	local bool bFound.

	if (!LiandriExchangeMutator(Level.Game.MutatorList).bSingleSlotReroll)
		return.

	Cost = LiandriExchangeMutator(Level.Game.MutatorList).SingleSlotRerollCost.
	if (CombatCredits < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT CREDITS FOR SINGLE REROLL", 'MenuSounds.Deny').
		return.
	}

	if (SlotIndex < 0 || SlotIndex >= 5 || ActiveCCSlots[SlotIndex] == -1)
		return.

	CombatCredits -= Cost.

	Mut = LiandriExchangeMutator(Level.Game.MutatorList).
	while (Mut != None && !Mut.IsA('LiandriExchangeMutator'))
		Mut = LiandriExchangeMutator(Mut.NextMutator).

	if (Mut == None)
		return.

	// Build pool of available items not already in active slots
	for (i = 0; i < 10; i++)
		CCPool[i] = Mut.MasterCCPool[i].

	// Remove currently active items from pool
	for (i = 0; i < 5; i++)
	{
		if (ActiveCCSlots[i] != -1)
		{
			for (int j = 0; j < 10; j++)
			{
				if (CCPool[j] == ActiveCCSlots[i])
				{
					CCPool[j] = -1.
					break.
				}
			}
		}
	}

	// Compact pool
	int ValidCount = 0.
	for (i = 0; i < 10; i++)
	{
		if (CCPool[i] != -1)
			CCPool[ValidCount++] = CCPool[i].
	}

	if (ValidCount == 0)
		return.

	RandomIndex = Rand(ValidCount).
	ActiveCCSlots[SlotIndex] = CCPool[RandomIndex].

	ClientReceiveMessage("SLOT " @ (SlotIndex+1) @ " REROLLED (-" @ Cost @ " CC)", 'MenuSounds.Select3').
}

reliable server function ServerSingleSlotRerollCD(int SlotIndex)
{
	local LiandriExchangeMutator Mut.
	local int i, RandomIndex.
	local int CDPool[10].
	local int Cost.
	local int ValidCount.

	if (!LiandriExchangeMutator(Level.Game.MutatorList).bSingleSlotReroll)
		return.

	Cost = LiandriExchangeMutator(Level.Game.MutatorList).SingleSlotRerollCost.
	if (CasualtyDividends < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT DIVIDENDS FOR SINGLE REROLL", 'MenuSounds.Deny').
		return.
	}

	if (SlotIndex < 0 || SlotIndex >= 5 || ActiveCDSlots[SlotIndex] == -1)
		return.

	CasualtyDividends -= Cost.

	Mut = LiandriExchangeMutator(Level.Game.MutatorList).
	while (Mut != None && !Mut.IsA('LiandriExchangeMutator'))
		Mut = LiandriExchangeMutator(Mut.NextMutator).

	if (Mut == None)
		return.

	for (i = 0; i < 10; i++)
		CDPool[i] = Mut.MasterCDPool[i].

	for (i = 0; i < 5; i++)
	{
		if (ActiveCDSlots[i] != -1)
		{
			for (int j = 0; j < 10; j++)
			{
				if (CDPool[j] == ActiveCDSlots[i])
				{
					CDPool[j] = -1.
					break.
				}
			}
		}
	}

	ValidCount = 0.
	for (i = 0; i < 10; i++)
	{
		if (CDPool[i] != -1)
			CDPool[ValidCount++] = CDPool[i].
	}

	if (ValidCount == 0)
		return.

	RandomIndex = Rand(ValidCount).
	ActiveCDSlots[SlotIndex] = CDPool[RandomIndex].

	ClientReceiveMessage("SLOT " @ (SlotIndex+1) @ " REROLLED (-" @ Cost @ " CD)", 'MenuSounds.Select3').
}

simulated function ClientReceiveMessage(string Msg, optional Sound SoundFX)
{
	local PlayerController PC.

	PC = PlayerController(Owner).
	if (PC != None)
	{
		PC.ClientMessage(Msg).
		if (SoundFX != None)
			PC.ClientPlaySound(SoundFX).
	}
}

// ===== ITEM DEFINITION HELPERS =====

function LiandriItemData GetCCItemDef(int MasterIndex)
{
	local LiandriItemData Item.
	local class<ALiandriConfig> ConfigClass.

	Item.MasterIndex = -1.
	if (MasterIndex < 0 || MasterIndex > 9)
		return Item.

	ConfigClass = class'LiandriExchange.ALiandriConfig'.
	switch (MasterIndex)
	{
		case 0: Item.Name = "Stim-Overclock"; Item.Cost = GetConfigInt(ConfigClass, "StimOverclockCost", 3); Item.FlavorText = "Removes all thermal safety limiters. Voiding weapon warranty is encouraged."; Item.bIsVehicle = False; Item.EffectClassName = "XPickups.UDamage"; break. // Berserk via UDamage pickup logic
		case 1: Item.Name = "Overtime Accelerator"; Item.Cost = GetConfigInt(ConfigClass, "OvertimeAcceleratorCost", 5); Item.FlavorText = "Livestock-grade cardiac stimulant. Knee cartilage degradation is not covered."; Item.bIsVehicle = False; break.
		case 2: Item.Name = "Hostile Takeover"; Item.Cost = GetConfigInt(ConfigClass, "HostileTakeoverCost", 5); Item.FlavorText = "Floods your weapon with unshielded isotopes. Expect 6th-degree burns."; Item.bIsVehicle = False; Item.EffectClassName = "XPickups.UDamage"; break.
		case 3: Item.Name = "Quad-Jump Prototype"; Item.Cost = GetConfigInt(ConfigClass, "QuadJumpCost", 5); Item.FlavorText = "Quad-jumping capable boots. Thrusters salvaged from an aircraft crash."; Item.bIsVehicle = False; break.
		case 4: Item.Name = "Vampiric Clause"; Item.Cost = GetConfigInt(ConfigClass, "VampiricClauseCost", 6); Item.FlavorText = "Experimental blood-recycling suit. Gross but efficient."; Item.bIsVehicle = False; break.
		case 5: Item.Name = "Recon Striker"; Item.Cost = GetConfigInt(ConfigClass, "ReconStrikerCost", 8); Item.FlavorText = "90% recycled mining scrap. Seatbelts removed to save on shipping costs."; Item.bIsVehicle = True; Item.VehicleClassName = "Onslaught.ONSHoverBike"; break.
		case 6: Item.Name = "Air-Support"; Item.Cost = GetConfigInt(ConfigClass, "AirSupportCost", 10); Item.FlavorText = "Parachutes and ejector seats not included."; Item.bIsVehicle = True; Item.VehicleClassName = "Onslaught.ONSHoverCraft"; break.
		case 7: Item.Name = "Hellbender Merger"; Item.Cost = GetConfigInt(ConfigClass, "HellbenderCost", 11); Item.FlavorText = "Rear turret wiring exposed. Bring a friend to absorb shrapnel."; Item.bIsVehicle = True; Item.VehicleClassName = "OnslaughtFull.ONSAttackCraft"; break.
		case 8: Item.Name = "Heavy Litigation"; Item.Cost = GetConfigInt(ConfigClass, "HeavyLitigationCost", 15); Item.FlavorText = "Cabin ventilation is currently broken. Hearing loss and exhaust poisoning are not covered by your contract."; Item.bIsVehicle = True; Item.VehicleClassName = "Onslaught.ONSGoliath"; break.
		case 9: Item.Name = "Boardroom Clearer"; Item.Cost = GetConfigInt(ConfigClass, "BoardroomClearerCost", 18); Item.FlavorText = "Long-term radiation safe radius exceeds the size of this arena."; Item.bIsVehicle = False; Item.EffectClassName = "XWeapons.Redeemer"; break.
	}
	Item.MasterIndex = MasterIndex.
	Item.Division = 0.
	return Item.
}

function LiandriItemData GetCDItemDef(int MasterIndex)
{
	local LiandriItemData Item.
	local class<ALiandriConfig> ConfigClass.

	Item.MasterIndex = -1.
	if (MasterIndex < 0 || MasterIndex > 9)
		return Item.

	ConfigClass = class'LiandriExchange.ALiandriConfig'.
	switch (MasterIndex)
	{
		case 0: Item.Name = "Emergency Resupply"; Item.Cost = GetConfigInt(ConfigClass, "EmergencyResupplyCost", 3); Item.FlavorText = "Recycled munitions scraped off the arena floor. May still contain trace amounts of previous contenders."; Item.bIsVehicle = False; break.
		case 1: Item.Name = "Personal Translocator"; Item.Cost = GetConfigInt(ConfigClass, "PersonalTranslocatorCost", 2); Item.FlavorText = "Quantum teleporter. Only occasionally leaves teeth behind."; Item.bIsVehicle = False; Item.EffectClassName = "XWeapons.Translocator"; break.
		case 2: Item.Name = "Bio-Hazard Disposal"; Item.Cost = GetConfigInt(ConfigClass, "BioHazardCost", 3); Item.FlavorText = "Toxic sludge tank strapped to your spine. Do not fall backward."; Item.bIsVehicle = False; Item.EffectClassName = "XWeapons.BioRifle"; break.
		case 3: Item.Name = "Kinetic Severance"; Item.Cost = GetConfigInt(ConfigClass, "KineticSeveranceCost", 4); Item.FlavorText = "Deflects shrapnel away from you."; Item.bIsVehicle = False; break.
		case 4: Item.Name = "Spider-Mine Surplus"; Item.Cost = GetConfigInt(ConfigClass, "SpiderMineCost", 4); Item.FlavorText = "Surplus factory rejects."; Item.bIsVehicle = False; Item.EffectClassName = "XWeapons.MineLayer"; break.
		case 5: Item.Name = "Adrenaline Shot"; Item.Cost = GetConfigInt(ConfigClass, "AdrenalineShotCost", 5); Item.FlavorText = "Progressively regenerates health. If you don't mind running with a needle stuck on you."; Item.bIsVehicle = False; break.
		case 6: Item.Name = "Ghost Protocol"; Item.Cost = GetConfigInt(ConfigClass, "GhostProtocolCost", 5); Item.FlavorText = "Pills that make you effectively transparent by separating your molecules. Don't worry, fully vanishing is rare."; Item.bIsVehicle = False; break.
		case 7: Item.Name = "Vitality Bailout"; Item.Cost = GetConfigInt(ConfigClass, "VitalityBailoutCost", 8); Item.FlavorText = "Chemical sludge that numbs fatal trauma."; Item.bIsVehicle = False; break.
		case 8: Item.Name = "Stationary Severance"; Item.Cost = GetConfigInt(ConfigClass, "StationarySeveranceCost", 10); Item.FlavorText = "Cannot retreat, turn fully, or protect your spine."; Item.bIsVehicle = True; break. // Random turret class
		case 9: Item.Name = "Anti-Trust Package"; Item.Cost = GetConfigInt(ConfigClass, "AntiTrustCost", 15); Item.FlavorText = "Detonation only after projectile outside of chamber not guaranteed."; Item.bIsVehicle = False; Item.EffectClassName = "XWeapons.AVRiL"; break.
	}
	Item.MasterIndex = MasterIndex.
	Item.Division = 1.
	return Item.
}

function int GetCCItemCost(int MasterIndex)
{
	local LiandriItemData Item.
	Item = GetCCItemDef(MasterIndex).
	return Item.Cost.
}

function int GetCDItemCost(int MasterIndex)
{
	local LiandriItemData Item.
	Item = GetCDItemDef(MasterIndex).
	return Item.Cost.
}

function string GetCCItemName(int MasterIndex)
{
	local LiandriItemData Item.
	Item = GetCCItemDef(MasterIndex).
	return Item.Name.
}

function string GetCDItemName(int MasterIndex)
{
	local LiandriItemData Item.
	Item = GetCDItemDef(MasterIndex).
	return Item.Name.
}

// ===== ITEM EXECUTION =====

function ExecuteCCItem(Pawn P, int MasterIndex)
{
	local xPawn XP.
	local Vehicle V.
	local Inventory Inv.

	XP = xPawn(P).
	if (XP == None)
		return.

	switch (MasterIndex)
	{
		case 0: // Stim-Overclock - Berserk 20s
			XP.GivePowerup(class'XPickups.Berserk', 20.0).
			break.
		case 1: // Overtime Accelerator - 2x speed/jump 30s
			XP.GivePowerup(class'XPickups.BootsOfFlight', 30.0). // Closest: jump boost
			// Custom speed boost handled via adrenaline combo or custom powerup
			XP.GroundSpeed *= 2.0.
			XP.AirControl *= 2.0.
			break.
		case 2: // Hostile Takeover - UDamage 30s
			XP.GivePowerup(class'XPickups.UDamage', 30.0).
			break.
		case 3: // Quad-Jump Prototype - Quad jump 120s
			XP.GivePowerup(class'XPickups.BootsOfFlight', 120.0).
			XP.MaxMultiJump = 3. // Quad jump = 3 extra jumps
			break.
		case 4: // Vampiric Clause - 50% lifesteal 30s
			// Custom: would need a custom powerup; for now grant Regen + Vampire
			XP.GivePowerup(class'XPickups.Regen', 30.0).
			break.
		case 5: // Recon Striker - Scorpion
			if (LiandriExchangeMutator(Level.Game.MutatorList).bEnableVehicles)
				LiandriDeployment.SafeSpawnVehicle(P, class'Onslaught.ONSHoverBike', V).
			break.
		case 6: // Air-Support - Raptor
			if (LiandriExchangeMutator(Level.Game.MutatorList).bEnableVehicles)
				LiandriDeployment.SafeSpawnVehicle(P, class'Onslaught.ONSHoverCraft', V).
			break.
		case 7: // Hellbender Merger - Hellbender
			if (LiandriExchangeMutator(Level.Game.MutatorList).bEnableVehicles)
				LiandriDeployment.SafeSpawnVehicle(P, class'OnslaughtFull.ONSAttackCraft', V).
			break.
		case 8: // Heavy Litigation - Goliath
			if (LiandriExchangeMutator(Level.Game.MutatorList).bEnableVehicles)
				LiandriDeployment.SafeSpawnVehicle(P, class'Onslaught.ONSGoliath', V).
			break.
		case 9: // Boardroom Clearer - Redeemer (1 shot)
			Inv = XP.CreateInventory(class'XWeapons.Redeemer').
			if (Inv != None)
			{
				Inv.AmmoCount = 1.
				XP.AddWeapon(Inv).
			}
			break.
	}
}

function ExecuteCDItem(Pawn P, int MasterIndex)
{
	local xPawn XP.
	local Inventory Inv.
	local class<Turret> TurretClass.
	local Pawn TurretPawn.
	local bool bUseAssaultTurret.

	XP = xPawn(P).
	if (XP == None)
		return.

	switch (MasterIndex)
	{
		case 0: // Emergency Resupply - Full ammo (non-Redeemer/IonPainter)
			ResupplyAmmo(XP).
			break.
		case 1: // Personal Translocator
			Inv = XP.FindInventoryType(class'XWeapons.Translocator').
			if (Inv != None)
				XP.ThrowWeapon(Inv).
			Inv = XP.CreateInventory(class'XWeapons.Translocator').
			if (Inv != None)
				XP.AddWeapon(Inv).
			break.
		case 2: // Bio-Hazard Disposal - BioRifle + 50 Shield
			Inv = XP.CreateInventory(class'XWeapons.BioRifle').
			if (Inv != None)
			{
				Inv.AmmoCount = Inv.MaxAmmo.
				XP.AddWeapon(Inv).
			}
			XP.ShieldStrength += 50.
			if (XP.ShieldStrength > 150) XP.ShieldStrength = 150.
			break.
		case 3: // Kinetic Severance - ADD 100 Super Shield
			XP.ShieldStrength += 100.
			if (XP.ShieldStrength > 250) XP.ShieldStrength = 250. // Hard cap higher than normal
			break.
		case 4: // Spider-Mine Surplus - Mine Layer full ammo
			Inv = XP.CreateInventory(class'XWeapons.MineLayer').
			if (Inv != None)
			{
				Inv.AmmoCount = Inv.MaxAmmo.
				XP.AddWeapon(Inv).
			}
			break.
		case 5: // Adrenaline Shot - Health regen (ComboDefensive)
			XP.ActivateAdrenalineCombo('ComboDefensive').
			break.
		case 6: // Ghost Protocol - Invisibility 25s + Speed
			XP.GivePowerup(class'XPickups.Invisibility', 25.0).
			XP.GroundSpeed *= 1.3.
			break.
		case 7: // Vitality Bailout - SET Health 300 (overheal)
			XP.Health = 300.
			if (XP.Health > 300) XP.Health = 300.
			break.
		case 8: // Stationary Severance - Random turret
			bUseAssaultTurret = (Rand(2) == 0).
			if (bUseAssaultTurret)
				TurretClass = class'UT2k4Assault.ASTurret_Minigun'.
			else
				TurretClass = class'Onslaught.ONSManualGunPawn'.
			LiandriDeployment.SafeSpawnTurret(P, TurretClass, TurretPawn).
			break.
		case 9: // Anti-Trust Package - AVRiL full ammo
			Inv = XP.CreateInventory(class'XWeapons.AVRiL').
			if (Inv != None)
			{
				Inv.AmmoCount = Inv.MaxAmmo.
				XP.AddWeapon(Inv).
			}
			break.
	}
}

function ResupplyAmmo(xPawn P)
{
	local Inventory Inv.
	local Weapon W.

	for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (Inv.IsA('Weapon'))
		{
			W = Weapon(Inv).
			// Skip Redeemer and Ion Painter
			if (!W.IsA('Redeemer') && !W.IsA('IonPainter'))
			{
				W.AmmoCount = W.MaxAmmo.
			}
		}
	}
}

function BotPurchaseTick()
{
	local Bot B.
	local int i, AffordableCC, AffordableCD.

	B = Bot(Owner).
	if (B == None || B.Pawn == None)
		return.

	// Simple: randomly try to buy something affordable
	AffordableCC = -1.
	AffordableCD = -1.

	for (i = 0; i < 5; i++)
	{
		if (ActiveCCSlots[i] != -1 && CombatCredits >= GetCCItemCost(ActiveCCSlots[i]))
		{
			if (AffordableCC == -1 || FRand() < 0.5)
				AffordableCC = i.
		}
		if (ActiveCDSlots[i] != -1 && CasualtyDividends >= GetCDItemCost(ActiveCDSlots[i]))
		{
			if (AffordableCD == -1 || FRand() < 0.5)
				AffordableCD = i.
		}
	}

	if (AffordableCC != -1 && FRand() < 0.3)
		ServerPurchaseCC(AffordableCC).
	else if (AffordableCD != -1 && FRand() < 0.3)
		ServerPurchaseCD(AffordableCD).
}




defaultproperties
{
	CombatCredits=0
	CasualtyDividends=0
	bDraftComplete=False
	bDraftInitialized=False
	BotPurchaseInterval=7.0
	bNetOwner=True
	RemoteRole=ROLE_SimulatedProxy
}
