namespace DefaultCallbacks
{

bool SpawnEffect(CBaseAnimating@ checkpoint)
{
	NetworkMessage net_msg(MSG_PVS, NetworkMessages::TE_CUSTOM, checkpoint.pev.origin);
		net_msg.WriteByte(2 /* TE_C_XEN_PORTAL */);
		net_msg.WriteVector(checkpoint.pev.origin);
		// For the beams
		net_msg.WriteByte(8);                                // iBeamCount
		net_msg.WriteVector(Vector(217.0f, 226.0f, 146.0f)); // vBeamColor
		net_msg.WriteByte(128);                              // iBeamAlpha
		net_msg.WriteCoord(256.0f);                          // flBeamRadius
		// For the dlight
		net_msg.WriteVector(Vector(39.0f, 209.0f, 137.0f));  // vLightColor
		net_msg.WriteCoord(160.0f);                          // flLightRadius
		// For the sprites
		net_msg.WriteVector(Vector(65.0f, 209.0f, 61.0f));   // vStartSpriteColor
		net_msg.WriteByte(10);                               // int( flStartSpriteScale * 10 )
		net_msg.WriteByte(12);                               // int( flStartSpriteFramerate )
		net_msg.WriteByte(255);                              // iStartSpriteAlpha
		net_msg.WriteVector(Vector(159.0f, 240.0f, 214.0f)); // vEndSpriteColor
		net_msg.WriteByte(10);                               // int( flEndSpriteScale * 10 )
		net_msg.WriteByte(12);                               // int( flEndSpriteFramerate )
		net_msg.WriteByte(255);                              // iEndSpriteAlpha
	net_msg.End();
	return true;
}

// bool OnSpawn(CBaseAnimating@ checkpoint) { return true; }

// bool OnIdle(CBaseAnimating@ checkpoint) { return true; }

bool OnSave(CBaseAnimating@ checkpoint)
{
	checkpoint.pev.rendermode = kRenderTransTexture;
	checkpoint.pev.renderamt = 255.0f;
	return true;
}

bool SaveEffect(CBaseAnimating@ checkpoint)
{
	if (checkpoint.pev.renderamt <= 128.0f)
		return true;

	checkpoint.pev.renderamt -= 30.0f;
	if (checkpoint.pev.renderamt < 128.0f)
		checkpoint.pev.renderamt = 128.0f;

	checkpoint.pev.nextthink = g_Engine.time + 0.1f;
	return false;
}

bool OnActivate(CBaseAnimating@ checkpoint)
{
	checkpoint.pev.rendermode = kRenderTransTexture;
	checkpoint.pev.renderamt = 255.0f;
	return true;
}

bool ActivateEffect(CBaseAnimating@ checkpoint)
{
	if (checkpoint.pev.renderamt > 0.0f)
	{
		checkpoint.pev.renderamt -= 30.0f;
		if (checkpoint.pev.renderamt < 0.0f)
			checkpoint.pev.renderamt = 0.0f;

		checkpoint.pev.nextthink = g_Engine.time + 0.1f;
		return false;
	}
	else
	{
		checkpoint.pev.effects |= EF_NODRAW; // Make this entity invisible
		checkpoint.pev.renderamt = 255.0f;
		return true;
	}
}

// bool OnRespawnStart(CBaseAnimating@ checkpoint, CSprite@ sprite) { return true; }

/*
// Implementions for some suggestions by ak47toh
// if you want to use it uncomment this function and replace null in main.as#L39
// https://discord.com/channels/818989352411463731/819002160297148429/993560417882345523
bool OnRespawn(CBaseAnimating@ checkpoint, CBasePlayer@ player, bool last_to_respawn)
{
	// 3rd suggestion
	if (last_to_respawn && !string(checkpoint.pev.noise).IsEmpty())
		g_EntityFuncs.FireTargets(checkpoint.pev.noise, checkpoint, checkpoint, USE_TOGGLE);
		// If you are going to use the function below: comment the function above and uncomment the other one at the end
		// g_Scheduler.SetTimeout('FireTargetsAfterTime', 3.0f, EHandle(@checkpoint)); // Fire targets after 3.0 sec

	// 5th suggestion (I assume he is referring to this event)
	if (player !is null && !string(checkpoint.pev.noise1).IsEmpty())
		g_EntityFuncs.FireTargets(checkpoint.pev.noise1, player, checkpoint, USE_TOGGLE);

	return true;
}
*/

// bool OnReenable(CBaseAnimating@ checkpoint) { return true; }

bool ResetEffect(CBaseAnimating@ checkpoint)
{
	if (checkpoint.pev.renderamt >= 255.0f)
		return true;

	checkpoint.pev.renderamt += 30.0f;
	if (checkpoint.pev.renderamt > 255.0f)
		checkpoint.pev.renderamt = 255.0f;

	checkpoint.pev.nextthink = g_Engine.time + 0.1f;
	return false;
}

float[][] HoldTimers()
{
	return
	{
		{0.5f, 0.3f, 0.4f, 0.5f, 3.0f},
		{0.4f, 0.3f, 0.5f, 0.5f, 2.8f},
		{0.4f, 0.5f, 0.4f, 0.6f, 2.6f}
	};
}

bool HoldEffect(CBaseAnimating@ auto_checkpoint)
{
	NetworkMessage net_msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
		net_msg.WriteByte(TE_BEAMCYLINDER);
		net_msg.WriteCoord(auto_checkpoint.pev.origin.x);                      // center position
		net_msg.WriteCoord(auto_checkpoint.pev.origin.y);                      // center position
		net_msg.WriteCoord(auto_checkpoint.pev.origin.z);                      // center position
		net_msg.WriteCoord(auto_checkpoint.pev.origin.x);                      // axis and radius
		net_msg.WriteCoord(auto_checkpoint.pev.origin.y);                      // axis and radius
		net_msg.WriteCoord(auto_checkpoint.pev.origin.z + 80.0f);              // axis and radius
		net_msg.WriteShort(g_EngineFuncs.ModelIndex('sprites/laserbeam.spr')); // sprite index
		net_msg.WriteByte(0);                                                  // starting frame
		net_msg.WriteByte(16);                                                 // frame rate in 0.1's
		net_msg.WriteByte(8);                                                  // life in 0.1's
		net_msg.WriteByte(8);                                                  // line width in 0.1's
		net_msg.WriteByte(0);                                                  // noise amplitude in 0.01's
		net_msg.WriteByte(RGBA_SVENCOOP.r);                                    // color
		net_msg.WriteByte(RGBA_SVENCOOP.g);                                    // color
		net_msg.WriteByte(RGBA_SVENCOOP.b);                                    // color
		net_msg.WriteByte(RGBA_SVENCOOP.a);                                    // brightness
		net_msg.WriteByte(0);                                                  // scroll speed in 0.1's
	net_msg.End();
	return true;
}

/*
void FireTargetsAfterTime(EHandle h_checkpoint)
{
	CBaseEntity@ checkpoint = null;
	if ((@checkpoint = h_checkpoint) !is null && !string(checkpoint.pev.noise).IsEmpty())
		g_EntityFuncs.FireTargets(checkpoint.pev.noise, checkpoint, checkpoint, USE_TOGGLE);
}
*/

}
