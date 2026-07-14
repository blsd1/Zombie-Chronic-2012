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
new Float:g_ability_cooldown[33]
new g_infections[33]
new Float:g_stealth_time[33]
new i_cooldown_time[33]
new g_maxplayers
new g_msgScreenFade, g_msgScreenShake, g_msg_sync

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
	
	// Inicializacia message IDs pre efekty
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msg_sync = CreateHudSyncObj()
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
		g_ability_cooldown[i] = 0.0
		remove_task(i)
		
	}
}

public use_ability_one(id)
{
	if(is_valid_ent(id) && is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_jump)
	{
		// Kontrola cooldownu
		new Float:current_time = get_gametime()
		if (g_ability_cooldown[id] > current_time)
		{
			return // Cooldown je aktívny, ignoruj
		}
		
		// Aktivuj schopnosť
		client_cmd(id, "spk ^"%s^"", JumpAbilityActive)
		set_task(g_lower_gravity_ability,"ghost_make_visible",id)
		set_user_gravity(id, 0.3)
		
		// Screen shake efekt
		message_begin(MSG_ONE, g_msgScreenShake, _, id)
		write_short(1<<12) // amplitude
		write_short(1<<10) // duration
		write_short(1<<12) // frequency
		message_end()
		
		// Orange screen fade pre 3 sekundy
		message_begin(MSG_ONE, g_msgScreenFade, _, id)
		write_short(1<<12) // duration (3 seconds)
		write_short(1<<10) // hold time
		write_short(0x0000) // fade type (fade in)
		write_byte(255) // red
		write_byte(165) // green (orange color)
		write_byte(0) // blue
		write_byte(100) // alpha
		message_end()
		
		color_chat(id, "!t[Jump zombie] !g%L", id, "GRAVITY_GAINED")
	}
}


public ShowHUD(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_jump)
	{
		remove_task(id)
		return
	}
	
	new Float:current_time = get_gametime()
	
	// Kontrola či cooldown je aktívny
	if (g_ability_cooldown[id] > current_time)
	{
		new remaining_time = floatround(g_ability_cooldown[id] - current_time)
		
		// Zobraz cooldown HUD v orange, dole vpravo
		set_hudmessage(200, 100, 0, 0.76, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(id, g_msg_sync, "%L", id, "COOLDOWN_HUD", remaining_time)
	}
	else
	{
		// Cooldown skončil, odstráň task
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
		set_user_gravity(id, zclass_gravity)
		color_chat(id, "!t[Jump zombie] !g%L", id, "ABILITY_ENDED")
		client_cmd(id, "spk ^"%s^"", JumpAbilityInActive)
		
		// Nastav cooldown TEraz (po skonceni ability)
		new Float:current_time = get_gametime()
		g_ability_cooldown[id] = current_time + g_gravity_cooldown
		
		// Spusti cooldown HUD display
		set_task(1.0, "ShowHUD", id, _, _, "b")
	}
}



public zp_user_infected_post(id, infector)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_jump) && !zp_get_user_nemesis(id))
	{
		color_chat(id, "!t[Jump zombie] !g%L", id, "PRESS_E_JUMP")
		
		i_cooldown_time[id] = floatround(g_gravity_cooldown)
		remove_task(id)
		g_stealth_time[id] = g_lower_gravity_ability
		g_ability_cooldown[id] = 0.0
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

public client_connect(id)
{
	g_ability_cooldown[id] = 0.0
}

public client_disconnected(id)
{
	remove_task(id)
	g_ability_cooldown[id] = 0.0
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