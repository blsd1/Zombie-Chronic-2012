
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <xs>
#include <zombieplague>
#include <hamsandwich>

#define PLUGIN "[ZP] Class - Sleep Zombie"
#define VERSION "1.0"
#define AUTHOR "ketamine"


new const zclass_name[] = { "Sleep Zombie" }
new const zclass_info[] = { "blinding humans" }
new const zclass_model[] = { "ch2012_sleep" }
new const zclass_clawmodel[] = { "ch2012_sleep_hand.mdl" }
const zclass_health = 2000
const zclass_speed = 280
const Float:zclass_gravity = 0.69
const Float:zclass_knockback = 0.24

new g_zclass_tank
new g_chance[33]
new g_msgScreenFade
const FFADE_IN = 0x0000
const FFADE_STAYOUT = 0x0004
const UNIT_SECOND = (1<<12)

new g_maxplayers
new is_cooldown_time[33] = 0
new is_cooldown[33] = 0

// --- config ------------------------ //
new Float:g_revenge_cooldown = 15.0 //cooldown time
new g_chance_to_cast = 25 //chance in percent, where 10 = 1%, 235= 23.5% e t.c.
new const sound_sleep[] = "ch2012/sleep.wav" //cast sound

// Custom Sleep Zombie sounds from ch2012 folder
new const g_spawn_sound[][] = 
{
	"ch2012/sleep_idle1.wav",
	"ch2012/sleep_idle2.wav",
	"ch2012/sleep_idle3.wav",
	"ch2012/sleep_idle4.wav",
	"ch2012/sleep_idle5.wav"
}

new const g_hit_sound[][] = 
{
	"ch2012/sleep_hit1.wav",
	"ch2012/sleep_hit2.wav",
	"ch2012/sleep_hit3.wav",
	"ch2012/sleep_hit4.wav"
}

new const g_idle_sound[][] = 
{
	"ch2012/sleep_idle1.wav",
	"ch2012/sleep_idle2.wav",
	"ch2012/sleep_idle3.wav",
	"ch2012/sleep_idle4.wav",
	"ch2012/sleep_idle5.wav"
}
// ----------------------------------- //

public plugin_precache()
{
	g_zclass_tank = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	precache_sound(sound_sleep)
	
	// Precache custom sleep sounds
	for(new i = 0; i < sizeof(g_spawn_sound); i++)
		precache_sound(g_spawn_sound[i])
	
	for(new i = 0; i < sizeof(g_hit_sound); i++)
		precache_sound(g_hit_sound[i])
	
	for(new i = 0; i < sizeof(g_idle_sound); i++)
		precache_sound(g_idle_sound[i])
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary("zombie_plague.txt")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_maxplayers = get_maxplayers()
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_logevent("roundStart", 2, "1=Round_Start")
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	// Sleep zombie is being attacked by a human
	if (!is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED
	
	if (attacker == victim || zp_get_user_zombie(attacker))
		return HAM_IGNORED
	
	if ((zp_get_user_zombie_class(victim) == g_zclass_tank) && zp_get_user_zombie(victim) && !zp_get_user_nemesis(victim) && (is_cooldown[victim] == 0))
	{
		g_chance[victim] = random_num(0,999)
		if (g_chance[victim] < g_chance_to_cast)
		{
			// Blind the attacker
			message_begin(MSG_ONE, g_msgScreenFade, _, attacker)
			write_short(4 * 256) // duration (4 seconds)
			write_short(4 * 256) // hold time
			write_short(FFADE_STAYOUT) // fade type
			write_byte(0) // red
			write_byte(0) // green
			write_byte(0) // blue
			write_byte(255) // alpha
			message_end()
			
			// Bonus +1000 HP for sleep zombie when blinding someone
			set_pev(victim, pev_health, pev(victim, pev_health) + 1000.0)
			
			set_task(4.0,"wake_up",attacker)
			
			// Start cooldown timer and HUD
			is_cooldown_time[victim] = floatround(g_revenge_cooldown)
			set_task(1.0, "ShowHUD", victim, _, _, "a", is_cooldown_time[victim])
			set_task(g_revenge_cooldown,"reset_cooldown",victim)
			
			emit_sound(attacker, CHAN_STREAM, sound_sleep, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			is_cooldown[victim] = 1
		}
	}
	
	return HAM_IGNORED
}

public reset_cooldown(id)
{
if ((zp_get_user_zombie_class(id) == g_zclass_tank) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
{
is_cooldown[id] = 0
is_cooldown_time[id] = floatround(g_revenge_cooldown)
color_chat(id, "!t[Sleep zombie] !g%L", id, "SLEEP_ABILITY_READY")
}
}

public ShowHUD(id)
{
if(is_user_alive(id))
{
is_cooldown_time[id] = is_cooldown_time[id] - 1;
set_hudmessage(200, 100, 0, 0.76, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1)
show_hudmessage(id, "%L", id, "SLEEP_COOLDOWN", is_cooldown_time[id])
}else{
remove_task(id)
}
}

public wake_up(id)
{
message_begin(MSG_ONE, g_msgScreenFade, _, id)
write_short(UNIT_SECOND) // duration
write_short(0) // hold time
write_short(FFADE_IN) // fade type
write_byte(0) // red
write_byte(0) // green
write_byte(0) // blue
write_byte(255) // alpha
message_end()
}

public zp_user_infected_post(id, infector)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_tank) && !zp_get_user_nemesis(id))
	{
		is_cooldown[id] = 0
		is_cooldown_time[id] = floatround(g_revenge_cooldown)

		color_chat(id, "!t[Sleep zombie] !g%L", id, "SLEEP_ABILITY_INFO"); color_chat(id, "!t[Sleep zombie] !g%L", id, "SLEEP_ABILITY_INFO")
		
		// Set custom sounds using ZP natives
		zp_override_user_painsound(id, "ch2012/sleep_hit1.wav", sizeof(g_hit_sound))
		zp_override_user_spawnsound(id, g_spawn_sound[random_num(0, sizeof(g_spawn_sound) - 1)])
		zp_override_user_idlesound(id, "ch2012/sleep_idle1.wav", sizeof(g_idle_sound))
	}
	
	if(infector > 0 && is_user_connected(infector) && (zp_get_user_zombie_class(infector) == g_zclass_tank) && !zp_get_user_nemesis(infector))
	{
		// Possible future upgrade system
	}
}

public zp_user_humanized_post(id)
{
remove_task(id)
is_cooldown[id] = 0
}

public roundStart()
{
for (new i = 1; i <= g_maxplayers; i++)
{
is_cooldown[i] = 0
is_cooldown_time[i] = floatround(g_revenge_cooldown)
remove_task(i)
}
}

stock color_chat(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)

	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!t", "^3")

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