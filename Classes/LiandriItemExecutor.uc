/******************************************************************************
 * LiandriItemExecutor -- Static utility class for item definitions and execution
 * Handles all item data lookups and effect execution.
 ******************************************************************************/
class LiandriItemExecutor extends Object;

struct LiandriItemData
{
	var string Name;
	var int Cost;
	var byte Division;        // 0 = CC, 1 = CD
	var int MasterIndex;      // 0-9 within division
	var string FlavorText;
	var bool bIsVehicle;
	var string VehicleClassName;
	var string EffectClassName;
	var string ExecFunction;
};

// ===== ITEM DEFINITION HELPERS =====
static function LiandriItemData GetCCItemDef(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;

	if (ConfigObj == None)
		ConfigObj = new(None) class'LiandriExchange.LiandriConfig';

	Item.MasterIndex = -1;
	if (MasterIndex < 0 || MasterIndex > 9)
		return Item;

	switch (MasterIndex)
	{
		case 0:
			if (ConfigObj.bStimOverclockEnabled)
			{
				Item.Name = "Stim-Overclock";
				Item.Cost = ConfigObj.StimOverclockCost;
				Item.FlavorText = "Removes all thermal safety limiters. Voiding weapon warranty is encouraged.";
				Item.bIsVehicle = False;
			}
			break;
		case 1:
			if (ConfigObj.bOvertimeAcceleratorEnabled)
			{
				Item.Name = "Overtime Accelerator";
				Item.Cost = ConfigObj.OvertimeAcceleratorCost;
				Item.FlavorText = "Livestock-grade cardiac stimulant. Knee cartilage degradation is not covered.";
				Item.bIsVehicle = False;
			}
			break;
		case 2:
			if (ConfigObj.bHostileTakeoverEnabled)
			{
				Item.Name = "Hostile Takeover";
				Item.Cost = ConfigObj.HostileTakeoverCost;
				Item.FlavorText = "Floods your weapon with unshielded isotopes. Expect 6th-degree burns.";
				Item.bIsVehicle = False;
			}
			break;
		case 3:
			if (ConfigObj.bQuadJumpEnabled)
			{
				Item.Name = "Quad-Jump Prototype";
				Item.Cost = ConfigObj.QuadJumpCost;
				Item.FlavorText = "Quad-jumping capable boots. Thrusters salvaged from an aircraft crash.";
				Item.bIsVehicle = False;
			}
			break;
		case 4:
			if (ConfigObj.bVampiricClauseEnabled)
			{
				Item.Name = "Vampiric Clause";
				Item.Cost = ConfigObj.VampiricClauseCost;
				Item.FlavorText = "Experimental blood-recycling suit. Gross but efficient.";
				Item.bIsVehicle = False;
				Item.EffectClassName = "XPickups.LifeSteal";   // life steal, not UDamage
				break;
			}
			break;
		case 5:
			if (ConfigObj.bReconStrikerEnabled && ConfigObj.bEnableVehicles)
			{
				Item.Name = "Recon Striker";
				Item.Cost = ConfigObj.ReconStrikerCost;
				Item.FlavorText = "90% recycled mining scrap. Seatbelts removed to save on shipping costs.";
				Item.bIsVehicle = True;
				Item.VehicleClassName = "Onslaught.ONSRV";
			}
			break;
		case 6:
			if (ConfigObj.bAirSupportEnabled && ConfigObj.bEnableVehicles)
			{
				Item.Name = "Air-Support";
				Item.Cost = ConfigObj.AirSupportCost;
				Item.FlavorText = "Parachutes and ejector seats not included.";
				Item.bIsVehicle = True;
				Item.VehicleClassName = "Onslaught.ONSAttackCraft";
			}
			break;
		case 7:
			if (ConfigObj.bHellbenderEnabled && ConfigObj.bEnableVehicles)
			{
				Item.Name = "Hellbender Merger";
				Item.Cost = ConfigObj.HellbenderCost;
				Item.FlavorText = "Rear turret wiring exposed. Bring a friend to absorb shrapnel.";
				Item.bIsVehicle = True;
				Item.VehicleClassName = "Onslaught.ONSPRV";
			}
			break;
		case 8:
			if (ConfigObj.bHeavyLitigationEnabled && ConfigObj.bEnableVehicles)
			{
				Item.Name = "Heavy Litigation";
				Item.Cost = ConfigObj.HeavyLitigationCost;
				Item.FlavorText = "Cabin ventilation is currently broken. Hearing loss and exhaust poisoning are not covered by your contract.";
				Item.bIsVehicle = True;
				Item.VehicleClassName = "Onslaught.ONSHoverTank";
			}
			break;
		case 9:
			if (ConfigObj.bBoardroomClearerEnabled)
			{
				Item.Name = "Boardroom Clearer";
				Item.Cost = ConfigObj.BoardroomClearerCost;
				Item.FlavorText = "Long-term radiation safe radius exceeds the size of this arena.";
				Item.bIsVehicle = False;
				Item.EffectClassName = "XWeapons.Redeemer";
			}
			break;
	}
	Item.MasterIndex = MasterIndex;
	Item.Division = 0;
	return Item;
}

static function LiandriItemData GetCDItemDef(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;

	if (ConfigObj == None)
		ConfigObj = new(None) class'LiandriExchange.LiandriConfig';

	Item.MasterIndex = -1;
	if (MasterIndex < 0 || MasterIndex > 9)
		return Item;

	switch (MasterIndex)
	{
		case 0:
			if (ConfigObj.bEmergencyResupplyEnabled)
			{
				Item.Name = "Emergency Resupply";
				Item.Cost = ConfigObj.EmergencyResupplyCost;
				Item.FlavorText = "Recycled munitions scraped off the arena floor. May still contain trace amounts of previous contenders.";
				Item.bIsVehicle = False;
			}
			break;
		case 1:
			if (ConfigObj.bPersonalTranslocatorEnabled)
			{
				Item.Name = "Personal Translocator";
				Item.Cost = ConfigObj.PersonalTranslocatorCost;
				Item.FlavorText = "Quantum teleporter. Only occasionally leaves teeth behind.";
				Item.bIsVehicle = False;
				Item.EffectClassName = "XWeapons.TransLauncher";
			}
			break;
		case 2:
			if (ConfigObj.bBioHazardEnabled)
			{
				Item.Name = "Bio-Hazard Disposal";
				Item.Cost = ConfigObj.BioHazardCost;
				Item.FlavorText = "Toxic sludge tank strapped to your spine. Do not fall backward.";
				Item.bIsVehicle = False;
				Item.EffectClassName = "XWeapons.BioRifle";
			}
			break;
		case 3:
			if (ConfigObj.bKineticSeveranceEnabled)
			{
				Item.Name = "Kinetic Severance";
				Item.Cost = ConfigObj.KineticSeveranceCost;
				Item.FlavorText = "Deflects shrapnel away from you.";
				Item.bIsVehicle = False;
			}
			break;
		case 4:
			if (ConfigObj.bSpiderMineEnabled)
			{
				Item.Name = "Spider-Mine Surplus";
				Item.Cost = ConfigObj.SpiderMineCost;
				Item.FlavorText = "Surplus factory rejects.";
				Item.bIsVehicle = False;
				Item.EffectClassName = "Onslaught.ONSMineLayer";
			}
			break;
		case 5:
			if (ConfigObj.bAdrenalineShotEnabled)
			{
				Item.Name = "Adrenaline Shot";
				Item.Cost = ConfigObj.AdrenalineShotCost;
				Item.FlavorText = "Progressively regenerates health. If you don't mind running with a needle stuck on you.";
				Item.bIsVehicle = False;
			}
			break;
		case 6:
			if (ConfigObj.bGhostProtocolEnabled)
			{
				Item.Name = "Ghost Protocol";
				Item.Cost = ConfigObj.GhostProtocolCost;
				Item.FlavorText = "Pills that make you effectively transparent by separating your molecules. Don't worry, fully vanishing is rare.";
				Item.bIsVehicle = False;
			}
			break;
		case 7:
			if (ConfigObj.bVitalityBailoutEnabled)
			{
				Item.Name = "Vitality Bailout";
				Item.Cost = ConfigObj.VitalityBailoutCost;
				Item.FlavorText = "Chemical sludge that numbs fatal trauma.";
				Item.bIsVehicle = False;
			}
			break;
		case 8:
			if (ConfigObj.bStationarySeveranceEnabled)
			{
				Item.Name = "Stationary Severance";
				Item.Cost = ConfigObj.StationarySeveranceCost;
				Item.FlavorText = "Cannot retreat, turn fully, or protect your spine.";
				Item.bIsVehicle = True; // Turret
			}
			break;
		case 9:
			if (ConfigObj.bAntiTrustEnabled)
			{
				Item.Name = "Anti-Trust Package";
				Item.Cost = ConfigObj.AntiTrustCost;
				Item.FlavorText = "Detonation only after projectile outside of chamber not guaranteed.";
				Item.bIsVehicle = False;
				Item.EffectClassName = "Onslaught.ONSAVRiL";
			}
			break;
	}
	Item.MasterIndex = MasterIndex;
	Item.Division = 1;
	return Item;
}

static function int GetCCItemCost(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCCItemDef(MasterIndex, ConfigObj);
	return Item.Cost;
}

static function int GetCDItemCost(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCDItemDef(MasterIndex, ConfigObj);
	return Item.Cost;
}

static function string GetCCItemName(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCCItemDef(MasterIndex, ConfigObj);
	return Item.Name;
}

static function string GetCDItemName(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCDItemDef(MasterIndex, ConfigObj);
	return Item.Name;
}

static function bool IsCCItemEnabled(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCCItemDef(MasterIndex, ConfigObj);
	return Item.MasterIndex != -1;
}

static function bool IsCDItemEnabled(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCDItemDef(MasterIndex, ConfigObj);
	return Item.MasterIndex != -1;
}

static function string GetCCItemFlavorText(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCCItemDef(MasterIndex, ConfigObj);
	return Item.FlavorText;
}

static function string GetCDItemFlavorText(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCDItemDef(MasterIndex, ConfigObj);
	return Item.FlavorText;
}

static function bool GetCCItemIsVehicle(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCCItemDef(MasterIndex, ConfigObj);
	return Item.bIsVehicle;
}

static function bool GetCDItemIsVehicle(int MasterIndex, LiandriConfig ConfigObj)
{
	local LiandriItemData Item;
	Item = GetCDItemDef(MasterIndex, ConfigObj);
	return Item.bIsVehicle;
}

// ===== ITEM EXECUTION =====

static function ExecuteCCItem(Pawn P, int MasterIndex, LiandriConfig ConfigObj)
{
	local xPawn XP;
	local Vehicle V;
	local Inventory Inv;


	XP = xPawn(P);
	if (XP == None)
		return;

	switch (MasterIndex)
	{
		case 0: // Stim-Overclock - Custom 3x fire rate for 30s (replicated, persists across weapons)
			ApplyFireRateBuff(XP, 3.0, 30.0);
			break;
		case 1: // Overtime Accelerator - 2x speed/jump 30s
			XP.GroundSpeed *= 2.0;
			XP.AirControl *= 2.0;
			XP.JumpZ *= 2.0;
			break;
		case 2: // Hostile Takeover - UDamage 30s
			XP.EnableUDamage(30.0);
			break;
		case 3: // Quad-Jump Prototype - extra air jumps
			XP.MaxMultiJump = 3;
			break;
		case 4: // Vampiric Clause - 50% life steal 30s
			// Effect handled by LiandriVampireGameRules server rules
			break;
		case 5: // Recon Striker - Scorpion (ONSHoverBike)
			if (ConfigObj != None && ConfigObj.bEnableVehicles)
				class'LiandriExchange.LiandriDeployment'.static.SafeSpawnVehicle(P, class'Onslaught.ONSRV', V);
			break;
		case 6: // Air-Support - Raptor (ONSHoverCraft)
			if (ConfigObj != None && ConfigObj.bEnableVehicles)
				class'LiandriExchange.LiandriDeployment'.static.SafeSpawnVehicle(P, class'Onslaught.ONSAttackCraft', V);
			break;
		case 7: // Hellbender Merger - Hellbender (ONSAttackCraft)
			if (ConfigObj != None && ConfigObj.bEnableVehicles)
				class'LiandriExchange.LiandriDeployment'.static.SafeSpawnVehicle(P, class'Onslaught.ONSPRV', V);
			break;
		case 8: // Heavy Litigation - Goliath (ONSGoliath)
			if (ConfigObj != None && ConfigObj.bEnableVehicles)
				class'LiandriExchange.LiandriDeployment'.static.SafeSpawnVehicle(P, class'Onslaught.ONSHoverTank', V);
			break;
		case 9: // Boardroom Clearer - Redeemer (1 shot)
			Inv = P.Spawn(class'XWeapons.Redeemer');
			if (Inv != None)
				Inv.GiveTo(P);
			break;
	}
}

// Apply replicated fire rate buff (uses LiandriFireRateBuff monitoring actor)
static function ApplyFireRateBuff(xPawn XP, float Multiplier, float Duration)
{
	local LiandriFireRateBuff Buff;

	if (XP == None)
		return;

	// Spawn new monitoring actor (not in weapon chain)
	// The buff itself handles deduplication in its PostBeginPlay
	Buff = XP.Spawn(class'LiandriExchange.LiandriFireRateBuff');
	if (Buff != None)
	{
		Buff.FireRateMultiplier = Multiplier;
		Buff.BuffDuration = Duration;
		Buff.SetOwner(XP);
		Buff.PostBeginPlay();
	}
}

static function ExecuteCDItem(Pawn P, int MasterIndex, LiandriConfig ConfigObj)
{
	local xPawn XP;
	local xPlayer XPlayer;
	local Inventory Inv;
	local Weapon W;
	local class<Pawn> TurretClass;
	local Pawn TurretPawn;
	local bool bUseAssaultTurret;

	XP = xPawn(P);
	if (XP == None)
		return;

	switch (MasterIndex)
	{
		case 0: // Emergency Resupply - Full ammo (non-Redeemer/IonPainter)
			ResupplyAmmo(XP);
			break;
		case 1: // Personal Translocator
			Inv = XP.FindInventoryType(class'XWeapons.TransLauncher');
			if (Inv != None)
				Inv.DropFrom(P.Location);
			Inv = P.Spawn(class'XWeapons.TransLauncher');
			if (Inv != None)
				Inv.GiveTo(P);
			break;
		case 2: // Bio-Hazard Disposal - BioRifle + 50 Shield
			Inv = P.Spawn(class'XWeapons.BioRifle');
			if (Inv != None)
			{
				W = Weapon(Inv);
				if (W != None)
					W.MaxOutAmmo();
				Inv.GiveTo(P);
			}
			XP.ShieldStrength += 50;
			if (XP.ShieldStrength > 150) XP.ShieldStrength = 150;
			break;
		case 3: // Kinetic Severance - ADD 100 Super Shield
			XP.AddShieldStrength(100);
			break;
		case 4: // Spider-Mine Surplus - Mine Layer full ammo
			Inv = P.Spawn(class'Onslaught.ONSMineLayer');
			if (Inv != None)
			{
				W = Weapon(Inv);
				if (W != None)
					W.MaxOutAmmo();
				Inv.GiveTo(P);
			}
			break;
		case 5: // Adrenaline Shot - Health regen combo
			XPlayer = xPlayer(P.Controller);
			if (XPlayer != None && XPlayer.Adrenaline >= 100)
			{
				XPlayer.DoCombo(class'XGame.ComboDefensive');
			}
			else
			{
				// Fallback: direct health regeneration if no adrenaline or not xPlayer
				XP.Health += 25;
				if (XP.Health > XP.HealthMax)
					XP.Health = XP.HealthMax;
				// Give adrenaline boost for future combos
				if (XPlayer != None)
					XPlayer.Adrenaline = Min(XPlayer.Adrenaline + 50, 100);
			}
			break;
		case 6: // Ghost Protocol - Invisibility + Speed
			XP.SetInvisibility(25.0);
			XP.GroundSpeed *= 1.3;
			break;
		case 7: // Vitality Bailout - overheal
			XP.Health = 300;
			if (XP.Health > XP.HealthMax)
				XP.Health = XP.HealthMax;
			break;
		case 8: // Stationary Severance - Random turret
			bUseAssaultTurret = (Rand(2) == 0);
			if (bUseAssaultTurret)
				TurretClass = class'UT2k4Assault.ASTurret_Minigun';
			else
				TurretClass = class'Onslaught.ONSManualGunPawn';
			class'LiandriExchange.LiandriDeployment'.static.SafeSpawnTurret(P, TurretClass, TurretPawn);
			break;
		case 9: // Anti-Trust Package - AVRiL full ammo
			Inv = P.Spawn(class'Onslaught.ONSAVRiL');
			if (Inv != None)
			{
				W = Weapon(Inv);
				if (W != None)
					W.MaxOutAmmo();
				Inv.GiveTo(P);
			}
			break;
	}
}

static function ResupplyAmmo(xPawn P)
{
	local Inventory Inv;
	local Weapon W;

	for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (Inv.IsA('Weapon'))
		{
			W = Weapon(Inv);
			// Skip Redeemer and Ion Painter
			if (!W.IsA('Redeemer') && !W.IsA('IonPainter'))
			{
				W.MaxOutAmmo();
			}
		}
	}
}

defaultproperties
{
}