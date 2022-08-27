#include '../structure/main'

CallbackHandler@ g_pAoMCallbacks = CallbackHandler(
	maps: 'aom_;aomdc_', 
	activateFX: function(CBaseAnimating@ checkpoint)
	{
		checkpoint.pev.renderfx = kRenderFxNone;
		checkpoint.pev.effects |= EF_NODRAW;
		return true;
	}, 
	saveFX: function(CBaseAnimating@ checkpoint)
	{
		checkpoint.pev.renderamt = 128.0f;
		checkpoint.pev.renderfx = kRenderFxDistort;
		return true;
	}, 
	resetFX: function(CBaseAnimating@ checkpoint)
	{
		checkpoint.pev.renderamt = 255.0f;
		checkpoint.pev.renderfx = kRenderFxNone;
		return true;
	}, 
	holdFX: null // No effect
);

