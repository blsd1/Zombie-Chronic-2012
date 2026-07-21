#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <zombieplague>

#define VERSION "1.2"

new const zclass_name[] = { "Crab zombie" }
new const zclass_info[] = { "[poskodenie]" }
new const zclass_model[] = { "ch2012_head" }
new const zclass_clawmodel[] = { "ch2012_head_hand.mdl" }
const zclass_health = 600
const zclass_speed = 900
const Float:zclass_gravity = 0.60
const Float:zclass_knockback = 1.14

new g_zclass_crab
new g_headcrab[33][2]

new const g_pain_sound[][] = 
{
	"ch2012/head_hit1.wav",
	"ch2012/head_hit2.wav",
	"ch2012/head_hit3.wav"
}

public plugin_precache()
{
	g_zclass_crab = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	
	for(new i = 0; i < sizeof(g_pain_sound); i++)
		precache_sound(g_pain_sound[i]);
}
public plugin_init()
{	
	register_plugin("[ZP] Headcrab zombie", VERSION, "aaarnas")
	register_dictionary("zombie_plague.txt")
	register_cvar("zp_headcrab_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("zp_headcrab_version", VERSION)
	RegisterHam(Ham_Spawn, "player", "FwdHamPlayerSpawnPost")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam( Ham_TakeDamage, "player", "fw_TakeDamage" )
}


public zprava(id)
{
	if( !is_user_alive( id ) || !zp_get_user_zombie( id ) || zp_get_user_zombie_class( id ) != g_zclass_crab || zp_get_user_nemesis( id )) 
		return PLUGIN_HANDLED 
	
	ChatColor(id, "!t[Crawler] !g%L", id, "CRAB_CRIT_DAMAGE");
	ChatColor(id, "!t[Crawler] !g%L", id, "CRAB_CRIT_DAMAGE");
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

public client_connect(id)
{
	g_headcrab[id][0] = false
	g_headcrab[id][1] = false
}	
public client_disconnected(id)
{
	g_headcrab[id][0] = false
	g_headcrab[id][1] = false
	set_pev(id, pev_bInDuck, 0)
	client_cmd(id, "-duck")
}
public FwdHamPlayerSpawnPost(id)
{
	if(g_headcrab[id][0]) {
		g_headcrab[id][0] = false
		set_user_hitzones(0, id, 255)
		set_pev(id, pev_bInDuck, 0)
		client_cmd(id, "-duck")
	}
	if(g_headcrab[id][1]) {
		set_user_hitzones(0, id, 255)
		g_headcrab[id][1] = false
	}
}
public fw_PlayerKilled(id)
{
	if(g_headcrab[id][0]) {
		g_headcrab[id][0] = false
		set_user_hitzones(0, id, 255)
		client_cmd(id, "cl_forwardspeed 400; cl_backspeed 400; cl_sidespeed 400")
		set_pev(id, pev_bInDuck, 0)
		client_cmd(id, "-duck")
	}
}

public fw_TakeDamage( victim, inflictor, attacker, Float:damage, damage_type )
{	
	if( !is_user_alive( attacker ) || !zp_get_user_zombie( attacker ) || zp_get_user_zombie_class( attacker ) != g_zclass_crab || zp_get_user_nemesis( attacker )) 
		return PLUGIN_HANDLED 
	if( zp_get_user_zombie_class( attacker ) == g_zclass_crab)  // Hr�� mus� b�t Crab zombie
	{
		if( random_num( 0, 100 ) < random_num( 0, 100 ) < random_num( 0, 100 ))
		{
			SetHamParamFloat( 4, damage *= 3.0 )
			
			cmd_fade8( attacker )
			client_print( attacker, print_center, "%L", attacker, "CRAB_CRIT_BITE")
			
			cmd_fade9( victim )
			client_print( victim, print_center, "%L", victim, "CRAB_CRIT_BITE")
		}
	}
	
	return HAM_IGNORED;
}
public cmd_fade8(id)
{	
	set_task(2.1, "cmd_fade9", id)
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
	write_short(2) // cas trvania  v sekundach 
	write_short(2)
	write_short(0x0004)
	write_byte(255) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(50) // alpha
	message_end()
}

public cmd_fade9(id)
{	
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
	write_short(99999) // cas trvania  v sekundach 
	write_short(4)
	write_short(0x0004)
	write_byte(255) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(10) // alpha
	message_end()
}

public zp_user_infect_attempt(id) {
	// Allow bots to be crab, but they will have different behavior
	// Don't force class change anymore
}
public zp_user_infected_post(id, infector, nemesis)
{		
	if(zp_get_user_zombie_class(id) == g_zclass_crab && !nemesis) {
		set_task(0.1, "zprava", id)
		client_cmd(id, "speak sound/headcrab/hc_headbite")
		g_headcrab[id][0] = true
		g_headcrab[id][1] = true
		
		// Bots: standing position with slower speed
		if(is_user_bot(id))
		{
			// Bots stand normally (no duck) but move slower
			set_pev(id, pev_maxspeed, 300.0)
		}
		else
		{
			// Players: duck mode with fast speed
			client_cmd(id, "cl_forwardspeed 2000; cl_backspeed 2000; cl_sidespeed 2000")
			set_pev(id, pev_bInDuck, 1)
			console_cmd(id, "+duck")
		}
		
		set_user_hitzones(0, id, 200)
		set_user_footsteps(id, 1)
		
		zp_override_user_painsound(id, "ch2012/head_hit1.wav", 3);
	}
	else if(zp_get_user_zombie_class(id) == g_zclass_crab) {
		set_task(0.1, "zprava", id)
		g_headcrab[id][0] = false
		set_user_hitzones(0, id, 255)
		set_pev(id, pev_bInDuck, 0)
		client_cmd(id, "-duck")
	}
	else g_headcrab[id][0] = false
}
public zp_user_humanized_post(id)
{
	g_headcrab[id][0] = false
	set_user_hitzones(0, id, 255)
	client_cmd(id, "cl_forwardspeed 400; cl_backspeed 400; cl_sidespeed 400")
	set_pev(id, pev_bInDuck, 0)
	client_cmd(id, "-duck")
}
public client_PreThink(id)
{
	if(g_headcrab[id][0] && !is_user_bot(id)) {
		set_pev(id, pev_bInDuck, 1)
		console_cmd(id, "+duck")
	}
}
