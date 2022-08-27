Util g_Util;

class Util
{
	int AlivePlayersCount()
	{
		int iCount = 0;
		CBasePlayer@ pPlayer;
		for (int i = 1; i <= g_PlayerFuncs.GetNumPlayers(); i++)
		{
			if ((@pPlayer = g_PlayerFuncs.FindPlayerByIndex(i)) !is null && pPlayer.IsConnected() && pPlayer.IsAlive())
				++iCount;
		}
		return iCount;
	}

	bool IsAdmin(CBasePlayer@ pPlayer)
	{
		if (g_PlayerFuncs.AdminLevel(pPlayer) < ADMIN_YES)
		{
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "You don't have access to this command.\n");
			return false;
		}
		return true;
	}
}
