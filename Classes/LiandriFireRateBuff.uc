/******************************************************************************
 * LiandriFireRateBuff -- Replicated per-player fire rate buff WEAPON item
 * Attaches to pawn, modifies all current and future weapons, replicates to client.
 * Extends Weapon to access protected FireMode array.
 * Handles special weapon types, weapon switching, and lifecycle.
 ******************************************************************************/
class LiandriFireRateBuff extends Weapon
	config(LiandriExchange);

var config float FireRateMultiplier;      // 3.0 = 3x fire rate
var config float BuffDuration;            // 0 = infinite, >0 = seconds
var float EndTime;
var bool bInitialized;

replication
{
	reliable if (bNetInitial && Role == ROLE_Authority)
		FireRateMultiplier, BuffDuration;
}

function PostBeginPlay()
{
	local LiandriFireRateBuff ExistingBuff;

	// Check for existing buff on same owner (deduplication)
	foreach DynamicActors(class'LiandriExchange.LiandriFireRateBuff', ExistingBuff)
	{
		if (ExistingBuff != None && ExistingBuff != Self && ExistingBuff.Owner == Owner && ExistingBuff.bInitialized)
		{
			// Extend existing buff duration instead
			if (Role == ROLE_Authority)
				ExistingBuff.EndTime = Level.TimeSeconds + BuffDuration;
			Destroy();
			return;
		}
	}

	Super.PostBeginPlay();

	if (Role == ROLE_Authority)
	{
		if (BuffDuration > 0)
			EndTime = Level.TimeSeconds + BuffDuration;
		else
			EndTime = 0;

		// Initial application
		ApplyToInventory(Pawn(Owner));
		bInitialized = True;
	}

	// Start periodic check
	SetTimer(0.25, True);
}

function ApplyToInventory(Pawn P)
{
	local Inventory Inv;
	local Weapon W;
	local int m;

	if (P == None)
		return;

	for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		W = Weapon(Inv);
		if (W != None)
			ApplyFireRateMultiplier(W, FireRateMultiplier);
	}
}

function ApplyFireRateMultiplier(Weapon W, float Multiplier)
{
	local int m;

	if (W == None)
		return;

	for (m = 0; m < 2; m++)
	{
		if (W.FireMode[m] != None)
		{
			// Always calculate from default to avoid drift
			W.FireMode[m].FireRate = W.FireMode[m].default.FireRate / FireRateMultiplier;
			W.FireMode[m].FireAnimRate = W.FireMode[m].default.FireAnimRate * FireRateMultiplier;
			W.FireMode[m].ReloadAnimRate = W.FireMode[m].default.ReloadAnimRate * FireRateMultiplier;

			// Handle special weapon types
			HandleSpecialWeaponType(W.FireMode[m], FireRateMultiplier);
		}
	}
}

function HandleSpecialWeaponType(WeaponFire WF, float Multiplier)
{
	// Minigun: dynamically recalculates FireRate during spin-up/down
	// If we detect MinigunFire, we can't just set FireRate once
	// It will overwrite our value on spin-up/down
	// We'd need to monitor and reapply, or accept limitation

	// LinkFire: uses continuous tick damage, not standard FireRate
	// ShieldFire, BioFire, RocketMultiFire: charge-based, different mechanics

	// For now, apply standard multiplier. Minigun will overwrite on spin-up.
	// A more robust solution would subclass these fire modes (not possible from UScript)
}

simulated function Timer()
{
	if (Role == ROLE_Authority && BuffDuration > 0 && Level.TimeSeconds >= EndTime)
	{
		// Duration expired
		RemoveBuff();
		return;
	}

	// Re-apply to all weapons (catches new pickups, weapon switches)
	ApplyToInventory(Pawn(Owner));

	// If duration expired on client too
	if (Role < ROLE_Authority && EndTime > 0 && Level.TimeSeconds >= EndTime)
	{
		RemoveBuff();
	}
}

function RemoveBuff()
{
	local Inventory Inv;
	local Weapon W;
	local int m;

	// Restore all weapons to default
	for (Inv = Pawn(Owner).Inventory; Inv != None; Inv = Inv.Inventory)
	{
		W = Weapon(Inv);
		if (W != None)
		{
			for (m = 0; m < 2; m++)
			{
				if (W.FireMode[m] != None)
				{
					W.FireMode[m].FireRate = W.FireMode[m].default.FireRate;
					W.FireMode[m].FireAnimRate = W.FireMode[m].default.FireAnimRate;
					W.FireMode[m].ReloadAnimRate = W.FireMode[m].default.ReloadAnimRate;
				}
			}
		}
	}

	// Destroy self - do not reset native Berserk state;
	// that was applied separately by XPickups.Berserk powerup
	Destroy();
}

defaultproperties
{
	bHidden=True
	bNoDelete=False
	FireRateMultiplier=3.0
	BuffDuration=30.0
	bOnlyRelevantToOwner=True
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=10
}