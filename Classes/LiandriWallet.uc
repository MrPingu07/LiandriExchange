/******************************************************************************
 * LiandriWallet -- LinkedReplicationInfo attached to PlayerReplicationInfo
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

// Config reference (server-side only; the client builds its own copy for the HUD)
var LiandriConfig ConfigObj;

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
	Super.PostBeginPlay();

	if (Role != ROLE_Authority)
		return;

	if (ConfigObj == None)
		ConfigObj = new(None) class'LiandriExchange.LiandriConfig';

	InitializeDraft();

	BotPurchaseInterval = 5.0 + FRand() * 5.0; // 5-10s random interval
	SetTimer(BotPurchaseInterval, True);
}

simulated function Timer()
{
	local Bot B;
	local Pawn P;

	if (Role != ROLE_Authority)
		return;

	if (ConfigObj == None || !ConfigObj.bEnableBotPurchases)
		return;

	// Find this wallet's owner
	P = GetOwnerPawn();
	if (P != None)
	{
		B = Bot(P.Controller);
		if (B != None && B.Pawn != None)
			class'LiandriExchange.LiandriBotAI'.static.BotPurchaseTick(Self);
	}

	BotPurchaseInterval = 5.0 + FRand() * 5.0;
	SetTimer(BotPurchaseInterval, True);
}

function LiandriExchangeMutator GetMutator()
{
	local LiandriExchangeMutator M;

	foreach AllActors(class'LiandriExchange.LiandriExchangeMutator', M)
	{
		if (M != None)
			return M;
	}
	return None;
}

function InitializeDraft()
{
	local LiandriExchangeMutator Mut;
	local int i, RandomIndex, Temp;
	local int CCPool[10], CDPool[10];
	local int DraftSize;

	if (Role != ROLE_Authority || bDraftInitialized)
		return;

	Mut = GetMutator();

	DraftSize = 5;
	if (Mut != None)
	{
		DraftSize = Mut.DraftPoolSize;
		for (i = 0; i < 10; i++)
		{
			CCPool[i] = Mut.MasterCCPool[i];
			CDPool[i] = Mut.MasterCDPool[i];
		}
	}
	else
	{
		// Fallback: identity pools 0-9
		for (i = 0; i < 10; i++)
		{
			CCPool[i] = i;
			CDPool[i] = i;
		}
	}

	if (DraftSize > 5) DraftSize = 5;
	if (DraftSize < 1) DraftSize = 1;

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

	// Sort first DraftSize items by cost (cheapest first)
	SortPoolByCost(CCPool, DraftSize, 0, ConfigObj);
	SortPoolByCost(CDPool, DraftSize, 1, ConfigObj);

	// Take first DraftSize items, empty the rest
	for (i = 0; i < 5; i++)
	{
		if (i < DraftSize)
		{
			ActiveCCSlots[i] = CCPool[i];
			ActiveCDSlots[i] = CDPool[i];
		}
		else
		{
			ActiveCCSlots[i] = -1;
			ActiveCDSlots[i] = -1;
		}
	}

	bDraftComplete = True;
	bDraftInitialized = True;
}

function ServerAddCC(int Amount)
{
	if (Role != ROLE_Authority)
		return;

	if (Amount > 0)
		CombatCredits += Amount;
}

function ServerAddCD(int Amount)
{
	if (Role != ROLE_Authority)
		return;

	if (Amount > 0)
		CasualtyDividends += Amount;
}

function ServerPurchaseCC(int SlotIndex)
{
	local int Cost;
	local string ItemName;
	local Pawn P;

	if (Role != ROLE_Authority || ConfigObj == None)
		return;

	if (SlotIndex < 0 || SlotIndex >= 5)
		return;

	if (ActiveCCSlots[SlotIndex] == -1)
		return;

	// Deny purchase if dead or spectating
	P = GetOwnerPawn();
	if (P == None || P.Health <= 0)
	{
		ClientReceiveMessage("CANNOT PURCHASE WHILE DEAD OR SPECTATING", Sound'MenuSounds.denied1');
		return;
	}

	if (!class'LiandriExchange.LiandriItemExecutor'.static.IsCCItemEnabled(ActiveCCSlots[SlotIndex], ConfigObj))
		return;

	Cost = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemCost(ActiveCCSlots[SlotIndex], ConfigObj);
	if (CombatCredits < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT CREDITS -- REQUISITION DENIED", Sound'MenuSounds.denied1');
		return;
	}

	CombatCredits -= Cost;

	if (P != None)
		class'LiandriExchange.LiandriItemExecutor'.static.ExecuteCCItem(P, ActiveCCSlots[SlotIndex], ConfigObj);

	ItemName = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemName(ActiveCCSlots[SlotIndex], ConfigObj);
	ClientReceiveMessage("REQUISITION CONFIRMED: " @ ItemName @ " (-" @ Cost @ " CC)", Sound'MenuSounds.select3');
}

function ServerPurchaseCD(int SlotIndex)
{
	local int Cost;
	local string ItemName;
	local Pawn P;

	if (Role != ROLE_Authority || ConfigObj == None)
		return;

	if (SlotIndex < 0 || SlotIndex >= 5)
		return;

	if (ActiveCDSlots[SlotIndex] == -1)
		return;

	// Deny purchase if dead or spectating
	P = GetOwnerPawn();
	if (P == None || P.Health <= 0)
	{
		ClientReceiveMessage("CANNOT PURCHASE WHILE DEAD OR SPECTATING", Sound'MenuSounds.denied1');
		return;
	}

	if (!class'LiandriExchange.LiandriItemExecutor'.static.IsCDItemEnabled(ActiveCDSlots[SlotIndex], ConfigObj))
		return;

	Cost = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemCost(ActiveCDSlots[SlotIndex], ConfigObj);
	if (CasualtyDividends < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT DIVIDENDS -- SUBSIDY DENIED", Sound'MenuSounds.denied1');
		return;
	}

	CasualtyDividends -= Cost;

	if (P != None)
		class'LiandriExchange.LiandriItemExecutor'.static.ExecuteCDItem(P, ActiveCDSlots[SlotIndex], ConfigObj);

	ItemName = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemName(ActiveCDSlots[SlotIndex], ConfigObj);
	ClientReceiveMessage("SUBSIDY GRANTED: " @ ItemName @ " (-" @ Cost @ " CD)", Sound'MenuSounds.select3');
}

function ServerRerollCC()
{
	local LiandriExchangeMutator Mut;
	local int i, DraftSize, RandomIndex, Temp;
	local int CCPool[10];
	local int Cost;
	local Pawn P;

	if (Role != ROLE_Authority || ConfigObj == None)
		return;

	// Deny reroll if dead or spectating
	P = GetOwnerPawn();
	if (P == None || P.Health <= 0)
	{
		ClientReceiveMessage("CANNOT REROLL WHILE DEAD OR SPECTATING", Sound'MenuSounds.denied1');
		return;
	}

	Cost = ConfigObj.RerollCCCost;
	if (CombatCredits < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT CREDITS FOR REROLL -- REQUEST DENIED", Sound'MenuSounds.denied1');
		return;
	}

	Mut = GetMutator();
	if (Mut == None)
		return;

	CombatCredits -= Cost;

	DraftSize = Mut.DraftPoolSize;
	if (DraftSize > 5) DraftSize = 5;
	if (DraftSize < 1) DraftSize = 1;

	for (i = 0; i < 10; i++)
		CCPool[i] = Mut.MasterCCPool[i];

	for (i = 9; i > 0; i--)
	{
		RandomIndex = Rand(i + 1);
		Temp = CCPool[i];
		CCPool[i] = CCPool[RandomIndex];
		CCPool[RandomIndex] = Temp;
	}

	// Sort first DraftSize items by cost (cheapest first)
	SortPoolByCost(CCPool, DraftSize, 0, ConfigObj);

	for (i = 0; i < 5; i++)
	{
		if (i < DraftSize)
			ActiveCCSlots[i] = CCPool[i];
		else
			ActiveCCSlots[i] = -1;
	}

	ClientReceiveMessage("DIVISION I REQUISITION POOL REFRESHED (-" $ Cost $ " CC)", Sound'MenuSounds.Select3');
}

function ServerRerollCD()
{
	local LiandriExchangeMutator Mut;
	local int i, DraftSize, RandomIndex, Temp;
	local int CDPool[10];
	local int Cost;
	local Pawn P;

	if (Role != ROLE_Authority || ConfigObj == None)
		return;

	// Deny reroll if dead or spectating
	P = GetOwnerPawn();
	if (P == None || P.Health <= 0)
	{
		ClientReceiveMessage("CANNOT REROLL WHILE DEAD OR SPECTATING", Sound'MenuSounds.denied1');
		return;
	}

	Cost = ConfigObj.RerollCDCost;
	if (CasualtyDividends < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT DIVIDENDS FOR REROLL -- REQUEST DENIED", Sound'MenuSounds.denied1');
		return;
	}

	Mut = GetMutator();
	if (Mut == None)
		return;

	CasualtyDividends -= Cost;

	DraftSize = Mut.DraftPoolSize;
	if (DraftSize > 5) DraftSize = 5;
	if (DraftSize < 1) DraftSize = 1;

	for (i = 0; i < 10; i++)
		CDPool[i] = Mut.MasterCDPool[i];

	for (i = 9; i > 0; i--)
	{
		RandomIndex = Rand(i + 1);
		Temp = CDPool[i];
		CDPool[i] = CDPool[RandomIndex];
		CDPool[RandomIndex] = Temp;
	}

	// Sort first DraftSize items by cost (cheapest first)
	SortPoolByCost(CDPool, DraftSize, 1, ConfigObj);

	for (i = 0; i < 5; i++)
	{
		if (i < DraftSize)
			ActiveCDSlots[i] = CDPool[i];
		else
			ActiveCDSlots[i] = -1;
	}

	ClientReceiveMessage("DIVISION II SUBSIDY POOL REFRESHED (-" $ Cost $ " CD)", Sound'MenuSounds.Select3');
}

function ServerSingleSlotRerollCC(int SlotIndex)
{
	local LiandriExchangeMutator Mut;
	local int i, j, RandomIndex;
	local int CCPool[10];
	local int Cost;
	local int ValidCount;
	local int Temp;

	if (Role != ROLE_Authority || ConfigObj == None)
		return;

	if (!ConfigObj.bSingleSlotReroll)
		return;

	Cost = ConfigObj.SingleSlotRerollCost;
	if (CombatCredits < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT CREDITS FOR SLOT REROLL", Sound'MenuSounds.denied1');
		return;
	}

	if (SlotIndex < 0 || SlotIndex >= 5 || ActiveCCSlots[SlotIndex] == -1)
		return;

	Mut = GetMutator();
	if (Mut == None)
		return;

	CombatCredits -= Cost;

	if (!ConfigObj.bSingleSlotReroll)
		return;

	for (i = 0; i < 10; i++)
		CCPool[i] = Mut.MasterCCPool[i];

	// Remove currently active items from pool
	for (i = 0; i < 5; i++)
	{
		if (i != SlotIndex && ActiveCCSlots[i] != -1)
		{
			for (j = 0; j < 10; j++)
			{
				if (CCPool[j] == ActiveCCSlots[i])
				{
					CCPool[j] = -1;
					break;
				}
			}
		}
	}

	ValidCount = 0;
	for (i = 0; i < 10; i++)
	{
		if (CCPool[i] != -1 && class'LiandriExchange.LiandriItemExecutor'.static.IsCCItemEnabled(CCPool[i], ConfigObj))
		{
			CCPool[ValidCount] = CCPool[i];
			ValidCount++;
		}
	}

	if (ValidCount == 0)
		return;

	for (i = ValidCount - 1; i > 0; i--)
	{
		RandomIndex = Rand(i + 1);
		Temp = CCPool[i];
		CCPool[i] = CCPool[RandomIndex];
		CCPool[RandomIndex] = Temp;
	}

	// Sort by cost (cheapest first)
	if (ValidCount > 1)
	{
		SortPoolByCost(CCPool, ValidCount, 0, ConfigObj);
	}

	ActiveCCSlots[SlotIndex] = CCPool[0];
	ClientReceiveMessage("SLOT " $ (SlotIndex + 1) $ " REROLLED (-" $ Cost $ " CC)", Sound'MenuSounds.Select3');
}

function ServerSingleSlotRerollCD(int SlotIndex)
{
	local LiandriExchangeMutator Mut;
	local int i, j, RandomIndex;
	local int CDPool[10];
	local int Cost;
	local int ValidCount;
	local int Temp;

	if (Role != ROLE_Authority || ConfigObj == None)
		return;

	if (!ConfigObj.bSingleSlotReroll)
		return;

	Cost = ConfigObj.SingleSlotRerollCost;
	if (CasualtyDividends < Cost)
	{
		ClientReceiveMessage("INSUFFICIENT DIVIDENDS FOR SLOT REROLL", Sound'MenuSounds.denied1');
		return;
	}

	if (SlotIndex < 0 || SlotIndex >= 5 || ActiveCDSlots[SlotIndex] == -1)
		return;

	Mut = GetMutator();
	if (Mut == None)
		return;

	CasualtyDividends -= Cost;

	if (!ConfigObj.bSingleSlotReroll)
		return;

	for (i = 0; i < 10; i++)
		CDPool[i] = Mut.MasterCDPool[i];

	// Remove currently active items from pool
	for (i = 0; i < 5; i++)
	{
		if (i != SlotIndex && ActiveCDSlots[i] != -1)
		{
			for (j = 0; j < 10; j++)
			{
				if (CDPool[j] == ActiveCDSlots[i])
				{
					CDPool[j] = -1;
					break;
				}
			}
		}
	}

	ValidCount = 0;
	for (i = 0; i < 10; i++)
	{
		if (CDPool[i] != -1 && class'LiandriExchange.LiandriItemExecutor'.static.IsCDItemEnabled(CDPool[i], ConfigObj))
		{
			CDPool[ValidCount] = CDPool[i];
			ValidCount++;
		}
	}

	if (ValidCount == 0)
		return;

	for (i = ValidCount - 1; i > 0; i--)
	{
		RandomIndex = Rand(i + 1);
		Temp = CDPool[i];
		CDPool[i] = CDPool[RandomIndex];
		CDPool[RandomIndex] = Temp;
	}

	// Sort by cost (cheapest first)
	if (ValidCount > 1)
	{
		SortPoolByCost(CDPool, ValidCount, 1, ConfigObj);
	}

	ActiveCDSlots[SlotIndex] = CDPool[0];
	ClientReceiveMessage("SLOT " $ (SlotIndex + 1) $ " REROLLED (-" $ Cost $ " CD)", Sound'MenuSounds.Select3');
}

function Pawn GetOwnerPawn()
{
	local Pawn P;
	local Controller C;

	if (Owner == None)
	{
		return None;
	}

	P = Pawn(Owner);
	if (P != None)
	{
		return P;
	}

	C = Controller(Owner.Owner);
	if (C != None)
	{
		return C.Pawn;
	}

	return None;
}

function LiandriExchangeMutator FindMutator()
{
	local LiandriExchangeMutator M;

	foreach AllActors(class'LiandriExchange.LiandriExchangeMutator', M)
	{
		if (M != None)
		{
			return M;
		}
	}
	return None;
}

function BotPurchaseTick()
{
	local LiandriExchangeMutator Mut;
	local int i, Slot;
	local int CCItems[5], CDItems[5];
	local int NumCC, NumCD;

	if (Role != ROLE_Authority || ConfigObj == None)
		return;

	if (!ConfigObj.bEnableBotPurchases)
		return;

	Mut = GetMutator();
	if (Mut == None)
		return;

	NumCC = 0;
	NumCD = 0;

	// Find affordable CC items
	for (i = 0; i < 5; i++)
	{
		if (ActiveCCSlots[i] != -1)
		{
			if (class'LiandriExchange.LiandriItemExecutor'.static.IsCCItemEnabled(ActiveCCSlots[i], ConfigObj))
			{
				if (CombatCredits >= class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemCost(ActiveCCSlots[i], ConfigObj))
				{
					CCItems[NumCC] = i;
					NumCC++;
				}
			}
		}
	}

	// Find affordable CD items
	for (i = 0; i < 5; i++)
	{
		if (ActiveCDSlots[i] != -1)
		{
			if (class'LiandriExchange.LiandriItemExecutor'.static.IsCDItemEnabled(ActiveCDSlots[i], ConfigObj))
			{
				if (CasualtyDividends >= class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemCost(ActiveCDSlots[i], ConfigObj))
				{
					CDItems[NumCD] = i;
					NumCD++;
				}
			}
		}
	}

	if (NumCC + NumCD == 0)
		return;

	// 30% chance to buy something
	if (FRand() > 0.3)
		return;

	if (NumCC > 0 && (NumCD == 0 || FRand() < 0.5))
	{
		Slot = CCItems[Rand(NumCC)];
		ServerPurchaseCC(Slot);
	}
	else if (NumCD > 0)
	{
		Slot = CDItems[Rand(NumCD)];
		ServerPurchaseCD(Slot);
	}
}

simulated function ClientReceiveMessage(string Msg, optional Sound SoundFX)
{
	local PlayerController PC;

	if (Role != ROLE_Authority)
		return;

	PC = PlayerController(GetOwnerController());
	if (PC != None)
	{
		PC.ClientMessage(Msg);
		if (SoundFX != None)
			PC.ClientPlaySound(SoundFX);
	}
}

function Controller GetOwnerController()
{
	local Pawn P;
	local Controller C;

	if (Owner == None)
	{
		return None;
	}

	P = Pawn(Owner);
	if (P != None)
	{
		return P.Controller;
	}

	C = Controller(Owner.Owner);
	if (C != None)
	{
		return C;
	}

	return None;
}

// Helper: sorts first Count items of Pool by item cost (cheapest first)
// Division: 0 = CC, 1 = CD
function SortPoolByCost(out int Pool[10], int Count, int Division, LiandriConfig Cfg)
{
	local int i, j, Temp, CostA, CostB;

	if (Cfg == None)
		return;

	// Simple bubble sort for small arrays (Count <= 5)
	for (i = 0; i < Count - 1; i++)
	{
		for (j = 0; j < Count - 1 - i; j++)
		{
			if (Division == 0)
			{
				CostA = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemCost(Pool[j], Cfg);
				CostB = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemCost(Pool[j + 1], Cfg);
			}
			else
			{
				CostA = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemCost(Pool[j], Cfg);
				CostB = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemCost(Pool[j + 1], Cfg);
			}

			if (CostA > CostB)
			{
				Temp = Pool[j];
				Pool[j] = Pool[j + 1];
				Pool[j + 1] = Temp;
			}
		}
	}
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
