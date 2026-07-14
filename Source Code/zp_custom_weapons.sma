#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <fun>
#include <zombieplague>

#define PLUGIN "[ZP] Custom Weapons"
#define VERSION "1.0"
#define AUTHOR "ketamine"

#define MAX_WEAPONS 32

new g_weapon_count
new g_weapon_names[MAX_WEAPONS][64]
new g_weapon_costs[MAX_WEAPONS]
new g_weapon_teams[MAX_WEAPONS] // 1 = Zombie, 2 = Human, 3 = Both

new g_fwBought

// Classic weapons IDs
new g_weapon_m4a1, g_weapon_ak47
new g_weapon_deagle, g_weapon_usp, g_weapon_glock , g_weapon_fiveseven, g_weapon_elite

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /guns", "cmd_weapons_menu")
	register_clcmd("say_team /guns", "cmd_weapons_menu")
	register_clcmd("say /zbrane", "cmd_weapons_menu")
	register_clcmd("say_team /zbrane", "cmd_weapons_menu")
	
	g_fwBought = CreateMultiForward("zp_custom_weapon_bought", ET_CONTINUE, FP_CELL, FP_CELL)
	
	// Register classic weapons for FREE (in init to be first)
	g_weapon_m4a1 = native_register_weapon_internal("M4A1", 0, 2)
	// AK-47 Legend will be registered here (position 2) from azp_weapon_ak47l.sma
	g_weapon_ak47 = native_register_weapon_internal("AK-47", 0, 2)
	g_weapon_deagle = native_register_weapon_internal("Desert Eagle", 0, 2)
	g_weapon_usp = native_register_weapon_internal("USP", 0, 2)
	g_weapon_glock = native_register_weapon_internal("Glock", 0, 2)
	g_weapon_fiveseven = native_register_weapon_internal("Five-SeveN", 0, 2)
	g_weapon_elite = native_register_weapon_internal("Dual Elites", 0, 2)
}

public plugin_cfg()
{
	// Nothing here - weapons registered in plugin_init
}

public plugin_natives()
{
	register_native("zp_register_custom_weapon", "native_register_weapon")
	register_native("zp_give_custom_weapon", "native_give_weapon")
	register_native("zp_get_custom_weapons_count", "native_get_weapons_count")
	register_native("zp_get_custom_weapon_name", "native_get_weapon_name")
	register_native("zp_get_custom_weapon_cost", "native_get_weapon_cost")
	register_native("zp_get_custom_weapon_team", "native_get_weapon_team")
}

public native_register_weapon(plugin_id, num_params)
{
	new name[64]
	get_string(1, name, charsmax(name))
	
	new cost = get_param(2)
	new team = get_param(3)
	
	return native_register_weapon_internal(name, cost, team)
}

native_register_weapon_internal(const name[], cost, team)
{
	if (g_weapon_count >= MAX_WEAPONS)
	{
		log_error(AMX_ERR_NATIVE, "[ZP Weapons] Maximum weapons limit reached (%d)", MAX_WEAPONS)
		return -1
	}
	
	new id = g_weapon_count
	copy(g_weapon_names[id], charsmax(g_weapon_names[]), name)
	g_weapon_costs[id] = cost
	g_weapon_teams[id] = team
	
	g_weapon_count++
	
	return id
}

public native_give_weapon(plugin_id, num_params)
{
	new id = get_param(1)
	new weapon_id = get_param(2)
	
	if (!is_user_connected(id))
		return false
	
	if (weapon_id < 0 || weapon_id >= g_weapon_count)
		return false
	
	// Call forward
	new ret
	ExecuteForward(g_fwBought, ret, id, weapon_id)
	
	return true
}

public native_get_weapons_count()
{
	return g_weapon_count
}

public native_get_weapon_name(plugin_id, num_params)
{
	new weapon_id = get_param(1)
	
	if (weapon_id < 0 || weapon_id >= g_weapon_count)
		return false
	
	set_string(2, g_weapon_names[weapon_id], get_param(3))
	return true
}

public native_get_weapon_cost(plugin_id, num_params)
{
	new weapon_id = get_param(1)
	
	if (weapon_id < 0 || weapon_id >= g_weapon_count)
		return -1
	
	return g_weapon_costs[weapon_id]
}

public native_get_weapon_team(plugin_id, num_params)
{
	new weapon_id = get_param(1)
	
	if (weapon_id < 0 || weapon_id >= g_weapon_count)
		return -1
	
	return g_weapon_teams[weapon_id]
}

public cmd_weapons_menu(id)
{
	if (!is_user_alive(id))
	{
		client_print(id, print_chat, "[ZP] Musite byt nazivu!")
		return PLUGIN_HANDLED
	}
	
	show_weapons_menu(id, 0)
	
	return PLUGIN_HANDLED
}

show_weapons_menu(id, page)
{
	if (g_weapon_count == 0)
	{
		client_print(id, print_chat, "[ZP] Ziadne custom zbrane nie su zaregistrovane!")
		return
	}
	
	new menu = menu_create("\yVyber Primarnej zbrani", "weapons_menu_handler")
	
	new is_zombie = zp_get_user_zombie(id)
	new player_money = cs_get_user_money(id)
	
	new item_text[128], weapon_name[64], cost, team
	for (new i = 0; i < g_weapon_count; i++)
	{
		// Skip secondary weapons in primary menu
		if (i == g_weapon_deagle || i == g_weapon_usp || i == g_weapon_glock || i == g_weapon_fiveseven || i == g_weapon_elite)
			continue
		
		copy(weapon_name, charsmax(weapon_name), g_weapon_names[i])
		cost = g_weapon_costs[i]
		team = g_weapon_teams[i]
		
		// Check team restriction
		new can_buy = false
		if (team == 3) // Both teams
			can_buy = true
		else if (team == 1 && is_zombie) // Zombies only
			can_buy = true
		else if (team == 2 && !is_zombie) // Humans only
			can_buy = true
		
		if (!can_buy)
			continue
		
		// Show FREE weapons in white, paid weapons in yellow
		if (cost == 0)
			formatex(item_text, charsmax(item_text), "\w%s", weapon_name)
		else
			formatex(item_text, charsmax(item_text), "\y%s  \r$%d", weapon_name, cost)
		
		new callback = menu_makecallback("weapons_menu_callback")
		menu_additem(menu, item_text, fmt("%d", i), 0, callback)
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Zatvorit")
	menu_setprop(menu, MPROP_BACKNAME, "Spat")
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej")
	
	menu_display(id, menu, page)
}

public weapons_menu_callback(id, menu, item)
{
	new data[16], name[64], access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback)
	
	new weapon_id = str_to_num(data)
	new cost = g_weapon_costs[weapon_id]
	new player_money = cs_get_user_money(id)
	
	if (player_money < cost)
		return ITEM_DISABLED
	
	return ITEM_ENABLED
}

public weapons_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new data[16], name[64], access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback)
	
	new weapon_id = str_to_num(data)
	new cost = g_weapon_costs[weapon_id]
	new player_money = cs_get_user_money(id)
	
	if (player_money < cost)
	{
		client_print(id, print_chat, "[ZP] Nemate dostatok penazi! Potrebujete $%d", cost)
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	// Take money (only if cost > 0)
	if (cost > 0)
	{
		cs_set_user_money(id, player_money - cost)
		client_print(id, print_chat, "[ZP] Kupili ste %s za $%d", g_weapon_names[weapon_id], cost)
	}
	else
	{
		client_print(id, print_chat, "[ZP] Dostali ste %s zadarmo!", g_weapon_names[weapon_id])
	}
	
	// Handle classic weapons directly
	if (weapon_id == g_weapon_m4a1 || weapon_id == g_weapon_ak47)
	{
		// Give primary weapon
		if (weapon_id == g_weapon_m4a1)
			give_weapon(id, CSW_M4A1)
		else if (weapon_id == g_weapon_ak47)
			give_weapon(id, CSW_AK47)
		
		// Show secondary menu after 0.1 second
		menu_destroy(menu)
		set_task(0.1, "show_secondary_menu", id)
		return PLUGIN_HANDLED
	}
	else if (weapon_id == g_weapon_deagle || weapon_id == g_weapon_usp || weapon_id == g_weapon_glock || weapon_id == g_weapon_fiveseven || weapon_id == g_weapon_elite)
	{
		// Give secondary weapon
		if (weapon_id == g_weapon_deagle)
			give_weapon(id, CSW_DEAGLE)
		else if (weapon_id == g_weapon_usp)
			give_weapon(id, CSW_USP)
		else if (weapon_id == g_weapon_glock)
			give_weapon(id, CSW_GLOCK18)
		else if (weapon_id == g_weapon_fiveseven)
			give_weapon(id, CSW_FIVESEVEN)
		else if (weapon_id == g_weapon_elite)
			give_weapon(id, CSW_ELITE)
	}
	else
	{
		// Call forward for custom weapons
		new ret
		ExecuteForward(g_fwBought, ret, id, weapon_id)
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public show_secondary_menu(id)
{
	if (!is_user_alive(id))
		return
	
	new menu = menu_create("\yVyber Sekundarnej zbrani", "secondary_menu_handler")
	
	// All secondary weapons are FREE
	menu_additem(menu, "\wDesert Eagle", "0")
	menu_additem(menu, "\wUSP", "1")
	menu_additem(menu, "\wGlock", "2")
	menu_additem(menu, "\wFiveseveN", "3")
	menu_additem(menu, "\wElite duals", "4")
	
	menu_setprop(menu, MPROP_EXITNAME, "Zatvorit")
	menu_display(id, menu, 0)
}

public secondary_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new data[16], name[64], access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback)
	
	new choice = str_to_num(data)
	
	switch(choice)
	{
		case 0: give_weapon(id, CSW_DEAGLE)
		case 1: give_weapon(id, CSW_USP)
		case 2: give_weapon(id, CSW_GLOCK18)
		case 3: give_weapon(id, CSW_FIVESEVEN)
		case 4: give_weapon(id, CSW_ELITE)
	}
	
	client_print(id, print_chat, "[ZP] Dostali ste sekundarnu zbran zadarmo!")
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

give_weapon(id, csw_id)
{
	if (!is_user_alive(id))
		return
	
	new weapon_name[32]
	get_weaponname(csw_id, weapon_name, charsmax(weapon_name))
	
	// Drop current weapon of same type
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	
	for (new i = 0; i < num; i++)
	{
		// Primary weapons
		if (csw_id == CSW_M4A1 || csw_id == CSW_AK47)
		{
			if ((1<<weapons[i]) & ((1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)))
			{
				new drop_name[32]
				get_weaponname(weapons[i], drop_name, charsmax(drop_name))
				engclient_cmd(id, "drop", drop_name)
			}
		}
		// Secondary weapons
		else if (csw_id == CSW_DEAGLE || csw_id == CSW_USP || csw_id == CSW_GLOCK18 || csw_id == CSW_FIVESEVEN || csw_id == CSW_ELITE)
		{
			if ((1<<weapons[i]) & ((1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)))
			{
				new drop_name[32]
				get_weaponname(weapons[i], drop_name, charsmax(drop_name))
				engclient_cmd(id, "drop", drop_name)
			}
		}
	}
	
	// Give weapon
	give_item(id, weapon_name)
	
	// Set ammo
	switch(csw_id)
	{
		case CSW_M4A1: cs_set_user_bpammo(id, CSW_M4A1, 90)
		case CSW_AK47: cs_set_user_bpammo(id, CSW_AK47, 90)
		case CSW_DEAGLE: cs_set_user_bpammo(id, CSW_DEAGLE, 35)
		case CSW_USP: cs_set_user_bpammo(id, CSW_USP, 100)
		case CSW_GLOCK18: cs_set_user_bpammo(id, CSW_GLOCK18, 120)
		case CSW_FIVESEVEN: cs_set_user_bpammo(id, CSW_FIVESEVEN, 120)
		case CSW_ELITE: cs_set_user_bpammo(id, CSW_ELITE, 120)
	}
	
	// Give grenades for primary weapons
	if (csw_id == CSW_M4A1 || csw_id == CSW_AK47)
	{
		give_item(id, "weapon_hegrenade")
		give_item(id, "weapon_flashbang")
	}
}

public client_disconnected(id)
{
	remove_task(id)
}
