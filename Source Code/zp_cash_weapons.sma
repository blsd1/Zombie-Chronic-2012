#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <zombieplague>
#include <engine>


new bool:zbran1[33]
new bool:zbran2[33]
new bool:zbran3[33]
new bool:zbran4[33]
new bool:zbran5[33]
new bool:zbran6[33]
new bool:zbran7[33]

new choosed_weapon[33]

// Event IDs for blocking original weapon sounds
new g_orig_event_ak47, g_orig_event_galil, g_orig_event_aug, g_orig_event_mac10
new g_MaxPlayers, g_IsInPrimaryAttack[33]
new g_clip_ammo[33]

new a_model[] = "models/ch2012/v_guitar.mdl"
new b_model[] = "models/ch2012/v_ak47_long.mdl"
new c_model[] = "models/ch2012/v_fnc-u56.mdl"
new d_model[] = "models/ch2012/v_cartblue.mdl"
new e_model[] = "models/ch2012/v_thompson.mdl"
new f_model[] = "models/ch2012/v_f2000.mdl"
new g_model[] = "models/ch2012/v_dmp7a1.mdl"
// Custom weapon sounds
new const sound_mac10[] = "weapons/gt-1.wav"
new const sound_sg552[] = "weapons/aklong1.wav"
new const sound_galil[] = "weapons/fnc-1.wav"
new const sound_ak47_fire[] = "weapons/cartblue_l.wav"
new const sound_m4a1[] = "weapons/thompsongold_shoot1.wav"
new const sound_mp5[] = "weapons/f2000-1.wav"
new const sound_m3[] = "weapons/dmp7-1.wav"

public plugin_init()
{
	register_plugin("Menu zbrani", "1.00", "ketamine") // vela by si chcel mistery
	
	register_clcmd("say /guns", "gunmenu")
	register_clcmd("say_team /guns", "gunmenu")
	register_clcmd("say /zbrane", "gunmenu")
	register_clcmd("say_team /zbrane", "gunmenu")
	
	RegisterHam(Ham_Spawn, "player", "player_spawn", 2)
	RegisterHam(Ham_TakeDamage,"player", "Hrac_Damage",0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_aug", "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_aug", "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mac10", "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mac10", "fw_PrimaryAttack_Post", 1)
	
	register_event("CurWeapon","CurWeapon","be","1=1")
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	
	g_MaxPlayers = get_maxplayers()

	return PLUGIN_CONTINUE
}

public plugin_natives()
{
	// Provide the weapons-menu native previously served by zp_custom_weapons.
	// chronic_2012 calls zp_open_weapons_menu() from its main menu / weapon button.
	register_native("zp_open_weapons_menu", "native_open_weapons_menu")
}

public native_open_weapons_menu(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
		return false

	gunmenu(id)
	return true
}

public fw_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(!is_user_alive(Player))
		return
	
	new weaponid = cs_get_weapon_id(Weapon)
	
	// Check if player has custom weapon and set flag
	if(weaponid == CSW_AK47 && (zbran1[Player] || zbran2[Player] || zbran4[Player] || zbran5[Player]))
	{
		g_IsInPrimaryAttack[Player] = 1
		g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	}
	else if(weaponid == CSW_GALIL && zbran3[Player])
	{
		g_IsInPrimaryAttack[Player] = 1
		g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	}
	else if(weaponid == CSW_AUG && zbran6[Player])
	{
		g_IsInPrimaryAttack[Player] = 1
		g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	}
	else if(weaponid == CSW_MAC10 && zbran7[Player])
	{
		g_IsInPrimaryAttack[Player] = 1
		g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	}
}

public fw_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack[get_pdata_cbase(Weapon, 41, 4)] = 0
	
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(!is_user_alive(Player))
		return
	
	new weaponid = cs_get_weapon_id(Weapon)
	
	// Play custom sound for each weapon
	if(weaponid == CSW_AK47)
	{
		if(!g_clip_ammo[Player])
			return
			
		// zbran1 = Guitar (AK47) -> sound_m3 (dmp7-1.wav)
		if(zbran1[Player])
		{
			emit_sound(Player, CHAN_WEAPON, sound_m3, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		// zbran2 = AK Long (AK47) -> sound_sg552 (aklong1.wav)
		else if(zbran2[Player])
		{
			emit_sound(Player, CHAN_WEAPON, sound_sg552, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		// zbran4 = Cart-Blue (AK47) -> sound_ak47_fire (cartblue_l.wav)
		else if(zbran4[Player])
		{
			emit_sound(Player, CHAN_WEAPON, sound_ak47_fire, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		// zbran5 = Thompson (AK47) -> sound_m4a1 (thompsongold_shoot1.wav)
		else if(zbran5[Player])
		{
			emit_sound(Player, CHAN_WEAPON, sound_m4a1, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	else if(weaponid == CSW_GALIL)
	{
		if(!g_clip_ammo[Player])
			return
			
		// zbran3 = FNC-U56 (GALIL) -> sound_galil (fnc-1.wav)
		if(zbran3[Player])
		{
			emit_sound(Player, CHAN_WEAPON, sound_galil, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	else if(weaponid == CSW_AUG)
	{
		if(!g_clip_ammo[Player])
			return
			
		// zbran6 = FN 2000 (AUG) -> sound_mp5 (f2000-1.wav)
		if(zbran6[Player])
		{
			emit_sound(Player, CHAN_WEAPON, sound_mp5, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	else if(weaponid == CSW_MAC10)
	{
		if(!g_clip_ammo[Player])
			return
			
		// zbran7 = Double MP7A1 (MAC10) -> sound_mac10 (gt-1.wav)
		if(zbran7[Player])
		{
			emit_sound(Player, CHAN_WEAPON, sound_mac10, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if(!(1 <= invoker <= g_MaxPlayers) || !g_IsInPrimaryAttack[invoker])
		return FMRES_IGNORED
		
	if(!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED
	
	// Block original weapon sounds for custom weapons
	if(eventid == g_orig_event_ak47 && (zbran1[invoker] || zbran2[invoker] || zbran4[invoker] || zbran5[invoker]))
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		return FMRES_SUPERCEDE
	}
	else if(eventid == g_orig_event_galil && zbran3[invoker])
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		return FMRES_SUPERCEDE
	}
	else if(eventid == g_orig_event_aug && zbran6[invoker])
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		return FMRES_SUPERCEDE
	}
	else if(eventid == g_orig_event_mac10 && zbran7[invoker])
	{
		playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public plugin_precache()
{
	precache_model(a_model)
	precache_model(b_model)
	precache_model(c_model)
	precache_model(d_model)
	precache_model(e_model)
	precache_model(f_model)
	precache_model(g_model)
	
	// Precache custom weapon sounds
	precache_sound(sound_mac10)
	precache_sound(sound_sg552)
	precache_sound(sound_galil)
	precache_sound(sound_ak47_fire)
	precache_sound(sound_m4a1)
	precache_sound(sound_mp5)
	precache_sound(sound_m3)
	
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if(equal("events/ak47.sc", name))
	{
		g_orig_event_ak47 = get_orig_retval()
	}
	else if(equal("events/galil.sc", name))
	{
		g_orig_event_galil = get_orig_retval()
	}
	else if(equal("events/aug.sc", name))
	{
		g_orig_event_aug = get_orig_retval()
	}
	else if(equal("events/mac10.sc", name))
	{
		g_orig_event_mac10 = get_orig_retval()
	}
	
	return FMRES_IGNORED
}

stock reset_all_weapons(id)
{
	zbran1[id] = false
	zbran2[id] = false
	zbran3[id] = false
	zbran4[id] = false
	zbran5[id] = false
	zbran6[id] = false
	zbran7[id] = false
}

public CurWeapon(id, entity)
{
	if(is_user_connected(id))
	{
		new weaponid = read_data(2)
		
		// zbran1 = Guitar (AK47)
		if(zbran1[id] && weaponid == CSW_AK47)
		{
			set_pev(id, pev_viewmodel2, a_model)
		}
		// zbran2 = AK Long (AK47)
		else if(zbran2[id] && weaponid == CSW_AK47)
		{
			set_pev(id, pev_viewmodel2, b_model)
		}
		// zbran3 = FNC-U56 (GALIL)
		else if(zbran3[id] && weaponid == CSW_GALIL)
		{
			set_pev(id, pev_viewmodel2, c_model)
		}
		// zbran4 = Cart-Blue (AK47)
		else if(zbran4[id] && weaponid == CSW_AK47)
		{
			set_pev(id, pev_viewmodel2, d_model)
		}
		// zbran5 = Thompson (AK47)
		else if(zbran5[id] && weaponid == CSW_AK47)
		{
			set_pev(id, pev_viewmodel2, e_model)
		}
		// zbran6 = FN 2000 (AUG)
		else if(zbran6[id] && weaponid == CSW_AUG)
		{
			set_pev(id, pev_viewmodel2, f_model)
		}
		// zbran7 = Double MP7A1 (MAC10)
		else if(zbran7[id] && weaponid == CSW_MAC10)
		{
			set_pev(id, pev_viewmodel2, g_model)
		}
	}
}

public Hrac_Damage(victim, inflictor, attacker, Float:damage, damage_bits)
{
	if(is_user_connected(attacker))
	{
		new weapon = get_user_weapon(attacker);
		
		switch(weapon)
		{
			case CSW_AK47:
			{
				if(zbran2[attacker] == true || zbran4[attacker] == true || zbran5[attacker] == true)
				{
					SetHamParamFloat(4,damage * 1.5);
				}
			}
			case CSW_GALIL:
			{
				if(zbran3[attacker] == true)
				{
					SetHamParamFloat(4,damage * 1.5);
				}
			}
			case CSW_AUG:
			{
				if(zbran6[attacker] == true)
				{
					SetHamParamFloat(4,damage * 1.5);
				}
			}
			case CSW_MAC10:
			{
				if(zbran7[attacker] == true)
				{
					SetHamParamFloat(4,damage * 1.0);
				}
			}
			case CSW_M4A1:
			{
				if(zbran1[attacker] == true)
				{
					SetHamParamFloat(4,damage * 1.5);
				}
			}
			case CSW_M3:
			{
				if(zbran1[attacker] == true)
				{
					SetHamParamFloat(4,damage * 1.5);
				}
			}
		}
	}
}

public gunmenu(id)
{
if(!zp_get_user_zombie(id))
{
if(choosed_weapon[id] == 0)
{
new menus = menu_create("Vyber si zbran na dalsiej strane novinka \r","zbrane_handle")
menu_additem(menus,"AK-47 Kalashnikov")
menu_additem(menus,"\yGuitar Wep \r3300$")
//
menu_additem(menus,"M4A1 Carbine")
menu_additem(menus,"\yAK Long \r3100$")
//
menu_additem(menus,"MP5 Navy")
menu_additem(menus,"\yFNC-U56 \r3650$")
//
menu_additem(menus,"AWP Magnum Sniper")
menu_additem(menus,"\yCart-Blue \r4300$")
//
menu_additem(menus,"Famas Gun")
menu_additem(menus,"\yThompson 45ACP \r3300$")
//
menu_additem(menus,"Steyr AUG A1")
menu_additem(menus,"\yFN 2000 \r3350$")
//
menu_additem(menus,"XM1014 M4")
menu_additem(menus,"\yDouble MP7A1 \r3700$")

menu_setprop(menus, MPROP_NEXTNAME, "More")
menu_setprop(menus, MPROP_BACKNAME, "Back")
menu_setprop(menus, MPROP_EXITNAME, "Exit")
menu_display(id,menus)
return PLUGIN_HANDLED
}
else
{
ChatColor(id, "!g[ZP] !yYou have already chosen a weapon!")
}
}
else
{
ChatColor(id, "!g[ZP] !yTo choose a weapon, you must be a human!")
}
return PLUGIN_HANDLED
}
public zbrane_handle(id,menu,item)
{
if(item == MENU_EXIT || !is_user_alive(id) || zp_get_user_zombie(id))
{
menu_destroy(menu)
return PLUGIN_HANDLED
}
new penize = cs_get_user_money(id)

switch(item)
{
case 0:
{
choosed_weapon[id] = 1
strip_user_weapons(id)
give_item(id, "weapon_ak47")
cs_set_user_bpammo(id, CSW_AK47, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
pistole(id)

}
case 1:
{
if(penize < 3300)
{
set_task(0.1, "gunmenu", id)
ChatColor(id, "!g[ZP] !yNemas dostatek penez!")
}
else
{
choosed_weapon[id] = 1
strip_user_weapons(id)
reset_all_weapons(id)
zbran1[id] = true
give_item(id, "weapon_ak47")
cs_set_user_bpammo(id, CSW_AK47, 90)
give_item(id, "weapon_knife")
cs_set_user_money(id , penize - 3300)
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
pistole(id)

}
}
case 2:
{
choosed_weapon[id] = 1
strip_user_weapons(id)
give_item(id, "weapon_m4a1")
cs_set_user_bpammo(id, CSW_M4A1, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
pistole(id)
}
case 3:
{
if(penize < 3100)
{
set_task(0.1, "gunmenu", id)
ChatColor(id, "!g[ZP] !yNemas dostatek penez!")
}
else
{
choosed_weapon[id] = 1
strip_user_weapons(id)
reset_all_weapons(id)
zbran2[id] = true
give_item(id, "weapon_ak47")
cs_set_user_bpammo(id, CSW_AK47, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
cs_set_user_money(id , penize - 3100)
pistole(id)
}
}
case 4:
{
choosed_weapon[id] = 1
strip_user_weapons(id)
give_item(id, "weapon_mp5navy")
cs_set_user_bpammo(id, CSW_MP5NAVY, 120)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
pistole(id)
}
case 5:
{
if(penize < 3650)
{
set_task(0.1, "gunmenu", id)
ChatColor(id, "!g[ZP] !yNemas dostatek penez!")
}
else
{
choosed_weapon[id] = 1
strip_user_weapons(id)
reset_all_weapons(id)
zbran3[id] = true
give_item(id, "weapon_galil")
cs_set_user_bpammo(id, CSW_GALIL, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
cs_set_user_money(id , penize - 3650)
pistole(id)
}
}
case 6:
{
choosed_weapon[id] = 1
strip_user_weapons(id)
give_item(id, "weapon_awp")
cs_set_user_bpammo(id, CSW_AWP, 30)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
pistole(id)
}
case 7:
{
if(penize < 4300)
{
set_task(0.1, "gunmenu", id)
ChatColor(id, "!g[ZP] !yNemas dostatek penez!")
}
else
{
choosed_weapon[id] = 1
strip_user_weapons(id)
reset_all_weapons(id)
zbran4[id] = true
give_item(id, "weapon_ak47")
cs_set_user_bpammo(id, CSW_AK47, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
cs_set_user_money(id , penize - 4300)
pistole(id)
}
}
case 8:
{
choosed_weapon[id] = 1
strip_user_weapons(id)
give_item(id, "weapon_famas")
cs_set_user_bpammo(id, CSW_FAMAS, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
pistole(id)
}
case 9:
{
if(penize < 3300)
{
set_task(0.1, "gunmenu", id)
ChatColor(id, "!g[ZP] !yNemas dostatek penez!")
}
else
{
choosed_weapon[id] = 1
strip_user_weapons(id)
reset_all_weapons(id)
zbran5[id] = true
give_item(id, "weapon_ak47")
cs_set_user_bpammo(id, CSW_AK47, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
cs_set_user_money(id , penize - 3300)
pistole(id)
}
}
case 10:
{
choosed_weapon[id] = 1
strip_user_weapons(id)
give_item(id, "weapon_aug")
cs_set_user_bpammo(id, CSW_AUG, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
pistole(id)
}
case 11:
{
if(penize < 3350)
{
set_task(0.1, "gunmenu", id)
ChatColor(id, "!g[ZP] !yNemas dostatek penez!")
}
else
{
choosed_weapon[id] = 1
strip_user_weapons(id)
reset_all_weapons(id)
zbran6[id] = true
give_item(id, "weapon_aug")
cs_set_user_bpammo(id, CSW_AUG, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
cs_set_user_money(id , penize - 3350)
pistole(id)
}
}
case 12:
{
choosed_weapon[id] = 1
strip_user_weapons(id)
give_item(id, "weapon_xm1014")
cs_set_user_bpammo(id, CSW_XM1014, 30)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
pistole(id)
}
case 13:
{
if(penize < 3700)
{
set_task(0.1, "gunmenu", id)
ChatColor(id, "!g[ZP] !yNemas dostatek penez!")
}
else
{
choosed_weapon[id] = 1
strip_user_weapons(id)
reset_all_weapons(id)
zbran7[id] = true
give_item(id, "weapon_mac10")
cs_set_user_bpammo(id, CSW_MAC10, 90)
give_item(id, "weapon_knife")
give_item(id, "weapon_hegrenade")
give_item(id, "weapon_flashbang")
cs_set_user_money(id , penize - 3700)
pistole(id)
}
}
}
return PLUGIN_HANDLED
}

public pistole(id)
{
new menus = menu_create("\y Choose a secondary weapon","pistole_handle")
menu_additem(menus,"Desert Eagle")
menu_additem(menus,"USP pistol")
menu_additem(menus,"Glock-18")
menu_additem(menus,"FiveseveN")
menu_additem(menus,"Elite duals")

menu_setprop(menus, MPROP_EXITNAME, "Exit")
menu_display(id,menus)
return PLUGIN_HANDLED
}

public pistole_handle(id,menu,item)
{
if(item == MENU_EXIT || !is_user_alive(id))
{
menu_destroy(menu)
return PLUGIN_HANDLED
}
switch(item)
{
case 0:
{
give_item(id,"weapon_deagle")
cs_set_user_bpammo(id, CSW_DEAGLE, 35)
}
case 1:
{
give_item(id,"weapon_usp")
cs_set_user_bpammo(id, CSW_USP, 90)
}
case 2:
{
give_item(id,"weapon_glock18")
cs_set_user_bpammo(id, CSW_GLOCK18, 60)
}
case 3:
{
give_item(id,"weapon_fiveseven")
cs_set_user_bpammo(id, CSW_FIVESEVEN, 60)
}
case 4:
{
give_item(id,"weapon_elite")
cs_set_user_bpammo(id, CSW_ELITE, 60)
}
}
return PLUGIN_HANDLED
}

public player_spawn(id)
{
zbran1[id] = false
zbran2[id] = false
zbran3[id] = false
zbran4[id] = false
zbran5[id] = false
zbran6[id] = false
zbran7[id] = false
choosed_weapon[id] = 0

}

public client_connect(id)
{
zbran1[id] = false
zbran2[id] = false
zbran3[id] = false
zbran4[id] = false
zbran5[id] = false
zbran6[id] = false
zbran7[id] = false
}

public zp_user_humanized_post( id )
{
   choosed_weapon[id] = 0;
}

public client_disconnected(id)
{
zbran1[id] = false
zbran2[id] = false
zbran3[id] = false
zbran4[id] = false
zbran5[id] = false
zbran6[id] = false
zbran7[id] = false
}

stock ChatColor(const id, const input[], any:...)
{
new count = 1, players[ 32 ]
static msg[ 191 ]
vformat( msg, 190, input, 3 )

replace_all( msg, 190, "!g", "^4" )
replace_all( msg, 190, "!y", "^1" )
replace_all( msg, 190, "!t", "^3" )

if(id) players[ 0 ] = id; else get_players( players, count, "ch" )
{
for(new i = 0; i < count; i++)
{
if( is_user_connected( players[ i ] ) )
{
message_begin( MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[ i ] )
write_byte( players[ i ] )
write_string( msg )
message_end( )
}
}
}
}