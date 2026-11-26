/******************************************************************************
 * LiandriHUDMessage -- Invisible LocalMessage to install HUD Menu Interaction
 * Client-side code hook triggered by server via ReceiveLocalizedMessage.
 ******************************************************************************/
class LiandriHUDMessage extends LocalMessage;

/** Nothing is ever drawn: this is a client-side code hook, not a notice. */
static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	return "";
}

static function bool IsConsoleMessage(int Switch)
{
	return False;
}

static function float GetLifeTime(int Switch)
{
	return 0.0;
}

static function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	local LiandriHUDMenu HUDMenu;
	local int i;

	if (P == None || P.bDeleteMe || P.Player == None)
		return;

	if (Switch <= 0)
	{
		// Teardown: remove our interaction
		for (i = P.Player.LocalInteractions.Length - 1; i >= 0; i--)
		{
			HUDMenu = LiandriHUDMenu(P.Player.LocalInteractions[i]);
			if (HUDMenu != None)
			{
				HUDMenu.bVisible = False;
				HUDMenu.bActive = False;
				if (HUDMenu.Master != None)
					HUDMenu.Master.RemoveInteraction(HUDMenu);
				break;
			}
		}
		return;
	}

	// Install: add interaction if not already present
	for (i = 0; i < P.Player.LocalInteractions.Length; i++)
	{
		HUDMenu = LiandriHUDMenu(P.Player.LocalInteractions[i]);
		if (HUDMenu != None)
		{
			HUDMenu.PC = P;
			HUDMenu.bVisible = True;
			HUDMenu.bActive = True;
			return;
		}
	}

	HUDMenu = LiandriHUDMenu(
		P.Player.InteractionMaster.AddInteraction(
			"LiandriExchange.LiandriHUDMenu", P.Player));

	if (HUDMenu != None)
	{
		HUDMenu.PC = P;
		HUDMenu.bVisible = True;
		HUDMenu.bActive = True;
	}
}

defaultproperties
{
	bIsSpecial=False
	bIsUnique=False
	bIsConsoleMessage=False
	bFadeMessage=False
	bBeep=False
	Lifetime=0.0
}