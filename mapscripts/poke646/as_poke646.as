// Poke646 Script
// Main Script
// Author: Zorbos

#include "ammo_nailclip"
#include "ammo_nailround"
#include "weapon_bradnailer"
#include "weapon_cmlwbr"
#include "weapon_heaterpipe"
#include "weapon_nailgun"
#include "weapon_sawedoff"
// #include "point_checkpoint"
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
	RegisterBradnailer();
	RegisterNailgun();
	RegisterSawedOff();
	RegisterHeaterpipe();
	RegisterCmlwbr();

	// Register ammo entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_nailclip", "ammo_nailclip" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_nailround", "ammo_nailround" );
}