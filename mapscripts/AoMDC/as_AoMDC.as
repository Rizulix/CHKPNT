// Afraid of Monsters: Director's Cut Script
// Main Script
// Author: Zorbos

// Weapons are NOT allowed to be given on these maps
const array<string> AOMDC_LIST_NOWEAPON = {"aomdc_1tutorial", "aomdc_2tutorial", "aomdc_3tutorial",
										   "aomdc_1nightmare", "aomdc_2nightmare", "aomdc_3nightmare",
										   "aomdc_1intro", "aomdc_2intro", "aomdc_3intro",
										   "aomdc_1end", "aomdc_2end", "aomdc_3end", "aomdc_4end", "aomdc_4mother"};
										   		
// Ending 1 Maplist
// Array indices are used as a means of deciding which maps are farther than others.
// Used for giving out weapons and ammo to the player.
const array<string> AOMDC_LIST_E1 = {"aomdc_1hospital", "aomdc_1hospital2", "aomdc_1garage", "aomdc_1backalley", "aomdc_1darkalley",
									 "aomdc_1sewer", "aomdc_1city", "aomdc_1city2", "aomdc_1cityx", "aomdc_1ridingcar",
									 "aomdc_1carforest", "aomdc_1afterforest", "aomdc_1angforest", "aomdc_1forhouse",
									 "aomdc_1forest2", "aomdc_1forest3", "aomdc_1heaven1", "aomdc_1heaven2"};

// Ending 2 Maplist										 
const array<string> AOMDC_LIST_E2 = {"aomdc_2hospital", "aomdc_2hospital2", "aomdc_2garage", "aomdc_2backalley", "aomdc_2darkalley",
									 "aomdc_2sewer", "aomdc_2city", "aomdc_2city2", "aomdc_2city3", "aomdc_2sick",
									 "aomdc_2sick2", "aomdc_2sorgarden", "aomdc_2sorgarden2", "aomdc_2arforest",
									 "aomdc_2afterforest", "aomdc_2angforest", "aomdc_2forhouse",
									 "aomdc_2forest2", "aomdc_2forest3", "aomdc_2heaven1", "aomdc_2heaven2"};

// Ending 3 Maplist	
const array<string> AOMDC_LIST_E3 = {"aomdc_3hospital", "aomdc_3hospital2", "aomdc_3garage", "aomdc_3backalley", "aomdc_3darkalley",
									 "aomdc_3sewer", "aomdc_3city", "aomdc_3city2", "aomdc_3city3", "aomdc_3city4", "aomdc_3cityz",
									 "aomdc_3sick", "aomdc_3sick2", "aomdc_3sorgarden", "aomdc_3sorgarden2",
									 "aomdc_3arforest", "aomdc_3afterforest", "aomdc_3angforest", "aomdc_3forhouse",
									 "aomdc_3forest2", "aomdc_3forest3", "aomdc_3heaven1", "aomdc_3heaven2"};

#include "weapon_dcberetta"
#include "weapon_dcp228"
#include "weapon_dcglock"
#include "weapon_dchammer"
#include "weapon_dcknife"
#include "weapon_dcmp5k"
#include "weapon_dcuzi"
#include "weapon_dcshotgun"
#include "weapon_dcrevolver"
#include "weapon_dcdeagle"
#include "weapon_dcaxe"
#include "weapon_dcl85a1"
#include "ammo_dcglock"
#include "ammo_dcdeagle"
#include "ammo_dcrevolver"
#include "ammo_dcmp5k"
#include "ammo_dcshotgun"
#include "item_aompills"
#include "item_aombattery"
// #include "point_checkpoint"
#include "../chkpnt/register"
#include "monster_hellhound"
#include "monster_ghost"
#include "AttachKeySpr"
#include "weaponmaker"
									 									 
CScheduledFunction@ interval;

void MapInit()
{ 
	// Register weapons
	RegisterDCBeretta();
	RegisterDCP228();
	RegisterDCGlock();
	RegisterDCHammer();
	RegisterDCKnife();
	RegisterDCMP5K();
	RegisterDCUzi();
	RegisterDCShotgun();
	RegisterDCRevolver();
	RegisterDCDeagle();
	RegisterDCAxe();
	RegisterDCL85A1();
	
	// Register monsters
	AOMHellhound::Register();
	AOMGhost::Register();
	
	// Register pills and batteries
	RegisterAOMBattery();
	RegisterAOMPills();
	
	// Register misc entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcglock", "ammo_dcglock" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcdeagle", "ammo_dcdeagle" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcrevolver", "ammo_dcrevolver" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcmp5k", "ammo_dcmp5k" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcshotgun", "ammo_dcshotgun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weaponmaker", "weaponmaker" );
	// RegisterPointCheckPointEntity();

	CHKPNT::Register();
	point_checkpoint::g_szEntityName = 'Checkpoint';
	point_checkpoint::g_flDelayBeforeStart = 6;
	point_checkpoint::g_flDelayBeforeReactivation = 9999;
	point_checkpoint::g_szEntityModel = 'models/AoMDC/lambda_custom.mdl';
	point_checkpoint::g_szPortalSprite = 'sprites/null.spr';
	point_checkpoint::g_szActivationSound = 'AoMDC/misc/checkpoint.wav';
	point_checkpoint::g_szPortalCreationSound = 'common/null.wav';
	point_checkpoint::g_szPortalShutdownSound = 'common/null.wav';
	point_checkpoint::g_szPlayerRespawnSound = 'ambience/port_suckin1.wav';
	point_checkpoint::g_szActivationMessage = '!checkpoint reached by !player..';
	point_checkpoint::g_szSaveMessage = '!checkpoint saved by !player, saved: !amount..';
	point_checkpoint::g_vecMins = Vector(-16, -16, -16);
	point_checkpoint::g_vecMaxs = Vector(16, 16, 16);

	// Hooks
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	
	// Parsers
	@interval = g_Scheduler.SetInterval("CheckDroppedWeapons", 15, -1);
	g_Scheduler.SetTimeout("CheckFLPlugin", 2);
	g_Scheduler.SetTimeout("CheckSurvival", 0.025);
}

// Check if survival is enabled and execute certain entities
void CheckSurvival()
{
	// Is survival on?
	bool bSurvivalEnabled = g_EngineFuncs.CVarGetFloat("mp_survival_starton") == 1 && g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1;
	
	const array<string> RemoveTargetnamesSurvivalOn = {"mm_checkpoint1", "mm_checkpoint2", "checkpoint_spr1", "checkpoint_spr2", "checkpoint_txt", "spr_checkpoint1", "spr_checkpoint2"};
	const array<string> RemoveTargetnamesSurvivalOff = {"start_block", "relay_init_map", "survival_weapons"};
	
	edict_t@ pEdict = null;
	CBaseEntity@ pEntity = null;
	
	// Activate the built in relays
	if(bSurvivalEnabled)
		g_EntityFuncs.FireTargets("relay_survivalenabled", null, null, USE_ON, 0, 0);
	else
		g_EntityFuncs.FireTargets("relay_survivaldisabled", null, null, USE_ON, 0, 0);
	
	// Now, search for survival/non-survival specific entities
	for( int pIndex = 0; pIndex < g_Engine.maxEntities; ++pIndex )
	{
		@pEdict = @g_EntityFuncs.IndexEnt(pIndex);
		@pEntity = g_EntityFuncs.Instance(pEdict);
		
		if( pEntity !is null )
		{		
			if(bSurvivalEnabled) // Remove non-survival entities (checkpoints)
			{
				if(RemoveTargetnamesSurvivalOn.find(pEntity.pev.targetname) >= 0)
					g_EntityFuncs.Remove(pEntity);
			}
			else // Remove survival checkpoints and entities
			{
				if(RemoveTargetnamesSurvivalOff.find(pEntity.pev.targetname) >= 0 ||
				   pEntity.GetClassname() == "point_checkpoint" || pEntity.pev.globalname == "survival_weapons")
					g_EntityFuncs.Remove(pEntity);
			}
		}
	}
}

// Checks if the Flashlight plugin is installed. If yes, spawns batteries. Otherwise does nothing.
void CheckFLPlugin()
{
	array<string> pluginList = g_PluginManager.GetPluginList();
		
	if(pluginList.find("AoMDCFlashlight") >= 0)
	{
		g_EngineFuncs.ServerPrint("\nAoMDCFlashlight plugin FOUND. Spawning batteries..");
		g_Scheduler.SetTimeout("RandomizeBatteries", 2); // Spawn the batteries
	}
	else
	{
		g_EngineFuncs.ServerPrint("\nERROR: Could not find AoMDCFlashlight plugin. Batteries not spawned.");
		g_EngineFuncs.ServerPrint("\nMake sure you add the plugin to default_plugins.txt!");
	}
}


// Anti-spam countermeasure (in case the ones built into the weapons themselves fail)
// Scans the map for dropped weapons and removes some if there are too many
void CheckDroppedWeapons()
{
	int numDropped = 0;
	CBaseEntity@ pEntity;
	edict_t@ pEdict;
	
	// Find dropped weapons by targetname
	for(int pIndex = 0; pIndex < g_Engine.maxEntities; ++pIndex)
	{
		@pEdict = @g_EntityFuncs.IndexEnt(pIndex);
		@pEntity = g_EntityFuncs.Instance(pEdict);
		
		if( pEntity !is null )
		{
			if(pEntity.pev.targetname == "weapon_dropped")
				numDropped++;
		}
	}
	
	// Sets an upper bound on dropped weapons to prevent spam.
	// If there are more than 20 weapons dropped, then someone is most likely spamming
	for(int pIndex = 0; pIndex < g_Engine.maxEntities && numDropped > 20; ++pIndex)
	{
		@pEdict = @g_EntityFuncs.IndexEnt(pIndex);
		@pEntity = g_EntityFuncs.Instance(pEdict);
		
		if( pEntity !is null )
		{
			if(pEntity.pev.targetname == "weapon_dropped")
			{
				g_EntityFuncs.Remove(pEntity);
				numDropped--;
			}
		}
	}
}

// Randomizes battery spawns by deleting a random amount in random locations
// constrained between a high and low percentage.
void RandomizeBatteries()
{
	int numSpawners = FindSpawners();
	float low, high;
	
	if(numSpawners >= 30) // Remove most of the spawners
	{
		low = 0.30;
		high = 0.40;
	}
	else if(numSpawners >= 10 && numSpawners < 30) // Remove a little more of the spawners
	{
		low = 0.30;
		high = 0.50;
	}
	else if(numSpawners >= 5 && numSpawners < 10) // Remove only a few spawners
	{
		low = 0.60;
		high = 0.75;
	}
	else // Not enough spawners to randomize. Don't do anything.
		return;
	
	float spawnersToRemove = numSpawners - Math.Ceil(numSpawners * Math.RandomFloat(low, high));
	
	// Loop and remove random battery spawners until a given percent remain
	for(float i = 0 ; i < spawnersToRemove ; i += 1)
	{
		CBaseEntity@ thisSpawner = g_EntityFuncs.RandomTargetname("batteryspawner");
		g_EntityFuncs.Remove(thisSpawner);
	}
	
	// Now, activate the remaining spawners
	g_EntityFuncs.FireTargets("batteryspawner", null, null, USE_ON, 0, 0);
	
	g_EngineFuncs.ServerPrint("\nSpawners successfully randomized..");
}

// Returns the number of battery spawners present in the map
int FindSpawners()
{
	int numSpawners = 0;
	
	// Count batteries	
	edict_t@ pEdict = null;
	CBaseEntity@ pEntity = null;
	
	for( int pIndex = 0; pIndex < g_Engine.maxEntities; ++pIndex )
	{
		@pEdict = @g_EntityFuncs.IndexEnt(pIndex);
		@pEntity = g_EntityFuncs.Instance(pEdict);
		
		if( pEntity !is null )
		{
			if(pEntity.GetClassname() == "monstermaker" &&
			   pEntity.pev.targetname == "batteryspawner")
				numSpawners++;
		}
	}
	
	g_EngineFuncs.ServerPrint("\nFindSpawners() finds " + numSpawners + " spawners.");
	
	return numSpawners;
}

// Equips players with both weapons and ammunition if certain conditions are met
void EquipPlayer(CBasePlayer@ pPlayer)
{
	const string currentMap = g_Engine.mapname;
	int m_iAmountToGive;
	
	if(AOMDC_LIST_NOWEAPON.find(currentMap) < 0) // Is this map a map that we should give weapons on?
	{
		bool bPlayerHasMelee = pPlayer.HasNamedPlayerItem("weapon_dcknife") !is null 
		|| pPlayer.HasNamedPlayerItem("weapon_dchammer") !is null
		|| pPlayer.HasNamedPlayerItem("weapon_dcaxe") !is null;
		
		bool bPlayerHasPistol = pPlayer.HasNamedPlayerItem("weapon_dcberetta") !is null
		|| pPlayer.HasNamedPlayerItem("weapon_dcp228") !is null
		|| pPlayer.HasNamedPlayerItem("weapon_dcglock") !is null;
		
		bool bPlayerHasPrimary = pPlayer.HasNamedPlayerItem("weapon_dcshotgun") !is null
		|| pPlayer.HasNamedPlayerItem("weapon_dcmp5k") !is null
		|| pPlayer.HasNamedPlayerItem("weapon_dcuzi") !is null;
		
		bool bPlayerHasMagnum = pPlayer.HasNamedPlayerItem("weapon_dcrevolver") !is null
		|| pPlayer.HasNamedPlayerItem("weapon_dcdeagle") !is null;
		
		// Only start giving the knife after the first map it naturally occurs in
		bool bCanGiveMelee = AOMDC_LIST_E1.find(currentMap) > AOMDC_LIST_E1.find("aomdc_1hospital")
			   || AOMDC_LIST_E2.find(currentMap) > AOMDC_LIST_E2.find("aomdc_2hospital")
			   || AOMDC_LIST_E3.find(currentMap) > AOMDC_LIST_E3.find("aomdc_3hospital");
		
		// Only start giving the shotgun after the first map it naturally occurs in
		bool bCanGivePrimary = AOMDC_LIST_E1.find(currentMap) > AOMDC_LIST_E1.find("aomdc_1hospital2")
			   || AOMDC_LIST_E2.find(currentMap) > AOMDC_LIST_E2.find("aomdc_2hospital2")
			   || AOMDC_LIST_E3.find(currentMap) > AOMDC_LIST_E3.find("aomdc_3hospital2");
		
		// Only start giving the deagle after the first map it naturally occurs in		
		bool bCanGiveMagnum = AOMDC_LIST_E1.find(currentMap) > AOMDC_LIST_E1.find("aomdc_1backalley")
			   || AOMDC_LIST_E2.find(currentMap) > AOMDC_LIST_E2.find("aomdc_2backalley")
			   || AOMDC_LIST_E3.find(currentMap) > AOMDC_LIST_E3.find("aomdc_3backalley");
		
		if(!bPlayerHasMelee) // Does the player have a melee weapon already?
			if(bCanGiveMelee)
				pPlayer.GiveNamedItem("weapon_dcknife");
			
		if(!bPlayerHasPistol) // Does the player have a pistol already?
			if(bCanGiveMelee)
				pPlayer.GiveNamedItem("weapon_dcp228");
			
		if(!bPlayerHasPrimary) // Does the player have a primary weapon already?
			if(bCanGivePrimary)
				pPlayer.GiveNamedItem("weapon_dcshotgun");
			
		if(!bPlayerHasMagnum) // Does the player have a magnum already?
			if(bCanGiveMagnum)
				pPlayer.GiveNamedItem("weapon_dcdeagle");
		
		// Get player reserve ammo amounts		
		int m_iReserve9mm = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("9mm"));
		int m_iReserveBuckshot = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"));
		int m_iReserve556 = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("556"));
		int m_iReserve357 = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("357"));
	
		// Give ammo if necessary (is ammo low enough and are we on a map that needs this ammo?)
		if(m_iReserve9mm < 65 && bCanGiveMelee)
			pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("9mm"), 65); // Set the ammo amounts
		if(m_iReserveBuckshot < 12 && bCanGivePrimary)
			pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"), 12);
		if(m_iReserve556 < 30 && bCanGivePrimary)
			pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("556"), 30);
		if(m_iReserve357 < 7 && bCanGiveMagnum)
			pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("357"), 7);
	}
}

HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
{
	EquipPlayer(pPlayer);
	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
	g_Scheduler.RemoveTimer(interval);
	return HOOK_CONTINUE;
}