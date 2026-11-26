/******************************************************************************
 * LiandriHUDMenu -- Centered requisition terminal (Interaction + Canvas)
 *
 * Full-screen centered modal window with Unreal Tournament logo, corporate
 * styling matching TeamDirector/RespawnDelay design language.
 * Keyboard-driven: F4 toggles, 1-5/Shift+1-5/Ctrl+1-5/Ctrl+Shift+1-5/R/Shift+R.
 * All purchases routed via console "mutate" for server authority.
 ******************************************************************************/
class LiandriHUDMenu extends Interaction;

struct HUDItem
{
	var string ItemName;
	var int Cost;
	var string FlavorText;
	var bool bAffordable;
	var bool bIsVehicle;
	var int MasterIndex;
};

struct DrawContext
{
	var float Col1X;
	var float Col2X;
	var float ColW;
	var float ItemY;
	var int Index;
	var color TitleColor;
	var color AffordableColor;
	var color UnaffordableColor;
	var color VehicleColor;
	var color WhiteColor;
	var color GrayColor;
	var Font BodyFont;
	var Font DescFont;
	var float Scale;
	var float LineH;
	var color StripeColor;
};

var bool bShowMenu;
var LiandriWallet Wallet;
var PlayerController PC;
var LiandriConfig Cfg;

var HUDItem CCItems[5];
var HUDItem CDItems[5];

// Animation state
var float MenuOpenTime;
var float LastKeyTime;

// Modifier key state tracking
var bool bShiftPressed;
var bool bCtrlPressed;

// UI constants (UnrealScript doesn't support const float, use var)
var float MENU_WIDTH_RATIO;
var float MENU_HEIGHT_RATIO;
var float MIN_MENU_WIDTH;
var float MIN_MENU_HEIGHT;
var float CONTENT_PADDING;
var float SECTION_SPACING;
var float ITEM_LINE_HEIGHT;
var float HEADER_HEIGHT;
var float LOGO_SIZE;
var float STRIPE_THICKNESS;
var float PANEL_ALPHA;
var float STRIPE_ALPHA;

// Corporate color palette (use var instead of const for compatibility)
var int COL_GOLD_R;
var int COL_GOLD_G;
var int COL_GOLD_B;
var int COL_AMBER_R;
var int COL_AMBER_G;
var int COL_AMBER_B;
var int COL_WHITE_R;
var int COL_WHITE_G;
var int COL_WHITE_B;
var int COL_GREEN_R;
var int COL_GREEN_G;
var int COL_GREEN_B;
var int COL_RED_R;
var int COL_RED_G;
var int COL_RED_B;
var int COL_GRAY_R;
var int COL_GRAY_G;
var int COL_GRAY_B;
var int COL_DARK_R;
var int COL_DARK_G;
var int COL_DARK_B;
var int COL_PANEL_R;
var int COL_PANEL_G;
var int COL_PANEL_B;
var int COL_STRIPE_R;
var int COL_STRIPE_G;
var int COL_STRIPE_B;

event Initialized()
{
	Super.Initialized();

	PC = ViewportOwner.Actor;
	Cfg = new(None) class'LiandriExchange.LiandriConfig';

	bShowMenu = False;
	bVisible = True;
	bActive = True;
	bRequiresTick = False;

	// Initialize UI constants (UnrealScript doesn't support const float)
	MENU_WIDTH_RATIO = 0.72;
	MENU_HEIGHT_RATIO = 0.88;
	MIN_MENU_WIDTH = 800.0;
	MIN_MENU_HEIGHT = 580.0;
	CONTENT_PADDING = 40.0;
	SECTION_SPACING = 24.0;
	ITEM_LINE_HEIGHT = 26.0;
	HEADER_HEIGHT = 120.0;
	LOGO_SIZE = 64.0;
	STRIPE_THICKNESS = 4.0;
	PANEL_ALPHA = 220.0;
	STRIPE_ALPHA = 255.0;

	// Corporate color palette
	COL_GOLD_R = 255;  COL_GOLD_G = 215;  COL_GOLD_B = 0;
	COL_AMBER_R = 255; COL_AMBER_G = 165; COL_AMBER_B = 0;
	COL_WHITE_R = 245; COL_WHITE_G = 250; COL_WHITE_B = 255;
	COL_GREEN_R = 70;  COL_GREEN_G = 255; COL_GREEN_B = 110;
	COL_RED_R = 255;   COL_RED_G = 72;    COL_RED_B = 72;
	COL_GRAY_R = 140;  COL_GRAY_G = 150;  COL_GRAY_B = 165;
	COL_DARK_R = 12;   COL_DARK_G = 14;   COL_DARK_B = 18;
	COL_PANEL_R = 18;  COL_PANEL_G = 22;  COL_PANEL_B = 30;
	COL_STRIPE_R = 255; COL_STRIPE_G = 195; COL_STRIPE_B = 0;

	EnsureWallet();
}

function Cleanup()
{
	bVisible = False;
	bActive = False;
	if (Master != None)
		Master.RemoveInteraction(Self);
	Wallet = None;
	PC = None;
	Master = None;
}

event NotifyLevelChange()
{
	Cleanup();
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

	// Track modifier key state
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

	// Toggle menu with F4 - open native GUI buy menu
	if (Key == IK_F4)
	{
		if (PC != None)
		{
			PC.ClientOpenMenu("LiandriExchange.LiandriBuyMenu", false, "", "");
			PC.ClientPlaySound(Sound'MenuSounds.select3');
		}
		return True;
	}

	if (!bShowMenu)
		return False;

	EnsureWallet();
	if (Wallet == None)
		return True;

	// 1-5: buy CC, Shift+1-5: buy CD, Ctrl(+Shift)+1-5: single slot reroll
	if (Key >= IK_1 && Key <= IK_5)
	{
		Slot = Key - IK_1;

		if (bCtrlPressed)
		{
			if (bShiftPressed)
				Cmd = "LiandriSlotCD" $ Slot;
			else
				Cmd = "LiandriSlotCC" $ Slot;
		}
		else if (bShiftPressed)
			Cmd = "LiandriBuyCD" $ Slot;
		else
			Cmd = "LiandriBuyCC" $ Slot;

		if (PC != None)
			PC.ConsoleCommand("mutate " $ Cmd);

		RefreshItemData();
		return True;
	}

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
		if (PC != None)
			LastKeyTime = PC.Level.TimeSeconds;
		return True;
	}

	// Escape also closes
	if (Key == IK_Escape)
	{
		bShowMenu = False;
		if (PC != None)
			PC.ClientPlaySound(Sound'MenuSounds.denied1');
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

function GetTeamColor(out color StripeColor, out color TextColor)
{
	local Pawn TargetPawn;
	local PlayerReplicationInfo TargetPRI;
	local int TeamNum;
	local bool bTeamGame;
	local GameReplicationInfo GRI;

	// Default to white (non-team mode)
	StripeColor.R = 255; StripeColor.G = 255; StripeColor.B = 255; StripeColor.A = 255;
	TextColor.R = 255;     TextColor.G = 255;  TextColor.B = 255;  TextColor.A = 255;

	if (PC == None || PC.PlayerReplicationInfo == None)
		return;

	GRI = PC.GameReplicationInfo;
	if (GRI == None && PC != None && PC.Level != None)
		GRI = PC.Level.GRI;

	// Determine if we're in a team game
	bTeamGame = ((PC != None && PC.Level != None && PC.Level.Game != None && PC.Level.Game.bTeamGame)
		|| (GRI != None && GRI.bTeamGame));

	// Try to get target info for team color (who we're spectating or our own pawn)
	TargetPawn = PC.Pawn;
	if (TargetPawn != None)
		TargetPRI = TargetPawn.PlayerReplicationInfo;
	else
		TargetPRI = None;

	// Determine team: use live pawn, or fall back to player's own team
	if (TargetPRI != None && TargetPawn != None && TargetPawn.Health > 0)
	{
		TeamNum = TargetPawn.GetTeamNum();
	}
	else if (PC.PlayerReplicationInfo != None && PC.PlayerReplicationInfo.Team != None)
	{
		TeamNum = PC.PlayerReplicationInfo.Team.TeamIndex;
	}
	else
	{
		TeamNum = 0; // Default to red
	}

	if (bTeamGame)
	{
		if (TeamNum == 0)
		{
			// Red team - warm palette
			StripeColor.R = 255; StripeColor.G = 60;   StripeColor.B = 60;   StripeColor.A = 255;
			TextColor.R = 255;     TextColor.G = 120;  TextColor.B = 120;  TextColor.A = 255;
		}
		else
		{
			// Blue team - cool palette
			StripeColor.R = 51;  StripeColor.G = 153; StripeColor.B = 255; StripeColor.A = 255;
			TextColor.R = 100;     TextColor.G = 180;  TextColor.B = 255;  TextColor.A = 255;
		}
	}
	// Non-team mode stays white (default)
}

function PostRender(Canvas C)
{
	local float Scale;
	local float MenuW, MenuH, MenuX, MenuY;
	local float ContentX, ContentY, ContentW;
	local float LineH, LogoS, StripeS;
	local Font TitleFont, BodyFont, SmallFont, DescFont;
	local color Gold, Amber, White, Green, Red, Gray, Dark, Panel;
	local color StripeColor, TextColor, HeaderStripeColor;
	local int i;
	local string Line;
	local float XL, YL;
	local float HeaderBottom, FooterY;
	local float ColW, Col1X, Col2X, ColY;
	local float ItemY, DividerY;
	local float HeaderX, HeaderY, HeaderW;
	local float LogoDrawH, LogoDrawW, LogoDrawX, LogoDrawY;
	local float TitleX, TitleY;
	local float CurrencyX, CurrencyY;
	local bool bHasFlavor;
	local DrawContext Ctx;

	Super.PostRender(C);

	if (!bShowMenu)
		return;

	EnsureWallet();
	if (Wallet == None)
		return;

	RefreshItemData();

	// Resolution-independent scaling (1024x768 reference = 1.0)
	// Clamp minimum at 1.0 for resolutions >= 768p
	Scale = C.ClipY / 768.0;
	if (Scale < 1.0)
		Scale = 1.0;

	// Menu dimensions
	MenuW = C.ClipX * MENU_WIDTH_RATIO;
	MenuH = C.ClipY * MENU_HEIGHT_RATIO;
	if (MenuW < MIN_MENU_WIDTH * Scale)
		MenuW = MIN_MENU_WIDTH * Scale;
	if (MenuH < MIN_MENU_HEIGHT * Scale)
		MenuH = MIN_MENU_HEIGHT * Scale;

	// Center on screen
	MenuX = (C.ClipX - MenuW) * 0.5;
	MenuY = (C.ClipY - MenuH) * 0.5;

	// Content area
	ContentX = MenuX + CONTENT_PADDING * Scale;
	ContentY = MenuY + CONTENT_PADDING * Scale;
	ContentW = MenuW - 2.0 * CONTENT_PADDING * Scale;

	// Scaled constants
	LineH = ITEM_LINE_HEIGHT * Scale;
	LogoS = LOGO_SIZE * Scale;
	StripeS = STRIPE_THICKNESS * Scale;

	// Resolve fonts
	TitleFont = Font(DynamicLoadObject("UT2003Fonts.FontEurostile37", class'Font'));
	if (TitleFont == None)
		TitleFont = C.MedFont;

	BodyFont = Font(DynamicLoadObject("UT2003Fonts.FontEurostile17", class'Font'));
	if (BodyFont == None)
		BodyFont = C.MedFont;

	SmallFont = Font(DynamicLoadObject("UT2003Fonts.FontEurostile12", class'Font'));
	if (SmallFont == None)
		SmallFont = C.SmallFont;

	DescFont = Font(DynamicLoadObject("UT2003Fonts.FontEurostile12", class'Font'));
	if (DescFont == None)
		DescFont = C.SmallFont;

	// Color palette - base colors
	Gold.R = COL_GOLD_R;   Gold.G = COL_GOLD_G;   Gold.B = COL_GOLD_B;   Gold.A = 255;
	Amber.R = COL_AMBER_R; Amber.G = COL_AMBER_G; Amber.B = COL_AMBER_B; Amber.A = 255;
	White.R = COL_WHITE_R; White.G = COL_WHITE_G; White.B = COL_WHITE_B; White.A = 255;
	Green.R = COL_GREEN_R; Green.G = COL_GREEN_G; Green.B = COL_GREEN_B; Green.A = 255;
	Red.R = COL_RED_R;     Red.G = COL_RED_G;     Red.B = COL_RED_B;     Red.A = 255;
	Gray.R = COL_GRAY_R;   Gray.G = COL_GRAY_G;   Gray.B = COL_GRAY_B;   Gray.A = 255;
	Dark.R = COL_DARK_R;   Dark.G = COL_DARK_G;   Dark.B = COL_DARK_B;   Dark.A = 255;
	Panel.R = COL_PANEL_R; Panel.G = COL_PANEL_G; Panel.B = COL_PANEL_B; Panel.A = int(PANEL_ALPHA);

	// Team-aware colors for stripes and text
	GetTeamColor(StripeColor, TextColor);
	HeaderStripeColor = StripeColor;

	// ============================================================
	// BACKGROUND PANEL (live HUD feed transparency: 80% opacity black)
	// ============================================================
	C.Style = 4; // ERenderStyle.STY_Alpha
	C.SetDrawColor(0, 0, 0, 204); // Matches TeamDirector/RespawnDelay banner
	C.SetPos(MenuX, MenuY);
	C.DrawTileStretched(material'InterfaceContent.SquareBoxA', MenuW, MenuH);
	C.Style = 1; // ERenderStyle.STY_Normal

	// ============================================================
	// TOP & BOTTOM STRIPES (team-colored)
	// ============================================================
	C.SetDrawColor(HeaderStripeColor.R, HeaderStripeColor.G, HeaderStripeColor.B, HeaderStripeColor.A);
	C.SetPos(MenuX, MenuY);
	C.DrawTileStretched(material'InterfaceContent.SquareBoxA', MenuW, StripeS);
	C.SetPos(MenuX, MenuY + MenuH - StripeS);
	C.DrawTileStretched(material'InterfaceContent.SquareBoxA', MenuW, StripeS);

	// ============================================================
	// LEFT & RIGHT BORDERS (team-colored, full height)
	// ============================================================
	C.SetDrawColor(HeaderStripeColor.R, HeaderStripeColor.G, HeaderStripeColor.B, HeaderStripeColor.A);
	C.SetPos(MenuX, MenuY);
	C.DrawTileStretched(material'InterfaceContent.SquareBoxA', StripeS, MenuH);
	C.SetPos(MenuX + MenuW - StripeS, MenuY);
	C.DrawTileStretched(material'InterfaceContent.SquareBoxA', StripeS, MenuH);

	// ============================================================
	// HEADER AREA with Unreal Tournament "U" Logo + Title
	// ============================================================
	HeaderX = MenuX;
	HeaderY = MenuY;
	HeaderW = MenuW;
	HeaderBottom = HeaderY + HEADER_HEIGHT * Scale;

	// Unreal Tournament "U" Logo (LastManStanding.LMSLogoSmall)
	// Matches TeamDirector/RespawnDelay: 2:1 aspect, height = HEADER_HEIGHT * Scale
	LogoDrawH = HEADER_HEIGHT * Scale * 0.85;
	LogoDrawW = LogoDrawH * 2.0; // 256/128 = 2:1
	LogoDrawX = HeaderX + 24.0 * Scale;
	LogoDrawY = HeaderY + (HEADER_HEIGHT * Scale - LogoDrawH) * 0.5;

	C.Style = 4; // ERenderStyle.STY_Alpha
	C.SetDrawColor(255, 255, 255, 255);
	C.SetPos(LogoDrawX, LogoDrawY);
	C.DrawTile(
		material'LastManStanding.LMSLogoSmall',
		LogoDrawW,
		LogoDrawH,
		0, 0,
		256, 128
	);
	C.Style = 1; // ERenderStyle.STY_Normal

	// Title text (right of logo) - team-colored
	TitleX = LogoDrawX + LogoDrawW + 16.0 * Scale;
	TitleY = HeaderY + (HEADER_HEIGHT * Scale) * 0.5;

	if (TitleFont != None)
		C.Font = TitleFont;
	C.FontScaleX = 0.7 * Scale;
	C.FontScaleY = 0.7 * Scale;

	C.StrLen("LIANDRI EXCHANGE", XL, YL);
	C.SetDrawColor(TextColor.R, TextColor.G, TextColor.B, 255);
	C.SetPos(TitleX, TitleY - YL * 0.5);
	C.DrawText("LIANDRI EXCHANGE");

	C.StrLen("REQUISITION TERMINAL", XL, YL);
	C.SetDrawColor(White.R, White.G, White.B, 200);
	C.SetPos(TitleX, TitleY - YL * 0.5 + YL * 1.1);
	C.DrawText("REQUISITION TERMINAL");

	// Currency display in header (right-aligned) - team-colored
	CurrencyX = HeaderX + HeaderW - 24.0 * Scale;
	CurrencyY = HeaderY + (HEADER_HEIGHT * Scale) * 0.5;

	if (BodyFont != None)
		C.Font = BodyFont;
	C.FontScaleX = 0.6 * Scale;
	C.FontScaleY = 0.6 * Scale;

	Line = "CC: " $ Wallet.CombatCredits $ "   CD: " $ Wallet.CasualtyDividends;
	C.StrLen(Line, XL, YL);
	C.SetDrawColor(TextColor.R, TextColor.G, TextColor.B, 255);
	C.SetPos(CurrencyX - XL, CurrencyY - YL * 0.5);
	C.DrawText(Line);

	// ============================================================
	// CONTENT AREA - Two columns side by side
	// ============================================================
	ColW = (ContentW - SECTION_SPACING * Scale) * 0.5;
	Col1X = ContentX;
	Col2X = ContentX + ColW + SECTION_SPACING * Scale;
	ColY = HeaderBottom + SECTION_SPACING * Scale;

	// Column headers
	if (BodyFont != None)
		C.Font = BodyFont;
	C.FontScaleX = 0.65 * Scale;
	C.FontScaleY = 0.65 * Scale;

	C.StrLen("PERFORMANCE REQUISITIONS", XL, YL);
	C.SetDrawColor(TextColor.R, TextColor.G, TextColor.B, 255);
	C.SetPos(Col1X + (ColW - XL) * 0.5, ColY);
	C.DrawText("PERFORMANCE REQUISITIONS");

	C.StrLen("SPONSOR SUBSIDIES", XL, YL);
	C.SetDrawColor(TextColor.R, TextColor.G, TextColor.B, 255);
	C.SetPos(Col2X + (ColW - XL) * 0.5, ColY);
	C.DrawText("SPONSOR SUBSIDIES");

	// Horizontal divider under column headers (team-colored)
	DividerY = ColY + YL + 8.0 * Scale;
	C.Style = 4; // ERenderStyle.STY_Alpha
	C.SetDrawColor(StripeColor.R, StripeColor.G, StripeColor.B, 180);
	C.SetPos(ContentX, DividerY);
	C.DrawTileStretched(material'InterfaceContent.SquareBoxA', ContentW, 1.0 * Scale);
	C.Style = 1; // ERenderStyle.STY_Normal

	// Vertical divider between columns (team-colored, full content height)
	DividerY += 4.0 * Scale;
	ItemY = DividerY;

	// Footer Y position (for vertical divider end)
	FooterY = MenuY + MenuH - CONTENT_PADDING * Scale - 4.0 * LineH;

	C.Style = 4; // ERenderStyle.STY_Alpha
	C.SetDrawColor(StripeColor.R, StripeColor.G, StripeColor.B, 180);
	// Center between the two columns
	C.SetPos(Col1X + ColW + SECTION_SPACING * Scale * 0.5 - StripeS * 0.5, DividerY);
	C.DrawTileStretched(material'InterfaceContent.SquareBoxA', StripeS, FooterY - DividerY - 8.0 * Scale);
	C.Style = 1; // ERenderStyle.STY_Normal

	// Items start below header divider
	ItemY = DividerY + 12.0 * Scale;

	// Draw 5 items per column
	for (i = 0; i < 5; i++)
	{
		Ctx.Col1X = Col1X;
		Ctx.Col2X = Col2X;
		Ctx.ColW = ColW;
		Ctx.ItemY = ItemY;
		Ctx.Index = i;
		Ctx.TitleColor = TextColor;
		Ctx.AffordableColor = Green;
		Ctx.UnaffordableColor = Red;
		Ctx.VehicleColor = Amber;
		Ctx.WhiteColor = White;
		Ctx.GrayColor = Gray;
		Ctx.BodyFont = BodyFont;
		Ctx.DescFont = DescFont;
		Ctx.Scale = Scale;
		Ctx.LineH = LineH;
		Ctx.StripeColor = StripeColor;

		DrawItemRow(C, Ctx, CCItems[i], CDItems[i]);

		ItemY += LineH * 2.5; // Space for name+cost line + description line + gap
	}

	// ============================================================
	// FOOTER - Controls cheatsheet
	// ============================================================
	FooterY = MenuY + MenuH - CONTENT_PADDING * Scale - 4.0 * LineH;

	// Footer top divider (team-colored)
	C.Style = 4; // ERenderStyle.STY_Alpha
	C.SetDrawColor(StripeColor.R, StripeColor.G, StripeColor.B, 180);
	C.SetPos(ContentX, FooterY - 8.0 * Scale);
	C.DrawTileStretched(material'InterfaceContent.SquareBoxA', ContentW, 1.0 * Scale);
	C.Style = 1; // ERenderStyle.STY_Normal

	if (SmallFont != None)
		C.Font = SmallFont;
	C.FontScaleX = 0.55 * Scale;
	C.FontScaleY = 0.55 * Scale;

	C.StrLen("[F4/ESC] CLOSE   [1-5] BUY CC   [SHIFT+1-5] BUY CD   [R] REROLL CC   [SHIFT+R] REROLL CD   [CTRL+1-5] REROLL SLOT CC   [CTRL+SHIFT+1-5] REROLL SLOT CD", XL, YL);
	C.SetDrawColor(Gray.R, Gray.G, Gray.B, 200);
	C.SetPos(MenuX + (MenuW - XL) * 0.5, FooterY);
	C.DrawText("[F4/ESC] CLOSE   [1-5] BUY CC   [SHIFT+1-5] BUY CD   [R] REROLL CC   [SHIFT+R] REROLL CD   [CTRL+1-5] REROLL SLOT CC   [CTRL+SHIFT+1-5] REROLL SLOT CD");

	// Flavor text for first affordable item (centered below footer)
	bHasFlavor = False;
	for (i = 0; i < 5; i++)
	{
		if (CCItems[i].ItemName != "" && CCItems[i].bAffordable)
		{
			Line = CCItems[i].FlavorText;
			bHasFlavor = True;
			break;
		}
	}
	if (!bHasFlavor)
	{
		for (i = 0; i < 5; i++)
		{
			if (CDItems[i].ItemName != "" && CDItems[i].bAffordable)
			{
				Line = CDItems[i].FlavorText;
				bHasFlavor = True;
				break;
			}
		}
	}

	if (bHasFlavor)
	{
		C.StrLen(Line, XL, YL);
		C.SetDrawColor(Amber.R, Amber.G, Amber.B, 180);
		C.SetPos(MenuX + (MenuW - XL) * 0.5, FooterY + YL + 4.0 * Scale);
		C.DrawText(Line);
	}

	// Reset font scale
	C.FontScaleX = 1.0;
	C.FontScaleY = 1.0;
}

function DrawItemRow(Canvas C, DrawContext Ctx, HUDItem CCItem, HUDItem CDItem)
{
	local float XL, YL;
	local string Line;
	local color ItemColor, CostColor;
	local float DescX;

	// --- Column 1: CC Item ---
	if (CCItem.ItemName != "")
	{
		if (Ctx.BodyFont != None)
			C.Font = Ctx.BodyFont;
		C.FontScaleX = 0.52 * Ctx.Scale;
		C.FontScaleY = 0.52 * Ctx.Scale;

		// Hotkey + Name
		Line = "[" $ (Ctx.Index + 1) $ "] " $ CCItem.ItemName;
		if (CCItem.bAffordable)
			ItemColor = Ctx.AffordableColor;
		else
			ItemColor = Ctx.UnaffordableColor;
		C.SetDrawColor(ItemColor.R, ItemColor.G, ItemColor.B, 255);
		C.SetPos(Ctx.Col1X, Ctx.ItemY);
		C.DrawText(Line);

		// Cost (right-aligned in column)
		Line = CCItem.Cost $ " CC";
		C.StrLen(Line, XL, YL);
		if (CCItem.bAffordable)
			CostColor = Ctx.TitleColor;
		else
			CostColor = Ctx.WhiteColor;
		C.SetDrawColor(CostColor.R, CostColor.G, CostColor.B, 255);
		C.SetPos(Ctx.Col1X + Ctx.ColW - XL, Ctx.ItemY);
		C.DrawText(Line);

		// Vehicle tag
		if (CCItem.bIsVehicle)
		{
			Line = "[DEPLOY]";
			C.StrLen(Line, XL, YL);
			C.SetDrawColor(Ctx.VehicleColor.R, Ctx.VehicleColor.G, Ctx.VehicleColor.B, 255);
			C.SetPos(Ctx.Col1X + Ctx.ColW - XL - 8.0 * Ctx.Scale - XL, Ctx.ItemY);
			C.DrawText(Line);
		}

		// Description (indented, smaller font)
		if (Ctx.DescFont != None)
			C.Font = Ctx.DescFont;
		C.FontScaleX = 0.45 * Ctx.Scale;
		C.FontScaleY = 0.45 * Ctx.Scale;
		DescX = Ctx.Col1X + 16.0 * Ctx.Scale;
		C.SetDrawColor(Ctx.GrayColor.R, Ctx.GrayColor.G, Ctx.GrayColor.B, 180);
		C.SetPos(DescX, Ctx.ItemY + Ctx.LineH);
		C.DrawText(CCItem.FlavorText);
	}
	else
	{
		// Empty slot
		if (Ctx.DescFont != None)
			C.Font = Ctx.DescFont;
		C.FontScaleX = 0.45 * Ctx.Scale;
		C.FontScaleY = 0.45 * Ctx.Scale;
		C.StrLen("[EMPTY SLOT]", XL, YL);
		C.SetDrawColor(Ctx.GrayColor.R, Ctx.GrayColor.G, Ctx.GrayColor.B, 100);
		C.SetPos(Ctx.Col1X + (Ctx.ColW - XL) * 0.5, Ctx.ItemY);
		C.DrawText("[EMPTY SLOT]");
	}

	// --- Column 2: CD Item ---
	if (CDItem.ItemName != "")
	{
		if (Ctx.BodyFont != None)
			C.Font = Ctx.BodyFont;
		C.FontScaleX = 0.52 * Ctx.Scale;
		C.FontScaleY = 0.52 * Ctx.Scale;

		// Hotkey + Name
		Line = "[SHIFT+" $ (Ctx.Index + 1) $ "] " $ CDItem.ItemName;
		if (CDItem.bAffordable)
			ItemColor = Ctx.AffordableColor;
		else
			ItemColor = Ctx.UnaffordableColor;
		C.SetDrawColor(ItemColor.R, ItemColor.G, ItemColor.B, 255);
		C.SetPos(Ctx.Col2X, Ctx.ItemY);
		C.DrawText(Line);

		// Cost (right-aligned in column)
		Line = CDItem.Cost $ " CD";
		C.StrLen(Line, XL, YL);
		if (CDItem.bAffordable)
			CostColor = Ctx.TitleColor;
		else
			CostColor = Ctx.WhiteColor;
		C.SetDrawColor(CostColor.R, CostColor.G, CostColor.B, 255);
		C.SetPos(Ctx.Col2X + Ctx.ColW - XL, Ctx.ItemY);
		C.DrawText(Line);

		// Vehicle/Turret tag
		if (CDItem.bIsVehicle)
		{
			Line = "[DEPLOY]";
			C.StrLen(Line, XL, YL);
			C.SetDrawColor(Ctx.VehicleColor.R, Ctx.VehicleColor.G, Ctx.VehicleColor.B, 255);
			C.SetPos(Ctx.Col2X + Ctx.ColW - XL - 8.0 * Ctx.Scale - XL, Ctx.ItemY);
			C.DrawText(Line);
		}

		// Description (indented, smaller font)
		if (Ctx.DescFont != None)
			C.Font = Ctx.DescFont;
		C.FontScaleX = 0.45 * Ctx.Scale;
		C.FontScaleY = 0.45 * Ctx.Scale;
		DescX = Ctx.Col2X + 16.0 * Ctx.Scale;
		C.SetDrawColor(Ctx.GrayColor.R, Ctx.GrayColor.G, Ctx.GrayColor.B, 180);
		C.SetPos(DescX, Ctx.ItemY + Ctx.LineH);
		C.DrawText(CDItem.FlavorText);
	}
	else
	{
		// Empty slot
		if (Ctx.DescFont != None)
			C.Font = Ctx.DescFont;
		C.FontScaleX = 0.45 * Ctx.Scale;
		C.FontScaleY = 0.45 * Ctx.Scale;
		C.StrLen("[EMPTY SLOT]", XL, YL);
		C.SetDrawColor(Ctx.GrayColor.R, Ctx.GrayColor.G, Ctx.GrayColor.B, 100);
		C.SetPos(Ctx.Col2X + (Ctx.ColW - XL) * 0.5, Ctx.ItemY);
		C.DrawText("[EMPTY SLOT]");
	}

	// Horizontal divider between item rows (team-colored, subtle)
	if (Ctx.Index < 4)
	{
		C.Style = 4; // ERenderStyle.STY_Alpha
		C.SetDrawColor(Ctx.StripeColor.R, Ctx.StripeColor.G, Ctx.StripeColor.B, 60);
		C.SetPos(Ctx.Col1X, Ctx.ItemY + Ctx.LineH * 2.0);
		C.DrawTileStretched(material'InterfaceContent.SquareBoxA', Ctx.ColW * 2.0 + SECTION_SPACING * Ctx.Scale, 0.5 * Ctx.Scale);
		C.Style = 1; // ERenderStyle.STY_Normal
	}
}

defaultproperties
{
	bVisible=True
	bActive=True
}