#include 'default'

funcdef bool CommonEventCallback(CBaseAnimating@);
funcdef bool RespawnStartCallback(CBaseAnimating@, CSprite@);
funcdef bool PlayerRespawnCallback(CBaseAnimating@, CBasePlayer@, bool);
funcdef float[][] HoldTimersCallback();

class CallbackHandler
{
	//
	private string[]               m_rgsMaps;
	//
	private CommonEventCallback@   m_fnSpawnEffect;
	private CommonEventCallback@   m_fnOnSpawn;
	private CommonEventCallback@   m_fnOnIdle;
	private CommonEventCallback@   m_fnOnSave;
	private CommonEventCallback@   m_fnSaveEffect;
	private CommonEventCallback@   m_fnOnActivate;
	private CommonEventCallback@   m_fnActivateEffect;
	private RespawnStartCallback@  m_fnOnRespawnStart;
	private PlayerRespawnCallback@ m_fnOnRespawn;
	private CommonEventCallback@   m_fnOnReenable;
	private CommonEventCallback@   m_fnResetEffect;
	//
	private HoldTimersCallback@   m_fnHoldTimers;
	private CommonEventCallback@   m_fnHoldEffect;

	CallbackHandler(
		const string& in       maps           = '%&$#?@!', 
		//
		CommonEventCallback@   spawnFX        = @DefaultCallbacks::SpawnEffect, 
		CommonEventCallback@   onSpawn        = null, 
		CommonEventCallback@   onIdle         = null, 
		CommonEventCallback@   onSave         = @DefaultCallbacks::OnSave, 
		CommonEventCallback@   saveFX         = @DefaultCallbacks::SaveEffect, 
		CommonEventCallback@   onActivate     = @DefaultCallbacks::OnActivate, 
		CommonEventCallback@   activateFX     = @DefaultCallbacks::ActivateEffect, 
		RespawnStartCallback@  onRespawnStart = null, 
		PlayerRespawnCallback@ onRespawn      = null, // @DefaultCallbacks::OnRespawn, 
		CommonEventCallback@   onReenable     = null, 
		CommonEventCallback@   resetFX        = @DefaultCallbacks::ResetEffect, 
		//
		HoldTimersCallback@    holdTimers     = @DefaultCallbacks::HoldTimers, 
		CommonEventCallback@   holdFX         = @DefaultCallbacks::HoldEffect
	)
	{
		m_rgsMaps           = maps.Split(';');
		//
		@m_fnSpawnEffect    = @spawnFX;
		@m_fnOnSpawn        = @onSpawn;
		@m_fnOnIdle         = @onIdle;
		@m_fnOnSave         = @onSave;
		@m_fnSaveEffect     = @saveFX;
		@m_fnOnActivate     = @onActivate;
		@m_fnActivateEffect = @activateFX;
		@m_fnOnRespawnStart = @onRespawnStart;
		@m_fnOnRespawn      = @onRespawn;
		@m_fnOnReenable     = @onReenable;
		@m_fnResetEffect    = @resetFX;
		//
		@m_fnHoldTimers     = @holdTimers;
		@m_fnHoldEffect     = @holdFX;
	}

	bool CanUse(string szMapname)
	{
		szMapname.ToLowercase();
		for (uint i = 0; i < m_rgsMaps.length(); i++)
		{
			if (szMapname.Find(m_rgsMaps[i].ToLowercase()) == 0)
				return true;
		}
		return false;
	}

	void SpawnEffect(CBaseAnimating@ pCheckpoint)
	{
		if (m_fnSpawnEffect is null)
			return;
		m_fnSpawnEffect(@pCheckpoint);
	}

	void OnSpawn(CBaseAnimating@ pCheckpoint)
	{
		if (m_fnOnSpawn is null)
			return;
		m_fnOnSpawn(@pCheckpoint);
	}

	void OnIdle(CBaseAnimating@ pCheckpoint)
	{
		if (m_fnOnIdle is null)
			return;
		m_fnOnIdle(@pCheckpoint);
	}

	void OnSave(CBaseAnimating@ pCheckpoint)
	{
		if (m_fnOnSave is null)
			return;
		m_fnOnSave(@pCheckpoint);
	}

	bool SaveEffect(CBaseAnimating@ pCheckpoint)
	{
		if (m_fnSaveEffect is null)
			return true;
		return m_fnSaveEffect(@pCheckpoint);
	}

	void OnActivate(CBaseAnimating@ pCheckpoint)
	{
		if (m_fnOnActivate is null)
			return;
		m_fnOnActivate(@pCheckpoint);
	}

	bool ActivateEffect(CBaseAnimating@ pCheckpoint)
	{
		if (m_fnActivateEffect is null)
			return true;
		return m_fnActivateEffect(@pCheckpoint);
	}

	void OnRespawnStart(CBaseAnimating@ pCheckpoint, CSprite@ pSprite)
	{
		if (m_fnOnRespawnStart is null)
			return;
		m_fnOnRespawnStart(@pCheckpoint, @pSprite);
	}

	void OnRespawn(CBaseAnimating@ pCheckpoint, CBasePlayer@ pPlayer, bool bLastToRespawn)
	{
		if (m_fnOnRespawn is null)
			return;
		m_fnOnRespawn(@pCheckpoint, @pPlayer, bLastToRespawn);
	}

	void OnReenable(CBaseAnimating@ pCheckpoint)
	{
		if (m_fnOnReenable is null)
			return;
		m_fnOnReenable(@pCheckpoint);
	}

	bool ResetEffect(CBaseAnimating@ pCheckpoint)
	{
		if (m_fnResetEffect is null)
			return true;
		return m_fnResetEffect(@pCheckpoint);
	}

	float[][] HoldTimers()
	{
		if (m_fnHoldTimers is null)
			return float[][]();
		return m_fnHoldTimers();
	}

	void HoldEffect(CBaseAnimating@ pAutoCheckpoint)
	{
		if (m_fnHoldEffect is null)
			return;
		m_fnHoldEffect(@pAutoCheckpoint);
	}
}
