#pragma semicolon 1

#include < amxmodx >
#include < fakemeta >
#include < engine >

native zp_get_user_zombie( iPlayer );
native zp_get_user_ammo_packs( iPlayer );
native zp_set_user_ammo_packs( iPlayer, iPacks );

#define MAX_ENTITIES		600
#define MAX_PLAYERS		32
#define MINE_ON			1
#define MINE_OFF			0
#define TASK_CREATE		84765
#define TASK_REMOVE		86766
#define MINE_COST			6
#define MINE_CLASSNAME		"zp_trip_mine"
#define MINE_MODEL_EXPLODE	"sprites/zerogxplode.spr"
#define MINE_MODEL_VIEW		"models/ch2012/v_laser_mine.mdl"
#define MINE_SOUND_ACTIVATE	"weapons/mine_activate.wav"
#define MINE_SOUND_CHARGE		"weapons/mine_charge.wav"
#define MINE_SOUND_DEPLOY		"weapons/mine_deploy.wav"
#define MINE_HEALTH		650.0
#define entity_get_owner(%0)		entity_get_int( %0, EV_INT_iuser2 )
#define entity_get_status(%0)		entity_get_int( %0, EV_INT_iuser1 )
#define entity_get_classname(%0,%1)	entity_get_string( %0, EV_SZ_classname, %1, charsmax( %1 ) )

new g_iTripMines[ 33 ];
new g_iPlantedMines[ 33 ];
new g_iPlanting[ 33 ];
new g_iRemoving[ 33 ];
new g_hExplode;

public plugin_init( )
{
	register_plugin( "[ZP] Trip Mines", "1.0", "Hattrick" );
	
	register_clcmd( "say /lm", "Command_Buy" );
	register_clcmd( "say lm", "Command_Buy" );
	
	register_clcmd( "CreateLaser", "Command_Plant" );
	register_clcmd( "TakeLaser", "Command_Take" );
	
	register_logevent( "Event_RoundStart", 2, "1=Round_Start" );
	
	register_think( MINE_CLASSNAME, "Forward_Think" );
}

public plugin_precache( )
{
	engfunc( EngFunc_PrecacheModel, MINE_MODEL_VIEW );
	
	engfunc( EngFunc_PrecacheSound, MINE_SOUND_ACTIVATE );
	engfunc( EngFunc_PrecacheSound, MINE_SOUND_CHARGE );
	engfunc( EngFunc_PrecacheSound, MINE_SOUND_DEPLOY );
	
	g_hExplode = engfunc( EngFunc_PrecacheModel, MINE_MODEL_EXPLODE );
}

public client_disconnected( iPlayer )
{
	g_iTripMines[ iPlayer ] = 0;
	g_iPlanting[ iPlayer ] = false;
	g_iRemoving[ iPlayer ] = false;
	
	if( g_iPlantedMines[ iPlayer ] )
	{
		Func_RemoveMinesByOwner( iPlayer );
		
		g_iPlantedMines[ iPlayer ] = 0;
	}
	
	remove_task( iPlayer + TASK_REMOVE );
	remove_task( iPlayer + TASK_CREATE );
}

public Command_Buy( iPlayer )
{
	if( !is_user_alive( iPlayer ) )
	{
		client_print( iPlayer, print_chat, "[ZP] You should be alive" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( zp_get_user_zombie( iPlayer ) )
	{
		client_print( iPlayer, print_chat, "[ZP] You should be human" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( zp_get_user_ammo_packs( iPlayer ) < MINE_COST )
	{
		client_print( iPlayer, print_chat, "[ZP] You need %i ammo packs", MINE_COST );
		
		return PLUGIN_CONTINUE;
	}
	
	zp_set_user_ammo_packs( iPlayer, zp_get_user_ammo_packs( iPlayer ) - MINE_COST );
	
	g_iTripMines[ iPlayer ]++;
	
	client_print( iPlayer, print_chat, "[ZP] You bought a trip mine. Press 'p' to plant it or 'v' to take it" );
	
	client_cmd( iPlayer, "bind p CreateLaser" );
	client_cmd( iPlayer, "bind v TakeLaser" );
	
	return PLUGIN_CONTINUE;
}

public Command_Plant( iPlayer )
{
	if( !is_user_alive( iPlayer ) )
	{
		client_print( iPlayer, print_chat, "[ZP] You should be alive" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( zp_get_user_zombie( iPlayer ) )
	{
		client_print( iPlayer, print_chat, "[ZP] You should be human" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( !g_iTripMines[ iPlayer ] )
	{
		client_print( iPlayer, print_chat, "[ZP] You don't have a trip mine to plant" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( g_iPlantedMines[ iPlayer ] > 1 )
	{
		client_print( iPlayer, print_chat, "[ZP] You can plant only 2 mines" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( g_iPlanting[ iPlayer ] || g_iRemoving[ iPlayer ] )
		return PLUGIN_CONTINUE;
	
	if( CanPlant( iPlayer ) ) {
		g_iPlanting[ iPlayer ] = true;
		
		message_begin( MSG_ONE_UNRELIABLE, 108, _, iPlayer );
		write_byte( 1 );
		write_byte( 0 );
		message_end( );
		
		set_task( 1.2, "Func_Plant", iPlayer + TASK_CREATE );
	}
	
	return PLUGIN_CONTINUE;
}

public Command_Take( iPlayer )
{
	if( !is_user_alive( iPlayer ) )
	{
		client_print( iPlayer, print_chat, "[ZP] You should be alive" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( zp_get_user_zombie( iPlayer ) )
	{
		client_print( iPlayer, print_chat, "[ZP] You should be human" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( !g_iPlantedMines[ iPlayer ] )
	{
		client_print( iPlayer, print_chat, "[ZP] You don't have a planted mine" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( g_iPlanting[ iPlayer ] || g_iRemoving[ iPlayer ] )
		return PLUGIN_CONTINUE;
	
	if( CanTake( iPlayer ) ) {
		g_iRemoving[ iPlayer ] = true;
		
		message_begin( MSG_ONE_UNRELIABLE, 108, _, iPlayer );
		write_byte( 1 );
		write_byte( 0 );
		message_end( );
		
		set_task( 1.2, "Func_Take", iPlayer + TASK_REMOVE );
	}
	
	return PLUGIN_CONTINUE;
}

public Event_RoundStart( ) {
	static iEntity, szClassName[ 32 ], iPlayer;
	for( iEntity = 0; iEntity < MAX_ENTITIES + 1; iEntity++ ) {
		if( !is_valid_ent( iEntity ) )
			continue;
		
		szClassName[ 0 ] = '^0';
		entity_get_classname( iEntity, szClassName );
		
		if( equal( szClassName, MINE_CLASSNAME ) )
			remove_entity( iEntity );
	}
	
	for( iPlayer = 1; iPlayer < 33; iPlayer++ ) {
		g_iTripMines[ iPlayer ] = 0;
		g_iPlantedMines[ iPlayer ] = 0;
	}
}

public Func_Take( iPlayer ) {
	iPlayer -= TASK_REMOVE;
	
	g_iRemoving[ iPlayer ] = false;
	
	static iEntity, szClassName[ 32 ], Float: flOwnerOrigin[ 3 ], Float: flEntityOrigin[ 3 ];
	for( iEntity = 0; iEntity < MAX_ENTITIES + 1; iEntity++ ) {
		if( !is_valid_ent( iEntity ) )
			continue;
		
		szClassName[ 0 ] = '^0';
		entity_get_classname( iEntity, szClassName );
		
		if( equal( szClassName, MINE_CLASSNAME ) ) {
			if( entity_get_owner( iEntity ) == iPlayer ) {
				entity_get_vector( iPlayer, EV_VEC_origin, flOwnerOrigin );
				entity_get_vector( iEntity, EV_VEC_origin, flEntityOrigin );
				
				if( get_distance_f( flOwnerOrigin, flEntityOrigin ) < 55.0 ) {
					g_iPlantedMines[ iPlayer ]--;
					g_iTripMines[ iPlayer ]++;
					
					remove_entity( iEntity );
					
					break;
				}
			}
		}
	}
}

public bool: CanTake( iPlayer ) {
	static iEntity, szClassName[ 32 ], Float: flOwnerOrigin[ 3 ], Float: flEntityOrigin[ 3 ];
	for( iEntity = 0; iEntity < MAX_ENTITIES + 1; iEntity++ ) {
		if( !is_valid_ent( iEntity ) )
			continue;
		
		szClassName[ 0 ] = '^0';
		entity_get_classname( iEntity, szClassName );
		
		if( equal( szClassName, MINE_CLASSNAME ) ) {
			if( entity_get_owner( iEntity ) == iPlayer ) {
				entity_get_vector( iPlayer, EV_VEC_origin, flOwnerOrigin );
				entity_get_vector( iEntity, EV_VEC_origin, flEntityOrigin );
				
				if( get_distance_f( flOwnerOrigin, flEntityOrigin ) < 55.0 )
					return true;
			}
		}
	}
	
	return false;
}

public bool: CanPlant( iPlayer ) {
	static Float: flOrigin[ 3 ];
	entity_get_vector( iPlayer, EV_VEC_origin, flOrigin );
	
	static Float: flTraceDirection[ 3 ], Float: flTraceEnd[ 3 ], Float: flTraceResult[ 3 ], Float: flNormal[ 3 ];
	velocity_by_aim( iPlayer, 64, flTraceDirection );
	flTraceEnd[ 0 ] = flTraceDirection[ 0 ] + flOrigin[ 0 ];
	flTraceEnd[ 1 ] = flTraceDirection[ 1 ] + flOrigin[ 1 ];
	flTraceEnd[ 2 ] = flTraceDirection[ 2 ] + flOrigin[ 2 ];
	
	static Float: flFraction, iTr;
	iTr = 0;
	engfunc( EngFunc_TraceLine, flOrigin, flTraceEnd, 0, iPlayer, iTr );
	get_tr2( iTr, TR_vecEndPos, flTraceResult );
	get_tr2( iTr, TR_vecPlaneNormal, flNormal );
	get_tr2( iTr, TR_flFraction, flFraction );
	
	if( flFraction >= 1.0 ) {
		client_print( iPlayer, print_chat, "[ZP] You must plant the tripmine on a wall" );
		
		return false;
	}
	
	return true;
}

public Func_Plant( iPlayer ) {
	iPlayer -= TASK_CREATE;
	
	g_iPlanting[ iPlayer ] = false;
	
	static Float: flOrigin[ 3 ];
	entity_get_vector( iPlayer, EV_VEC_origin, flOrigin );
	
	static Float: flTraceDirection[ 3 ], Float: flTraceEnd[ 3 ], Float: flTraceResult[ 3 ], Float: flNormal[ 3 ];
	velocity_by_aim( iPlayer, 128, flTraceDirection );
	flTraceEnd[ 0 ] = flTraceDirection[ 0 ] + flOrigin[ 0 ];
	flTraceEnd[ 1 ] = flTraceDirection[ 1 ] + flOrigin[ 1 ];
	flTraceEnd[ 2 ] = flTraceDirection[ 2 ] + flOrigin[ 2 ];
	
	static Float: flFraction, iTr;
	iTr = 0;
	engfunc( EngFunc_TraceLine, flOrigin, flTraceEnd, 0, iPlayer, iTr );
	get_tr2( iTr, TR_vecEndPos, flTraceResult );
	get_tr2( iTr, TR_vecPlaneNormal, flNormal );
	get_tr2( iTr, TR_flFraction, flFraction );
	
	static iEntity;
	iEntity = create_entity( "info_target" );
	
	if( !iEntity )
		return;
	
	entity_set_string( iEntity, EV_SZ_classname, MINE_CLASSNAME );
	entity_set_model( iEntity, MINE_MODEL_VIEW );
	entity_set_size( iEntity, Float: { -4.0, -4.0, -4.0 }, Float: { 4.0, 4.0, 4.0 } );
	
	entity_set_int( iEntity, EV_INT_iuser2, iPlayer );
	
	g_iPlantedMines[ iPlayer ]++;
	
	entity_set_float( iEntity, EV_FL_frame, 0.0 );
	entity_set_float( iEntity, EV_FL_framerate, 0.0 );
	entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_FLY );
	entity_set_int( iEntity, EV_INT_solid, SOLID_NOT );
	entity_set_int( iEntity, EV_INT_body, 3 );
	entity_set_int( iEntity, EV_INT_sequence, 7 );
	entity_set_float( iEntity, EV_FL_takedamage, DAMAGE_NO );
	entity_set_int( iEntity, EV_INT_iuser1, MINE_OFF );
	
	static Float: flNewOrigin[ 3 ], Float: flEntAngles[ 3 ];
	flNewOrigin[ 0 ] = flTraceResult[ 0 ] + ( flNormal[ 0 ] * 8.0 );
	flNewOrigin[ 1 ] = flTraceResult[ 1 ] + ( flNormal[ 1 ] * 8.0 );
	flNewOrigin[ 2 ] = flTraceResult[ 2 ] + ( flNormal[ 2 ] * 8.0 );
	
	entity_set_origin( iEntity, flNewOrigin );
	
	vector_to_angle( flNormal, flEntAngles );
	entity_set_vector( iEntity, EV_VEC_angles, flEntAngles );
	flEntAngles[ 0 ] *= -1.0;
	flEntAngles[ 1 ] *= -1.0;
	flEntAngles[ 2 ] *= -1.0;
	entity_set_vector( iEntity, EV_VEC_v_angle, flEntAngles );
	
	g_iTripMines[ iPlayer ]--;
	
	emit_sound( iEntity, CHAN_WEAPON, MINE_SOUND_DEPLOY, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	emit_sound( iEntity, CHAN_VOICE, MINE_SOUND_CHARGE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 0.6 );
}

public Func_RemoveMinesByOwner( iPlayer ) {
	static iEntity, szClassName[ 32 ];
	for( iEntity = 0; iEntity < MAX_ENTITIES + 1; iEntity++ ) {
		if( !is_valid_ent( iEntity ) )
			continue;
		
		szClassName[ 0 ] = '^0';
		entity_get_classname( iEntity, szClassName );
		
		if( equal( szClassName, MINE_CLASSNAME ) )
			if( entity_get_int( iEntity, EV_INT_iuser2 ) == iPlayer )
				remove_entity( iEntity );
	}
}

Func_Explode( iEntity ) {
	g_iPlantedMines[ entity_get_owner( iEntity ) ]--;
	
	static Float: flOrigin[ 3 ], Float: flZombieOrigin[ 3 ], Float: flHealth, Float: flVelocity[ 3 ];
	entity_get_vector( iEntity, EV_VEC_origin, flOrigin );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_EXPLOSION );
	engfunc( EngFunc_WriteCoord, flOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 2 ] );
	write_short( g_hExplode );
	write_byte( 55 );
	write_byte( 15 );
	write_byte( 0 );
	message_end( );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_EXPLOSION );
	engfunc( EngFunc_WriteCoord, flOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 2 ] );
	write_short( g_hExplode );
	write_byte( 65 );
	write_byte( 15 );
	write_byte( 0 );
	message_end( );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_EXPLOSION );
	engfunc( EngFunc_WriteCoord, flOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 2 ] );
	write_short( g_hExplode );
	write_byte( 85 );
	write_byte( 15 );
	write_byte( 0 );
	message_end( );
	
	static iZombie;
	for( iZombie = 1; iZombie < MAX_PLAYERS + 1; iZombie++ ) {
		if( is_user_connected( iZombie ) ) {
			if( is_user_alive( iZombie ) ) {
				entity_get_vector( iZombie, EV_VEC_origin, flZombieOrigin );
				
				if( get_distance_f( flOrigin, flZombieOrigin ) < 360.0 ) {
					flHealth = entity_get_float( iZombie, EV_FL_health );
					entity_get_vector( iZombie, EV_VEC_velocity, flVelocity );
					
					flVelocity[ 2 ] += 456.0;
					flVelocity[ 1 ] += 320.0;
					flVelocity[ 0 ] += 299.0;
					
					entity_set_vector( iZombie, EV_VEC_velocity, flVelocity );
					
					if( zp_get_user_zombie( iZombie ) )
						fm_set_user_health( iZombie, floatmax( flHealth - random_float( 1600.0, 2800.0 ), 0.0 ) );
				}
			}
		}
	}
	
	remove_entity( iEntity );
}

public Forward_Think( iEntity ) {
	static Float: flGameTime, iStatus;
	flGameTime = get_gametime( );
	iStatus = entity_get_status( iEntity );
	
	switch( iStatus ) {
		case MINE_OFF: {
			entity_set_int( iEntity, EV_INT_iuser1, MINE_ON );
			entity_set_float( iEntity, EV_FL_takedamage, DAMAGE_YES );
			entity_set_int( iEntity, EV_INT_solid, SOLID_BBOX );
			entity_set_float( iEntity, EV_FL_health, MINE_HEALTH + 1000.0 );
			
			emit_sound( iEntity, CHAN_VOICE, MINE_SOUND_ACTIVATE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		}
		
		case MINE_ON: {
			static Float: flHealth;
			flHealth = entity_get_float( iEntity, EV_FL_health );
			
			if( flHealth <= 1000.0 ) {
				Func_Explode( iEntity );
				
				return FMRES_IGNORED;
			}
		}
	}
	
	if( is_valid_ent( iEntity ) )
		entity_set_float( iEntity, EV_FL_nextthink, flGameTime + 0.1 );
	
	return FMRES_IGNORED;
}

public fm_set_user_health( iPlayer, Float: flHealth )
	flHealth ? set_pev( iPlayer, pev_health, flHealth ) : dllfunc( DLLFunc_ClientKill, iPlayer );
