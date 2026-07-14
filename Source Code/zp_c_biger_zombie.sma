#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <engine>

#define PLUGIN "[ZP] Class - Biger"
#define VERSION "1.0"
#define AUTHOR "ketamine"

// Zombie Attributes
new g_zclass_biger
new const zclass_name[] = "Biger Zombie" // name
new const zclass_info[] = "[hp boost]" // description
new const zclass_model[] = "ch2012_big" // model
new const zclass_clawmodel[] = "ch2012_big_hand.mdl" // claw model
const zclass_health = 2700 // health
const zclass_speed = 250 // speed
const Float:zclass_gravity = 1.00 // gravity
const Float:zclass_knockback = 1.00 // knockback

new g_cooldown[33]
new i_cooldown_time[33]
new g_maxplayers

// --- config ------------------------ //
const hp_boost = 300
new Float:g_cooldown_duration = 11.0

// Custom Biger Zombie sounds from ch2012 folder
new const g_ability_sound[][] = 
{
	"ch2012/big_active1.wav",
	"ch2012/big_active2.wav",
	"ch2012/big_active3.wav",
	"ch2012/big_die3.wav"
}

new const g_spawn_sound[][] = 
{
	"ch2012/big_start.wav",
}

new g_sprite_ability

new const g_hit_sound[][] = 
{
	"ch2012/big_hit1.wav",
	"ch2012/big_hit2.wav",
	"ch2012/big_hit3.wav",
	"ch2012/big_hit4.wav",
	"ch2012/big_hit5.wav"
}

new const g_death_sound[][] = 
{
	"ch2012/big_die1.wav",
	"ch2012/big_die2.wav",
	"ch2012/big_die3.wav"
}
// ----------------------------------- //

public plugin_init()
{   
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary("zombie_plague.txt")
	register_cvar("zp_zclass_biger_zombie", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
	register_logevent("roundStart", 2, "1=Round_Start")
	g_maxplayers = get_maxplayers()
	register_forward(FM_PlayerPreThink, "prethink")
}

public prethink(id)
{
	static button, oldbuttons
	button = pev(id, pev_button)
	oldbuttons = pev(id, pev_oldbuttons)
	if (button & IN_RELOAD && !(oldbuttons & IN_RELOAD)) 
	{
		use_ability_hp(id)
	} 
}

public plugin_precache()
{
	g_zclass_biger = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	
	// Precache sprite for ability effect
	g_sprite_ability = precache_model("sprites/ch2012_big_active.spr")
	
	// Precache custom biger sounds
	for (new i = 0; i < sizeof(g_ability_sound); i++)
		precache_sound(g_ability_sound[i])
	
	for (new i = 0; i < sizeof(g_spawn_sound); i++)
		precache_sound(g_spawn_sound[i])
	
	for (new i = 0; i < sizeof(g_hit_sound); i++)
		precache_sound(g_hit_sound[i])
	
	for (new i = 0; i < sizeof(g_death_sound); i++)
		precache_sound(g_death_sound[i])
	
	// Precache claw model
	new clawmodel[64]
	formatex(clawmodel, charsmax(clawmodel), "models/ch2012/%s", zclass_clawmodel)
	precache_model(clawmodel)
}

public plugin_natives()
{
	register_native("is_user_biger_zombie", "native_is_user_biger_zombie", 1)
}

public native_is_user_biger_zombie(id)
{
	if (!is_user_connected(id))
		return 0
		
	if (!zp_get_user_zombie(id))
		return 0
		
	if (zp_get_user_zombie_class(id) == g_zclass_biger)
		return 1
		
	return 0
}

public zp_user_infected_post(id, infector)
{
	// Reset cooldown pre kazdeho zombika
	i_cooldown_time[id] = floatround(g_cooldown_duration)
	g_cooldown[id] = 0
	remove_task(id)
	remove_task(id+1000) // cooldown hud task
	
	// Ak je to Biger zombie, nastav custom zvuky
	if (zp_get_user_zombie_class(id) == g_zclass_biger)
	{
		// Override spawn sound (will play random from big_start or big_active1)
		zp_override_user_spawnsound(id, g_spawn_sound[random_num(0, sizeof(g_spawn_sound) - 1)])
		
		// Override hit/pain sounds (5 variants)
		zp_override_user_painsound(id, "ch2012/big_hit1.wav", sizeof(g_hit_sound))
		
		// Override death sound
		zp_override_user_deathsound(id, "ch2012/big_die1.wav")
		
		// Override idle sound (4 variants from ability sounds)
		zp_override_user_idlesound(id, "ch2012/big_start.wav", sizeof(g_spawn_sound))
	}
}

public roundStart()
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		i_cooldown_time[i] = floatround(g_cooldown_duration)
		g_cooldown[i] = 0
		remove_task(i)
		remove_task(i+1000) // cooldown hud task
	}
}

// Funkcia na vytvorenie viacerých sprite-ov okolo hráča
stock create_ability_sprites(Float:origin[3], g_sprite_ability, count)
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
		write_short(g_sprite_ability)
		write_byte(random_num(5, 15)) // scale - náhodná veľkosť
		write_byte(200) // brightness
		message_end()
	}
}

public use_ability_hp(id)
{
	if (is_valid_ent(id) && is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_biger)
	{
		if (g_cooldown[id] == 0)
		{		
			// Play random ability sound
			new sound_to_play[64]
			copy(sound_to_play, charsmax(sound_to_play), g_ability_sound[random_num(0, sizeof(g_ability_sound) - 1)])
			emit_sound(id, CHAN_VOICE, sound_to_play, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			// Vytvor 12 sprite efektov okolo hráča
			static Float:origin[3]
			pev(id, pev_origin, origin)
			
			create_ability_sprites(origin, g_sprite_ability, 12)
			
			// Pridaj HP
			new current_hp = pev(id, pev_health)
			set_pev(id, pev_health, float(current_hp + hp_boost))
			
			// Vizuálny efekt - svetlo červený flash
			UTIL_ScreenFade(id, 255, 100, 100, 75)
			
			// Zobraz +300 HP v strede obrazovky
			client_print(id, print_center, "+%d HP", hp_boost)
			
			g_cooldown[id] = 1
			
			color_chat(id, "!t[Biger zombie] !g%L", id, "BIGER_HP_BOOST_ACTIVE", hp_boost)
			
			// Spusti cooldown
			i_cooldown_time[id] = floatround(g_cooldown_duration)
			set_task(g_cooldown_duration, "reset_cooldown", id+1000)
			set_task(1.0, "ShowHUD", id, _, _, "a", i_cooldown_time[id])
		}
	}
}

public ShowHUD(id)
{
	if (is_valid_ent(id) && is_user_alive(id) && i_cooldown_time[id] > 0)
	{
		i_cooldown_time[id] = i_cooldown_time[id] - 1
		
		if (i_cooldown_time[id] > 0)
		{
			set_hudmessage(200, 100, 0, 0.76, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1)
			show_hudmessage(id, "%L", id, "BIGER_COOLDOWN", i_cooldown_time[id])
		}
	}
	else
	{
		remove_task(id)
	}
}

public reset_cooldown(taskid)
{
	new id = taskid - 1000
	
	if (is_valid_ent(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_biger)
	{
		g_cooldown[id] = 0
		i_cooldown_time[id] = 0
		remove_task(id) // Stop HUD task
		
		if (is_user_alive(id))
		{
			color_chat(id, "!t[Biger zombie] !g%L", id, "BIGER_HP_BOOST_READY")
		}
	}
}

// Screen fade utility
UTIL_ScreenFade(id, red, green, blue, alpha)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id)
	write_short((1<<12))
	write_short((1<<12))
	write_short(0x0000)
	write_byte(red)
	write_byte(green)
	write_byte(blue)
	write_byte(alpha)
	message_end()
}

// Color chat utility
color_chat(id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!t", "^3")
	replace_all(msg, 190, "!n", "^1")
	
	if (id) players[0] = id
	else get_players(players, count, "ch")
	
	for (new i = 0; i < count; i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
			write_byte(players[i])
			write_string(msg)
			message_end()
		}
	}
}
