/******************************************************************************
 * LiandriConfigGUI -- "Configure Mutators" submenu for LiandriExchange
 * GUIPage + moEditBox pattern (same as TeamDirector/Kakutou2k4-Enhanced)
 ******************************************************************************/
class LiandriConfigGUI extends GUIPage;

var moEditBox BoxCCPerFrag;
var moEditBox BoxCDPerDeath;
var moEditBox BoxSuicidePenalty;
var moEditBox BoxRerollCost;
var moEditBox BoxDraftPoolSize;
var moEditBox BoxSingleSlotRerollCost;
var moEditBox BoxRerollCCCost;
var moEditBox BoxRerollCDCost;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController, MyOwner);

    BoxCCPerFrag = moEditBox(Controls[4]);
    BoxCDPerDeath = moEditBox(Controls[5]);
    BoxSuicidePenalty = moEditBox(Controls[6]);
    BoxRerollCost = moEditBox(Controls[7]);
    BoxDraftPoolSize = moEditBox(Controls[8]);
    BoxSingleSlotRerollCost = moEditBox(Controls[9]);
    BoxRerollCCCost = moEditBox(Controls[10]);
    BoxRerollCDCost = moEditBox(Controls[11]);

    BoxCCPerFrag.SetText(string(class'LiandriExchangeMutator'.default.CCPerFrag));
    BoxCDPerDeath.SetText(string(class'LiandriExchangeMutator'.default.CDPerDeath));
    BoxSuicidePenalty.SetText(string(class'LiandriExchangeMutator'.default.SuicidePenalty));
    BoxRerollCost.SetText(string(class'LiandriExchangeMutator'.default.RerollCost));
    BoxDraftPoolSize.SetText(string(class'LiandriExchangeMutator'.default.DraftPoolSize));
    BoxSingleSlotRerollCost.SetText(string(class'LiandriExchangeMutator'.default.SingleSlotRerollCost));
    BoxRerollCCCost.SetText(string(class'LiandriExchangeMutator'.default.RerollCCCost));
    BoxRerollCDCost.SetText(string(class'LiandriExchangeMutator'.default.RerollCDCost));
}

function bool InternalOnClick(GUIComponent Sender)
{
    class'LiandriExchangeMutator'.default.CCPerFrag = ClampInt(BoxCCPerFrag, 0, 10);
    class'LiandriExchangeMutator'.default.CDPerDeath = ClampInt(BoxCDPerDeath, 0, 10);
    class'LiandriExchangeMutator'.default.SuicidePenalty = ClampInt(BoxSuicidePenalty, -10, 10);
    class'LiandriExchangeMutator'.default.RerollCost = ClampInt(BoxRerollCost, 1, 50);
    class'LiandriExchangeMutator'.default.DraftPoolSize = ClampInt(BoxDraftPoolSize, 1, 10);
    class'LiandriExchangeMutator'.default.SingleSlotRerollCost = ClampInt(BoxSingleSlotRerollCost, 1, 50);
    class'LiandriExchangeMutator'.default.RerollCCCost = ClampInt(BoxRerollCCCost, 1, 100);
    class'LiandriExchangeMutator'.default.RerollCDCost = ClampInt(BoxRerollCDCost, 1, 100);

    class'LiandriExchangeMutator'.static.StaticSaveConfig();

    Controller.CloseMenu(False);
    return True;
}

function int ClampInt(moEditBox Box, int Min, int Max)
{
    local int V;

    if (Box == None)
        return Min;

    V = int(Box.GetText());
    if (V < Min)
        V = Min;
    if (V > Max)
        V = Max;

    Box.SetText(string(V));
    return V;
}

function bool ResetToDefaults(GUIComponent Sender)
{
    BoxCCPerFrag.SetText("1");
    BoxCDPerDeath.SetText("1");
    BoxSuicidePenalty.SetText("0");
    BoxRerollCost.SetText("5");
    BoxDraftPoolSize.SetText("5");
    BoxSingleSlotRerollCost.SetText("2");
    BoxRerollCCCost.SetText("5");
    BoxRerollCDCost.SetText("5");
    return True;
}

defaultproperties
{
    Begin Object Class=GUIButton Name=DialogBackground
        WinWidth=1.0
        WinHeight=1.0
        WinTop=0
        WinLeft=0
        bAcceptsInput=false
        bNeverFocus=true
        StyleName="ComboListBox"
        bBoundToParent=true
        bScaleToParent=true
    End Object
    Controls(0)=GUIButton'DialogBackground'

    Begin Object Class=GUIButton Name=OkButton
        Caption="OK"
        WinWidth=0.2
        WinHeight=0.04
        WinLeft=0.6
        WinTop=0.9
        OnClick=InternalOnClick
        bBoundToParent=true
    End Object
    Controls(1)=GUIButton'OkButton'

    Begin Object Class=GUILabel Name=DialogText
        Caption="Liandri Exchange Configuration"
        TextAlign=TXTA_Center
        TextColor=(R=255,G=215,B=0,A=255)
        TextFont="UT2HeaderFont"
        WinWidth=1.000000
        WinHeight=20.000000
        WinLeft=0.000000
        WinTop=0.1
        bBoundToParent=true
    End Object
    Controls(2)=GUILabel'DialogText'

    Begin Object Class=GUILabel Name=DialogText2
        Caption="Currency & Draft Settings - applies next match"
        TextAlign=TXTA_Center
        TextColor=(R=255,G=215,B=0,A=255)
        TextFont="UT2MenuFont"
        WinWidth=1.000000
        WinHeight=20.000000
        WinLeft=0.000000
        WinTop=0.18
        bBoundToParent=true
    End Object
    Controls(3)=GUILabel'DialogText2'

    Begin Object Class=moEditBox Name=EditBoxCCPerFrag
        WinWidth=0.4
        WinHeight=0.04
        WinLeft=0.05
        WinTop=0.28
        Caption="Combat Credits per Frag (0-10)"
        bReadOnly=false
        bBoundToParent=true
    End Object
    Controls(4)=moEditBox'EditBoxCCPerFrag'

    Begin Object Class=moEditBox Name=EditBoxCDPerDeath
        WinWidth=0.4
        WinHeight=0.04
        WinLeft=0.55
        WinTop=0.28
        Caption="Casualty Dividends per Death (0-10)"
        bReadOnly=false
        bBoundToParent=true
    End Object
    Controls(5)=moEditBox'EditBoxCDPerDeath'

    Begin Object Class=moEditBox Name=EditBoxSuicidePenalty
        WinWidth=0.4
        WinHeight=0.04
        WinLeft=0.05
        WinTop=0.38
        Caption="Suicide Penalty (-10 to 10, 0=none)"
        bReadOnly=false
        bBoundToParent=true
    End Object
    Controls(6)=moEditBox'EditBoxSuicidePenalty'

    Begin Object Class=moEditBox Name=EditBoxRerollCost
        WinWidth=0.4
        WinHeight=0.04
        WinLeft=0.55
        WinTop=0.38
        Caption="Full Division Reroll Cost (1-50)"
        bReadOnly=false
        bBoundToParent=true
    End Object
    Controls(7)=moEditBox'EditBoxRerollCost'

    Begin Object Class=moEditBox Name=EditBoxDraftPoolSize
        WinWidth=0.4
        WinHeight=0.04
        WinLeft=0.05
        WinTop=0.48
        Caption="Draft Pool Size (1-10)"
        bReadOnly=false
        bBoundToParent=true
    End Object
    Controls(8)=moEditBox'EditBoxDraftPoolSize'

    Begin Object Class=moEditBox Name=EditBoxSingleSlotRerollCost
        WinWidth=0.4
        WinHeight=0.04
        WinLeft=0.55
        WinTop=0.48
        Caption="Single Slot Reroll Cost (1-50)"
        bReadOnly=false
        bBoundToParent=true
    End Object
    Controls(9)=moEditBox'EditBoxSingleSlotRerollCost'

    Begin Object Class=moEditBox Name=EditBoxRerollCCCost
        WinWidth=0.4
        WinHeight=0.04
        WinLeft=0.05
        WinTop=0.58
        Caption="Reroll Division I (Requisitions) Cost CC (1-100)"
        bReadOnly=false
        bBoundToParent=true
    End Object
    Controls(10)=moEditBox'EditBoxRerollCCCost'

    Begin Object Class=moEditBox Name=EditBoxRerollCDCost
        WinWidth=0.4
        WinHeight=0.04
        WinLeft=0.55
        WinTop=0.58
        Caption="Reroll Division II (Subsidies) Cost CD (1-100)"
        bReadOnly=false
        bBoundToParent=true
    End Object
    Controls(11)=moEditBox'EditBoxRerollCDCost'

    Begin Object Class=GUIButton Name=ResetButton
        Caption="Reset to Defaults"
        WinWidth=0.2
        WinHeight=0.04
        WinLeft=0.2
        WinTop=0.9
        OnClick=ResetToDefaults
        bBoundToParent=true
    End Object
    Controls(12)=GUIButton'ResetButton'

    WinLeft=0
    WinTop=0.2
    WinWidth=1
    WinHeight=0.6
    bRequire640x480=True
}