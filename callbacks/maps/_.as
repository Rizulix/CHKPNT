#include 'aom'
#include 'hunger'
#include 'wanted'
// Include here your own Callback file, ex:
// #include "my_map"

CallbackHandler@[] g_pCustomCallbacks = {
	g_pAoMCallbacks, 
	g_pHungerCallbacks, 
	g_pWantedCallbacks, 
	// Add your Callback instance here, ex:
	// g_pMyMapCallbacks, 
};

