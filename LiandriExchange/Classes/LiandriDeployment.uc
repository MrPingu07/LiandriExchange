/******************************************************************************
 * LiandriDeployment — Static utility for safe spatial deployment
 * Verifies clearance before spawning vehicles/turrets, auto-seats player.
 ******************************************************************************/

class LiandriDeployment extends Object;

const DEPLOY_BASE_DISTANCE = 300.0;
const DEPLOY_Z_OFFSET = 50.0;
const DEPLOY_OFFSET_MULT = 1.5;
const FLOOR_TRACE_DIST = 200.0;
const CEILING_TRACE_DIST = 500.0;
const MAX_DEPLOY_ATTEMPTS = 9;

static function bool SafeSpawnVehicle(Pawn Owner, class<Vehicle> VClass, out Vehicle Spawned)
{
	local Vector BaseLoc, Forward, TestLoc;
	local Rotator SpawnRot;
	local float Radius, Height;
	local int i, j;
	local Vector Offsets[9];
	local Actor HitActor;
	local Vector HitLoc, HitNorm;
	local bool bClear;
	local Vehicle V;
	local Controller C;

	if (Owner == None || VClass == None)
		return False;

	// Get vehicle collision bounds
	GetClassDefaultObject(VClass).GetCollisionRadiusAndHeight(Radius, Height);

	// Base spawn location: in front of player
	Forward = Vector(Owner.Rotation);
	BaseLoc = Owner.Location + Forward * DEPLOY_BASE_DISTANCE;
	BaseLoc.Z += DEPLOY_Z_OFFSET;
	SpawnRot = Owner.Rotation;

	// Generate test offsets: center, 4 cardinal, 4 diagonal
	Offsets[0] = Vect(0, 0, 0);
	Offsets[1] = Vect(Radius * DEPLOY_OFFSET_MULT, 0, 0);
	Offsets[2] = Vect(-Radius * DEPLOY_OFFSET_MULT, 0, 0);
	Offsets[3] = Vect(0, Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[4] = Vect(0, -Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[5] = Vect(Radius * DEPLOY_OFFSET_MULT, Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[6] = Vect(Radius * DEPLOY_OFFSET_MULT, -Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[7] = Vect(-Radius * DEPLOY_OFFSET_MULT, Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[8] = Vect(-Radius * DEPLOY_OFFSET_MULT, -Radius * DEPLOY_OFFSET_MULT, 0);

	// Try each offset
	for (i = 0; i < MAX_DEPLOY_ATTEMPTS; i++)
	{
		TestLoc = BaseLoc + Offsets[i];

		// Check floor clearance
		HitActor = Owner.Trace(HitLoc, HitNorm, TestLoc, TestLoc - Vect(0, 0, FLOOR_TRACE_DIST), False, Vect(Radius, Radius, Height));
		if (HitActor == None)
			continue; // No floor

		// Check ceiling clearance
		HitActor = Owner.Trace(HitLoc, HitNorm, TestLoc, TestLoc + Vect(0, 0, CEILING_TRACE_DIST), False, Vect(Radius, Radius, Height));
		if (HitActor != None)
			continue; // Ceiling too low

		// Check collision at spawn point (encroachment)
		bClear = True;
		ForEach OverlappingActors(class'Actor', HitActor, TestLoc, Vect(Radius, Radius, Height))
		{
			if (HitActor != Owner && HitActor.bBlockActors && !HitActor.IsA('PlayerReplicationInfo'))
			{
				bClear = False;
				break;
			}
		}

		if (!bClear)
			continue;

		// All checks passed - spawn vehicle
		V = Spawn(VClass, , , TestLoc, SpawnRot);
		if (V != None)
		{
			Spawned = V;

			// Auto-seat the purchasing player (driver seat)
			V.TryToDrive(Owner);

			// Ensure driver reference (no lock — player always retains entry)
			V.Driver = Owner;

			// Play spawn sound
			Owner.ClientPlaySound(sound'AnnouncerMain.Incoming');

			return True;
		}
	}

	// All attempts failed
	Owner.ClientMessage("DEPLOYMENT ABORTED: INSUFFICIENT CLEARANCE — LIABILITY WAIVER VOID");
	Owner.ClientPlaySound(sound'MenuSounds.Deny');
	return False;
}

static function bool SafeSpawnTurret(Pawn Owner, class<Pawn> TurretClass, out Pawn Spawned)
{
	local Vector BaseLoc, Forward, TestLoc;
	local Rotator SpawnRot;
	local float Radius, Height;
	local int i;
	local Vector Offsets[9];
	local Actor HitActor;
	local Vector HitLoc, HitNorm;
	local bool bClear;
	local Pawn Turret;

	if (Owner == None || TurretClass == None)
		return False;

	// Get turret collision bounds
	GetClassDefaultObject(TurretClass).GetCollisionRadiusAndHeight(Radius, Height);

	// Base spawn location: in front of player
	Forward = Vector(Owner.Rotation);
	BaseLoc = Owner.Location + Forward * DEPLOY_BASE_DISTANCE;
	BaseLoc.Z += DEPLOY_Z_OFFSET;
	SpawnRot = Owner.Rotation;
	SpawnRot.Yaw = Owner.Rotation.Yaw; // Face same direction as player

	// Generate test offsets (same pattern)
	Offsets[0] = Vect(0, 0, 0);
	Offsets[1] = Vect(Radius * DEPLOY_OFFSET_MULT, 0, 0);
	Offsets[2] = Vect(-Radius * DEPLOY_OFFSET_MULT, 0, 0);
	Offsets[3] = Vect(0, Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[4] = Vect(0, -Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[5] = Vect(Radius * DEPLOY_OFFSET_MULT, Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[6] = Vect(Radius * DEPLOY_OFFSET_MULT, -Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[7] = Vect(-Radius * DEPLOY_OFFSET_MULT, Radius * DEPLOY_OFFSET_MULT, 0);
	Offsets[8] = Vect(-Radius * DEPLOY_OFFSET_MULT, -Radius * DEPLOY_OFFSET_MULT, 0);

	for (i = 0; i < MAX_DEPLOY_ATTEMPTS; i++)
	{
		TestLoc = BaseLoc + Offsets[i];

		// Floor check
		HitActor = Owner.Trace(HitLoc, HitNorm, TestLoc, TestLoc - Vect(0, 0, FLOOR_TRACE_DIST), False, Vect(Radius, Radius, Height));
		if (HitActor == None)
			continue;

		// Ceiling check
		HitActor = Owner.Trace(HitLoc, HitNorm, TestLoc, TestLoc + Vect(0, 0, CEILING_TRACE_DIST), False, Vect(Radius, Radius, Height));
		if (HitActor != None)
			continue;

		// Encroachment check
		bClear = True;
		ForEach OverlappingActors(class'Actor', HitActor, TestLoc, Vect(Radius, Radius, Height))
		{
			if (HitActor != Owner && HitActor.bBlockActors && !HitActor.IsA('PlayerReplicationInfo'))
			{
				bClear = False;
				break;
			}
		}

		if (!bClear)
			continue;

		Turret = Spawn(TurretClass, , , TestLoc, SpawnRot);
		if (Turret != None)
		{
			Spawned = Turret;

			// Play spawn sound
			Owner.ClientPlaySound(sound'AnnouncerMain.Incoming');

			return True;
		}
	}

	Owner.ClientMessage("DEPLOYMENT ABORTED: INSUFFICIENT CLEARANCE — LIABILITY WAIVER VOID");
	Owner.ClientPlaySound(sound'MenuSounds.Deny');
	return False;
}

static function bool CheckClearance(Vector Loc, float Radius, float Height)
{
	local Actor HitActor;
	local Vector HitLoc, HitNorm;

	// Floor
	HitActor = Trace(HitLoc, HitNorm, Loc, Loc - Vect(0, 0, FLOOR_TRACE_DIST), False, Vect(Radius, Radius, Height));
	if (HitActor == None)
		return False;

	// Ceiling
	HitActor = Trace(HitLoc, HitNorm, Loc, Loc + Vect(0, 0, CEILING_TRACE_DIST), False, Vect(Radius, Radius, Height));
	if (HitActor != None)
		return False;

	return True;
}

defaultproperties
{
}
