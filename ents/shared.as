#include '../callbacks/loader'

// There are enemies near the checkpoint? (possible spawnkill) scare them away.
bool g_bScareNearEnemies = false;
// Share Checkpoint name (eg: Respawn-Point) with auto_checkpoint
string g_szCheckpointName = 'ERR_NO_NAME';

// Keep tracking of a single instance of auto_checkpoint
EHandle g_hAutoCheckpoint = EHandle(null);
CBaseEntity@ g_pAutoCheckpoint { get { return g_hAutoCheckpoint; } };

// Shared callbacks instance
CallbackHandler@ g_pCallbacks = CallbackHandler();

string str(const string& in szStr, dictionary@ pArgs)
{
	string str = szStr;
	string[] args = pArgs.getKeys();
	for (uint i = 0; i < args.length(); i++)
		str.Replace(args[i], string(pArgs[args[i]]));
	return str;
}