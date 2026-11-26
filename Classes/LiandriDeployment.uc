/******************************************************************************
 * LiandriDeployment -- Simple deployment utility
 * Spawns vehicles/turrets in front of the player without complex traces.
 ******************************************************************************/
class LiandriDeployment extends Object;

static function bool SafeSpawnVehicle(Pawn Owner, class<Vehicle> VClass, out Vehicle Spawned)
{
	local Vector SpawnLoc;
	local Vehicle V;
	local PlayerController PC;

	if (Owner == None || VClass == None)
		return False;

	SpawnLoc = Owner.Location + Vector(Owner.Rotation) * 300.0;
	SpawnLoc.Z += 50.0;

	// Enable vehicles so they render (SVehicleFactory.uc destroys them if bAllowVehicles is off).
	Owner.Level.Game.bAllowVehicles = True;

	V = Owner.Spawn(VClass, Owner, 'LiandriVehicle', SpawnLoc, Owner.Rotation);
	if (V == None)
		return False;

	Spawned = V;

	// Align vehicle team with the owner's team so the native team-lock check
	// in TryToDrive does not reject entry.
	if (Owner.PlayerReplicationInfo != None && Owner.PlayerReplicationInfo.Team != None)
		V.SetTeamNum(Owner.PlayerReplicationInfo.Team.TeamIndex);

	// Vehicles are hidden by default; show them.
	V.bHidden = False;

	// Auto-seat the purchasing player (driver seat)
	V.TryToDrive(Owner);

	PC = PlayerController(Owner.Controller);
	if (PC != None)
		PC.ClientPlaySound(Sound'MenuSounds.select3');

	return True;
}

static function bool SafeSpawnTurret(Pawn Owner, class<Pawn> TurretClass, out Pawn Spawned)
{
	local Vector SpawnLoc;
	local Pawn Turret;
	local PlayerController PC;

	if (Owner == None || TurretClass == None)
		return False;

	SpawnLoc = Owner.Location + Vector(Owner.Rotation) * 300.0;
	SpawnLoc.Z += 50.0;

	Turret = Owner.Spawn(TurretClass, Owner, 'LiandriTurret', SpawnLoc, Owner.Rotation);
	if (Turret == None)
		return False;

	Spawned = Turret;

	PC = PlayerController(Owner.Controller);
	if (PC != None)
		PC.ClientPlaySound(Sound'MenuSounds.select3');

	return True;
}

defaultproperties
{
}
