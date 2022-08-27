#include 'maps/_'

bool g_bCustomCallbacksLoaded = false;
void LoadCustomCallbacks()
{
	if (g_bCustomCallbacksLoaded)
		return;

	g_bCustomCallbacksLoaded = true;
	for (uint i = 0; i < g_pCustomCallbacks.length(); i++)
	{
		if (g_pCustomCallbacks[i] !is null && g_pCustomCallbacks[i].CanUse(g_Engine.mapname))
		{
			@g_pCallbacks = @g_pCustomCallbacks[i];
			g_Game.AlertMessage(at_console, 'CHKPNT: Loading custom callbacks for %1!\n', g_Engine.mapname);
			break;
		}
	}
}
