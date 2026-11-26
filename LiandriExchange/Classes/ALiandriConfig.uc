/******************************************************************************
 * ALiandriConfig — Configuration object (config(LiandriExchange))
 * All tunable values exposed for .ini and Mutator Config GUI.
 * Prefixed with 'A' to ensure early parse order.
 ******************************************************************************/

class ALiandriConfig extends Object
	config(LiandriExchange)
	perObjectConfig;




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
}