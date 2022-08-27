#include 'ents/point_checkpoint'
#include 'ents/auto_checkpoint'

namespace CHKPNT
{

void Register(string szTargetname = '')
{
	point_checkpoint::Register();
	auto_checkpoint::Register();

	g_EntityFuncs.CreateEntity('auto_checkpoint', {{'origin', '0 0 0'}, {'targetname', szTargetname}});
}

}

