/******************************************************************************
 * ALiandriStructs — Shared struct definitions for Liandri Exchange
 * Separate file with 'A' prefix to ensure first parse order for cross-file visibility.
 ******************************************************************************/

struct LiandriItemData
{
	var string Name;
	var int Cost;
	var byte Division;        // 0 = CC, 1 = CD
	var int MasterIndex;      // 0-9 within division
	var string FlavorText;
	var bool bIsVehicle;
	var name VehicleClassName;    // Class name as string
	var name EffectClassName;     // Class name as string
	var name ExecFunction;        // Function name to execute on purchase
};