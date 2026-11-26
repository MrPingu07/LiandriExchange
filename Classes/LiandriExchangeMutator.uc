/******************************************************************************
 * LiandriExchangeMutator -- Main mutator entry point
 * Attaches LiandriWallet to PlayerReplicationInfo, handles draft, currency.
 * Spawns LiandriGameRules for kill/death tracking.
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
var config int RerollCCCost;          // Cost to reroll Division I (CC)
var config int RerollCDCost;          // Cost to reroll Division II (CD)

var LiandriConfig ConfigObj;
var LiandriGameRules GameRulesObj;
var LiandriVampireGameRules GameRulesObjVampire;

// Master item pools (indices 0-9 for each division)
var int MasterCCPool[10];
var int MasterCDPool[10];

function PostBeginPlay()
{
	local int i;
	local LiandriWallet Wallet;
	local PlayerReplicationInfo PRI;

	Super.PostBeginPlay();

	// Non-Actor config object: instantiate with "new", not Spawn.
	ConfigObj = new(None) class'LiandriExchange.LiandriConfig';
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
		RerollCCCost = ConfigObj.RerollCCCost;
		RerollCDCost = ConfigObj.RerollCDCost;
	}

	// Initialize master pools (0-9)
	for (i = 0; i < 10; i++)
	{
		MasterCCPool[i] = i;
		MasterCDPool[i] = i;
	}

	if (Role != ROLE_Authority)
		return;

	// Spawn GameRules for kill/death tracking
	GameRulesObj = Spawn(class'LiandriExchange.LiandriGameRules');
	if (GameRulesObj != None)
	{
		GameRulesObj.CCPerFrag = CCPerFrag;
		GameRulesObj.CDPerDeath = CDPerDeath;
		GameRulesObj.SuicidePenalty = SuicidePenalty;

		if (Level.Game.GameRulesModifiers == None)
			Level.Game.GameRulesModifiers = GameRulesObj;
		else
			Level.Game.GameRulesModifiers.AddGameRules(GameRulesObj);
	}

	// Spawn VampireGameRules for life-steal (50% of damage dealt heals player, capped at 3× max health)
	GameRulesObjVampire = Spawn(class'LiandriExchange.LiandriVampireGameRules');
	if (GameRulesObjVampire != None)
	{
		if (Level.Game.GameRulesModifiers == None)
			Level.Game.GameRulesModifiers = GameRulesObjVampire;
		else
			Level.Game.GameRulesModifiers.AddGameRules(GameRulesObjVampire);
	}

	// Attach wallets to players that already exist
	if (Level.GRI != None)
	{
		for (i = 0; i < Level.GRI.PRIArray.Length; i++)
		{
			PRI = Level.GRI.PRIArray[i];
			if (PRI != None)
			{
				Wallet = GetOrCreateWallet(PRI);
				// Nudge the client so its HUD interaction is installed.
				if (Wallet != None && PlayerController(PRI.Owner) != None)
					PlayerController(PRI.Owner).ReceiveLocalizedMessage(class'LiandriExchange.LiandriHUDMessage', 1);
			}
		}
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

function LiandriWallet GetOrCreateWallet(PlayerReplicationInfo PRI)
{
	local LiandriWallet Wallet;

	Wallet = FindWallet(PRI);
	if (Wallet != None || PRI == None)
		return Wallet;

	Wallet = Spawn(class'LiandriExchange.LiandriWallet', PRI);
	if (Wallet != None)
	{
		Wallet.ConfigObj = ConfigObj;
		Wallet.NextReplicationInfo = PRI.CustomReplicationInfo;
		PRI.CustomReplicationInfo = Wallet;
		Wallet.InitializeDraft();
	}

	return Wallet;
}

function ModifyPlayer(Pawn Other)
{
	local PlayerController PC;

	Super.ModifyPlayer(Other);

	if (Role != ROLE_Authority || Other == None)
		return;

	GetOrCreateWallet(Other.PlayerReplicationInfo);

	PC = PlayerController(Other.Controller);
	if (PC != None)
	{
		PC.ReceiveLocalizedMessage(class'LiandriExchange.LiandriHUDMessage', 1);
	}
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if (Other.IsA('PlayerReplicationInfo'))
		GetOrCreateWallet(PlayerReplicationInfo(Other));

	return Super.CheckReplacement(Other, bSuperRelevant);
}

// Fallback console entry point, e.g. "mutate liandri" to reopen the terminal.
function Mutate(string MutateString, PlayerController Sender)
{
	local LiandriWallet Wallet;
	local int Slot;

	Super.Mutate(MutateString, Sender);

	if (Role != ROLE_Authority || Sender == None)
		return;

	Wallet = GetOrCreateWallet(Sender.PlayerReplicationInfo);
	if (Wallet == None)
		return;

	if (Left(MutateString, 12) ~= "LiandriBuyCC")
	{
		Slot = int(Mid(MutateString, 12));
		Wallet.ServerPurchaseCC(Slot);
	}
	else if (Left(MutateString, 12) ~= "LiandriBuyCD")
	{
		Slot = int(Mid(MutateString, 12));
		Wallet.ServerPurchaseCD(Slot);
	}
	else if (Left(MutateString, 15) ~= "LiandriRerollCC")
	{
		Wallet.ServerRerollCC();
	}
	else if (Left(MutateString, 15) ~= "LiandriRerollCD")
	{
		Wallet.ServerRerollCD();
	}
	else if (Left(MutateString, 13) ~= "LiandriSlotCC")
	{
		Slot = int(Mid(MutateString, 13));
		Wallet.ServerSingleSlotRerollCC(Slot);
	}
	else if (Left(MutateString, 13) ~= "LiandriSlotCD")
	{
		Slot = int(Mid(MutateString, 13));
		Wallet.ServerSingleSlotRerollCD(Slot);
	}
	else if (MutateString ~= "LiandriMenu")
	{
		// Open native GUI buy menu (VMSMod style)
		Sender.ClientOpenMenu("LiandriExchange.LiandriBuyMenu", false, "", "");
	}
	else if (MutateString ~= "Liandri")
	{
		Sender.ReceiveLocalizedMessage(class'LiandriExchange.LiandriHUDMessage', 1);
	}
}

// MutatorFillPlayInfo for config GUI
function MutatorFillPlayInfo(PlayInfo PlayInfo)
{
	class'LiandriExchange.LiandriConfig'.static.FillPlayInfo(PlayInfo);
	Super.MutatorFillPlayInfo(PlayInfo);
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
	RerollCCCost=5
	RerollCDCost=5
	GroupName="LiandriExchange"
	FriendlyName="Liandri Exchange"
	Description="Liandri Mining Corporation Requisition Terminal v3.4.1. Convert combat performance into corporate-sponsored equipment. Combat Credits (CC) earned per frag unlock offensive assets. Casualty Dividends (CD) earned per death unlock survivability tools. 5+5 randomized draft per match. Safe spatial deployment. Fully configurable."
	ConfigMenuClassName="LiandriExchange.LiandriConfigGUI"
}
