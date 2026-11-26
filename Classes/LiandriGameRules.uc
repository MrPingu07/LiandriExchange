/******************************************************************************
 * LiandriGameRules -- GameRules subclass for kill/death currency tracking
 * Uses GameInfo.GameRulesModifiers chain (not Mutator hooks) for reliable scoring.
 ******************************************************************************/
class LiandriGameRules extends GameRules;

var int CCPerFrag;
var int CDPerDeath;
var int SuicidePenalty;

function PostBeginPlay()
{
	local LiandriExchangeMutator Mut;

	Super.PostBeginPlay();

	// Cache config from mutator
	Mut = LiandriExchangeMutator(Level.Game.BaseMutator);
	while (Mut != None && !Mut.IsA('LiandriExchangeMutator'))
		Mut = LiandriExchangeMutator(Mut.NextMutator);
	if (Mut != None)
	{
		CCPerFrag = Mut.CCPerFrag;
		CDPerDeath = Mut.CDPerDeath;
		SuicidePenalty = Mut.SuicidePenalty;
	}
}

function LiandriWallet FindWallet(PlayerReplicationInfo PRI)
{
	local LinkedReplicationInfo L;

	if (PRI == None)
		return None;

	L = PRI.CustomReplicationInfo;
	while (L != None)
	{
		if (LiandriWallet(L) != None)
			return LiandriWallet(L);
		L = L.NextReplicationInfo;
	}

	return None;
}

function ScoreKill(Controller Killer, Controller Killed)
{
	local PlayerReplicationInfo KillerPRI, KilledPRI;
	local LiandriWallet KillerWallet, KilledWallet;
	local bool bIsSuicide;

	Super.ScoreKill(Killer, Killed);

	if (Killed == None || Killed.PlayerReplicationInfo == None)
		return;

	KilledPRI = Killed.PlayerReplicationInfo;
	KilledWallet = FindWallet(KilledPRI);

	// Determine if suicide (fall/world damage OR DamageType == Suicide OR KilledBy == Self)
	// Note: GameRules doesn't get DamageType directly; we infer from killer
	bIsSuicide = False;
	if (Killer == Killed)
		bIsSuicide = True;
	else if (Killer == None)
		bIsSuicide = True; // World kill

	if (KilledWallet != None)
	{
		if (bIsSuicide)
		{
			if (SuicidePenalty == 0)
				KilledWallet.ServerAddCD(0); // Explicit no-grant
			else
				KilledWallet.ServerAddCD(SuicidePenalty); // Negative or custom penalty
		}
		else
		{
			// Normal death: grant CD
			KilledWallet.ServerAddCD(CDPerDeath);
		}
	}

	// Frag credit to killer (if different player)
	if (Killer != None && Killer.PlayerReplicationInfo != None && Killer != Killed)
	{
		KillerPRI = Killer.PlayerReplicationInfo;
		KillerWallet = FindWallet(KillerPRI);
		if (KillerWallet != None)
		{
			KillerWallet.ServerAddCC(CCPerFrag);
		}
	}
}

defaultproperties
{
	CCPerFrag=1
	CDPerDeath=1
	SuicidePenalty=0
}