/*
	VIP Model & Chat Tag Plugin
	- Hráči s admin_level_H dostanou VIP model
	- VIP tag v chatu
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <zombieplague>

#define PLUGIN "VIP Model & Chat Tag"
#define VERSION "1.1"
#define AUTHOR "ketamine"

#define ADMIN_ACCESS ADMIN_LEVEL_H

new const VIP_MODELS[][] = {
	"ch2012_vip",
	"ch2012_vip2"
}

new g_PlayerModel[33][32]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("ResetHUD", "Event_ResetHUD", "be")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	// Hook say commands pre VIP tag
	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_say_team")
	
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged")
}

public plugin_precache()
{
	// Precache oba VIP modely
	for(new i = 0; i < sizeof(VIP_MODELS); i++)
	{
		new model_path[128]
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", VIP_MODELS[i], VIP_MODELS[i])
		precache_model(model_path)
	}
}

public client_putinserver(id)
{
	g_PlayerModel[id][0] = 0
}

public client_disconnected(id)
{
	remove_task(id)
	g_PlayerModel[id][0] = 0
}

public Event_ResetHUD(id)
{
	if(!is_user_alive(id))
		return
		
	if(get_user_flags(id) & ADMIN_ACCESS)
	{
		// Nenastavuj VIP model ak je zombie
		if(zp_get_user_zombie(id))
			return
			
		set_task(0.5, "Set_VIP_Model", id)
	}
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	if(get_user_flags(id) & ADMIN_ACCESS)
	{
		// Nenastavuj VIP model ak je zombie
		if(zp_get_user_zombie(id))
			return
			
		static model[32]
		cs_get_user_model(id, model, charsmax(model))
		
		// Kontrola či má jeden z VIP modelov
		new bool:has_vip_model = false
		for(new i = 0; i < sizeof(VIP_MODELS); i++)
		{
			if(equal(model, VIP_MODELS[i]))
			{
				has_vip_model = true
				break
			}
		}
		
		if(!has_vip_model)
		{
			set_task(0.1, "Set_VIP_Model", id)
		}
	}
}

public Set_VIP_Model(id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return
		
	if(get_user_flags(id) & ADMIN_ACCESS)
	{
		// Nenastavuj VIP model ak je zombie
		if(zp_get_user_zombie(id))
			return
			
		// Ak už má priradený model, použi ten istý
		if(g_PlayerModel[id][0] == 0)
		{
			// Inak vyber náhodný
			new random_index = random(sizeof(VIP_MODELS))
			copy(g_PlayerModel[id], charsmax(g_PlayerModel[]), VIP_MODELS[random_index])
		}
		
		// Nastav VIP model pomocou engfunc
		engfunc(EngFunc_SetClientKeyValue, id, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", g_PlayerModel[id])
		
		// Debug log
		static name[32]
		get_user_name(id, name, charsmax(name))
		log_amx("[VIP Model] Nastavujem model %s pre %s", g_PlayerModel[id], name)
	}
}

public fw_ClientUserInfoChanged(id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return FMRES_IGNORED
		
	if(!(get_user_flags(id) & ADMIN_ACCESS))
		return FMRES_IGNORED
		
	// Nenastavuj VIP model ak je zombie
	if(zp_get_user_zombie(id))
		return FMRES_IGNORED
		
	static new_model[32]
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", new_model, charsmax(new_model))
	
	// Kontrola či má jeden z VIP modelov
	new bool:has_vip_model = false
	for(new i = 0; i < sizeof(VIP_MODELS); i++)
	{
		if(equal(new_model, VIP_MODELS[i]))
		{
			has_vip_model = true
			break
		}
	}
	
	if(!has_vip_model && g_PlayerModel[id][0] != 0)
	{
		engfunc(EngFunc_SetClientKeyValue, id, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", g_PlayerModel[id])
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public hook_say(id)
{
	if(!(get_user_flags(id) & ADMIN_ACCESS))
		return PLUGIN_CONTINUE
		
	new said[192]
	read_args(said, charsmax(said))
	remove_quotes(said)
	
	if(equal(said, ""))
		return PLUGIN_CONTINUE
	
	// Ak je to príkaz (začína / alebo !), nespracovávaj
	if(said[0] == '/' || said[0] == '!' || said[0] == '.' || said[0] == '@')
		return PLUGIN_CONTINUE
	
	new name[32]
	get_user_name(id, name, charsmax(name))
	
	new players[32], num
	get_players(players, num, "ch")
	
	for(new i = 0; i < num; i++)
	{
		new player = players[i]
		client_print_color(player, id, "^4[VIP]^3 %s^1 :  %s", name, said)
	}
	
	return PLUGIN_HANDLED
}

public hook_say_team(id)
{
	if(!(get_user_flags(id) & ADMIN_ACCESS))
		return PLUGIN_CONTINUE
		
	new said[192]
	read_args(said, charsmax(said))
	remove_quotes(said)
	
	if(equal(said, ""))
		return PLUGIN_CONTINUE
	
	// Ak je to príkaz (začína / alebo !), nespracovávaj
	if(said[0] == '/' || said[0] == '!' || said[0] == '.' || said[0] == '@')
		return PLUGIN_CONTINUE
	
	new name[32]
	get_user_name(id, name, charsmax(name))
	
	new CsTeams:team = cs_get_user_team(id)
	new players[32], num
	get_players(players, num, "ch")
	
	for(new i = 0; i < num; i++)
	{
		new player = players[i]
		if(cs_get_user_team(player) == team)
		{
			client_print_color(player, id, "^4[VIP]^3 %s^1 :  %s", name, said)
		}
	}
	
	return PLUGIN_HANDLED
}

public Message_SayText(msgid, dest, receiver)
{
	return PLUGIN_CONTINUE
}

