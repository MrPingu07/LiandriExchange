/******************************************************************************
 * LiandriBotAI -- Bot purchasing AI logic
 * Handles automated bot purchases.
 ******************************************************************************/
class LiandriBotAI extends Object;

static function BotPurchaseTick(LiandriWallet Wallet)
{
	local Bot B;
	local int i, AffordableCC, AffordableCD;
	local LiandriConfig ConfigObj;

	ConfigObj = Wallet.ConfigObj;
	if (ConfigObj == None || !ConfigObj.bEnableBotPurchases)
		return;

	B = Bot(Wallet.Owner);
	if (B == None || B.Pawn == None)
		return;

	// Simple: randomly try to buy something affordable
	AffordableCC = -1;
	AffordableCD = -1;

	for (i = 0; i < 5; i++)
	{
		if (Wallet.ActiveCCSlots[i] != -1 && Wallet.CombatCredits >= class'LiandriExchange.LiandriItemExecutor'.static.GetCCItemCost(Wallet.ActiveCCSlots[i], Wallet.ConfigObj))
		{
			if (AffordableCC == -1 || FRand() < 0.5)
				AffordableCC = i;
		}
		if (Wallet.ActiveCDSlots[i] != -1 && Wallet.CasualtyDividends >= class'LiandriExchange.LiandriItemExecutor'.static.GetCDItemCost(Wallet.ActiveCDSlots[i], Wallet.ConfigObj))
		{
			if (AffordableCD == -1 || FRand() < 0.5)
				AffordableCD = i;
		}
	}

	if (AffordableCC != -1 && FRand() < 0.3)
		Wallet.ServerPurchaseCC(AffordableCC);
	else if (AffordableCD != -1 && FRand() < 0.3)
		Wallet.ServerPurchaseCD(AffordableCD);
}

defaultproperties
{
}