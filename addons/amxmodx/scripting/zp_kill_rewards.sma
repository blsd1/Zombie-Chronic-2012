#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "ZP Kill Rewards"
#define VERSION "1.0"
#define AUTHOR "ketamine"

new g_body[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
}

public plugin_natives()
{
	register_native("zp_get_user_body", "native_get_user_body", 1)
	register_native("zp_set_user_body", "native_set_user_body", 1)
}

public client_connect(id)
{
	g_body[id] = 0
}

public client_disconnected(id)
{
	g_body[id] = 0
}

public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	if (!is_user_valid_connected(attacker) || victim == attacker)
		return HAM_IGNORED
	
	// Human zabije zombie alebo nemesisa - dostane 50 bodov
	if (!zp_get_user_zombie(attacker) && zp_get_user_zombie(victim))
	{
		g_body[attacker] += 50
		client_print(attacker, print_chat, "[ZP] +50 bodov za zabite zombie! (celkom: %d)", g_body[attacker])
	}
	
	return HAM_IGNORED
}

stock is_user_valid_connected(id)
{
	return (1 <= id <= 32 && is_user_connected(id))
}

// Native funkcie
public native_get_user_body(plugin, params)
{
	new id = get_param(1)
	if (!is_user_valid_connected(id))
		return 0
	return g_body[id]
}

public native_set_user_body(plugin, params)
{
	new id = get_param(1)
	new amount = get_param(2)
	
	if (!is_user_valid_connected(id))
		return 0
		
	g_body[id] = amount
	return g_body[id]
}
