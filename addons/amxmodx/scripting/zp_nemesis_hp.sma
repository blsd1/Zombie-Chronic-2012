#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <engine>
#include <fun>
#include <dhudmessage>
#include <csx>
#include <nvault>
#include <zombieplague>

#define PLUGIN_NAME "[ZP] Nemesis Health Reminder"
#define PLUGIN_VERS "1.0"
#define PLUGIN_AUTH "zmd94"

#define TASK_HEALTH 95000

#define HOLD_TIME     2.0

const Float:HUD_MODE_X = -1.0
const Float:HUD_MODE_Y = 0.0
const Float:START_TIME = 1.0

new g_maxplayers

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH)
	
	// Fwd's
	RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "Fwd_PlayerKilled_Pre", 0)
	register_logevent("endRound", 2, "1=Round_End")
}

public Fwd_PlayerSpawn_Post(id)
{
	if (task_exists(id+TASK_HEALTH))
		remove_task(id+TASK_HEALTH)
}

public Fwd_PlayerKilled_Pre(victim, attacker, shouldgib)
{
	if (task_exists(victim+TASK_HEALTH))
		remove_task(victim+TASK_HEALTH)
}

public endRound()
{
for (new i = 1; i <= g_maxplayers; i++)
{
remove_task(i+TASK_HEALTH)
remove_task(0);
}
}

public zp_round_started(mode, id)
{
	if (mode != MODE_NEMESIS)
		return
		
	if (!zp_get_user_nemesis(id))
		return
		
	set_task(START_TIME, "Task_ShowHealth", id+TASK_HEALTH, _, _, "b") 
}

public Task_ShowHealth(id)
{
	id -= TASK_HEALTH
	
	if (!zp_get_user_nemesis(id))
		remove_task(id+TASK_HEALTH)
	
	set_dhudmessage(255, 0, 100, HUD_MODE_X, HUD_MODE_Y, 0, 0.0, 0.9, 0.1, 0.2, true);
	show_dhudmessage( 0, "^n^nNemesis HP: %i", get_user_health(id))
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
