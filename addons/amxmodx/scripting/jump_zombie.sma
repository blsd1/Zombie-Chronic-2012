#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <engine>

#define PLUGIN "[ZP] Jump Zombie"
#define VERSION "1.0"
#define AUTHOR "ketamine"

// Zombie Attributes
new g_zclass_jump
new const zclass_name[] = "Jump Zombie" // name
new const zclass_info[] = "[vysoke skoky]" // description
new const zclass_model[] = "ch2012_jump" // model
new const zclass_clawmodel[] = "ch2012_jump_hand.mdl" // claw model
const zclass_health = 2100 // health
const zclass_speed = 280 // speed
const Float:zclass_gravity = 0.8 // gravity
const Float:zclass_knockback = 1.00 // knockback

new i_stealth_time_hud[33]
new g_cooldown[33]
new g_infections[33]
new Float:g_stealth_time[33]
new i_cooldown_time[33]
new g_maxplayers

// --- config ------------------------ //
new Float:g_lower_gravity_ability = 10.0 //first stealth time
new Float:g_gravity_cooldown = 30.0 //cooldown time

new const JumpAbilityInActive[] = { "ch2012/jump_inf1.wav" }
new const JumpAbilityActive[] = { "ch2012/jump_start.wav" }

new const g_spawn_sound[][] = 
{
	"ch2012/jump_inf1.wav",
	"ch2012/jump_start2.wav"
}

new const g_hit_sound[][] = 
{
	"ch2012/jump_hit1.wav",
	"ch2012/jump_hit2.wav",
	"ch2012/jump_hit3.wav",
	"ch2012/jump_hit4.wav"
}

new const g_death_sound[][] = 
{
	"ch2012/jump_die.wav"
}

// ----------------------------------- //



public plugin_init()
{   
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("zp_zclass_jump_zombie",VERSION,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward( FM_CmdStart , "fw_FM_CmdStart" );
	register_logevent("roundStart", 2, "1=Round_Start")
	g_maxplayers = get_maxplayers()
	register_dictionary("zp_zombie_jump.txt");
	register_forward(FM_PlayerPreThink, "prethink")
}

public prethink(id)
{
	static button,oldbuttons; 
	button = pev( id, pev_button ); 
	oldbuttons = pev( id, pev_oldbuttons ); 
	if(button & IN_USE && !(oldbuttons & IN_USE)) 
	{
		use_ability_one(id)
	} 
}

public plugin_precache()
{
	g_zclass_jump = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	
	precache_sound(JumpAbilityInActive)
	precache_sound(JumpAbilityActive)

	for(new i = 0; i < sizeof(g_spawn_sound); i++)
		precache_sound(g_spawn_sound[i])
	
	for(new i = 0; i < sizeof(g_hit_sound); i++)
		precache_sound(g_hit_sound[i])
	
	for(new i = 0; i < sizeof(g_death_sound); i++)
		precache_sound(g_death_sound[i])
}

public roundStart()
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		i_cooldown_time[i] = floatround(g_gravity_cooldown)
		g_cooldown[i] = 0
		remove_task(i)
		
	}
}

public use_ability_one(id)
{
	if(is_valid_ent(id) && is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_jump)
	{
		if(g_cooldown[id] == 0)
		{		
			client_cmd(id, "spk ^"%s^"", JumpAbilityActive)
			set_task(g_stealth_time[id],"ghost_make_visible",id)
			set_task(g_gravity_cooldown,"reset_cooldown",id)
			g_cooldown[id] = 1
			set_user_gravity(id, 0.3)
		
		color_chat(id, "!t[Jump ZOMBIE] !gZISKAL SI NA 10 SEKUND GRAVITACIU")
			i_cooldown_time[id] = floatround(g_gravity_cooldown)
			i_stealth_time_hud[id] = floatround(g_stealth_time[id])
			
			set_task(1.0, "ShowHUD", id, _, _, "a",i_cooldown_time[id])
			set_task(1.0, "ShowHUDstealthes", id, _, _, "a",i_stealth_time_hud[id])
		}
	}
}


public ShowHUD(id)
{
	if(is_valid_ent(id) && is_user_alive(id))
	{
		i_cooldown_time[id] = i_cooldown_time[id] - 1;
		set_hudmessage(200, 100, 100, 0.05, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1)
		show_hudmessage(id, "Cooldown: %d s",i_cooldown_time[id])
	}else{
		remove_task(id)
	}
}

public ShowHUDstealthes(id)
{
	if(is_valid_ent(id) && is_user_alive(id))
	{
	}else{
		remove_task(id)
	}
}

public ghost_make_visible(id)
{
	if(is_valid_ent(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_jump)
	{
		set_user_gravity(id, 1.0)
                color_chat(id, "^4[BIG ZOMBIE] ^1Tvoja schopnost vyprsala tvoj problem ty kokot ")
		client_cmd(id, "spk ^"%s^"", JumpAbilityInActive)
		
	}
}

public reset_cooldown(id)
{
	if(is_valid_ent(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_jump)
	{
		g_cooldown[id] = 0
		
		color_chat(id, "^4[Jump ZOMBIE] ^1SCHOPNOST JE PRIPRAVENA STLAC E")
		
	}
}

public zp_user_infected_post(id, infector)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_jump) && !zp_get_user_nemesis(id))
	{
		color_chat(id, "^4[Jump ZOMBIE] ^1Stisknutim E dostanes gravitaciu ")
		
		i_cooldown_time[id] = floatround(g_gravity_cooldown)
		remove_task(id)
		g_stealth_time[id] = g_lower_gravity_ability
		g_cooldown[id] = 0
		g_infections[id] = 0
		
		zp_override_user_painsound(id, "ch2012/jump_hit1.wav", sizeof(g_hit_sound))
		zp_override_user_deathsound(id, g_death_sound[random_num(0, sizeof(g_death_sound) - 1)])
		zp_override_user_spawnsound(id, g_spawn_sound[random_num(0, sizeof(g_spawn_sound) - 1)])
		zp_override_user_idlesound(id, "ch2012/jump_idle1.wav", sizeof(g_spawn_sound))
	}
	
	if(infector > 0 && is_user_connected(infector) && (zp_get_user_zombie_class(infector) == g_zclass_jump) && !zp_get_user_nemesis(infector))
	{
		g_stealth_time[infector] = g_stealth_time[infector] + 1;
		infections_hud(infector)
	}
}

public infections_hud(id)
{
	if(is_valid_ent(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_jump)
	{
		// Unused for now
		//new i_stealth_time = floatround(g_stealth_time[id])
		//color_chat(id, "%L", id, "ABILITY_TIME",i_stealth_time)
	}
}

public zp_user_humanized_post(id)
{
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
	remove_task(id)
}

public zp_user_unfrozen(id)
{
	if(is_valid_ent(id) && is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_jump)
	{
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!(damage_type & DMG_FALL) || !zp_get_user_zombie(victim) || zp_get_user_zombie_class(victim) != g_zclass_jump)
		return HAM_IGNORED
	
	SetHamParamFloat(4, 0.0)
	return HAM_HANDLED
}

public fw_PlayerPreThink(player)
{
	if(!is_user_alive(player))
		return FMRES_IGNORED
	
	if(zp_get_user_zombie(player) && zp_get_user_zombie_class(player) == g_zclass_jump)
		set_pev(player, pev_flTimeStepSound, 999)
	
	return FMRES_IGNORED
}

public fw_FM_CmdStart( id , Handle )
{
	static iButtons , iOldButtons;
	
	iButtons = get_uc( Handle , UC_Buttons );
	iOldButtons = pev( id , pev_oldbuttons );
	
	if( ( iButtons & IN_RELOAD ) && !( iOldButtons & IN_RELOAD ) ) 
	{
		use_ability_one(id)           
	}
}

stock color_chat(const id, const input[], any:...) 
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