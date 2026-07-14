
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>
#include <engine>
#include <xs>
#include <fun>
#include <nvault>

new g_Had_gM89[ 33 ];
new g_msgSayText
new g_M89current = 0;
#define GM89_MAXTEAM	4
#define PLUGIN 		"Hannibal Lector"
#define AUTHOR 		"Laoming"
#define VERSION 	"0.9"

#define AUTHOR_LAOMING		// Compile my plugin without this variable is impossible .) Lao.

#define ITEM_COST 	350
#define KILL_ARMOR	5
#define ARMOR_MAX	900
#define ARMOR_BASIC	900
#define HEALTH_BASIC	800	

#define VIP 		ADMIN_LEVEL_G

#define TASK_NACITAT 846465465466

#if cellbits == 32
const OFFSET_CLIPAMMO 	= 51
#else
const OFFSET_CLIPAMMO 	= 65
#endif
const OFFSET_LINUX_WEAPONS = 4
			
new g_ExtraHannibal, g_hannibal[ 33 ], g_antidote_id;

new MaHanibala[ 33 ] 	= false;

new jumpnum[ 33 ] 	= 0;
new bool:dojump[ 33 ] 	= false;

new g_HudHanibal;

new const snd_hanstr[ ] 	 = 	{ "mixa_zombie/term_str.wav" }
new const snd_hanend[ ]	  = 	{ "mixa_zombie/term_end.wav" }

public plugin_init( )
{
	#if defined AUTHOR_LAOMING
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_dictionary( "zp_extra_hannibal.txt" );

	g_ExtraHannibal = zp_register_extra_item( "Hannibal", ITEM_COST, ZP_TEAM_HUMAN )
	
	// Store antidote ID if available (attempt to get it)
	g_antidote_id = 0  // Will be set when antidote is purchased
	#endif
	
	register_event( "ResetHUD", "playerSpawn", "be" )
	register_event( "HLTV", "event_round_start", "a", "1=0", "2=0" )
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam( Ham_Killed, "player", "fw_PlayerKilled" )

	g_msgSayText = get_user_msgid("SayText")
	g_HudHanibal = CreateHudSyncObj( );
}

public plugin_precache( )
{	
	precache_sound( snd_hanstr ); 
	precache_sound( snd_hanend );
}

public zp_extra_item_selected( player, itemid)
{
	// Hannibal nemôže kupovať vôbec nič (okrem seba samého)
	if(g_hannibal[player] && itemid != g_ExtraHannibal)
	{
		client_print(player, print_center, "%L", player, "HAN_CANNOT")
		return ZP_PLUGIN_HANDLED
	}
	
	if ( itemid != g_ExtraHannibal )
		return PLUGIN_CONTINUE
		
	if (g_hannibal[ player ] )
	{
		client_print( player, print_center, "%L", player, "HAN_ALREADY_HAVE" )
		return ZP_PLUGIN_HANDLED;
	}

	if( g_M89current >= GM89_MAXTEAM )
	{
		client_print( player, print_center, "%L", player, "HAN_TOO_MANY" );
		return ZP_PLUGIN_HANDLED;
	}
	
	// Kontrola či existuje terminátor
	for( new id=1; id<=32; id++ )
	{
		if( !is_user_connected(id) )
			continue;
			
		if(zp_get_user_terminator( id ) )
		{
			for( new i=1; i<=32; i++ )
			{
				if( !is_user_connected(i) )
					continue;
				client_print( i, print_center, "%L", i, "HAN_CANNOT" )
			}
			return ZP_PLUGIN_HANDLED;
		}
	}
	
	if ( !zp_has_round_started( ) )
	{
		client_print( player, print_center, "%L", player, "HAN_WAIT_ZOMBIE" )
		return ZP_PLUGIN_HANDLED;
	}

	client_printcolor( player, "/g[ZP] /y%L", player, "HAN_GET" );
	zp_give_user_chainsaw( player );
	zp_set_user_hannibal( player );
	set_user_rendering( player, kRenderFxGlowShell, 255, 105, 180, kRenderNormal, 14 );
	strip_user_weapons( player );
	g_M89current += 1;
	g_Had_gM89[ player ] = true;
	give_item( player, "weapon_knife" );
	give_item( player, "weapon_hegrenade" );
	client_printcolor( player, "/g[ZP] /y%L", player, "HAN_CURRENT_COUNT", g_M89current );
	give_item( player, "weapon_flashbang" );
	give_item( player, "weapon_mac10" );
	engclient_cmd( player, "weapon_mac10" );
	set_task( 0.1, "SwitchToChainsaw", player );
	
	cs_set_user_bpammo( player, CSW_MAC10, 50 );
	set_user_health( player, HEALTH_BASIC );
	g_hannibal[ player ] = true;
	MaHanibala[ player ] = true;
	set_user_armor( player, ARMOR_BASIC );
	Forward_Hud( player );
	
	return PLUGIN_CONTINUE
}

public fw_PlayerKilled( victim, attacker, shouldgib )
{
	if( g_hannibal[ victim ] )
	{
		g_M89current -= 1;
		g_hannibal[ victim ] = false;
	}	
          
}

public SwitchToChainsaw( player )
	engclient_cmd( player, "weapon_knife" );

public Forward_Hud( id )
{	
	new hName[ 32 ];
	get_user_name( id, hName, 31 );
	
	client_cmd( id, "spk ^"%s^"", snd_hanstr );	
	set_hudmessage( 209, 70, 220, 0.05, 0.45, 1, 0.0, 5.0, 0.9, 0.9, -1 );
	ShowSyncHudMsg( 0, g_HudHanibal, "%L", LANG_PLAYER, "HAN_IS_HANNIBAL", hName );
}

public event_round_start( )
{
	for (new player = 1; player <= 32; player++)
	{
		if(!is_user_connected(player))
			continue
			
		if(g_hannibal[player])
		{
			// Ak je stále Hannibal a prežil, daj mu HP a armor po freezetime + 3s
			new Float:freezetime = get_cvar_float("mp_freezetime")
			set_task(freezetime + 3.0, "task_give_hannibal_bonus", player)
		}
		else
		{
			remove_user_hannibal(player)
		}
	}
}

public task_give_hannibal_bonus(player)
{
	if(!is_user_alive(player) || !g_hannibal[player])
		return
		
	set_user_health(player, 600)
	cs_set_user_armor(player, 600, CS_ARMOR_VESTHELM)
	
	client_print(player, print_chat, "%L", player, "HAN_SURVIVAL_BONUS")
}

public playerSpawn( player )
{
	if ( MaHanibala[ player ] )
	{	
		jumpnum[ player ] = 0
		dojump[ player ] = false
		MaHanibala[ player ] = false
		g_hannibal[ player ] = false;
	}
}

public client_putinserver( id )
{
	jumpnum[ id ] = 0
	dojump[ id ] = false
	MaHanibala[ id ] = false;
}

public client_disconnected( id )
{
	jumpnum[ id ] = 0
	dojump[ id] = false
	MaHanibala[ id ] = false;
	g_hannibal[ id ] = false;
}
	
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_bits)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED
	
	new iWeapon = get_user_weapon(attacker)
	if( !(iWeapon == CSW_MAC10) )
	{
		if( is_user_alive( attacker ) )
		{
			if( g_hannibal[ attacker ] )
			{
				new armor = get_user_armor( attacker );
				if( armor >= ARMOR_MAX )
				{
					set_user_armor( attacker, ARMOR_MAX );
					return HAM_IGNORED;
				}
				else
				{
					client_print( attacker, print_center, "%L", attacker, "HAN_ARMOR_PLUS" )
					set_user_armor( attacker, get_user_armor( attacker ) + KILL_ARMOR )
				}
			}
		}
	}
	return HAM_IGNORED;
}


public zp_user_infected_post( id )
{
	MaHanibala[ id ] = false;
	g_hannibal[ id ] = false;
	if( g_Had_gM89[ id ] )
	{
		g_M89current -= 1;
		g_Had_gM89[ id ] = false;
	}
	jumpnum[ id ] = 0;
}

public remove_user_hannibal( id )
{
	// Kontrola či hráč vôbec mal Hannibala
	if(!MaHanibala[id])
		return
	
	jumpnum[ id ] = 0
	dojump[ id ] = false
	MaHanibala[ id ] = false;
	g_hannibal[ id ] = false;
	client_print( id, print_center, "%L", id, "HAN_EXPIRED" );
	client_cmd( id, "spk ^"%s^"", snd_hanend );
}

public client_PreThink( id )
{
	if( !is_user_alive( id ) ) return PLUGIN_CONTINUE;
	
	if ( g_hannibal[ id ] )
	{
		new nbut = get_user_button( id );
		new obut = get_user_oldbutton( id );
		
		if(( nbut & IN_JUMP ) && !( get_entity_flags( id ) & FL_ONGROUND ) && !( obut & IN_JUMP ) )
		{
			if( jumpnum[ id ] < 3 )
			{
				dojump[ id ] = true
				jumpnum[ id ]++
				client_printcolor( id, "/g[ZP] /y%L", id, "HAN_JUMPED", jumpnum[ id ] );
				return PLUGIN_CONTINUE
			}
			else
			{
				if (!task_exists(id+TASK_NACITAT))
				{
					client_printcolor( id, "!g[ZP] !y%L", id, "HAN_JUMPED_OUT");
					set_task(4.5, "nacitat_skoky", id+TASK_NACITAT)
				}
			}	                      
                }              
	}
	return PLUGIN_CONTINUE;
}

public nacitat_skoky( id )
{
	id -= TASK_NACITAT
	dojump[ id ] = false
	jumpnum[ id ] = 0
    client_printcolor( id, "/y[ZP] /y%L", id, "HAN_JUMPS_RESTORED");
}

public client_PostThink( id )
{
	if( !is_user_alive( id ) ) return PLUGIN_CONTINUE;
	
	if ( g_hannibal[ id ] )
	{
		if( dojump[ id ] == true )
		{
			new Float:velocity[ 3 ];
			entity_get_vector( id,EV_VEC_velocity,velocity )
			velocity[2] = random_float( 230.0,240.0 );
			entity_set_vector( id,EV_VEC_velocity,velocity )
			dojump[ id ] = false                            
			return PLUGIN_CONTINUE;
		}
	}
	return PLUGIN_CONTINUE;
} 

stock client_printcolor(const id, const input[], any:...)
{
	new iCount = 1, iPlayers[32]
	
	static szMsg[191]
	vformat(szMsg, charsmax(szMsg), input, 3)
	
	replace_all(szMsg, 190, "/g", "^4") // green txt
	replace_all(szMsg, 190, "/y", "^1") // orange txt
	replace_all(szMsg, 190, "/ctr", "^3") // team txt
	replace_all(szMsg, 190, "/w", "^0") // team txt
	
	if(id) iPlayers[0] = id
	else get_players(iPlayers, iCount, "ch")
		
	for (new i = 0; i < iCount; i++)
	{
		if (is_user_connected(iPlayers[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, iPlayers[i])
			write_byte(iPlayers[i])
			write_string(szMsg)
			message_end()
		}
	}
}
