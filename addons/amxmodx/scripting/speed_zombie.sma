#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <engine>

#define PLUGIN "[ZP] Class - Speed"
#define VERSION "1.0"
#define AUTHOR "ketamine"

// Zombie Attributes
new g_zclass_speed
new const zclass_name[] = "Speed Zombie" // name
new const zclass_info[] = "[speed boost]" // description
new const zclass_model[] = "ch2012_speed" // model
new const zclass_clawmodel[] = "ch2012_speed_hand.mdl" // claw model
const zclass_health = 2100 // health
const zclass_speed = 300 // speed
const Float:zclass_gravity = 1.00 // gravity
const Float:zclass_knockback = 2.49 // knockback

new g_speed_boost[33]
new g_cooldown[33]
new i_cooldown_time[33]
new g_maxplayers

// --- config ------------------------ //
new Float:g_base_speed = 300.0
new Float:g_boost_speed = 450.0 // 1.5x boost
new Float:g_ability_duration = 5.0
new Float:g_cooldown_duration = 25.0

new const SpeedBoostSound[] = { "sound/ch2012/speed_active.wav" }

// Custom Speed Zombie sounds from ch2012 folder
new const g_spawn_sound[][] = 
{
	"ch2012/speed_start1.wav",
	"ch2012/speed_start2.wav"
}

new const g_hit_sound[][] = 
{
	"ch2012/speed_hit1.wav",
	"ch2012/speed_hit2.wav",
	"ch2012/speed_hit3.wav",
	"ch2012/speed_hit4.wav"
}

new const g_death_sound[][] = 
{
	"ch2012/speed_die1.wav",
	"ch2012/speed_die2.wav",
    "ch2012/speed_die3.wav"
}

// ----------------------------------- //

public plugin_init()
{   
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("zp_zclass_speed_zombie",VERSION,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
	register_forward( FM_CmdStart , "fw_FM_CmdStart" );
	register_logevent("roundStart", 2, "1=Round_Start")
	g_maxplayers = get_maxplayers()
	register_forward(FM_PlayerPreThink, "prethink")
}

public prethink(id)
{
	static button,oldbuttons; 
	button = pev( id, pev_button ); 
	oldbuttons = pev( id, pev_oldbuttons ); 
	if(button & IN_RELOAD && !(oldbuttons & IN_RELOAD)) 
	{
		use_ability_speed(id)
	} 
}

public plugin_precache()
{
	g_zclass_speed = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	
	precache_generic(SpeedBoostSound)
	
	// Precache custom speed sounds
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
	register_native("is_user_speed_zombie", "native_is_user_speed_zombie", 1);
}

public native_is_user_speed_zombie(id)
{
	if(!is_user_connected(id))
		return 0;
		
	if(!zp_get_user_zombie(id))
		return 0;
		
	if(zp_get_user_zombie_class(id) == g_zclass_speed)
		return 1;
		
	return 0;
}

public roundStart()
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		i_cooldown_time[i] = floatround(g_cooldown_duration)
		g_cooldown[i] = 0
		g_speed_boost[i] = 0
		remove_task(i)
		remove_task(i+1000) // cooldown hud task
		remove_task(i+2000) // ability duration task
	}
}

public use_ability_speed(id)
{
	if(is_valid_ent(id) && is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_speed)
	{
		if(g_cooldown[id] == 0)
		{		
			client_cmd(id, "spk ^"%s^"", SpeedBoostSound)
			
			// Aktivuj speed boost
			g_speed_boost[id] = 1
			set_user_maxspeed(id, g_boost_speed)
			
			// Vizuálny efekt - červený flash
			UTIL_ScreenFade(id, 200, 100, 0, 75)
			
			// Nastav task na ukončenie ability
			set_task(g_ability_duration, "speed_boost_end", id+2000)
			g_cooldown[id] = 1
			
			color_chat(id, "!t[Speed Zombie] !gSPEED BOOST AKTIVNY!")
		}
	}
}

public speed_boost_end(taskid)
{
	new id = taskid - 2000
	
	if(is_valid_ent(id) && is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_speed)
	{
		// Vypni speed boost
		g_speed_boost[id] = 0
		set_user_maxspeed(id, g_base_speed)
		
		// Slabší vizuálny efekt pri ukončení
		
		color_chat(id, "!t[Speed Zombie] !gSpeed boost skoncil")
		
		// Spusti cooldown
		i_cooldown_time[id] = floatround(g_cooldown_duration)
		set_task(g_cooldown_duration, "reset_cooldown", id+2000)
		set_task(1.0, "ShowHUD", id+1000, _, _, "a", i_cooldown_time[id])
	}
}

public ShowHUD(taskid)
{
	new id = taskid - 1000
	
	if(is_valid_ent(id) && is_user_alive(id))
	{
		i_cooldown_time[id] = i_cooldown_time[id] - 1;
		set_hudmessage(200, 100, 0, 0.76, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1)
		show_hudmessage(id, "Cooldown: %d s",i_cooldown_time[id])
	}
	else
	{
		remove_task(taskid)
	}
}

public reset_cooldown(taskid)
{
	new id = taskid - 2000
	
	if(is_valid_ent(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie_class(id) == g_zclass_speed)
	{
		g_cooldown[id] = 0
		
		color_chat(id, "!t[Speed Zombie] !gSCHOPNOST JE PRIPRAVENA")
		
		// Prehraj zvuk ked je schopnost nabita
		client_cmd(id, "spk epic_zombie/schopnost_aktivna.wav")
	}
}

public zp_user_infected_post(id, infector)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_speed) && !zp_get_user_nemesis(id))
	{
		color_chat(id, "!t[Speed Zombie] !gStlačenim R aktivuješ speed boost!")
		
		i_cooldown_time[id] = floatround(g_cooldown_duration)
		remove_task(id+1000)
		remove_task(id+2000)
		g_cooldown[id] = 0
		g_speed_boost[id] = 0
		
		// Nastav základnú rýchlosť
		set_user_maxspeed(id, g_base_speed)
		
		// Set custom sounds using ZP natives
		zp_override_user_painsound(id, "ch2012/speed_hit1.wav", sizeof(g_hit_sound))
		zp_override_user_deathsound(id, g_death_sound[random_num(0, sizeof(g_death_sound) - 1)])
		zp_override_user_idlesound(id, "ch2012/speed_start1.wav", sizeof(g_spawn_sound))
	}
}

public zp_user_humanized_post(id)
{
	remove_task(id+1000)
	remove_task(id+2000)
	g_speed_boost[id] = 0
	g_cooldown[id] = 0
}

public fw_FM_CmdStart( id , Handle )
{
	static iButtons , iOldButtons;
	
	iButtons = get_uc( Handle , UC_Buttons );
	iOldButtons = pev( id , pev_oldbuttons );
	
	if( ( iButtons & IN_RELOAD ) && !( iOldButtons & IN_RELOAD ) ) 
	{
		use_ability_speed(id)           
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

// Screenfade funkcia
stock UTIL_ScreenFade(player, r = 0, g = 0, b = 0, alpha = 80)
{
	static msgid
	if(!msgid) msgid = get_user_msgid("ScreenFade")
	
	message_begin(MSG_ONE_UNRELIABLE, msgid, .player = player)
	write_short(1 << 11)
	write_short(1 << 11)
	write_short(0x0000)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(alpha)
	message_end()
}
