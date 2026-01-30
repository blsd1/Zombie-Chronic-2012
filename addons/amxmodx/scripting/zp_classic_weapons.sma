#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <zp_weapons>

#define PLUGIN "[ZP] Classic Weapons"
#define VERSION "1.0"
#define AUTHOR "ketamine"

new g_weapon_m4a1, g_weapon_ak47
new g_weapon_deagle, g_weapon_usp, g_weapon_glock

new g_bought_primary[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_cfg()
{
	// Register primary weapons
	g_weapon_m4a1 = zp_register_custom_weapon("M4A1", 3100, 2) // Humans only
	g_weapon_ak47 = zp_register_custom_weapon("AK-47", 2500, 2) // Humans only
	
	// Register secondary weapons
	g_weapon_deagle = zp_register_custom_weapon("Desert Eagle", 650, 2)
	g_weapon_usp = zp_register_custom_weapon("USP", 500, 2)
	g_weapon_glock = zp_register_custom_weapon("Glock", 400, 2)
}

public zp_custom_weapon_bought(id, weapon_id)
{
	// Check if it's a primary weapon
	if (weapon_id == g_weapon_m4a1)
	{
		give_weapon(id, CSW_M4A1)
		g_bought_primary[id] = 1
		
		// Show secondary menu after 0.1 second
		set_task(0.1, "show_secondary_menu", id)
	}
	else if (weapon_id == g_weapon_ak47)
	{
		give_weapon(id, CSW_AK47)
		g_bought_primary[id] = 1
		
		// Show secondary menu after 0.1 second
		set_task(0.1, "show_secondary_menu", id)
	}
	// Secondary weapons
	else if (weapon_id == g_weapon_deagle)
	{
		give_weapon(id, CSW_DEAGLE)
	}
	else if (weapon_id == g_weapon_usp)
	{
		give_weapon(id, CSW_USP)
	}
	else if (weapon_id == g_weapon_glock)
	{
		give_weapon(id, CSW_GLOCK18)
	}
}

public show_secondary_menu(id)
{
	if (!is_user_alive(id))
		return
	
	new menu = menu_create("\r[ZP] \wSecondary Zbrane", "secondary_menu_handler")
	
	new player_money = cs_get_user_money(id)
	new item_text[128]
	
	// Desert Eagle
	if (player_money >= 650)
		formatex(item_text, charsmax(item_text), "\wDesert Eagle \r[$650]")
	else
		formatex(item_text, charsmax(item_text), "\dDesert Eagle [$650]")
	menu_additem(menu, item_text, "0")
	
	// USP
	if (player_money >= 500)
		formatex(item_text, charsmax(item_text), "\wUSP \r[$500]")
	else
		formatex(item_text, charsmax(item_text), "\dUSP [$500]")
	menu_additem(menu, item_text, "1")
	
	// Glock
	if (player_money >= 400)
		formatex(item_text, charsmax(item_text), "\wGlock \r[$400]")
	else
		formatex(item_text, charsmax(item_text), "\dGlock [$400]")
	menu_additem(menu, item_text, "2")
	
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
	new player_money = cs_get_user_money(id)
	new cost = 0
	new weapon_csw = 0
	
	switch(choice)
	{
		case 0: // Desert Eagle
		{
			cost = 650
			weapon_csw = CSW_DEAGLE
		}
		case 1: // USP
		{
			cost = 500
			weapon_csw = CSW_USP
		}
		case 2: // Glock
		{
			cost = 400
			weapon_csw = CSW_GLOCK18
		}
	}
	
	if (player_money < cost)
	{
		client_print(id, print_chat, "[ZP] Nemate dostatok penazi! Potrebujete $%d", cost)
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	// Take money and give weapon
	cs_set_user_money(id, player_money - cost)
	give_weapon(id, weapon_csw)
	
	client_print(id, print_chat, "[ZP] Kupili ste sekundarnu zbran za $%d", cost)
	
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
		else if (csw_id == CSW_DEAGLE || csw_id == CSW_USP || csw_id == CSW_GLOCK18)
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
	}
}

public client_disconnect(id)
{
	g_bought_primary[id] = 0
	remove_task(id)
}
