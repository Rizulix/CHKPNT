#include 'shared'

/**
 * point_checkpoint
 * This point entity represents a point in the world where players can trigger a checkpoint
 * Dead players are revived
 */

namespace point_checkpoint
{

enum PointCheckpointFlags
{
	SF_CHECKPOINT_REUSABLE = 1 << 0, // This checkpoint is reusable
	SF_CHECKPOINT_USE_ONLY = 1 << 1, // This checkpoint may only be activated with the use key
	SF_CHECKPOINT_NO_AUTO = 1 << 2,  // Ignores auto_checkpoint
};

// Spawn Effect?
bool g_fSpawnEffect = false;
// Delays
float g_flDelayBeforeStart = 3.0f;
float g_flDelayBetweenRevive = 1.0f;
float g_flDelayBeforeReactivation = 60.0f;
// Name
string g_szEntityName = 'Respawn-Point';
// Models
string g_szEntityModel = 'models/common/lambda.mdl';
// Sprites
string g_szPortalSprite = 'sprites/exit1.spr';
// Event Sounds
string g_szActivationSound = '../media/valve.mp3';
string g_szPlayerRespawnSound = 'debris/beamstart4.wav';
string g_szPortalCreationSound = 'debris/beamstart7.wav';
string g_szPortalShutdownSound = 'ambience/port_suckout1.wav';
// Event Messages
string g_szSaveMessage = '!player has reached a !checkpoint, saved: !amount.';
string g_szActivationMessage = '!player just activated a !checkpoint.';
string g_szAutoActivationMessage = 'Auto-activating a !checkpoint, remaining: !amount.';
string g_szVoteActivationMessage = 'Activating a !checkpoint, remaining: !amount.';
string g_szForceActivationMessage = '!player has forced the activation of a !checkpoint, remaining: !amount.';
// Entity Size
Vector g_vecMins = Vector(-8.0f, -8.0f, -16.0f);
Vector g_vecMaxs = Vector(8.0f, 8.0f, 16.0f);
// Event Use Types
USE_TYPE g_useOnSpawn = USE_TOGGLE;
USE_TYPE g_useOnActivate = USE_TOGGLE;
float g_flActivateValue = 0.0f;

class point_checkpoint : ScriptBaseAnimating
{
	// Sprite Instance
	private CSprite@ m_pSprite = null;
	// Keep tracking target player index
	private int m_iNextPlayerToRevive = 1;
	// Show Xenmaker-like effect when the checkpoint is spawned?
	private bool m_fSpawnEffect = g_fSpawnEffect;
	// When we started a respawn private
	private float m_flRespawnStartTime = 0.0f;
	// How much time between being triggered and starting the revival of dead players
	private float m_flDelayBeforeStart = g_flDelayBeforeStart;
	// Time between player revive private
	private float m_flDelayBetweenRevive = g_flDelayBetweenRevive;
	// How much time before this checkpoint becomes active again, if SF_CHECKPOINT_REUSABLE is set
	private float m_flDelayBeforeReactivation = g_flDelayBeforeReactivation;
	// Saves the custom respawn point assigned by the mapper
	private Vector m_vecRespawnPoint = g_vecZero;
	// Set the USE_TYPE to use on target when this checkpoint is spawned
	private USE_TYPE m_useOnSpawn = g_useOnSpawn;
	// Set the USE_TYPE to use on target when this checkpoint is activated
	private USE_TYPE m_useOnActivate = g_useOnActivate;
	// Set the state value when its UseType is USE_SET
	private float m_flActivateValue = g_flActivateValue;

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if (szKey == 'm_fSpawnEffect')
		{
			m_fSpawnEffect = atoi(szValue) != 0;
			return true;
		}
		else if (szKey == 'm_flDelayBeforeStart')
		{
			m_flDelayBeforeStart = atof(szValue);
			return true;
		}
		else if (szKey == 'm_flDelayBetweenRevive')
		{
			m_flDelayBetweenRevive = atof(szValue);
			return true;
		}
		else if (szKey == 'm_flDelayBeforeReactivation')
		{
			m_flDelayBeforeReactivation = atof(szValue);
			return true;
		}
		else if (szKey == 'minhullsize')
		{
			g_Utility.StringToVector(pev.vuser1, szValue);
			return true;
		}
		else if (szKey == 'maxhullsize')
		{
			g_Utility.StringToVector(pev.vuser2, szValue);
			return true;
		}
		else if (szKey == 'm_vecRespawnPoint')
		{
			g_Utility.StringToVector(pev.vuser3, szValue);
			m_vecRespawnPoint = pev.vuser3;
			if (!InAutoMode())
				return true;
			// Trigger UpdateRespawnPoints method
			g_pAutoCheckpoint.Use(self, self, USE_SET, 0.0f);
			return true;
		}
		else if (szKey == 'm_useOnSpawn')
		{
			m_useOnSpawn = USE_TYPE(atoi(szValue));
			return true;
		}
		else if (szKey == 'm_useOnActivate')
		{
			m_useOnActivate = USE_TYPE(atoi(szValue));
			return true;
		}
		else if (szKey == 'm_flActivateValue')
		{
			m_flActivateValue = atof(szValue);
			return true;
		}
		else
			return BaseClass.KeyValue(szKey, szValue);
	}

	// If youre gonna use this in your script, make sure you don't try
	// to access invalid animations. -zode
	void SetAnim(int animIndex)
	{
		pev.sequence = animIndex;
		pev.frame = 0.0f;
		self.ResetSequenceInfo();
	}

	void Precache()
	{
		BaseClass.Precache();

		// Allow for custom models
		if (string(pev.model).IsEmpty())
			g_Game.PrecacheModel(g_szEntityModel);
		else
			g_Game.PrecacheModel(pev.model);

		g_Game.PrecacheModel(g_szPortalSprite);

		g_SoundSystem.PrecacheSound(g_szActivationSound);
		g_SoundSystem.PrecacheSound(g_szPortalCreationSound);
		g_SoundSystem.PrecacheSound(g_szPortalShutdownSound);

		if (string(pev.message).IsEmpty())
			pev.message = g_szPlayerRespawnSound;

		g_SoundSystem.PrecacheSound(pev.message);
	}

	void Spawn()
	{
		Precache();
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_TRIGGER;
		pev.framerate = 1.0f;

		pev.health = 1.0f; // Enabled by default
		pev.frags = 0.0f;  // Not activated by default
		pev.speed = 0.0f;  // Not reached by default
		pev.dmg = 0.0f;    // Not yet used by default

		// Allow for custom models
		if (string(pev.model).IsEmpty())
			g_EntityFuncs.SetModel(self, g_szEntityModel);
		else
			g_EntityFuncs.SetModel(self, pev.model);

		g_EntityFuncs.SetOrigin(self, pev.origin);

		// Custom hull size
		if (pev.vuser1 != g_vecZero && pev.vuser2 != g_vecZero)
			g_EntityFuncs.SetSize(pev, pev.vuser1, pev.vuser2);
		else
			g_EntityFuncs.SetSize(pev, g_vecMins, g_vecMaxs);

		SetAnim(0); // Set sequence to 0 aka idle

		// If the map supports survival mode but survival is not active yet
		// spawn disabled checkpoint
		if (g_SurvivalMode.MapSupportEnabled() && !g_SurvivalMode.IsActive())
			SetEnabled(false);
		else
			SetEnabled(true);

		if (IsEnabled())
		{
			// Fire netname entity on spawn (if specified and checkpoint is enabled)
			if (!string(pev.netname).IsEmpty())
				g_EntityFuncs.FireTargets(pev.netname, self, self, m_useOnSpawn);

			// Create Xenmaker-like effect
			if (m_fSpawnEffect)
				g_pCallbacks.SpawnEffect(self);
		}

		g_pCallbacks.OnSpawn(self);

		SetThink(ThinkFunction(this.IdleThink));
		pev.nextthink = g_Engine.time + 0.1f;
	}

	void Touch(CBaseEntity@ pOther)
	{
		if (pev.SpawnFlagBitSet(SF_CHECKPOINT_USE_ONLY))
			return;

		if (!IsEnabled() || IsActivated() || IsReached() || !pOther.IsPlayer())
			return;

		Use(pOther, pOther, USE_TOGGLE, 0.0f);
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		if (!IsEnabled() || IsActivated())
			return;

		if (pActivator.IsPlayer())
		{
			bool bSave = InAutoMode() && !IsAlredyUsed();

			if (IsReached() && bSave)
			{
				// Trigger DoVote method
				g_pAutoCheckpoint.Use(pActivator, pActivator, USE_TOGGLE, 0.0f);
				return;
			}

			pev.speed = 1.0f; // Set reached
			string szAmount = 'NaN';

			SetThink(bSave ? ThinkFunction(this.SaveThink) : ThinkFunction(this.ActivateThink));
			pev.nextthink = g_Engine.time + 0.1f;

			bSave ? g_pCallbacks.OnSave(self) : g_pCallbacks.OnActivate(self);

			if (bSave)
			{
				g_pAutoCheckpoint.Touch(self); // Saves this checkpoint
				szAmount = '' + g_pAutoCheckpoint.pev.iuser1;
			}
			else
			{
				pev.frags = 1.0f; // Set activated
				g_SoundSystem.EmitSound(self.edict(), CHAN_AUTO, g_szActivationSound, 1.0f, ATTN_NONE);
			}

			g_Game.AlertMessage(at_logged, 'CHECKPOINT: "%1" has %2 a Checkpoint.\n', pActivator.pev.netname, bSave ? 'saved' : 'activated');
			g_PlayerFuncs.ClientPrintAll(
				HUD_PRINTTALK, 
				str(
					bSave ? g_szSaveMessage : g_szActivationMessage, 
					{{'!checkpoint', g_szCheckpointName}, {'!player', '' + pActivator.pev.netname}, {'!amount', szAmount}}
				) + '\n'
			);

			// Trigger targets
			self.SUB_UseTargets(pActivator, m_useOnActivate, m_useOnActivate == USE_SET ? m_flActivateValue : 0.0f);
		}
		else if (pActivator.GetClassname() == 'auto_checkpoint')
		{
			if (useType == USE_OFF)
			{
				SetThink(ThinkFunction(this.ResetThink));
				pev.nextthink = g_Engine.time + 0.1f;
				return;
			}

			if (!IsReached() || IsActivated())
				return;

			pev.fuser1 = 1.1f + m_flDelayBeforeStart + m_flDelayBetweenRevive * g_PlayerFuncs.GetNumPlayers();
			bool bForced = pCaller.IsPlayer();

			SetThink(ThinkFunction(this.ActivateThink));
			pev.nextthink = g_Engine.time + 0.1f;

			g_pCallbacks.OnActivate(self);

			pev.frags = 1.0f; // Set activated
			g_SoundSystem.EmitSound(self.edict(), CHAN_AUTO, g_szActivationSound, 1.0f, ATTN_NONE);

			g_Game.AlertMessage(
				at_logged, 
				'CHECKPOINT: "%1" has %2 a Checkpoint.\n', 
				bForced ? pCaller.pev.netname : pCaller.pev.targetname, 
				bForced ? 'forced' : 'activated'
			);
			g_PlayerFuncs.ClientPrintAll(
				HUD_PRINTTALK, 
				str(
					bForced ? g_szForceActivationMessage : useType == USE_ON ? g_szVoteActivationMessage : g_szAutoActivationMessage, 
					{{'!checkpoint', g_szCheckpointName}, {'!player', '' + pCaller.pev.netname}, {'!amount', '' + g_pAutoCheckpoint.pev.iuser1}}
				) + '\n'
			);
		}
	}

	int ObjectCaps()
	{
		if (pev.SpawnFlagBitSet(SF_CHECKPOINT_USE_ONLY) || IsReached() && InAutoMode())
			return BaseClass.ObjectCaps() | FCAP_IMPULSE_USE;

		return BaseClass.ObjectCaps();
	}

	bool IsEnabled() const { return pev.health != 0.0f; }

	bool IsActivated() const { return pev.frags != 0.0f; }

	void SetEnabled(const bool bEnabled)
	{
		if (bEnabled == IsEnabled())
			return;

		if (bEnabled && !IsActivated())
			pev.effects &= ~EF_NODRAW;
		else
			pev.effects |= EF_NODRAW;

		pev.health = bEnabled ? 1.0f : 0.0f;
	}

	// GeckoN: Idle Think - just to make sure the animation gets updated properly.
	// Should fix the "checkpoint jitter" issue.
	void IdleThink()
	{
		self.StudioFrameAdvance();
		pev.nextthink = g_Engine.time + 0.1f;

		g_pCallbacks.OnIdle(self);
	}

	void ActivateThink()
	{
		if (g_pCallbacks.ActivateEffect(self))
		{
			SetThink(ThinkFunction(this.RespawnStartThink));
			pev.nextthink = g_Engine.time + m_flDelayBeforeStart;

			m_flRespawnStartTime = g_Engine.time;
		}
		else
			self.StudioFrameAdvance();
	}

	void RespawnStartThink()
	{
		// Clean up the old sprite if needed
		if (m_pSprite !is null)
			g_EntityFuncs.Remove(m_pSprite);

		m_iNextPlayerToRevive = 1;

		@m_pSprite = g_EntityFuncs.CreateSprite(g_szPortalSprite, GetRespawnPoint(), true);
		m_pSprite.TurnOn();
		m_pSprite.pev.rendermode = kRenderTransAdd;
		m_pSprite.pev.renderamt = 128.0f;

		g_SoundSystem.EmitSound(self.edict(), CHAN_AUTO, g_szPortalCreationSound, 1.0f, ATTN_NORM);

		g_pCallbacks.OnRespawnStart(self, m_pSprite);

		SetThink(ThinkFunction(this.RespawnThink));
		pev.nextthink = g_Engine.time + 0.1f;
	}

	// Revives 1 player every m_flDelayBetweenRevive seconds, if any players need reviving.
	void RespawnThink()
	{
		CBasePlayer@ pPlayer;
		bool bLastPlayer = false;

		if (g_bScareNearEnemies)
		{
			g_bScareNearEnemies = false;
			GetSoundEntInstance().InsertSound(bits_SOUND_DANGER, GetRespawnPoint(), NORMAL_EXPLOSION_VOLUME, 3.0f, self);
		}

		while (m_iNextPlayerToRevive <= g_PlayerFuncs.GetNumPlayers())
		{
			@pPlayer = g_PlayerFuncs.FindPlayerByIndex(m_iNextPlayerToRevive);
			++m_iNextPlayerToRevive; // Make sure to increment this to avoid unneeded loop

			// Only respawn if the player died before this checkpoint was activated
			// Prevents exploitation
			if (
				pPlayer !is null &&
				pPlayer.IsConnected() &&
				!pPlayer.IsAlive() &&
				(InAutoMode() ? pPlayer.m_fDeadTime - 1.0f : pPlayer.m_fDeadTime) < m_flRespawnStartTime
			)
			{
				// Revive player and move to this checkpoint
				pPlayer.GetObserver().RemoveDeadBody();
				pPlayer.SetOrigin(GetRespawnPoint());
				pPlayer.Revive();

				// Call player equip
				// Only disable default giving if there are game_player_equip entities in give mode
				CBaseEntity@ pEquipEntity = null;
				while ((@pEquipEntity = g_EntityFuncs.FindEntityByClassname(pEquipEntity, 'game_player_equip')) !is null)
					pEquipEntity.Use(pPlayer, pPlayer, USE_TOGGLE, 0.0f);

				// Congratulations, and celebrations, YOU'RE ALIVE!
				g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_AUTO, pev.message, 1.0f, ATTN_NORM);
				break;
			}
		}

		g_pCallbacks.OnRespawn(self, pPlayer, (bLastPlayer = m_iNextPlayerToRevive > g_PlayerFuncs.GetNumPlayers()));

		// All players have been checked, close portal after 5 seconds.
		if (bLastPlayer)
		{
			SetThink(ThinkFunction(this.StartKillSpriteThink));
			pev.nextthink = g_Engine.time + 5.0f;
		}
		// Another player could require reviving
		else
			pev.nextthink = g_Engine.time + m_flDelayBetweenRevive;
	}

	void StartKillSpriteThink()
	{
		g_SoundSystem.EmitSound(self.edict(), CHAN_AUTO, g_szPortalShutdownSound, 1.0f, ATTN_NORM);

		SetThink(ThinkFunction(this.KillSpriteThink));
		pev.nextthink = g_Engine.time + 3.0f;
	}

	void CheckReusable()
	{
		if (pev.SpawnFlagBitSet(SF_CHECKPOINT_REUSABLE))
		{
			SetThink(ThinkFunction(this.ReenableThink));
			pev.nextthink = g_Engine.time + m_flDelayBeforeReactivation;
		}
		else
		{
			SetThink(ThinkFunction(this.IdleThink));
			pev.nextthink = g_Engine.time + 0.1f;
		}
	}

	void KillSpriteThink()
	{
		if (m_pSprite !is null)
		{
			g_EntityFuncs.Remove(m_pSprite);
			@m_pSprite = null;
		}

		pev.dmg = 1.0f; // Set used
		CheckReusable();
	}

	void ReenableThink()
	{
		if (IsEnabled())
			// Make visible again
			pev.effects &= ~EF_NODRAW;

		pev.frags = 0.0f; // Set deactivated
		pev.speed = 0.0f; // Not reached
		pev.dmg = 0.0f;   // Auto-checkpoint can use this again

		g_pCallbacks.OnReenable(self);

		SetThink(ThinkFunction(this.IdleThink)); // Originaly RespawnThink idk why
		pev.nextthink = g_Engine.time + 0.1f;
	}

	bool IsReached() const { return pev.speed != 0.0f; }

	bool IsAlredyUsed() const { return pev.dmg != 0.0f; }

	bool InAutoMode() const { return g_pAutoCheckpoint !is null && !pev.SpawnFlagBitSet(SF_CHECKPOINT_NO_AUTO); }

	Vector GetRespawnPoint() const { return pev.vuser3 != g_vecZero ? pev.vuser3 : pev.origin; }

	void SaveThink()
	{
		if (g_pCallbacks.SaveEffect(self))
		{
			SetThink(ThinkFunction(this.IdleThink));
			pev.nextthink = g_Engine.time + 0.1f;
		}
		else
			self.StudioFrameAdvance();
	}

	void ResetThink()
	{
		if (g_pCallbacks.ResetEffect(self))
		{
			SetThink(ThinkFunction(this.IdleThink));
			pev.nextthink = g_Engine.time + 0.1f;

			pev.vuser3 = m_vecRespawnPoint != g_vecZero ? m_vecRespawnPoint : g_vecZero;

			pev.frags = 0.0f; // Set deactivated
			pev.speed = 0.0f; // Not reached
		}
		else
			self.StudioFrameAdvance();
	}

	void UpdateOnRemove()
	{
		if (InAutoMode())
			g_pAutoCheckpoint.Use(self, self, USE_TOGGLE, 0.0f);

		BaseClass.UpdateOnRemove();
	}
}

void Register()
{
	LoadCustomCallbacks();

	g_szCheckpointName = g_szEntityName;

	if (!g_CustomEntityFuncs.IsCustomEntity('point_checkpoint'))
		g_CustomEntityFuncs.RegisterCustomEntity('point_checkpoint::point_checkpoint', 'point_checkpoint');
}

}
