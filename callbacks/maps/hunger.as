#include '../structure/main'

CallbackHandler@ g_pHungerCallbacks = CallbackHandler(
	maps: 'th_ep', 
	onSpawn: function(CBaseAnimating@ checkpoint)
	{
		// Precache this for "OnRespawn" event
		g_Game.PrecacheModel('sprites/lgtning.spr');

		// Set sequence to 1 aka idle_closed
		checkpoint.pev.sequence = 1;
		checkpoint.pev.frame = 0.0f;
		checkpoint.ResetSequenceInfo();
		return true;
	}, 
	onSave: null, 
	saveFX: null, 
	onActivate: function(CBaseAnimating@ checkpoint)
	{
		if (string(checkpoint.pev.netname).IsEmpty())
		{
			TraceResult tr;
			Vector origin = checkpoint.pev.vuser3 != g_vecZero ? checkpoint.pev.vuser3 : checkpoint.pev.origin; // Custom respawn point?
			g_EngineFuncs.MakeVectors(checkpoint.pev.angles);
			g_Utility.TraceLine(origin, origin + g_Engine.v_up * 4096.0f, ignore_monsters, checkpoint.edict(), tr);
			// Don't care if we did'nt hit skybox, it'll look like it came from the sky anyways
			checkpoint.pev.vuser4 = tr.vecEndPos;
		}
		else
		{
			CBaseEntity@ target = null;
			while((@target = g_EntityFuncs.FindEntityByTargetname(target, checkpoint.pev.netname)) !is null)
				checkpoint.pev.vuser4 = target.pev.origin;
		}

		checkpoint.pev.sequence = 2;
		checkpoint.pev.frame = 0.0f;
		checkpoint.ResetSequenceInfo();
		// Don't wait 0.1 sec
		checkpoint.pev.nextthink = g_Engine.time;
		return true;
	}, 
	activateFX: null, 
	onRespawnStart: function(CBaseAnimating@ checkpoint, CSprite@ sprite)
	{
		// Set sequence to 0 aka idle_open
		checkpoint.pev.sequence = 0;
		checkpoint.pev.frame = 0.0f;
		checkpoint.ResetSequenceInfo();
		return true;
	}, 
	onRespawn: function(CBaseAnimating@ checkpoint, CBasePlayer@ player, bool last_to_respawn)
	{
		if (player !is null)
		{
			NetworkMessage net_msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
				net_msg.WriteByte(TE_BEAMPOINTS);
				net_msg.WriteCoord(checkpoint.pev.vuser4.x);                         // start position
				net_msg.WriteCoord(checkpoint.pev.vuser4.y);                         // start position
				net_msg.WriteCoord(checkpoint.pev.vuser4.z);                         // start position
				net_msg.WriteCoord(player.pev.origin.x);                             // end position
				net_msg.WriteCoord(player.pev.origin.y);                             // end position
				net_msg.WriteCoord(player.pev.origin.z);                             // end position
				net_msg.WriteShort(g_EngineFuncs.ModelIndex('sprites/lgtning.spr')); // sprite index
				net_msg.WriteByte(0);                                                // starting frame
				net_msg.WriteByte(20);                                               // frame rate in 0.1's
				net_msg.WriteByte(1);                                                // life in 0.1's
				net_msg.WriteByte(24);                                               // line width in 0.1's
				net_msg.WriteByte(80);                                               // noise amplitude in 0.01's
				net_msg.WriteByte(172);                                              // color
				net_msg.WriteByte(255);                                              // color
				net_msg.WriteByte(255);                                              // color
				net_msg.WriteByte(255);                                              // brightness
				net_msg.WriteByte(0);                                                // scroll speed in 0.1's
			net_msg.End();
		}

		if (last_to_respawn)
		{
			checkpoint.pev.rendermode = kRenderTransTexture;
			checkpoint.pev.renderamt = 255.0f;
			g_Scheduler.SetTimeout('FadeThink', 0.1f, EHandle(@checkpoint));
		}
		else
			checkpoint.StudioFrameAdvance();

		return true;
	}, 
	onReenable: function(CBaseAnimating@ checkpoint)
	{
		// Set sequence to 1 aka idle_closed
		checkpoint.pev.sequence = 1;
		checkpoint.pev.frame = 0.0f;
		checkpoint.ResetSequenceInfo();
		return true;
	}, 
	resetFX: function(CBaseAnimating@ checkpoint)
	{
		// Set sequence to 1 aka idle_closed
		if (checkpoint.pev.sequence != 1)
		{
			checkpoint.pev.sequence = 1;
			checkpoint.pev.frame = 0.0f;
			checkpoint.ResetSequenceInfo();
		}
		return DefaultCallbacks::ResetEffect(checkpoint);
	}
);

namespace Hunger
{
void FadeThink(EHandle h_checkpoint)
{
	if (!h_checkpoint)
		return;

	CBaseAnimating@ checkpoint = cast<CBaseAnimating>(h_checkpoint.GetEntity());
	if (checkpoint.pev.renderamt > 0.0f)
	{
		checkpoint.StudioFrameAdvance();

		checkpoint.pev.renderamt -= 5.0f;
		if (checkpoint.pev.renderamt < 0.0f)
			checkpoint.pev.renderamt = 0.0f;

		g_Scheduler.SetTimeout('FadeThink', 0.1f, h_checkpoint);
	}
}
}
