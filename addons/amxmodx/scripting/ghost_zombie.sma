#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <engine>

#define PLUGIN "[ZP] Class - Ghost"
#define VERSION "1.3"
#define AUTHOR "ketamine"

// Zombie Attributes
new g_zclass_ghost
new const zclass_name[] = "Ghost Zombie" // name
new const zclass_info[] = "[invisibility]" // description
new const zclass_model[] = "ch2012_ghost" // model
new const zclass_clawmodel[] = "ch2012_ghost_hand.mdl" // claw model
const zclass_health = 1350 // health
const zclass_speed = 275 // speed
const Float:zclass_gravity = 0.9 // gravity
const Float:zclass_knockback = 1.0// knockback

new i_stealth_time_hud[33]
new g_cooldown[33]
new g_infections[33]
new Float:g_stealth_time[33]
new i_cooldown_time[33]
new g_maxplayers
new g_msgScreenFade

// --- config ------------------------ //
new Float:g_stealth_time_standart = 15.0 //first stealth time
new Float:g_stealth_cooldown_standart = 25.0 //cooldown time

new const GhostLaugh[] = { "sound/epic_zombie/ghost_smiech.wav" }
new const GhostVisible[] = { "sound/epic_zombie/ghost_nactive.wav" }
new const GhostInvisible[] = { "sound/epic_zombie/ghost_active.wav" }

// Custom Ghost Zombie sounds from ch2012 folder
new const g_spawn_sound[][] = 
{
	"ch2012/ghost_start1.wav",
	"ch2012/ghost_start2.wav",
	"ch2012/ghost_start3.wav"
}

new const g_hit_sound[][] = 
{
	"ch2012/ghost_hit1.wav",
	"ch2012/ghost_hit2.wav"
}

new g_sprite_ability

new const g_death_sound[][] = 
{
	"ch2012/ghost_death1.wav",
	"ch2012/ghost_death2.wav"
}

new const g_idle_sound[][] = 
{
	"epic_zombie/ghost_smiech.wav"
}
// ----------------------------------- //


public plugin_init()
{   
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("zp_zclass_ghost_zombie",VERSION,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward( FM_CmdStart , "fw_FM_CmdStart" );
	register_logevent("roundStart", 2, "1=Round_Start")
	g_maxplayers = get_maxplayers()
	g_msgScreenFade = get_user_msgid("ScreenFade")
	register_dictionary("zp_zombie_ghost.txt");
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
	g_zclass_ghost = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	
	// Precache sprite for ability effect
	g_sprite_ability = precache_model("sprites/ch2012_ghost.spr")
	
	precache_generic(GhostLaugh)
	precache_generic(GhostVisible)
	precache_generic(GhostInvisible)
	precache_generic("sound/epic_zombie/schopnost_aktivna.wav")
	
	// Precache custom ghost sounds
	for(new i = 0; i < sizeof(g_spawn_sound); i++)
		precache_sound(g_spawn_sound[i])
	
	for(new i = 0; i < sizeof(g_hit_sound); i++)
		precache_sound(g_hit_sound[i])
	
	for(new i = 0; i < sizeof(g_death_sound); i++)
		precache_sound(g_death_sound[i])
	
	// Precache claw model
	new clawmodel[64]
	formatex(clawmodel, charsmax(clawmodel), "models/ch2012/%s", zclass_clawmodel)
	precache_model(clawmodel)
}

public plugin_natives()
{
	register_native("is_user_ghost_zombie", "native_is_user_ghost_zombie", 1);
}

public native_is_user_ghost_zombie(id)
{
	if(!is_user_connected(id))
		return 0;
		
	if(!zp_get_user_zombie(id))
		return 0;
		
	if(zp_get_user_zombie_class(id) == g_zclass_ghost)
		return 1;
		
	return 0;
}

public roundStart()
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		i_cooldown_time[i] = floatround(g_stealth_cooldown_standart)
		g_cooldown[i] = 0
		remove_task(i)
		
	}
}

// Funkcia na vytvorenie viacerých sprite-ov okolo hráča
stock create_ability_sprites(Float:origin[3], sprite_index, count)
{
	for(new i = 0; i < count; i++)
	{
		// Náhodný offset pre každý sprite
		new Float:offset_x = float(random_num(-30, 30))
		new Float:offset_y = float(random_num(-30, 30))
		new Float:offset_z = float(random_num(20, 50))
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0)
		write_byte(TE_SPRITE)
		write_coord(floatround(origin[0] + offset_x))
		write_coord(floatround(origin[1] + offset_y))
		write_coord(floatround(origin[2] + offset_z))
		write_short(sprite_index)
		write_byte(random_num(5, 15)) // scale - náhodná veľkosť
		write_byte(200) // brightness
		message_end()
	}
}

public use_ability_one(id)
{
	if(is_valid_ent(id) && is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_ghost)
	{
		if(g_cooldown[id] == 0)
		{		
			client_cmd(id, "spk ^"%s^"", GhostInvisible)
			
			// Vytvor efekt bielych gul pri neviditelnosti
			static Float:origin[3]
			pev(id, pev_origin, origin)
			
			// Sprite efekt vyletujúci z hráča
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0)
			write_byte(TE_SPRITE)
			write_coord(floatround(origin[0]))
			write_coord(floatround(origin[1]))
			write_coord(floatround(origin[2]) + 36)
			write_short(g_sprite_ability)
			write_byte(10) // scale
			write_byte(200) // brightness
			message_end()
			
			// TE_IMPLOSION - 12 bielych gul vyletujucich z hracka
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0)
			write_byte(TE_IMPLOSION)
			write_coord(floatround(origin[0])) // x
			write_coord(floatround(origin[1])) // y
			write_coord(floatround(origin[2]) + 36) // z (trochu vyssie)
			write_byte(128) // radius
			write_byte(12) // count - 12 spritov
			write_byte(3) // duration
			message_end()
			
			// Nastav neviditelnost a odstran shadow pomocou effects
			set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransColor, 0)
			set_pev(id, pev_effects, pev(id, pev_effects) | EF_NODRAW)
			
			// White screenfade (ako sting finger syringe throw)
			UTIL_ScreenFade(id, 255, 255, 255, 80)
			
			set_task(g_stealth_time[id],"ghost_make_visible",id)
			g_cooldown[id] = 1
			
			color_chat(id, "!t[Ghost zombie] !gSI NEVIDITELNY!")
			i_stealth_time_hud[id] = floatround(g_stealth_time[id])
			
			// Zobraz len timer neviditelnosti
			set_task(1.0, "ShowHUDstealthes", id, _, _, "a",i_stealth_time_hud[id])
		}
	}
}


public ShowHUD(id)
{
	if(is_valid_ent(id) && is_user_alive(id))
	{
		i_cooldown_time[id] = i_cooldown_time[id] - 1;
		set_hudmessage(200, 100, 0, 0.76, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1)
		show_hudmessage(id, "Cooldown: %d s",i_cooldown_time[id])
	}else{
		remove_task(id)
	}
}

public ShowHUDstealthes(id)
{
	if(is_valid_ent(id) && is_user_alive(id))
	{
		i_stealth_time_hud[id] = i_stealth_time_hud[id] - 1;
		set_hudmessage(200, 200, 200, -1.0, 0.1, 0, 1.0, 1.1, 0.0, 0.0, -1)
		show_hudmessage(id, "Neviditelnost: %d s", i_stealth_time_hud[id])
	}else{
		remove_task(id)
	}
}

public ghost_make_visible(id)
{
	if(is_valid_ent(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_ghost)
	{
		// Odstran EF_NODRAW flag
		set_pev(id, pev_effects, pev(id, pev_effects) & ~EF_NODRAW)
		
		// Vrat normalnu viditelnost
		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
		
		// Ak je first zombie, nastav zlty glow
		if (zp_get_user_first_zombie(id))
		{
			set_user_rendering(id, kRenderFxGlowShell, 255, 200, 0, kRenderNormal, 25)
		}
		
		// Menší efekt keď končí ability (slabší screenfade)
		UTIL_ScreenFade(id, 255, 255, 255, 60)
		
		client_cmd(id, "spk ^"%s^"", GhostVisible)
		
		// AŽ TERAZ spusti cooldown timer a task
		i_cooldown_time[id] = floatround(g_stealth_cooldown_standart)
		set_task(g_stealth_cooldown_standart,"reset_cooldown",id)
		set_task(1.0, "ShowHUD", id, _, _, "a",i_cooldown_time[id])
	}
}

public reset_cooldown(id)
{
	if(is_valid_ent(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_ghost)
	{
		g_cooldown[id] = 0
		
		color_chat(id, "!t[Ghost zombie] !gSCHOPNOST JE PRIPRAVENA")
		
		// Prehraj zvuk ked je schopnost nabita
		client_cmd(id, "spk epic_zombie/schopnost_aktivna.wav")
		
		// Prehraj smiech keď je cooldown hotový
		client_cmd(id, "spk epic_zombie/ghost_smiech.wav", GhostLaugh)
	}
}

public zp_user_infected_post(id, infector)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_ghost) && !zp_get_user_nemesis(id))
	{
		color_chat(id, "!t[Ghost zombie] !gStlačenim E aktivuješ svoju schopnosť")
		
		i_cooldown_time[id] = floatround(g_stealth_cooldown_standart)
		remove_task(id)
		g_stealth_time[id] = g_stealth_time_standart
		g_cooldown[id] = 0
		g_infections[id] = 0
		
		// Set custom sounds using ZP natives
		zp_override_user_painsound(id, "ch2012/ghost_hit1.wav", sizeof(g_hit_sound))
		zp_override_user_deathsound(id, g_death_sound[random_num(0, sizeof(g_death_sound) - 1)])
		zp_override_user_spawnsound(id, g_spawn_sound[random_num(0, sizeof(g_spawn_sound) - 1)])
		zp_override_user_idlesound(id, "epic_zombie/ghost_smiech.wav", sizeof(g_spawn_sound))
		
		// Nastav normalnu viditelnost
		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
		
		// Ak je first zombie, nastav zlty glow
		if (zp_get_user_first_zombie(id))
		{
			set_user_rendering(id, kRenderFxGlowShell, 255, 200, 0, kRenderNormal, 25)
		}
	}
	
	if(infector > 0 && is_user_connected(infector) && (zp_get_user_zombie_class(infector) == g_zclass_ghost) && !zp_get_user_nemesis(infector))
	{
		g_stealth_time[infector] = g_stealth_time[infector] + 1;
		infections_hud(infector)
	}
}

public infections_hud(id)
{
	if(is_valid_ent(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_ghost)
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
	if(is_valid_ent(id) && is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_ghost)
	{
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!(damage_type & DMG_FALL) || !zp_get_user_zombie(victim) || zp_get_user_zombie_class(victim) != g_zclass_ghost)
		return HAM_IGNORED
	
	SetHamParamFloat(4, 0.0)
	return HAM_HANDLED
}

public fw_PlayerPreThink(player)
{
	if(!is_user_alive(player))
		return FMRES_IGNORED
	
	if(zp_get_user_zombie(player) && zp_get_user_zombie_class(player) == g_zclass_ghost)
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

// Screenfade funkcia (z sting finger)
stock UTIL_ScreenFade(player, r = 0, g = 0, b = 0, alpha = 80)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, .player = player)
	write_short(1 << 11)
	write_short(1 << 11)
	write_short(0x0000)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(alpha)
	message_end()
}