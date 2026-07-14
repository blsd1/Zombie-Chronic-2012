
#include	< amxmodx >
#include 	< zombieplague >
#include 	< fun >
#include 	< cstrike >
#include 	< engine >

#define PL_NAME				"[ZP] Terminator fixed"
#define VERSION 			"1.0"
#define PL_AUTHOR			"Ketamine"

#define TERM_COST                       200

#define TERM_MAXARMOR 			550

#define TERM_MINJUMP			300.0
#define TERM_MAXJUMP                    300.0
#define TERM_KILLAP                     5
#define TERM_JUMPS                      4

#define R                  		0
#define G                    		200
#define B                     		0
#define AMMOUNT_GLOW                    15

#define TASK_NACITAT 846465465466

// Max simultaneous Terminators on a normal round. When this many already exist,
// the next player who buys Terminator becomes a Nemesis instead.
#define TERM_MAX 5
			
new iTerm, terminator[ 33 ];

new TERM_health, TERM_armor;
new TERM_regen_hp, TERM_regen_armor;

#define TASK_REGEN 100000

new MaTerma[ 33 ] = false;

new jumpnum[ 33 ] = 0

new bool:dojump[ 33 ] = false;

new g_HudTerm;


public plugin_init( )
{
	register_plugin( PL_NAME, VERSION, PL_AUTHOR )

	register_dictionary( "zp_extra_terminator.txt" )
	register_dictionary( "zombie_plague.txt" ) // "too many terminators -> Nemesis" notice keys live here

	iTerm = zp_register_extra_item( "Terminator [ExtraVIP]", TERM_COST, ZP_TEAM_HUMAN )
	
	register_event( "HLTV", "event_round_start", "a", "1=0", "2=0" )

	register_event( "DeathMsg","event_death","a" )	
	
	TERM_health 	= 	register_cvar( "zp_term_health", "555" )
	TERM_armor  	= 	register_cvar( "zp_term_armor", "555" )

	// Kolko HP a armor dostane terminator kazde 3 sekundy (nastavitelne)
	TERM_regen_hp    = register_cvar( "zp_term_regen_hp", "100" )
	TERM_regen_armor = register_cvar( "zp_term_regen_armor", "100" )

	g_HudTerm 	= 	CreateHudSyncObj( );
}


public zp_user_infected_post( id )
{
	if( !zp_get_user_nemesis( id ) ) client_set_variables( id );
}

public client_putinserver( i )
{
	client_set_variables( i );
}

public client_disconnected( i )
{
	client_set_variables( i );
}

public zp_extra_item_selected( human, itemid )
{
	if ( itemid == iTerm )
	{
		if ( terminator[ human ] )
		{
			client_print( human, print_center, "%L", human, "TERM_ALREADY_HAVE" )
			return ZP_PLUGIN_HANDLED;
		}
		
		if ( !zp_has_round_started( ) )
		{
			client_print( human, print_center, "%L", human, "TERM_WAIT_FIRST_ZOMBIE" )
			return ZP_PLUGIN_HANDLED;
		}
		
		// Too many Terminators on a normal round: this buyer becomes a Nemesis instead of a Terminator
		if ( is_normal_round( ) && count_terminators( ) >= TERM_MAX )
		{
			make_terminator_nemesis( human );
			return PLUGIN_CONTINUE; // cost stays spent - they paid and got a Nemesis
		}

		MaTerma[ human ] = true
		terminator[ human ] = true
		zp_set_user_terminator( human );
		make_user_terminator( human );
	}
	return PLUGIN_CONTINUE;
}
	
public event_round_start( )
{
	for(new player = 1; player <= 32; player++)
	{
		if(!is_user_connected(player))
			continue
			
		if(MaTerma[player] && terminator[player])
		{
			// Ak je stále Terminator a prežil, daj mu HP a armor po freezetime + 3s
			remove_task(player + TASK_REGEN); set_task(3.0, "task_term_regen", player + TASK_REGEN, _, _, "b")
		}
		else if(MaTerma[player])
		{
			remove_user_terminator(player)
		}
	}
}

public task_give_terminator_bonus(player)
{
	if(!is_user_alive(player) || !terminator[player] || !MaTerma[player])
		return
		
	set_user_health(player, 350)
	cs_set_user_armor(player, 350, CS_ARMOR_VESTHELM)
	
	client_print(player, print_center, "[ZP] %L", player, "TERM_SURVIVAL_BONUS")
}

public task_term_regen(taskid)
{
	new player = taskid - TASK_REGEN
	if(!is_user_alive(player) || !terminator[player] || !MaTerma[player])
	{
		remove_task(taskid)
		return
	}

	// Drz glow aby ostal viditelne terminator aj v novom kole
	set_user_rendering(player, kRenderFxGlowShell, R, G, B, kRenderNormal, AMMOUNT_GLOW)

	// HP regeneracia (cvar zp_term_regen_hp), strop = zp_term_health
	new addhp = get_pcvar_num(TERM_regen_hp)
	if(addhp > 0)
	{
		new maxhp = get_pcvar_num(TERM_health)
		new newhp = get_user_health(player) + addhp
		if(newhp > maxhp)
			newhp = maxhp
		set_user_health(player, newhp)
	}

	// Armor regeneracia (cvar zp_term_regen_armor), strop = TERM_MAXARMOR
	new addarmor = get_pcvar_num(TERM_regen_armor)
	if(addarmor > 0)
	{
		new newarmor = get_user_armor(player) + addarmor
		if(newarmor > TERM_MAXARMOR)
			newarmor = TERM_MAXARMOR
		cs_set_user_armor(player, newarmor, CS_ARMOR_VESTHELM)
	}
}

make_user_terminator( human )
{
	new CurWeapon = get_user_weapon( human );
	switch( CurWeapon )
	{
		case CSW_AK47: engclient_cmd( human, "weapon_ak47" );
		case CSW_AUG: engclient_cmd( human, "weapon_aug" );
		case CSW_GALIL: engclient_cmd( human, "weapon_galil" );
		case CSW_M3: engclient_cmd( human, "weapon_m3" );
		case CSW_MP5NAVY: engclient_cmd( human, "weapon_mp5navy" );
		case CSW_G3SG1: engclient_cmd( human, "weapon_g3sg1" );
		case CSW_SG552: engclient_cmd( human, "weapon_sg552" );
		case CSW_KNIFE: engclient_cmd( human, "weapon_knife" );
	}
	set_user_health( human, get_pcvar_num( TERM_health ) );
	set_user_armor( human, get_pcvar_num( TERM_armor ) );

	// Spusti regeneraciu HP/armor kazde 3 sekundy
	remove_task( human + TASK_REGEN )
	set_task( 3.0, "task_term_regen", human + TASK_REGEN, _, _, "b" )

	new name[ 32 ]
	get_user_name( human, name, 31 )
	set_hudmessage( 5, 240, 5, 0.05, 0.45, 1, 0.0, 4.5, 0.9, 0.9, -1 )
	ShowSyncHudMsg( 0, g_HudTerm, "%L", LANG_PLAYER, "TERM_IS_TERMINATOR", name );
	set_user_rendering( human, kRenderFxGlowShell, R, G, B, kRenderNormal, AMMOUNT_GLOW );	
}

// Count how many players currently have Terminator active
count_terminators( )
{
	new count = 0
	for ( new i = 1; i <= 32; i++ )
	{
		if ( is_user_connected( i ) && terminator[ i ] )
			count++
	}
	return count
}

// A normal round = not a Nemesis / Survivor / Swarm / Plague special round
bool:is_normal_round( )
{
	return ( !zp_is_nemesis_round( ) && !zp_is_survivor_round( ) && !zp_is_swarm_round( ) && !zp_is_plague_round( ) )
}

// Too many Terminators: turn this player into a Nemesis instead, with a nemesis-style notice
make_terminator_nemesis( human )
{
	new name[ 32 ]
	get_user_name( human, name, charsmax( name ) )

	// Core handles the actual Nemesis transformation
	zp_make_user_nemesis( human )

	// Nemesis-style HUD notice to everyone: "<name> is Nemesis" / "There are too many terminators"
	set_hudmessage( 200, 0, 0, -1.0, 0.25, 1, 0.0, 5.0, 0.5, 0.5, -1 )
	ShowSyncHudMsg( 0, g_HudTerm, "%L^n%L", LANG_PLAYER, "TERM_NEMESIS_TITLE", name, LANG_PLAYER, "TERM_TOO_MANY" )

	// Center message for the new Nemesis
	client_print( human, print_center, "%L", human, "TERM_YOU_ARE_NEMESIS" )
}

public remove_user_terminator( id )
{
	remove_task( id + TASK_REGEN )
	jumpnum[ id ] = 0
	dojump[ id ] = false
	MaTerma[ id ] = false
	terminator[ id ] = false
	if( is_user_connected(id) )
	{
		client_print( id, print_center, "%L", id, "TERM_EXPIRED" );
	}
}

public event_death( ) 
{ 
	new attacker = read_data( 1 ); 
	new victim = read_data( 2 ); 
	
	if( !is_user_connected( attacker ) || !is_user_connected( victim ) )
		return;
	
	if( !is_user_alive( victim ) )
	{
		if( terminator[ victim ] )
		{
			client_set_variables( victim );
		}
	}
	if( is_user_alive( attacker ) )
	{
		if( terminator[ attacker ] )
		{
			new iArmor = get_user_armor( attacker ) 
			
			if( iArmor >= TERM_MAXARMOR )
			{
				set_user_armor( attacker, TERM_MAXARMOR );
				return;
			}
			else
			{
				set_user_armor( attacker, get_user_armor( attacker ) + TERM_KILLAP );
			}
		}
	}
}  

public client_PreThink( id )
{
	if( !is_user_alive( id ) ) 
		return PLUGIN_CONTINUE;
	
	if ( terminator[ id ] )
	{
		new nbut = get_user_button( id )
		new obut = get_user_oldbutton( id )
		if(( nbut & IN_JUMP ) && !( get_entity_flags( id ) & FL_ONGROUND ) && !( obut & IN_JUMP ) )
		{
			if( jumpnum[ id ] < TERM_JUMPS ) 
			{
				dojump[ id ] = true
				jumpnum[ id ]++
				ChatColor( id, "!y[ZP] !y%L", id, "TERM_JUMPS", jumpnum[ id ] );
				return PLUGIN_CONTINUE
			}
			else
			{
				if (!task_exists(id+TASK_NACITAT))
				{
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
}

public client_PostThink( id )
{
	if( !is_user_alive( id ) ) 
		return PLUGIN_CONTINUE;
	
	if ( terminator[ id ] )
	{
		if( dojump[ id ] == true )
		{
			new Float:velocity[ 3 ]	
			
			entity_get_vector( id,EV_VEC_velocity,velocity )
			velocity[ 2 ] = random_float( TERM_MINJUMP, TERM_MAXJUMP )
			entity_set_vector( id,EV_VEC_velocity,velocity )
			dojump[ id ] = false
			return PLUGIN_CONTINUE;
		}
	}
	return PLUGIN_CONTINUE
}

public client_set_variables( i )
{
	if( !is_user_connected( i ) || is_user_bot( i ) )
		return;
	
	remove_task( i + TASK_REGEN ); set_user_rendering( i, kRenderFxNone, 0, 0, 0, kRenderNormal, AMMOUNT_GLOW );
	
	jumpnum[ i ]		 = 	0;
	dojump[ i ] 		 = 	false;
	MaTerma[ i ]		 = 	false;
	terminator[ i ]	 	 = 	false;

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