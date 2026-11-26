/******************************************************************************
 * LiandriConfig -- Configuration object (config(LiandriExchange))
 * All tunable values exposed for .ini and Mutator Config GUI.
 ******************************************************************************/
class LiandriConfig extends Object
	config(LiandriExchange);

// Currency & Draft
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

// Item Prices - Division I (CC)
var config int StimOverclockCost;
var config int OvertimeAcceleratorCost;
var config int HostileTakeoverCost;
var config int QuadJumpCost;
var config int VampiricClauseCost;
var config int ReconStrikerCost;
var config int AirSupportCost;
var config int HellbenderCost;
var config int HeavyLitigationCost;
var config int BoardroomClearerCost;

// Item Prices - Division II (CD)
var config int EmergencyResupplyCost;
var config int PersonalTranslocatorCost;
var config int BioHazardCost;
var config int KineticSeveranceCost;
var config int SpiderMineCost;
var config int AdrenalineShotCost;
var config int GhostProtocolCost;
var config int VitalityBailoutCost;
var config int StationarySeveranceCost;
var config int AntiTrustCost;

// Item Enabled Toggles
var config bool bStimOverclockEnabled;
var config bool bOvertimeAcceleratorEnabled;
var config bool bHostileTakeoverEnabled;
var config bool bQuadJumpEnabled;
var config bool bVampiricClauseEnabled;
var config bool bReconStrikerEnabled;
var config bool bAirSupportEnabled;
var config bool bHellbenderEnabled;
var config bool bHeavyLitigationEnabled;
var config bool bBoardroomClearerEnabled;

var config bool bEmergencyResupplyEnabled;
var config bool bPersonalTranslocatorEnabled;
var config bool bBioHazardEnabled;
var config bool bKineticSeveranceEnabled;
var config bool bSpiderMineEnabled;
var config bool bAdrenalineShotEnabled;
var config bool bGhostProtocolEnabled;
var config bool bVitalityBailoutEnabled;
var config bool bStationarySeveranceEnabled;
var config bool bAntiTrustEnabled;

// PlayInfo Group Labels
var localized string CurrencyGroup;
var localized string PricesCCGroup;
var localized string PricesCDGroup;
var localized string TogglesCCGroup;
var localized string TogglesCDGroup;

// Currency & Draft Labels/Descs
var localized string CCPerFragLabel, CCPerFragDesc;
var localized string CDPerDeathLabel, CDPerDeathDesc;
var localized string SuicidePenaltyLabel, SuicidePenaltyDesc;
var localized string RerollCostLabel, RerollCostDesc;
var localized string DraftPoolSizeLabel, DraftPoolSizeDesc;
var localized string EnableVehiclesLabel, EnableVehiclesDesc;
var localized string EnableBotPurchasesLabel, EnableBotPurchasesDesc;
var localized string FullDivisionRerollLabel, FullDivisionRerollDesc;
var localized string SingleSlotRerollLabel, SingleSlotRerollDesc;
var localized string SingleSlotRerollCostLabel, SingleSlotRerollCostDesc;

// Division I Price Labels/Descs
var localized string StimOverclockCostLabel, StimOverclockCostDesc;
var localized string OvertimeAcceleratorCostLabel, OvertimeAcceleratorCostDesc;
var localized string HostileTakeoverCostLabel, HostileTakeoverCostDesc;
var localized string QuadJumpCostLabel, QuadJumpCostDesc;
var localized string VampiricClauseCostLabel, VampiricClauseCostDesc;
var localized string ReconStrikerCostLabel, ReconStrikerCostDesc;
var localized string AirSupportCostLabel, AirSupportCostDesc;
var localized string HellbenderCostLabel, HellbenderCostDesc;
var localized string HeavyLitigationCostLabel, HeavyLitigationCostDesc;
var localized string BoardroomClearerCostLabel, BoardroomClearerCostDesc;

// Division II Price Labels/Descs
var localized string EmergencyResupplyCostLabel, EmergencyResupplyCostDesc;
var localized string PersonalTranslocatorCostLabel, PersonalTranslocatorCostDesc;
var localized string BioHazardCostLabel, BioHazardCostDesc;
var localized string KineticSeveranceCostLabel, KineticSeveranceCostDesc;
var localized string SpiderMineCostLabel, SpiderMineCostDesc;
var localized string AdrenalineShotCostLabel, AdrenalineShotCostDesc;
var localized string GhostProtocolCostLabel, GhostProtocolCostDesc;
var localized string VitalityBailoutCostLabel, VitalityBailoutCostDesc;
var localized string StationarySeveranceCostLabel, StationarySeveranceCostDesc;
var localized string AntiTrustCostLabel, AntiTrustCostDesc;

// Toggle Labels
var localized string StimOverclockEnabledLabel;
var localized string OvertimeAcceleratorEnabledLabel;
var localized string HostileTakeoverEnabledLabel;
var localized string QuadJumpEnabledLabel;
var localized string VampiricClauseEnabledLabel;
var localized string ReconStrikerEnabledLabel;
var localized string AirSupportEnabledLabel;
var localized string HellbenderEnabledLabel;
var localized string HeavyLitigationEnabledLabel;
var localized string BoardroomClearerEnabledLabel;

var localized string EmergencyResupplyEnabledLabel;
var localized string PersonalTranslocatorEnabledLabel;
var localized string BioHazardEnabledLabel;
var localized string KineticSeveranceEnabledLabel;
var localized string SpiderMineEnabledLabel;
var localized string AdrenalineShotEnabledLabel;
var localized string GhostProtocolEnabledLabel;
var localized string VitalityBailoutEnabledLabel;
var localized string StationarySeveranceEnabledLabel;
var localized string AntiTrustEnabledLabel;

// PlayInfo Config GUI
static function FillPlayInfo(PlayInfo PlayInfo)
{
	// Currency & Draft
	PlayInfo.AddSetting(default.CurrencyGroup, "CCPerFrag", default.CCPerFragLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.CurrencyGroup, "CDPerDeath", default.CDPerDeathLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.CurrencyGroup, "SuicidePenalty", default.SuicidePenaltyLabel, 0, 0, "Text", "3;-999:999");
	PlayInfo.AddSetting(default.CurrencyGroup, "RerollCost", default.RerollCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.CurrencyGroup, "DraftPoolSize", default.DraftPoolSizeLabel, 0, 0, "Text", "3;1:5");
	PlayInfo.AddSetting(default.CurrencyGroup, "bEnableVehicles", default.EnableVehiclesLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.CurrencyGroup, "bEnableBotPurchases", default.EnableBotPurchasesLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.CurrencyGroup, "bFullDivisionReroll", default.FullDivisionRerollLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.CurrencyGroup, "bSingleSlotReroll", default.SingleSlotRerollLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.CurrencyGroup, "SingleSlotRerollCost", default.SingleSlotRerollCostLabel, 0, 0, "Text", "3;0:999");

	// Division I Prices (CC)
	PlayInfo.AddSetting(default.PricesCCGroup, "StimOverclockCost", default.StimOverclockCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCCGroup, "OvertimeAcceleratorCost", default.OvertimeAcceleratorCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCCGroup, "HostileTakeoverCost", default.HostileTakeoverCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCCGroup, "QuadJumpCost", default.QuadJumpCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCCGroup, "VampiricClauseCost", default.VampiricClauseCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCCGroup, "ReconStrikerCost", default.ReconStrikerCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCCGroup, "AirSupportCost", default.AirSupportCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCCGroup, "HellbenderCost", default.HellbenderCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCCGroup, "HeavyLitigationCost", default.HeavyLitigationCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCCGroup, "BoardroomClearerCost", default.BoardroomClearerCostLabel, 0, 0, "Text", "3;0:999");

	// Division II Prices (CD)
	PlayInfo.AddSetting(default.PricesCDGroup, "EmergencyResupplyCost", default.EmergencyResupplyCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCDGroup, "PersonalTranslocatorCost", default.PersonalTranslocatorCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCDGroup, "BioHazardCost", default.BioHazardCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCDGroup, "KineticSeveranceCost", default.KineticSeveranceCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCDGroup, "SpiderMineCost", default.SpiderMineCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCDGroup, "AdrenalineShotCost", default.AdrenalineShotCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCDGroup, "GhostProtocolCost", default.GhostProtocolCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCDGroup, "VitalityBailoutCost", default.VitalityBailoutCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCDGroup, "StationarySeveranceCost", default.StationarySeveranceCostLabel, 0, 0, "Text", "3;0:999");
	PlayInfo.AddSetting(default.PricesCDGroup, "AntiTrustCost", default.AntiTrustCostLabel, 0, 0, "Text", "3;0:999");

	// Item Enabled Toggles - Division I
	PlayInfo.AddSetting(default.TogglesCCGroup, "bStimOverclockEnabled", default.StimOverclockEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCCGroup, "bOvertimeAcceleratorEnabled", default.OvertimeAcceleratorEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCCGroup, "bHostileTakeoverEnabled", default.HostileTakeoverEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCCGroup, "bQuadJumpEnabled", default.QuadJumpEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCCGroup, "bVampiricClauseEnabled", default.VampiricClauseEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCCGroup, "bReconStrikerEnabled", default.ReconStrikerEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCCGroup, "bAirSupportEnabled", default.AirSupportEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCCGroup, "bHellbenderEnabled", default.HellbenderEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCCGroup, "bHeavyLitigationEnabled", default.HeavyLitigationEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCCGroup, "bBoardroomClearerEnabled", default.BoardroomClearerEnabledLabel, 1, 0, "Check", "", "", True);

	// Item Enabled Toggles - Division II
	PlayInfo.AddSetting(default.TogglesCDGroup, "bEmergencyResupplyEnabled", default.EmergencyResupplyEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCDGroup, "bPersonalTranslocatorEnabled", default.PersonalTranslocatorEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCDGroup, "bBioHazardEnabled", default.BioHazardEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCDGroup, "bKineticSeveranceEnabled", default.KineticSeveranceEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCDGroup, "bSpiderMineEnabled", default.SpiderMineEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCDGroup, "bAdrenalineShotEnabled", default.AdrenalineShotEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCDGroup, "bGhostProtocolEnabled", default.GhostProtocolEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCDGroup, "bVitalityBailoutEnabled", default.VitalityBailoutEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCDGroup, "bStationarySeveranceEnabled", default.StationarySeveranceEnabledLabel, 1, 0, "Check", "", "", True);
	PlayInfo.AddSetting(default.TogglesCDGroup, "bAntiTrustEnabled", default.AntiTrustEnabledLabel, 1, 0, "Check", "", "", True);
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "CCPerFrag": return default.CCPerFragDesc;
		case "CDPerDeath": return default.CDPerDeathDesc;
		case "SuicidePenalty": return default.SuicidePenaltyDesc;
		case "RerollCost": return default.RerollCostDesc;
		case "DraftPoolSize": return default.DraftPoolSizeDesc;
		case "bEnableVehicles": return default.EnableVehiclesDesc;
		case "bEnableBotPurchases": return default.EnableBotPurchasesDesc;
		case "bFullDivisionReroll": return default.FullDivisionRerollDesc;
		case "bSingleSlotReroll": return default.SingleSlotRerollDesc;
		case "SingleSlotRerollCost": return default.SingleSlotRerollCostDesc;

		case "StimOverclockCost": return default.StimOverclockCostDesc;
		case "OvertimeAcceleratorCost": return default.OvertimeAcceleratorCostDesc;
		case "HostileTakeoverCost": return default.HostileTakeoverCostDesc;
		case "QuadJumpCost": return default.QuadJumpCostDesc;
		case "VampiricClauseCost": return default.VampiricClauseCostDesc;
		case "ReconStrikerCost": return default.ReconStrikerCostDesc;
		case "AirSupportCost": return default.AirSupportCostDesc;
		case "HellbenderCost": return default.HellbenderCostDesc;
		case "HeavyLitigationCost": return default.HeavyLitigationCostDesc;
		case "BoardroomClearerCost": return default.BoardroomClearerCostDesc;

		case "EmergencyResupplyCost": return default.EmergencyResupplyCostDesc;
		case "PersonalTranslocatorCost": return default.PersonalTranslocatorCostDesc;
		case "BioHazardCost": return default.BioHazardCostDesc;
		case "KineticSeveranceCost": return default.KineticSeveranceCostDesc;
		case "SpiderMineCost": return default.SpiderMineCostDesc;
		case "AdrenalineShotCost": return default.AdrenalineShotCostDesc;
		case "GhostProtocolCost": return default.GhostProtocolCostDesc;
		case "VitalityBailoutCost": return default.VitalityBailoutCostDesc;
		case "StationarySeveranceCost": return default.StationarySeveranceCostDesc;
		case "AntiTrustCost": return default.AntiTrustCostDesc;

		case "bStimOverclockEnabled": return "";
		case "bOvertimeAcceleratorEnabled": return "";
		case "bHostileTakeoverEnabled": return "";
		case "bQuadJumpEnabled": return "";
		case "bVampiricClauseEnabled": return "";
		case "bReconStrikerEnabled": return "";
		case "bAirSupportEnabled": return "";
		case "bHellbenderEnabled": return "";
		case "bHeavyLitigationEnabled": return "";
		case "bBoardroomClearerEnabled": return "";

		case "bEmergencyResupplyEnabled": return "";
		case "bPersonalTranslocatorEnabled": return "";
		case "bBioHazardEnabled": return "";
		case "bKineticSeveranceEnabled": return "";
		case "bSpiderMineEnabled": return "";
		case "bAdrenalineShotEnabled": return "";
		case "bGhostProtocolEnabled": return "";
		case "bVitalityBailoutEnabled": return "";
		case "bStationarySeveranceEnabled": return "";
		case "bAntiTrustEnabled": return "";
	}

	return "";
}

defaultproperties
{
	// Currency & Draft
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

	// Division I Prices (CC)
	StimOverclockCost=3
	OvertimeAcceleratorCost=5
	HostileTakeoverCost=5
	QuadJumpCost=5
	VampiricClauseCost=6
	ReconStrikerCost=8
	AirSupportCost=10
	HellbenderCost=11
	HeavyLitigationCost=15
	BoardroomClearerCost=18

	// Division II Prices (CD)
	EmergencyResupplyCost=3
	PersonalTranslocatorCost=2
	BioHazardCost=3
	KineticSeveranceCost=4
	SpiderMineCost=4
	AdrenalineShotCost=5
	GhostProtocolCost=5
	VitalityBailoutCost=8
	StationarySeveranceCost=10
	AntiTrustCost=15

	// All enabled by default
	bStimOverclockEnabled=True
	bOvertimeAcceleratorEnabled=True
	bHostileTakeoverEnabled=True
	bQuadJumpEnabled=True
	bVampiricClauseEnabled=True
	bReconStrikerEnabled=True
	bAirSupportEnabled=True
	bHellbenderEnabled=True
	bHeavyLitigationEnabled=True
	bBoardroomClearerEnabled=True

	bEmergencyResupplyEnabled=True
	bPersonalTranslocatorEnabled=True
	bBioHazardEnabled=True
	bKineticSeveranceEnabled=True
	bSpiderMineEnabled=True
	bAdrenalineShotEnabled=True
	bGhostProtocolEnabled=True
	bVitalityBailoutEnabled=True
	bStationarySeveranceEnabled=True
	bAntiTrustEnabled=True

	// PlayInfo Groups
	CurrencyGroup="CURRENCY & DRAFT PARAMETERS"
	PricesCCGroup="DIVISION I: PERFORMANCE REQUISITION PRICING (CC)"
	PricesCDGroup="DIVISION II: SPONSOR SUBSIDY PRICING (CD)"
	TogglesCCGroup="DIVISION I: REQUISITION AVAILABILITY"
	TogglesCDGroup="DIVISION II: SUBSIDY AVAILABILITY"

	// Currency & Draft Labels/Descs
	CCPerFragLabel="CREDIT ACCRUAL PER FRAG"
	CCPerFragDesc="Combat Credits awarded per confirmed elimination. Default: 1"
	CDPerDeathLabel="DIVIDEND ACCRUAL PER CASUALTY"
	CDPerDeathDesc="Casualty Dividends awarded per non-suicide death. Default: 1"
	SuicidePenaltyLabel="SUICIDE FRAUD PREVENTION"
	SuicidePenaltyDesc="CD penalty for self-termination (fall/world damage counts). 0 = no dividend. Negative = penalty. Default: 0"
	RerollCostLabel="POOL REFRESH EXPENDITURE"
	RerollCostDesc="Cost to reroll entire division pool. Default: 5"
	DraftPoolSizeLabel="ACTIVE REQUISITION SLOTS"
	DraftPoolSizeDesc="Number of active offers per division (1-5). Default: 5"
	EnableVehiclesLabel="VEHICLE REQUISITIONS"
	EnableVehiclesDesc="Allow vehicle spawns (Scorpion, Raptor, Hellbender, Goliath). Default: Enabled"
	EnableBotPurchasesLabel="AUTOMATED AGENT PURCHASING"
	EnableBotPurchasesDesc="Allow AI contestants to utilize requisition system. Default: Enabled"
	FullDivisionRerollLabel="FULL DIVISION REROLL"
	FullDivisionRerollDesc="Enable [R]/[SHIFT+R] to refresh all 5 slots in a division. Default: Enabled"
	SingleSlotRerollLabel="SINGLE SLOT REROLL"
	SingleSlotRerollDesc="Enable [CTRL+1-5]/[CTRL+SHIFT+1-5] to reroll individual slots. Default: Disabled"
	SingleSlotRerollCostLabel="SINGLE SLOT REROLL COST"
	SingleSlotRerollCostDesc="Cost for individual slot reroll. Default: 2"

	// Division I Price Labels/Descs
	StimOverclockCostLabel="STIM-OVERCLOCK PRICE"
	StimOverclockCostDesc="Berserk (20s). Default: 3 CC"
	OvertimeAcceleratorCostLabel="OVERTIME ACCELERATOR PRICE"
	OvertimeAcceleratorCostDesc="2x Speed/Jump (30s). Default: 5 CC"
	HostileTakeoverCostLabel="HOSTILE TAKEOVER PRICE"
	HostileTakeoverCostDesc="UDamage (30s). Default: 5 CC"
	QuadJumpCostLabel="QUAD-JUMP PROTOTYPE PRICE"
	QuadJumpCostDesc="Quad Jump (120s). Default: 5 CC"
	VampiricClauseCostLabel="VAMPIRIC CLAUSE PRICE"
	VampiricClauseCostDesc="50% Life Steal (30s). Default: 6 CC"
	ReconStrikerCostLabel="RECON STRIKER PRICE"
	ReconStrikerCostDesc="Spawn Scorpion. Default: 8 CC"
	AirSupportCostLabel="AIR-SUPPORT PRICE"
	AirSupportCostDesc="Spawn Raptor. Default: 10 CC"
	HellbenderCostLabel="HELLBENDER MERGER PRICE"
	HellbenderCostDesc="Spawn Hellbender. Default: 11 CC"
	HeavyLitigationCostLabel="HEAVY LITIGATION PRICE"
	HeavyLitigationCostDesc="Spawn Goliath. Default: 15 CC"
	BoardroomClearerCostLabel="BOARDROOM CLEARER PRICE"
	BoardroomClearerCostDesc="Redeemer (1 shot). Default: 18 CC"

	// Division II Price Labels/Descs
	EmergencyResupplyCostLabel="EMERGENCY RESUPPLY PRICE"
	EmergencyResupplyCostDesc="Full ammo (non-super). Default: 3 CD"
	PersonalTranslocatorCostLabel="PERSONAL TRANSLOCATOR PRICE"
	PersonalTranslocatorCostDesc="Translocator (lost on death). Default: 2 CD"
	BioHazardCostLabel="BIO-HAZARD DISPOSAL PRICE"
	BioHazardCostDesc="BioRifle + 50 Shield. Default: 3 CD"
	KineticSeveranceCostLabel="KINETIC SEVERANCE PRICE"
	KineticSeveranceCostDesc="+100 Super Shield. Default: 4 CD"
	SpiderMineCostLabel="SPIDER-MINE SURPLUS PRICE"
	SpiderMineCostDesc="Mine Layer (full ammo). Default: 4 CD"
	AdrenalineShotCostLabel="ADRENALINE SHOT PRICE"
	AdrenalineShotCostDesc="Health Regen (ComboDefensive). Default: 5 CD"
	GhostProtocolCostLabel="GHOST PROTOCOL PRICE"
	GhostProtocolCostDesc="Invisibility 25s + Speed. Default: 5 CD"
	VitalityBailoutCostLabel="VITALITY BAILOUT PRICE"
	VitalityBailoutCostDesc="Set Health 300 (overheal). Default: 8 CD"
	StationarySeveranceCostLabel="STATIONARY SEVERANCE PRICE"
	StationarySeveranceCostDesc="Spawn Mounted Turret (random). Default: 10 CD"
	AntiTrustCostLabel="ANTI-TRUST PACKAGE PRICE"
	AntiTrustCostDesc="AVRiL (full ammo). Default: 15 CD"

	// Toggle Labels
	StimOverclockEnabledLabel="STIM-OVERCLOCK AVAILABLE"
	OvertimeAcceleratorEnabledLabel="OVERTIME ACCELERATOR AVAILABLE"
	HostileTakeoverEnabledLabel="HOSTILE TAKEOVER AVAILABLE"
	QuadJumpEnabledLabel="QUAD-JUMP PROTOTYPE AVAILABLE"
	VampiricClauseEnabledLabel="VAMPIRIC CLAUSE AVAILABLE"
	ReconStrikerEnabledLabel="RECON STRIKER AVAILABLE"
	AirSupportEnabledLabel="AIR-SUPPORT AVAILABLE"
	HellbenderEnabledLabel="HELLBENDER MERGER AVAILABLE"
	HeavyLitigationEnabledLabel="HEAVY LITIGATION AVAILABLE"
	BoardroomClearerEnabledLabel="BOARDROOM CLEARER AVAILABLE"

	EmergencyResupplyEnabledLabel="EMERGENCY RESUPPLY AVAILABLE"
	PersonalTranslocatorEnabledLabel="PERSONAL TRANSLOCATOR AVAILABLE"
	BioHazardEnabledLabel="BIO-HAZARD DISPOSAL AVAILABLE"
	KineticSeveranceEnabledLabel="KINETIC SEVERANCE AVAILABLE"
	SpiderMineEnabledLabel="SPIDER-MINE SURPLUS AVAILABLE"
	AdrenalineShotEnabledLabel="ADRENALINE SHOT AVAILABLE"
	GhostProtocolEnabledLabel="GHOST PROTOCOL AVAILABLE"
	VitalityBailoutEnabledLabel="VITALITY BAILOUT AVAILABLE"
	StationarySeveranceEnabledLabel="STATIONARY SEVERANCE AVAILABLE"
	AntiTrustEnabledLabel="ANTI-TRUST PACKAGE AVAILABLE"
}