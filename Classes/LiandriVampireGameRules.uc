/******************************************************************************
 * LiandriVampireGameRules — Vampire life-steal rules
 * Damaging opponents heals the player; capped at 3× server-dictated max health.
 ******************************************************************************/
class LiandriVampireGameRules extends VampireGameRules;

function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
	local float HealAmount;
	local float MaxAllowed;

	if ( NextGameRules != None )
		return NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );

	if ( (InstigatedBy != Injured) && (InstigatedBy != None) && (InstigatedBy.Health > 0) 
		&& (InstigatedBy.PlayerReplicationInfo != None) && (Injured.PlayerReplicationInfo != None) 
		&& ((InstigatedBy.PlayerReplicationInfo.Team == None) || (InstigatedBy.PlayerReplicationInfo.Team != Injured.PlayerReplicationInfo.Team)) )
	{
		// Steal 50% of damage dealt, but cap at 3× max health
		HealAmount = Damage * 0.500000;  // ConversionRatio
		MaxAllowed = 3.0 * InstigatedBy.HealthMax;  // 3x server max
		InstigatedBy.Health = Min( InstigatedBy.Health + HealAmount, MaxAllowed );
	}
	return Damage;
}

// server querying
function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
	local int i;
	i = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "Mutator";
	ServerState.ServerInfo[i].Value = GetHumanReadableName();
}

defaultproperties
{
	 ConversionRatio=0.500000
}