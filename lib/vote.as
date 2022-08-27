SimpleVoteSystem g_SimpleVote;

enum VoteChoice
{
	VOTE_AGAINST = -1,
	VOTE_NULL = 0,
	VOTE_IN_FAVOR = 1,
};

class SimpleVoteSystem
{
	// Store player list and vote according to their id
	private dictionary m_dicVotes;

	void StartVote()
	{
		m_dicVotes.deleteAll();
		CBasePlayer@ pVoter = null;
		for (int i = 1; i <= g_PlayerFuncs.GetNumPlayers(); i++)
		{
			if ((@pVoter = g_PlayerFuncs.FindPlayerByIndex(i)) !is null && pVoter.IsConnected())
				m_dicVotes[g_EngineFuncs.GetPlayerAuthId(pVoter.edict())] = VOTE_NULL;
		}
	}

	bool HandleVote(CBasePlayer@ pPlayer, int iChoice)
	{
		string szAuthID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

		if (!m_dicVotes.exists(szAuthID))
		{
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "You're not on the voting list.\n");
			return false;
		}

		if (int(m_dicVotes[szAuthID]) != VOTE_NULL)
		{
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, 'You alredy voted.\n');
			return false;
		}

		m_dicVotes[szAuthID] = iChoice;
		return true;
	}

	bool VoteResults(int& out iInFavor, int& out iAgainst, int& out iRequired, bool& out bPassed)
	{
		iInFavor = 0; iAgainst = 0; iRequired = 0; bPassed = false;

		int choice = -1;
		string[] @voters = m_dicVotes.getKeys();
		for (uint i = 0; i < voters.length(); i++)
		{
			if ((choice = int(m_dicVotes[voters[i]])) != VOTE_NULL)
				choice == VOTE_IN_FAVOR ? ++iInFavor : ++iAgainst;
		}

		m_dicVotes.deleteAll();
		int iTotal = iInFavor + iAgainst;
		if (iTotal != 0)
		{
			iRequired = int(ceil(iTotal * 0.65f));
			bPassed = iInFavor / float(iTotal) >= 0.65f;
			return true;
		}
		return false;
	}
}
