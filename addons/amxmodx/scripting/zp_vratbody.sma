#include <amxmodx>
#include <zombieplague>
#include <cstrike>

#define PLUGIN "[ZP] Vrat Body"
#define VERSION "1.0"
#define AUTHOR "ketamine"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /vratbody", "cmd_vratbody")
	register_clcmd("say_team /vratbody", "cmd_vratbody")
}

public cmd_vratbody(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	
	// Pridaj 16000 money
	cs_set_user_money(id, cs_get_user_money(id) + 16000)
	
	// Pridaj 500 ammo packs
	new current_ap = zp_get_user_ammo_packs(id)
	zp_set_user_ammo_packs(id, current_ap + 500)
	
	// Pridaj 500 spirits
	new current_spirits = zp_get_user_spirits(id)
	zp_set_user_spirits(id, current_spirits + 500)
	
	// Zobraz spravu
	client_print(id, print_chat, "[ZP] Dostali ste +16000$ +500 Ammo Packs a +500 Spirits!")
	
	return PLUGIN_HANDLED
}
