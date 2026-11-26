/******************************************************************************
 * LiandriHUDInteraction -- Fast-buy HUD overlay (Interaction + Canvas)
 * Keyboard-driven, never steals mouse-look. Shows the 5+5 active draft.
 *
 * Purchases are sent through the console "mutate" path so they always reach
 * the server, even when this interaction runs on a network client.
 ******************************************************************************/
class LiandriHUDInteraction extends Interaction;

struct HUDItem
{
	var string ItemName;
	var int Cost;
	var string FlavorText;
	var bool bAffordable;
	var bool bIsVehicle;
	var int MasterIndex;
};

var bool bShowHUD;
var LiandriWallet Wallet;
var PlayerController PC;
var LiandriConfig Cfg;
var float KeyRepeatDelay;
var bool bShiftPressed;
var bool bCtrlPressed;

var HUDItem CCItems[5];
var HUDItem CDItems[5];

event Initialized()
{
	Super.Initialized();

	PC = ViewportOwner.Actor;
	Cfg = new(None) class'LiandriExchange.LiandriConfig';

	bShowHUD = False;
	KeyRepeatDelay = 0.15;
	bVisible = True;
	bActive = True;

	EnsureWallet();
}

function EnsureWallet()
{
	local LinkedReplicationInfo L;

	if (PC == None)
		PC = ViewportOwner.Actor;

	if (Wallet != None || PC == None || PC.PlayerReplicationInfo == None)
		return;

	L = PC.PlayerReplicationInfo.CustomReplicationInfo;
	while (L != None)
	{
		if (LiandriWallet(L) != None)
		{
			Wallet = LiandriWallet(L);
			return;
		}
		L = L.NextReplicationInfo;
	}
}

simulated function bool KeyEvent(out EInputKey Key, out EInputAction Action, float Delta)
{
	local int Slot;
	local string Cmd;

	if (Key == IK_Shift)
	{
		bShiftPressed = (Action == IST_Press);
		return False;
	}

	if (Key == IK_Ctrl)
	{
		bCtrlPressed = (Action == IST_Press);
		return False;
	}

	if (Action != IST_Press)
		return False;

	// Toggle terminal with F4 - open native GUI buy menu
	if (Key == IK_F4)
	{
		if (PC != None)
		{
			PC.ClientOpenMenu("LiandriExchange.LiandriBuyMenu", false, "", "");
			PC.ClientPlaySound(Sound'MenuSounds.Select3');
		}
		return True;
	}

	if (!bShowHUD)
		return False;

	EnsureWallet();
	if (Wallet == None)
		return True;

	// R / Shift+R: full division reroll
	if (Key == IK_R)
	{
		if (bShiftPressed)
			Cmd = "LiandriRerollCD";
		else
			Cmd = "LiandriRerollCC";

		if (PC != None)
			PC.ConsoleCommand("mutate " $ Cmd);

		RefreshItemData();
		return True;
	}

	return False;
}

function RefreshItemData()
{
	local int i, Idx;

	EnsureWallet();
	if (Wallet == None)
		return;

	if (Cfg == None)
		Cfg = new(None) class'LiandriExchange.LiandriConfig';

	for (i = 0; i < 5; i++)
	{
		Idx = Wallet.ActiveCCSlots[i];
		if (Idx != -1)
		{
			CCItems[i].MasterIndex = Idx;
			CCItems[i].ItemName = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemName(Idx, Cfg);
			CCItems[i].Cost = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemCost(Idx, Cfg);
			CCItems[i].FlavorText = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemFlavorText(Idx, Cfg);
			CCItems[i].bIsVehicle = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemIsVehicle(Idx, Cfg);
			CCItems[i].bAffordable = (Wallet.CombatCredits >= CCItems[i].Cost);
		}
		else
		{
			CCItems[i].MasterIndex = -1;
			CCItems[i].ItemName = "";
			CCItems[i].Cost = 0;
			CCItems[i].FlavorText = "";
			CCItems[i].bIsVehicle = False;
			CCItems[i].bAffordable = False;
		}

		Idx = Wallet.ActiveCDSlots[i];
		if (Idx != -1)
		{
			CDItems[i].MasterIndex = Idx;
			CDItems[i].ItemName = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemName(Idx, Cfg);
			CDItems[i].Cost = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemCost(Idx, Cfg);
			CDItems[i].FlavorText = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemFlavorText(Idx, Cfg);
			CDItems[i].bIsVehicle = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemIsVehicle(Idx, Cfg);
			CDItems[i].bAffordable = (Wallet.CasualtyDividends >= CDItems[i].Cost);
		}
		else
		{
			CDItems[i].MasterIndex = -1;
			CDItems[i].ItemName = "";
			CDItems[i].Cost = 0;
			CDItems[i].FlavorText = "";
			CDItems[i].bIsVehicle = False;
			CDItems[i].bAffordable = False;
		}
	}
}

function PostRender(Canvas C)
{
	local int i;
	local float X, Y, LineH, Scale;
	local color Gold, Amber, Red, Gray, Green, White;
	local string Line;

	Super.PostRender(C);

	if (!bShowHUD)
		return;

	EnsureWallet();
	if (Wallet == None)
		return;

	RefreshItemData();

	Scale = C.ClipY / 768.0;
	if (Scale < 0.75)
		Scale = 0.75;

	if (C.MedFont != None)
		C.Font = C.MedFont;
	else
		C.Font = C.SmallFont;

	Gold.R = 255;   Gold.G = 215;   Gold.B = 0;     Gold.A = 255;
	Amber.R = 255;  Amber.G = 165;  Amber.B = 0;    Amber.A = 255;
	Red.R = 255;    Red.G = 0;      Red.B = 0;      Red.A = 255;
	Gray.R = 128;   Gray.G = 128;   Gray.B = 128;   Gray.A = 255;
	Green.R = 0;    Green.G = 255;  Green.B = 0;    Green.A = 255;
	White.R = 255;  White.G = 255;  White.B = 255;  White.A = 255;

	X = 20.0 * Scale;
	Y = 20.0 * Scale;
	LineH = 18.0 * Scale;

	C.SetPos(X, Y);
	C.DrawColor = Gold;
	C.DrawText("LIANDRI EXCHANGE -- REQUISITION TERMINAL v3.4.1");
	Y += LineH * 1.5;

	C.SetPos(X, Y);
	C.DrawColor = White;
	C.DrawText("CC: " $ Wallet.CombatCredits $ "   |   CD: " $ Wallet.CasualtyDividends);
	Y += LineH * 1.3;

	C.SetPos(X, Y);
	C.DrawColor = Gold;
	C.DrawText("DIVISION I: PERFORMANCE REQUISITIONS (CC)");
	Y += LineH;

	for (i = 0; i < 5; i++)
	{
		if (CCItems[i].ItemName == "")
			continue;

		Line = "[" $ (i + 1) $ "] " $ CCItems[i].ItemName;
		C.SetPos(X, Y);
		if (CCItems[i].bAffordable)
			C.DrawColor = Green;
		else
			C.DrawColor = Red;
		C.DrawText(Line);

		C.SetPos(X + 300.0 * Scale, Y);
		C.DrawText(CCItems[i].Cost $ " CC");

		if (CCItems[i].bIsVehicle)
		{
			C.SetPos(X + 400.0 * Scale, Y);
			C.DrawColor = Amber;
			C.DrawText("[DEPLOY]");
		}

		Y += LineH;
	}

	Y += LineH * 0.5;

	C.SetPos(X, Y);
	C.DrawColor = Gold;
	C.DrawText("DIVISION II: SPONSOR SUBSIDIES (CD)");
	Y += LineH;

	for (i = 0; i < 5; i++)
	{
		if (CDItems[i].ItemName == "")
			continue;

		Line = "[SHIFT+" $ (i + 1) $ "] " $ CDItems[i].ItemName;
		C.SetPos(X, Y);
		if (CDItems[i].bAffordable)
			C.DrawColor = Green;
		else
			C.DrawColor = Red;
		C.DrawText(Line);

		C.SetPos(X + 300.0 * Scale, Y);
		C.DrawText(CDItems[i].Cost $ " CD");

		if (CDItems[i].bIsVehicle)
		{
			C.SetPos(X + 400.0 * Scale, Y);
			C.DrawColor = Amber;
			C.DrawText("[DEPLOY]");
		}

		Y += LineH;
	}

	Y += LineH;

	C.SetPos(X, Y);
	C.DrawColor = White;
	C.DrawText("[R] REROLL DIVISION I   [SHIFT+R] REROLL DIVISION II");
	Y += LineH;

	C.SetPos(X, Y);
	C.DrawText("[CTRL+1-5] REROLL SLOT CC   [CTRL+SHIFT+1-5] REROLL SLOT CD");
	Y += LineH;

	C.SetPos(X, Y);
	C.DrawColor = Gray;
	C.DrawText("[F4] CLOSE TERMINAL");

	for (i = 0; i < 5; i++)
	{
		if (CCItems[i].ItemName != "" && CCItems[i].bAffordable)
		{
			Y += LineH;
			C.SetPos(X, Y);
			C.DrawColor = Gray;
			C.DrawText("> " $ CCItems[i].FlavorText);
			break;
		}
	}
}

defaultproperties
{
}
