/******************************************************************************
 * LiandriExchangeMutator — Main mutator entry point
 * Attaches LiandriWallet to PlayerReplicationInfo, handles draft, currency.
 ******************************************************************************/

class LiandriExchangeMutator extends Mutator
	config(LiandriExchange)
	placeable;

var config int CCPerFrag;
var config int CDPerDeath;
var config int SuicidePenalty;        // 0 = no CD on suicide
var config int RerollCost;
var config int DraftPoolSize;         // 5 default
var config bool bEnableVehicles;
var config bool bEnableBotPurchases;
var config bool bFullDivisionReroll;
var config bool bSingleSlotReroll;
var config int SingleSlotRerollCost;

var ALiandriConfig ConfigObj;

// Master item pools (indices 0-9 for each division)
var int MasterCCPool[10];
var int MasterCDPool[10];

// Replication
replication
{
	reliable if (Role == ROLE_Authority)
		ConfigObj, MasterCCPool, MasterCDPool;
}

function PostBeginPlay()
{
	local int i;
	super.PostBeginPlay();

	// Load config object
	ConfigObj = Spawn(class'LiandriExchange.ALiandriConfig');
	if (ConfigObj != None)
	{
		CCPerFrag = ConfigObj.CCPerFrag;
		CDPerDeath = ConfigObj.CDPerDeath;
		SuicidePenalty = ConfigObj.SuicidePenalty;
		RerollCost = ConfigObj.RerollCost;
		DraftPoolSize = ConfigObj.DraftPoolSize;
		bEnableVehicles = ConfigObj.bEnableVehicles;
		bEnableBotPurchases = ConfigObj.bEnableBotPurchases;
		bFullDivisionReroll = ConfigObj.bFullDivisionReroll;
		bSingleSlotReroll = ConfigObj.bSingleSlotReroll;
		SingleSlotRerollCost = ConfigObj.SingleSlotRerollCost;
	}

	// Initialize master pools (0-9)
	for (i = 0; i < 10; i++)
	{
		MasterCCPool[i] = i;
		MasterCDPool[i] = i;
	}

	// Attach wallets to existing players
	AttachWalletsToAllPlayers();
}

function AttachWalletsToAllPlayers()
{
	local PlayerReplicationInfo PRI;
	local LiandriWallet Wallet;

	for (PRI = Level.Game.GRI.PRI; PRI != None; PRI = PRI.NextPlayer)
	{
		if (PRI.Player != None && PRI.Wallet == None)
		{
			Wallet = Spawn(class'LiandriExchange.LiandriWallet', PRI);
			if (Wallet != None)
			{
				PRI.Wallet = Wallet;
				Wallet.InitializeDraft();
			}
		}
	}
}

function MutatorTakeDamage(int ActualDamage, Controller InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType, Actor HitActor, Actor DamageCauser)
{
	local xPlayerReplicationInfo VictimPRI, KillerPRI;
	local LiandriWallet VictimWallet, KillerWallet;
	local bool bIsSuicide;

	super.MutatorTakeDamage(ActualDamage, InstigatedBy, HitLocation, Momentum, DamageType, HitActor, DamageCauser);

	if (HitActor == None || HitActor.PlayerReplicationInfo == None)
		return;

	VictimPRI = xPlayerReplicationInfo(HitActor.PlayerReplicationInfo);
	VictimWallet = LiandriWallet(VictimPRI.Wallet);

	// Determine if suicide (fall/world damage OR DamageType == Suicide OR KilledBy == Self)
	bIsSuicide = False;
	if (DamageCauser == HitActor)
		bIsSuicide = True;
	else if (DamageType != None && DamageType.IsA('Suicide'))
		bIsSuicide = True;
	else if (DamageType != None && (DamageType.IsA('FallDamage') || DamageType.IsA('WorldDamage')))
		bIsSuicide = True;

	if (VictimWallet != None)
	{
		if (bIsSuicide)
		{
			if (SuicidePenalty == 0)
				VictimWallet.ServerAddCD(0); // Explicit no-grant
			else
				VictimWallet.ServerAddCD(SuicidePenalty); // Negative or custom penalty
		}
		else
		{
			// Normal death: grant CD
			VictimWallet.ServerAddCD(CDPerDeath);
		}
	}

	// Frag credit to killer (if different player)
	if (InstigatedBy != None && InstigatedBy.PlayerReplicationInfo != None && InstigatedBy.PlayerReplicationInfo != VictimPRI)
	{
		KillerPRI = xPlayerReplicationInfo(InstigatedBy.PlayerReplicationInfo);
		KillerWallet = LiandriWallet(KillerPRI.Wallet);
		if (KillerWallet != None)
		{
			KillerWallet.ServerAddCC(CCPerFrag);
		}
	}
}

function PostLogin(playerpawn NewPlayer)
{
	local xPlayerReplicationInfo PRI;
	local LiandriWallet Wallet;

	super.PostLogin(NewPlayer);

	PRI = xPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);
	if (PRI != None && PRI.Wallet == None)
	{
		Wallet = Spawn(class'LiandriExchange.LiandriWallet', PRI);
		if (Wallet != None)
		{
			PRI.Wallet = Wallet;
			Wallet.InitializeDraft();
		}
	}
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	local xPlayerReplicationInfo PRI;
	local LiandriWallet Wallet;

	if (Other.IsA('PlayerReplicationInfo'))
	{
		PRI = xPlayerReplicationInfo(Other);
		if (PRI.Wallet == None)
		{
			Wallet = Spawn(class'LiandriExchange.LiandriWallet', PRI);
			if (Wallet != None)
			{
				PRI.Wallet = Wallet;
				Wallet.InitializeDraft();
			}
		}
	}

	return Super.CheckReplacement(Other, bSuperRelevant);
}

function InitMutator(string Options, out string ErrorMessage)
{
	local string Opt;
	super.InitMutator(Options, ErrorMessage);

	// Parse URL options if any
	while (GetNextOption(Options, Opt))
	{
		if (ParseOption(Options, "CCPerFrag") != "")
			CCPerFrag = int(ParseOption(Options, "CCPerFrag"));
		if (ParseOption(Options, "CDPerDeath") != "")
			CDPerDeath = int(ParseOption(Options, "CDPerDeath"));
		if (ParseOption(Options, "DraftPoolSize") != "")
			DraftPoolSize = int(ParseOption(Options, "DraftPoolSize"));
	}
}

defaultproperties
{
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
	GroupName="LiandriExchange"
	FriendlyName="Liandri Exchange"
	Description="Corporate sponsorship economy mutator. Trade performance for requisitions."
}
