
#include	< amxmodx >
#include 	< zombieplague >
#include 	< fun >
#include 	< cstrike >
#include 	< engine >

#define PL_NAME				"[ZP] Terminator fixed"
#define VERSION 			"v0.4"
#define PL_AUTHOR			"Ketamine"

#define TERM_COST                       200

#define TERM_MAXARMOR 			555

#define TERM_MINJUMP			300.0
#define TERM_MAXJUMP                    300.0
#define TERM_KILLAP                     5
#define TERM_JUMPS                      4

#define R                  		0
#define G                    		240
#define B                     		0
#define AMMOUNT_GLOW                    20
			
new iTerm, terminator[ 33 ];

new TERM_health, TERM_armor;

new MaTerma[ 33 ] = false;

new jumpnum[ 33 ] = 0

new bool:dojump[ 33 ] = false;

new g_HudTerm;

new const snd_termstr[ ] 	 = 	{ "mixa_zombie/term_str.wav" }
new const snd_termend[ ]	 	 = 	{ "mixa_zombie/term_end.wav" }

public plugin_init( )
{
	register_plugin( PL_NAME, VERSION, PL_AUTHOR )
	
	iTerm = zp_register_extra_item( "Terminator [ExtraVIP]", TERM_COST, ZP_TEAM_HUMAN )
	
	register_event( "HLTV", "event_round_start", "a", "1=0", "2=0" )

	register_event( "DeathMsg","event_death","a" )	
	
	TERM_health 	= 	register_cvar( "zp_term_health", "555" )
	TERM_armor  	= 	register_cvar( "zp_term_armor", "555" )
	
	g_HudTerm 	= 	CreateHudSyncObj( );
}

public plugin_precache( )
{	
	precache_sound( snd_termstr ); 
	precache_sound( snd_termend );
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
			client_print( human, print_center, "Uz mas terminatora!" )
			return ZP_PLUGIN_HANDLED;
		}
		
		if ( !zp_has_round_started( ) )
		{
			client_print( human, print_center, "Musis pockat az bude prvni zombie !" )
			return ZP_PLUGIN_HANDLED;
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
			new Float:freezetime = get_cvar_float("mp_freezetime")
			set_task(freezetime + 3.0, "task_give_terminator_bonus", player)
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
	
	client_print(player, print_center, "[ZP] Dostal si bonus za prezitie: 350 HP + 350 Armor!")
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
	
	new name[ 32 ]
	get_user_name( human, name, 31 )
	set_hudmessage( 5, 240, 5, 0.05, 0.45, 1, 0.0, 4.5, 0.9, 0.9, -1 )
	ShowSyncHudMsg( 0, g_HudTerm, "%s je Terminator", name );
	client_cmd( human, "spk ^"%s^"", snd_termstr );	
	set_user_rendering( human, kRenderFxGlowShell, R, G, B, kRenderNormal, AMMOUNT_GLOW );	
}

public remove_user_terminator( id )
{
	jumpnum[ id ] = 0
	dojump[ id ] = false
	MaTerma[ id ] = false
	terminator[ id ] = false
	if( is_user_connected(id) )
	{
		client_print( id, print_center, "Terminator ti na nove kolo vyprsel..." );
		client_cmd( id, "spk ^"%s^"", snd_termend );
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
				return PLUGIN_CONTINUE
			}
		}
		if( ( nbut & IN_JUMP ) && ( get_entity_flags( id ) & FL_ONGROUND ) )
		{
			jumpnum[ id ] = 0
			return PLUGIN_CONTINUE;
		}
	}
	return PLUGIN_CONTINUE;
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
	
	set_user_rendering( i, kRenderFxNone, 0, 0, 0, kRenderNormal, AMMOUNT_GLOW );
	
	jumpnum[ i ]		 = 	0;
	dojump[ i ] 		 = 	false;
	MaTerma[ i ]		 = 	false;
	terminator[ i ]	 	 = 	false;

}