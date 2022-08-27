#include '../structure/main'

// Code from:
// https://github.com/RedSprend/svencoop_plugins/blob/master/svencoop/scripts/maps/wanted/point_checkpoint.as
CallbackHandler@ g_pWantedCallbacks = CallbackHandler(
	maps: 'want', 
	onSpawn: function(CBaseAnimating@ checkpoint)
	{
		// for (uint i = 1; i < 6; i++)
			// g_SoundSystem.PrecacheSound('wanted/chicken/chick_scream' + i + '.wav');

		// g_Game.PrecacheModel('models/wanted/chicken.mdl');
		// g_Game.PrecacheModel('models/wanted/w_pistol.mdl');

		checkpoint.pev.scale = 2.0f;
		checkpoint.pev.angles = Vector(90.0f, 0.0f, 0.0f);
		checkpoint.pev.renderfx = kRenderFxGlowShell;
		// checkpoint.pev.rendermode = kRenderNormal;
		checkpoint.pev.renderamt = 8.0f;
		switch(Math.RandomLong(0, 2))
		{
			case 0: checkpoint.pev.rendercolor = Vector(128.0f, 0.0f, 0.0f); break;
			case 1: checkpoint.pev.rendercolor = Vector(0.0f, 128.0f, 0.0f); break;
			case 2: checkpoint.pev.rendercolor = Vector(0.0f, 0.0f, 128.0f); break;
		}
		return true;
	}, 
	onIdle: function(CBaseAnimating@ checkpoint)
	{
		checkpoint.pev.angles.y += 1.0f;
		checkpoint.pev.nextthink = g_Engine.time + 0.02f;
		return true;
	}, 
	saveFX: function(CBaseAnimating@ checkpoint)
	{
		if (checkpoint.pev.renderamt <= 128.0f)
			return true;

		checkpoint.pev.angles.y += 1.0f;
		checkpoint.pev.renderamt -= 1.3f;

		if (checkpoint.pev.renderamt < 128.0f)
			checkpoint.pev.renderamt = 128.0f;

		checkpoint.pev.nextthink = g_Engine.time + 0.02f;
		return false;
	}, 
	activateFX: function(CBaseAnimating@ checkpoint)
	{
		if (checkpoint.pev.renderamt > 0.0f)
		{
			checkpoint.pev.angles.y += 1.0f;
			checkpoint.pev.renderamt -= 1.3;

			if (checkpoint.pev.renderamt < 0.0f)
				checkpoint.pev.renderamt = 0.0f;

			checkpoint.pev.nextthink = g_Engine.time + 0.02f;
			return false;
		}
		else
		{
			checkpoint.pev.effects |= EF_NODRAW;
			checkpoint.pev.renderamt = 255.0f;
			return true;
		}
	}, 
	onRespawn: function(CBaseAnimating@ checkpoint, CBasePlayer@ player, bool last_to_respawn)
	{
		// This is my own interpretation, the original code is marked as UNDONE!
		int iRandom = Math.RandomLong(3, 5);
		Vector origin = checkpoint.pev.vuser3 != g_vecZero ? checkpoint.pev.vuser3 : checkpoint.pev.origin; // Custom respawn point?

		for (int i = 0; i < iRandom; i++)
		{
			NetworkMessage net_msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
				net_msg.WriteByte(TE_MODEL);
				net_msg.WriteCoord(origin.x);                                              // origin
				net_msg.WriteCoord(origin.y);                                              // origin
				net_msg.WriteCoord(origin.z);                                              // origin
				net_msg.WriteCoord(Math.RandomFloat(-100.0f, 100.0f));                     // velocity
				net_msg.WriteCoord(Math.RandomFloat(500.0f, 800.0f));                      // velocity
				net_msg.WriteCoord(Math.RandomFloat(-360.0f, 360.0f));                     // velocity
				net_msg.WriteAngle(Math.RandomFloat(-360.0f, 360.0f));                     // yaw
				net_msg.WriteShort(g_EngineFuncs.ModelIndex('models/wanted/chicken.mdl')); // model index
				net_msg.WriteByte(0);                                                      // bounce sound
				net_msg.WriteByte(10);                                                     // life time in 0.1's
			net_msg.End();

			g_SoundSystem.EmitSound(checkpoint.edict(), CHAN_AUTO, 'wanted/chicken/chick_scream' + Math.RandomLong(1, 5) + '.wav', 1.0f, ATTN_NORM);
		}
		return true;
	}, 
	resetFX: function(CBaseAnimating@ checkpoint)
	{
		if (checkpoint.pev.renderamt <= 255.0f)
			return true;

		checkpoint.pev.angles.y -= 1.0f;
		checkpoint.pev.renderamt += 1.3f;

		if (checkpoint.pev.renderamt > 255.0f)
			checkpoint.pev.renderamt = 255.0f;

		checkpoint.pev.nextthink = g_Engine.time + 0.02f;
		return false;
	}
);

