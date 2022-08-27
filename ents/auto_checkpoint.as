#include 'shared'
#include '../lib/util'
#include '../lib/vote'

/**
 * auto_checkpoint
 * This entity will activate the already saved checkpoints once all players are dead
 */

namespace auto_checkpoint
{

// Activation Flag
const int AUTO_ACTIVATION = 1 << 0;
const int NOTIFY_ACTIVATION = 1 << 1;
// Scheduled Type
const int NORMAL_SCHEDULED = 1 << 0;
const int SPAWNKILL_SCHEDULED = 1 << 1;
// Command regex
const Regex::Regex g_pChatCommands('^[/|!|.|#](cp|no|yes|forcecp|cancelcp)$', Regex::FlagType(Regex::ECMAScript | Regex::icase));

// Update Respawn Points of all Checkpoints saved?
bool g_fUpdateRespawnPoints = true;
// Unable Messages
string g_szNoCheckpoints = 'No !checkpoint available.';
string g_szNoSurvival = 'Survival mode is not activated.';
string g_szAllAlive = 'All players are alive, omitting results...';
// Vote Messages
string g_szWaitForVote = 'Wait !delay sec.';
string g_szVoteInProgress = 'Vote in progress!';
string g_szNoVoteToCancel = "There's nothing to cancel!";
string g_szVoteCanceled = 'Vote to activate a !checkpoint has been cancelled!';
string g_szAdminCancelsVote = 'Vote to activate a !checkpoint has been cancelled by !player!';
string g_szVoteStarted = 'Activate a !checkpoint? Say "!yes" to use it or "!no" to not use it.';
// Vote Results Messages
string g_szVoteFailed = 'Vote failed.';
string g_szVoteSuccess = 'Vote successful.';
string g_szNoOneVoted = '!result No one voted.'; // !result will always be g_szVoteFailed unless...
string g_szVoteResult = '!result Got "!infavor", needed "!required".';
// Vote Choice Messages
string g_szVotedFor = '!player voted for.';
string g_szVotedAgainst = '!player voted against.';

class auto_checkpoint : ScriptBaseAnimating
{
	// Timer for CheckForVote
	private CScheduledFunction@ m_pCheckForVote = null;
	// Timer for VoteResults
	private CScheduledFunction@ m_pVoteResults = null;
	// Checkpoints Instances
	private EHandle[] m_rghCheckpoints;
	// Beam Cylinder effect timers
	private float[][] m_matTimers;
	// Keep tracking effect timer sub-element index (width)
	private uint m_uiTimerSubIndex = 0;
	// Another instance of this class exist?
	private bool m_fDuplicate = false;
	// Enable overwriting of the Respawn point of all saved Checkpoints
	private bool m_fUpdateRespawnPoints = g_fUpdateRespawnPoints;
	// Cooldown for Votes
	private float m_flNextVote = 0.0f;
	// Cooldown for Checkpoint activation
	private float m_flNextActivation = 0.0f;

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if (szKey == 'm_fUpdateRespawnPoints')
		{
			m_fUpdateRespawnPoints = atoi(szValue) != 0;
			return true;
		}
		else
			return BaseClass.KeyValue(szKey, szValue);
	}

	void PreSpawn()
	{
		BaseClass.PreSpawn();
		m_fDuplicate = g_hAutoCheckpoint;
	}

	void Spawn()
	{
		Precache();

		if (m_fDuplicate)
		{
			g_EntityFuncs.Remove(self);
			return;
		}

		g_hAutoCheckpoint = EHandle(@self);
		m_matTimers = g_pCallbacks.HoldTimers();

		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;

		if (self.GetTargetname().IsEmpty())
			pev.targetname = 'as:auto_checkpoint';

		pev.nextthink = g_Engine.time + 0.1f;

		g_Game.AlertMessage(at_logged, 'AUTO-CHECKPOINT: Enabled.\n');
		g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, 'Auto-Checkpoint enabled!\n');
	}

	void Precache()
	{
		BaseClass.Precache();
		g_Game.PrecacheModel('sprites/laserbeam.spr');
	}

	uint SavedCheckpoints()
	{
		uint i = 0;
		for (uint j = 0; j < m_rghCheckpoints.length(); j++)
			i += m_rghCheckpoints[j] ? 1 : 0;
		return i;
	}

	void Think()
	{
		uint uiSaved = SavedCheckpoints();

		if (IsEnabled() && uiSaved != 0)
			g_pCallbacks.HoldEffect(self);

		if (m_matTimers.length() != 0 && uiSaved != 0)
		{
			uint i = Math.min(uiSaved, m_matTimers.length()) - 1;
			m_uiTimerSubIndex >= m_matTimers[i].length() - 1 ? m_uiTimerSubIndex = 0 : ++m_uiTimerSubIndex;
			pev.nextthink = g_Engine.time + m_matTimers[i][m_uiTimerSubIndex];
		}
		else
			pev.nextthink = g_Engine.time + 0.1f;
	}

	void Touch(CBaseEntity@ pOther)
	{
		if (pOther.GetClassname() != 'point_checkpoint')
			return;

		if (FindCheckpointIndex(pOther) != -1)
			return;

		m_rghCheckpoints.insertLast(EHandle(@pOther));
		pev.iuser1 = SavedCheckpoints();

		if (m_fUpdateRespawnPoints)
			UpdateRespawnPoints(pOther.pev.vuser3 != g_vecZero ? pOther.pev.vuser3 : pOther.pev.origin);

		@m_pCheckForVote = g_Scheduler.SetTimeout(@this, 'CheckForVote', 0.0f, NORMAL_SCHEDULED);
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		if (pActivator.IsPlayer())
		{
			DoVote(cast<CBasePlayer>(pActivator));
		}
		else if (pActivator.GetClassname() == 'point_checkpoint')
		{
			if (useType == USE_SET)
				UpdateRespawnPoints(pActivator.pev.vuser3);
			else
				RemoveCheckpoint(pActivator);
		}
	}

	bool InVote() { return m_flNextVote > g_Engine.time && m_pVoteResults !is null; }

	bool IsEnabled() { return g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsActive(); }

	void ResetResultSchedule()
	{
		g_Scheduler.RemoveTimer(m_pVoteResults);
		@m_pVoteResults = @null;
	}

	void ResetCheckSchedule()
	{
		g_Scheduler.RemoveTimer(m_pCheckForVote);
		@m_pCheckForVote = @null;
	}

	void ResetSchedulers()
	{
		ResetResultSchedule();
		ResetCheckSchedule();
	}

	bool OnPlayerCommand(CBasePlayer@ pPlayer, string szCommand)
	{
		if (!IsEnabled() || SavedCheckpoints() == 0)
		{
			g_PlayerFuncs.ClientPrint(
				pPlayer, 
				HUD_PRINTTALK, 
				str(IsEnabled() ? g_szNoCheckpoints : g_szNoSurvival, {{'!checkpoint', g_szCheckpointName}}) + '\n'
			);
			return false;
		}

		if (szCommand == 'cp')
		{
			DoVote(pPlayer);
		}
		else if (szCommand == 'forcecp' && g_Util.IsAdmin(pPlayer))
		{
			ActivateCheckpoint(pPlayer, NOTIFY_ACTIVATION);
			return true;
		}
		else if (szCommand == 'cancelcp' && g_Util.IsAdmin(pPlayer))
		{
			if (InVote())
			{
				ResetResultSchedule();
				m_flNextVote = g_Engine.time + 15.0f;
				g_Game.AlertMessage(at_logged, 'AUTO-CHECKPOINT: Vote cancelled by "%1".\n', pPlayer.pev.netname);
				g_PlayerFuncs.ClientPrintAll(
					HUD_PRINTTALK, 
					str(g_szAdminCancelsVote, {{'!checkpoint', g_szCheckpointName}, {'!player', '' + pPlayer.pev.netname}}) + '\n'
				);
			}
			else
				g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, str(g_szNoVoteToCancel, {{'!checkpoint', g_szCheckpointName}}) + '\n');

			return true;
		}
		else if (szCommand == 'yes' || szCommand == 'no')
		{
			bool bInFavor = szCommand == 'yes';
			if (InVote() && g_SimpleVote.HandleVote(pPlayer, bInFavor ? VOTE_IN_FAVOR : VOTE_AGAINST)) {
				g_Game.AlertMessage(at_logged, 'AUTO-CHECKPOINT: "%1" voted "%2".\n', pPlayer.pev.netname, szCommand);
				g_PlayerFuncs.ClientPrintAll(
					HUD_PRINTTALK, 
					str(bInFavor ? g_szVotedFor : g_szVotedAgainst, {{'!checkpoint', g_szCheckpointName}, {'!player', '' + pPlayer.pev.netname}}) + '\n'
				);
				return true;
			}
		}
		return false;
	}

	void OnPlayerDeath(bool bAttemptingToReviveAnotherPlayer)
	{
		if (!IsEnabled() || SavedCheckpoints() == 0)
			return;

		if (g_Util.AlivePlayersCount() != 0)
		{
			CheckForVote();
			return;
		}

		ResetCheckSchedule();

		if (m_flNextActivation > g_Engine.time)
		{
			float flDelay = m_flNextActivation - g_Engine.time;
			float flCompesation = flDelay < 0.5f && bAttemptingToReviveAnotherPlayer ? 0.5f - flDelay : 0.0f;
			@m_pCheckForVote = g_Scheduler.SetTimeout(@this, 'CheckForVote', flDelay + flCompesation, SPAWNKILL_SCHEDULED);
		}
		else if (bAttemptingToReviveAnotherPlayer)
		{
			@m_pCheckForVote = g_Scheduler.SetTimeout(@this, 'CheckForVote', 0.5f, NORMAL_SCHEDULED);
		}
		else
			CheckForVote();
	}

	void CheckForVote(int type = 0)
	{
		if (type != 0)
			ResetCheckSchedule();

		if (type == SPAWNKILL_SCHEDULED)
			g_bScareNearEnemies = true;

		bool bCanVote = g_Engine.time > m_flNextVote;
		int iAliveCount = g_Util.AlivePlayersCount();
		int iNumPlayers = g_PlayerFuncs.GetNumPlayers();

		if (iAliveCount == iNumPlayers)
			return;

		if (iAliveCount == 0)
		{
			ActivateCheckpoint(self, NOTIFY_ACTIVATION | AUTO_ACTIVATION);
			return;
		}

		if (iNumPlayers > 2)
		{
			float flAliveRequired = iNumPlayers * 0.34f;
			int iAliveRequired = int(fraction(flAliveRequired) >= 0.5f ? ceil(flAliveRequired) : floor(flAliveRequired));
			bCanVote = iAliveCount <= iAliveRequired && bCanVote;
		}

		if (bCanVote)
			DoVote();
	}

	void DoVote(CBasePlayer@ pPlayer = null)
	{
		if (m_pVoteResults !is null)
		{
			if (pPlayer !is null)
				g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, str(g_szVoteInProgress, {{'!checkpoint', g_szCheckpointName}}) + '\n');
			return;
		}

		if (m_flNextVote > g_Engine.time)
		{
			if (pPlayer !is null)
				g_PlayerFuncs.ClientPrint(
					pPlayer, 
					HUD_PRINTTALK, 
					str(g_szWaitForVote, {{'!checkpoint', g_szCheckpointName}, {'!delay', formatFloat(m_flNextVote - g_Engine.time, precision: 3)}}) + '\n'
				);
			return;
		}

		ResetResultSchedule();
		g_SimpleVote.StartVote();
		m_flNextVote = g_Engine.time + 50.0f;
		@m_pVoteResults = g_Scheduler.SetTimeout(@this, 'VoteResults', 20.0f);
		g_Game.AlertMessage(at_logged, 'AUTO-CHECKPOINT: "%1" started a vote.\n', pPlayer is null ? pev.targetname : pPlayer.pev.netname);
		g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, str(g_szVoteStarted, {{'!checkpoint', g_szCheckpointName}}) + '\n');
	}

	void VoteResults()
	{
		bool bHaveCheckpoint = SavedCheckpoints() != 0;
		bool bAllPlayersAlive = g_Util.AlivePlayersCount() == g_PlayerFuncs.GetNumPlayers();

		if (!bHaveCheckpoint || bAllPlayersAlive)
		{
			ResetResultSchedule();
			g_Game.AlertMessage(
				at_logged, 
				'AUTO-CHECKPOINT: Omitting vote results, reason: "%1".\n', 
				bAllPlayersAlive ? 'All players alive' : 'No Checkpoints'
			);
			g_PlayerFuncs.ClientPrintAll(
				HUD_PRINTTALK, 
				str(bAllPlayersAlive ? g_szAllAlive : g_szNoCheckpoints, {{'!checkpoint', g_szCheckpointName}}) + '\n'
			);
			return;
		}

		bool bCanActivate;
		int iInFavor, iAgainst, iRequired;
		bool bGotResult = g_SimpleVote.VoteResults(iInFavor, iAgainst, iRequired, bCanActivate);

		g_Game.AlertMessage(
			at_logged, 
			'AUTO-CHECKPOINT: Vote finished, result: "%1". (%2)\n', 
			bCanActivate ? 'succeded' : 'failed', 
			bGotResult ? 'No one voted' : 'Got: "' + iInFavor + '", needed: "' + iRequired + '"'
		);
		g_PlayerFuncs.ClientPrintAll(
			HUD_PRINTTALK, 
			str(
				bGotResult ? g_szVoteResult : g_szNoOneVoted, 
				{{'!checkpoint', g_szCheckpointName}, 
				{'!result', str(bCanActivate ? g_szVoteSuccess : g_szVoteFailed, {{'!checkpoint', g_szCheckpointName}})}, 
				{'!infavor', '' + iInFavor}, 
				{'!required', '' + iRequired}}
			) + '\n'
		);

		if (bCanActivate)
			ActivateCheckpoint(self);
	}

	void ActivateCheckpoint(CBaseEntity@ pCaller, int flags = 0)
	{
		if (InVote() && (flags & NOTIFY_ACTIVATION) != 0)
		{
			g_Game.AlertMessage(at_logged, 'AUTO-CHECKPOINT: Vote cancelled, reason: "%1".\n', pCaller.IsPlayer() ? 'forced' : 'all players dead');
			g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, str(g_szVoteCanceled, {{'!checkpoint', g_szCheckpointName}}) + '\n');
		}

		ResetSchedulers();
		CBaseEntity@ pCheckpoint = null;
		for (uint i = 0; i < m_rghCheckpoints.length(); i++)
		{
			if ((@pCheckpoint = m_rghCheckpoints[i]) !is null && pCheckpoint.pev.frags == 0.0f)
			{
				m_rghCheckpoints.removeAt(i);
				pev.iuser1 = SavedCheckpoints();
				pCheckpoint.Use(self, pCaller, (flags & AUTO_ACTIVATION) != 0 ? USE_TOGGLE : USE_ON, 0.0f);
				m_flNextActivation = g_Engine.time + pCheckpoint.pev.fuser1 + 1.0f;
				break;
			}
		}
	}

	// EHandle has no opEquals/opCmp method
	int FindCheckpointIndex(CBaseEntity@ pEntity)
	{
		for (uint i = 0; i < m_rghCheckpoints.length(); i++)
		{
			if (m_rghCheckpoints[i] && pEntity is m_rghCheckpoints[i])
				return i;
		}
		return -1;
	}

	void RemoveCheckpoint(CBaseEntity@ pEntity)
	{
		const int iIndex = FindCheckpointIndex(pEntity);
		if (iIndex != -1)
			m_rghCheckpoints.removeAt(iIndex);
	}

	void UpdateRespawnPoints(Vector vecPos)
	{
		CBaseEntity@ pCheckpoint = null;
		for (uint i = 0; i < m_rghCheckpoints.length(); i++)
		{
			if ((@pCheckpoint = m_rghCheckpoints[i]) !is null)
				pCheckpoint.pev.vuser3 = vecPos;
		}

		g_EntityFuncs.SetOrigin(self, vecPos);
		g_EngineFuncs.DropToFloor(self.edict());
	}

	void UpdateOnRemove()
	{
		ResetSchedulers();
		CBaseEntity@ pCheckpoint = null;
		for (uint i = 0; i < m_rghCheckpoints.length(); i++)
		{
			if ((@pCheckpoint = m_rghCheckpoints[i]) !is null && pCheckpoint.pev.frags == 0.0f)
				pCheckpoint.Use(self, self, USE_OFF, 0.0f);
		}

		m_rghCheckpoints.resize(0);
		if (g_hAutoCheckpoint && !m_fDuplicate)
		{
			g_Game.AlertMessage(at_logged, 'AUTO-CHECKPOINT: Disabled.\n');
			g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, 'Auto-Checkpoint disabled!\n');
		}
	}
}

HookReturnCode PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@, int)
{
	if (!g_hAutoCheckpoint)
		return HOOK_CONTINUE;

	bool bHoldingMouse2 = pPlayer.m_afButtonLast & IN_ATTACK2 != 0 || pPlayer.m_afButtonPressed & IN_ATTACK2 != 0;
	bool bMedkitInHand = pPlayer.m_hActiveItem ? pPlayer.m_hActiveItem.GetEntity().GetClassname() == 'weapon_medkit' : false;

	auto_checkpoint@ ent = cast<auto_checkpoint>(CastToScriptClass(g_hAutoCheckpoint));
	g_Scheduler.SetTimeout(@ent, 'OnPlayerDeath', 0.0f, bHoldingMouse2 && bMedkitInHand);
	return HOOK_CONTINUE;
}

HookReturnCode ClientSay(SayParameters@ pParams)
{
	CBasePlayer@ pPlayer = pParams.GetPlayer();
	const CCommand@ args = pParams.GetArguments();

	if (!Regex::Match(args[0], g_pChatCommands))
		return HOOK_CONTINUE;

	if (args.ArgC() > 1)
		return HOOK_CONTINUE;

	if (!g_hAutoCheckpoint)
	{
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, 'Auto-Checkpoint isn\'t available.\n');
		return HOOK_CONTINUE;
	}

	auto_checkpoint@ ent = cast<auto_checkpoint>(CastToScriptClass(g_hAutoCheckpoint));
	pParams.ShouldHide = ent.OnPlayerCommand(pPlayer, args[0].SubString(1));
	return HOOK_CONTINUE;
}

void Register()
{
	LoadCustomCallbacks();

	g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
	g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @PlayerKilled);

	if (!g_CustomEntityFuncs.IsCustomEntity('auto_checkpoint'))
		g_CustomEntityFuncs.RegisterCustomEntity('auto_checkpoint::auto_checkpoint', 'auto_checkpoint');
}

}
