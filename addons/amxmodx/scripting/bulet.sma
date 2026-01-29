#include <amxmodx>

#define PLUGIN "Bullet Damage"
#define AUTHOR "ConnorMcLeod"
#define VERSION "0.0.1"

#define MAX_PLAYERS	32

new g_iMaxPlayers
new g_pCvarEnabled

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	g_pCvarEnabled = register_cvar("bullet_damage", "1")

	register_event("Damage", "Event_Damage", "b", "2>0", "3=0")

	g_iMaxPlayers = get_maxplayers()
}

public Event_Damage( iVictim )
{
	if( get_pcvar_num(g_pCvarEnabled) && (read_data(4) || read_data(5) || read_data(6)) )
	{
		new id = get_user_attacker(iVictim)
		if( (1 <= id <= g_iMaxPlayers) && is_user_connected(id) )
		{
			set_hudmessage(1, 253, 10, -1.0, 0.55, 0, 6.0, 1.0)
			show_hudmessage(id, "%d^n", read_data(2))
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1029\\ f0\\ fs16 \n\\ par }
*/
