#include <amxmodx>
#include <zombieplague>
#include <fun>

new g_itemid_hp2000
new g_hp2000_used[33]

public plugin_init()
{
	register_plugin("[ZP] Extra Item: +2000 HP", "1.0", "ketamine")
	register_dictionary("zp_extra_hp_1000.txt")
}

public plugin_precache()
{
	// Register extra item directly (will be overridden by .ini if it exists there)
	g_itemid_hp2000 = zp_register_extra_item("+2000 HP", 50, ZP_TEAM_ZOMBIE)
	
	precache_generic("sound/epic_zombie/zm_buyhealth.wav")
	
	// Debug log
	if (g_itemid_hp2000 == -1)
		log_amx("[ZP +2000 HP] ERROR: Failed to register extra item!")
	else
		log_amx("[ZP +2000 HP] Successfully registered with item ID: %d", g_itemid_hp2000)
}

public client_putinserver(id)
{
	g_hp2000_used[id] = 0
}

public client_disconnected(id)
{
	g_hp2000_used[id] = 0
}

public zp_user_humanized_post(id)
{
	g_hp2000_used[id] = 0
}

public zp_user_infected_post(id, infector)
{
	g_hp2000_used[id] = 0
}

public zp_extra_item_selected(id, itemid)
{
	if (itemid != g_itemid_hp2000)
		return PLUGIN_CONTINUE

	if (g_hp2000_used[id] >= 5)
	{
		client_print(id, print_chat, "[ZP] %L", id, "HP_LIMIT_REACHED")
		return ZP_PLUGIN_HANDLED 
	}
	
	g_hp2000_used[id]++
	
	new current_hp = get_user_health(id)
	new new_hp = current_hp + 1000
	set_user_health(id, new_hp)

	
	return PLUGIN_CONTINUE
}
