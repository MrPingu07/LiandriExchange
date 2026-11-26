/******************************************************************************
 * LiandriBuyMenu -- Native GUI purchase window (extends UT2K4GenericMessageBox)
 * Resolution-independent, uses XInterface components (buttons, labels).
 * Opened via PlayerController.ClientOpenMenu("LiandriExchange.LiandriBuyMenu").
 ******************************************************************************/
class LiandriBuyMenu extends UT2K4GenericMessageBox;

var array<GUIButton> CCButtons;
var array<GUIButton> CDButtons;
var array<int> CCItemIDs;
var array<int> CDItemIDs;
var array<GUILabel> CCLabels;
var array<GUILabel> CDLabels;
var GUILabel lblCC;
var GUILabel lblCD;
var GUILabel lblDivision1;
var GUILabel lblDivision2;
var GUILabel lblMessage;
var GUIButton btnRerollCC;
var GUIButton btnRerollCD;

var int LastCC;
var int LastCD;
var int LastCCSerial;
var int LastCDSerial;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int i;
    local GUIButton B;
    local GUILabel StateLbl;

    Super.InitComponent(MyController, MyOwner);

    // Remove default message text
    RemoveComponent(l_Text2);

    // Title (without "Liandri Exchange -- ")
    l_Text.Caption = "REQUISITION TERMINAL";
    l_Text.bBoundToParent = True;
    l_Text.bScaleToParent = True;
    l_Text.WinLeft = 0.05;
    l_Text.WinWidth = 0.90;
    l_Text.WinTop = 0.03;
    l_Text.WinHeight = 0.05;
    l_Text.TextAlign = TXTA_Center;

    // CC/CD currency display
    lblCC = GUILabel(AddComponent("XInterface.GUILabel"));
    if (lblCC != None)
    {
        lblCC.bBoundToParent = True;
        lblCC.bScaleToParent = True;
        lblCC.WinLeft = 0.06;
        lblCC.WinWidth = 0.44;
        lblCC.WinTop = 0.09;
        lblCC.WinHeight = 0.035;
        lblCC.TextAlign = TXTA_Left;
        lblCC.StyleName = "TextLabel";
        lblCC.TextColor.R = 255; lblCC.TextColor.G = 215; lblCC.TextColor.B = 0; lblCC.TextColor.A = 255;
        lblCC.Caption = "Combat Credits: 0";
    }

    lblCD = GUILabel(AddComponent("XInterface.GUILabel"));
    if (lblCD != None)
    {
        lblCD.bBoundToParent = True;
        lblCD.bScaleToParent = True;
        lblCD.WinLeft = 0.50;
        lblCD.WinWidth = 0.44;
        lblCD.WinTop = 0.09;
        lblCD.WinHeight = 0.035;
        lblCD.TextAlign = TXTA_Right;
        lblCD.StyleName = "TextLabel";
        lblCD.TextColor.R = 100; lblCD.TextColor.G = 180; lblCD.TextColor.B = 255; lblCD.TextColor.A = 255;
        lblCD.Caption = "Casualty Dividends: 0";
    }

    // Division headers (without "Division I: " and "Division II: ")
    lblDivision1 = GUILabel(AddComponent("XInterface.GUILabel"));
    if (lblDivision1 != None)
    {
        lblDivision1.bBoundToParent = True;
        lblDivision1.bScaleToParent = True;
        lblDivision1.WinLeft = 0.06;
        lblDivision1.WinWidth = 0.44;
        lblDivision1.WinTop = 0.14;
        lblDivision1.WinHeight = 0.03;
        lblDivision1.TextAlign = TXTA_Left;
        lblDivision1.StyleName = "TextLabel";
        lblDivision1.TextColor.R = 255; lblDivision1.TextColor.G = 215; lblDivision1.TextColor.B = 0; lblDivision1.TextColor.A = 255;
        lblDivision1.Caption = "PERFORMANCE REQUISITIONS (CC)";
    }

    lblDivision2 = GUILabel(AddComponent("XInterface.GUILabel"));
    if (lblDivision2 != None)
    {
        lblDivision2.bBoundToParent = True;
        lblDivision2.bScaleToParent = True;
        lblDivision2.WinLeft = 0.50;
        lblDivision2.WinWidth = 0.44;
        lblDivision2.WinTop = 0.14;
        lblDivision2.WinHeight = 0.03;
        lblDivision2.TextAlign = TXTA_Left;
        lblDivision2.StyleName = "TextLabel";
        lblDivision2.TextColor.R = 100; lblDivision2.TextColor.G = 180; lblDivision2.TextColor.B = 255; lblDivision2.TextColor.A = 255;
        lblDivision2.Caption = "SPONSOR SUBSIDIES (CD)";
    }

    // Status message label
    lblMessage = GUILabel(AddComponent("XInterface.GUILabel"));
    if (lblMessage != None)
    {
        lblMessage.bBoundToParent = True;
        lblMessage.bScaleToParent = True;
        lblMessage.WinLeft = 0.06;
        lblMessage.WinWidth = 0.88;
        lblMessage.WinTop = 0.84;
        lblMessage.WinHeight = 0.045;
        lblMessage.TextAlign = TXTA_Center;
        lblMessage.VertAlign = TXTA_Center;
        lblMessage.bMultiLine = True;
        lblMessage.StyleName = "TextLabel";
        lblMessage.TextColor.R = 255; lblMessage.TextColor.G = 48; lblMessage.TextColor.B = 48; lblMessage.TextColor.A = 255;
        lblMessage.Caption = "";
    }

    // Close button
    b_OK.Caption = "CLOSE";
    b_OK.bBoundToParent = True;
    b_OK.bScaleToParent = True;
    b_OK.WinLeft = 0.42;
    b_OK.WinWidth = 0.16;
    b_OK.WinTop = 0.94;
    b_OK.WinHeight = 0.045;

    // Reroll CC button (under left column)
    btnRerollCC = GUIButton(AddComponent("XInterface.GUIButton"));
    if (btnRerollCC != None)
    {
        btnRerollCC.bBoundToParent = True;
        btnRerollCC.bScaleToParent = True;
        btnRerollCC.WinLeft = 0.06;
        btnRerollCC.WinWidth = 0.42;
        btnRerollCC.WinTop = 0.84;
        btnRerollCC.WinHeight = 0.045;
        btnRerollCC.Caption = "REROLL REQUISITIONS (5 CC)";
        btnRerollCC.Hint = "Reroll all Division I items for 5 CC";
        btnRerollCC.OnClick = RerollCCClicked;
    }

    // Reroll CD button (under right column)
    btnRerollCD = GUIButton(AddComponent("XInterface.GUIButton"));
    if (btnRerollCD != None)
    {
        btnRerollCD.bBoundToParent = True;
        btnRerollCD.bScaleToParent = True;
        btnRerollCD.WinLeft = 0.52;
        btnRerollCD.WinWidth = 0.42;
        btnRerollCD.WinTop = 0.84;
        btnRerollCD.WinHeight = 0.045;
        btnRerollCD.Caption = "REROLL SUBSIDIES (5 CD)";
        btnRerollCD.Hint = "Reroll all Division II items for 5 CD";
        btnRerollCD.OnClick = RerollCDClicked;
    }

    // Initialize button arrays
    CCButtons.Length = 0;
    CDButtons.Length = 0;
    CCItemIDs.Length = 0;
    CDItemIDs.Length = 0;
    CCLabels.Length = 0;
    CDLabels.Length = 0;

    // Create 5 CC buttons (left column)
    for (i = 0; i < 5; i++)
    {
        B = GUIButton(AddComponent("XInterface.GUIButton"));
        if (B == None)
            continue;

        B.bBoundToParent = True;
        B.bScaleToParent = True;
        B.WinLeft = 0.06;
        B.WinWidth = 0.42;
        B.WinTop = 0.19 + i * 0.13;
        B.WinHeight = 0.055;
        B.Caption = "[EMPTY SLOT]";
        B.Hint = "";
        B.TabOrder = i;
        B.OnClick = CCItemClicked;

        StateLbl = GUILabel(AddComponent("XInterface.GUILabel"));
        if (StateLbl != None)
        {
            StateLbl.bBoundToParent = True;
            StateLbl.bScaleToParent = True;
            StateLbl.WinLeft = 0.06;
            StateLbl.WinWidth = 0.42;
            StateLbl.WinTop = B.WinTop + 0.055;
            StateLbl.WinHeight = 0.025;
            StateLbl.TextAlign = TXTA_Center;
            StateLbl.StyleName = "TextLabel";
            StateLbl.TextColor.R = 255; StateLbl.TextColor.G = 48; StateLbl.TextColor.B = 48; StateLbl.TextColor.A = 255;
            StateLbl.Caption = "";
            StateLbl.SetVisibility(False);
        }

        CCButtons[CCButtons.Length] = B;
        CCLabels[CCLabels.Length] = StateLbl;
        CCItemIDs[CCItemIDs.Length] = -1;
    }

    // Create 5 CD buttons (right column)
    for (i = 0; i < 5; i++)
    {
        B = GUIButton(AddComponent("XInterface.GUIButton"));
        if (B == None)
            continue;

        B.bBoundToParent = True;
        B.bScaleToParent = True;
        B.WinLeft = 0.52;
        B.WinWidth = 0.42;
        B.WinTop = 0.19 + i * 0.13;
        B.WinHeight = 0.055;
        B.Caption = "[EMPTY SLOT]";
        B.Hint = "";
        B.TabOrder = i + 10;
        B.OnClick = CDItemClicked;

        StateLbl = GUILabel(AddComponent("XInterface.GUILabel"));
        if (StateLbl != None)
        {
            StateLbl.bBoundToParent = True;
            StateLbl.bScaleToParent = True;
            StateLbl.WinLeft = 0.52;
            StateLbl.WinWidth = 0.42;
            StateLbl.WinTop = B.WinTop + 0.055;
            StateLbl.WinHeight = 0.025;
            StateLbl.TextAlign = TXTA_Center;
            StateLbl.StyleName = "TextLabel";
            StateLbl.TextColor.R = 255; StateLbl.TextColor.G = 48; StateLbl.TextColor.B = 48; StateLbl.TextColor.A = 255;
            StateLbl.Caption = "";
            StateLbl.SetVisibility(False);
        }

        CDButtons[CDButtons.Length] = B;
        CDLabels[CDLabels.Length] = StateLbl;
        CDItemIDs[CDItemIDs.Length] = -1;
    }

    LastCC = -1;
    LastCD = -1;
    LastCCSerial = -1;
    LastCDSerial = -1;
    RefreshCurrency();
}

function RefreshCurrency()
{
    local LiandriWallet Wallet;
    local int CC, CD;

    Wallet = GetWallet();
    if (Wallet == None)
        return;

    CC = Wallet.CombatCredits;
    CD = Wallet.CasualtyDividends;

    if (lblCC != None)
        lblCC.Caption = "Combat Credits: " $ CC;
    if (lblCD != None)
        lblCD.Caption = "Casualty Dividends: " $ CD;

    // Update reroll button captions with current config costs
    UpdateRerollButtonCaptions();

    RefreshButtons(Wallet);
    LastCC = CC;
    LastCD = CD;
}

function UpdateRerollButtonCaptions()
{
    local LiandriConfig Cfg;

    Cfg = new(None) class'LiandriExchange.LiandriConfig';
    if (Cfg == None)
        return;

    if (btnRerollCC != None)
        btnRerollCC.Caption = "REROLL REQUISITIONS (" $ Cfg.RerollCCCost $ " CC)";
    if (btnRerollCD != None)
        btnRerollCD.Caption = "REROLL SUBSIDIES (" $ Cfg.RerollCDCost $ " CD)";
}

function RefreshButtons(LiandriWallet Wallet)
{
    local int i, Idx, Cost;
    local bool bAffordable, bEnabled;
    local LiandriConfig Cfg;

    if (Wallet == None)
        return;

    Cfg = new(None) class'LiandriExchange.LiandriConfig';

    // CC buttons (no "[1]" prefix)
    for (i = 0; i < CCButtons.Length; i++)
    {
        if (CCButtons[i] == None)
            continue;

        Idx = Wallet.ActiveCCSlots[i];
        if (Idx != -1)
        {
            CCItemIDs[i] = Idx;
            Cost = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemCost(Idx, Cfg);
            bEnabled = class'LiandriExchange.LiandriItemExecutor'.static.IsCCItemEnabled(Idx, Cfg);
            bAffordable = (Wallet.CombatCredits >= Cost) && bEnabled;

            CCButtons[i].Caption = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemName(Idx, Cfg) $ "   " $ Cost $ " CC";
            CCButtons[i].Hint = class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemFlavorText(Idx, Cfg);

            if (!bEnabled)
            {
                CCButtons[i].MenuState = MSAT_Disabled;
                CCButtons[i].bAcceptsInput = False;
                CCButtons[i].Hint = "Disabled by server.";
            }
            else if (!bAffordable)
            {
                CCButtons[i].MenuState = MSAT_Disabled;
                CCButtons[i].bAcceptsInput = False;
                CCButtons[i].Hint = "Insufficient Credits: " $ CCButtons[i].Hint;
            }
            else
            {
                CCButtons[i].MenuState = MSAT_Blurry;
                CCButtons[i].bAcceptsInput = True;
            }

            if (CCLabels[i] != None)
            {
                if (!bEnabled)
                    CCLabels[i].Caption = "DISABLED";
                else if (!bAffordable)
                    CCLabels[i].Caption = "NEED " $ (Cost - Wallet.CombatCredits) $ " MORE CC";
                else
                    CCLabels[i].Caption = "";
                CCLabels[i].SetVisibility(!bEnabled || !bAffordable);
            }
        }
        else
        {
            CCItemIDs[i] = -1;
            CCButtons[i].Caption = "[EMPTY SLOT]";
            CCButtons[i].Hint = "";
            CCButtons[i].MenuState = MSAT_Disabled;
            CCButtons[i].bAcceptsInput = False;
            if (CCLabels[i] != None)
            {
                CCLabels[i].Caption = "";
                CCLabels[i].SetVisibility(False);
            }
        }
    }

    // CD buttons (no "[SHIFT+1]" prefix)
    for (i = 0; i < CDButtons.Length; i++)
    {
        if (CDButtons[i] == None)
            continue;

        Idx = Wallet.ActiveCDSlots[i];
        if (Idx != -1)
        {
            CDItemIDs[i] = Idx;
            Cost = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemCost(Idx, Cfg);
            bEnabled = class'LiandriExchange.LiandriItemExecutor'.static.IsCDItemEnabled(Idx, Cfg);
            bAffordable = (Wallet.CasualtyDividends >= Cost) && bEnabled;

            CDButtons[i].Caption = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemName(Idx, Cfg) $ "   " $ Cost $ " CD";
            CDButtons[i].Hint = class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemFlavorText(Idx, Cfg);

            if (!bEnabled)
            {
                CDButtons[i].MenuState = MSAT_Disabled;
                CDButtons[i].bAcceptsInput = False;
                CDButtons[i].Hint = "Disabled by server.";
            }
            else if (!bAffordable)
            {
                CDButtons[i].MenuState = MSAT_Disabled;
                CDButtons[i].bAcceptsInput = False;
                CDButtons[i].Hint = "Insufficient Dividends: " $ CDButtons[i].Hint;
            }
            else
            {
                CDButtons[i].MenuState = MSAT_Blurry;
                CDButtons[i].bAcceptsInput = True;
            }

            if (CDLabels[i] != None)
            {
                if (!bEnabled)
                    CDLabels[i].Caption = "DISABLED";
                else if (!bAffordable)
                    CDLabels[i].Caption = "NEED " $ (Cost - Wallet.CasualtyDividends) $ " MORE CD";
                else
                    CDLabels[i].Caption = "";
                CDLabels[i].SetVisibility(!bEnabled || !bAffordable);
            }
        }
        else
        {
            CDItemIDs[i] = -1;
            CDButtons[i].Caption = "[EMPTY SLOT]";
            CDButtons[i].Hint = "";
            CDButtons[i].MenuState = MSAT_Disabled;
            CDButtons[i].bAcceptsInput = False;
            if (CDLabels[i] != None)
            {
                CDLabels[i].Caption = "";
                CDLabels[i].SetVisibility(False);
            }
        }
    }
}

function bool CCItemClicked(GUIComponent Sender)
{
    local int i;
    local PlayerController PC;

    for (i = 0; i < CCButtons.Length; i++)
    {
        if (Sender != CCButtons[i])
            continue;

        if (CCItemIDs[i] == -1)
            return True;

        PC = PlayerOwner();
        if (PC != None)
            PC.ConsoleCommand("mutate LiandriBuyCC" $ i);

        RefreshCurrency();
        return True;
    }
    return False;
}

function bool CDItemClicked(GUIComponent Sender)
{
    local int i;
    local PlayerController PC;

    for (i = 0; i < CDButtons.Length; i++)
    {
        if (Sender != CDButtons[i])
            continue;

        if (CDItemIDs[i] == -1)
            return True;

        PC = PlayerOwner();
        if (PC != None)
            PC.ConsoleCommand("mutate LiandriBuyCD" $ i);

        RefreshCurrency();
        return True;
    }
    return False;
}

function bool RerollCCClicked(GUIComponent Sender)
{
    local PlayerController PC;

    PC = PlayerOwner();
    if (PC != None)
        PC.ConsoleCommand("mutate LiandriRerollCC");

    RefreshCurrency();
    return True;
}

function bool RerollCDClicked(GUIComponent Sender)
{
    local PlayerController PC;

    PC = PlayerOwner();
    if (PC != None)
        PC.ConsoleCommand("mutate LiandriRerollCD");

    RefreshCurrency();
    return True;
}

function LiandriWallet GetWallet()
{
    local PlayerController PC;
    local LinkedReplicationInfo L;

    PC = PlayerOwner();
    if (PC == None || PC.PlayerReplicationInfo == None)
        return None;

    L = PC.PlayerReplicationInfo.CustomReplicationInfo;
    while (L != None)
    {
        if (LiandriWallet(L) != None)
            return LiandriWallet(L);
        L = L.NextReplicationInfo;
    }
    return None;
}

function bool InternalOnPreDraw(Canvas C)
{
    local bool b;

    b = Super.InternalOnPreDraw(C);
    RefreshCurrency();
    return b;
}

defaultproperties
{
    bAllowedAsLast=True
    OpenSound=Sound'MenuSounds.selectDshort'
    WinTop=0.100000
    WinLeft=0.150000
    WinWidth=0.700000
    WinHeight=0.800000
}