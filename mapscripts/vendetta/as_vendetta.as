// Poke646: Vendetta Script
// Main Script
// Author: Zorbos

#include "ammo_par21_clip"
#include "ammo_par21_grenades"
#include "weapon_cmlwbr"
#include "weapon_leadpipe"
#include "weapon_par21"
#include "weapon_sawedoff"
// #include "../poke646/point_checkpoint"
#include "../chkpnt/register"


void MapInit()
{
	// Survival checkpoint
	// POKECHECKPOINT::RegisterPointCheckPointEntity();

	CHKPNT::Register();
	point_checkpoint::g_flDelayBeforeStart = 6;
	point_checkpoint::g_szEntityModel = 'models/poke646/misc/checkpoint.mdl';
	point_checkpoint::g_szPortalSprite = 'sprites/e-tele1.spr';
	point_checkpoint::g_szActivationSound = 'poke646/misc/checkpoint_survival.wav';
	point_checkpoint::g_szPortalCreationSound = 'poke646/misc/checkpoint_pulse.wav';
	point_checkpoint::g_szPortalShutdownSound = 'poke646/misc/checkpoint_close.wav';
	point_checkpoint::g_szPlayerRespawnSound = 'poke646/misc/checkpoint_pulse.wav';
	point_checkpoint::g_vecMins = Vector(-16, -16, -16);
	point_checkpoint::g_vecMaxs = Vector(16, 16, 16);

	// Register weapons
	RegisterPAR21();
	RegisterSawedOff();
	RegisterLeadpipe();
	RegisterCmlwbr();
	
	// Register ammo entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_par21_clip", "ammo_par21_clip" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_par21_grenades", "ammo_par21_grenades" );
}