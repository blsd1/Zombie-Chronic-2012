#include < amxmodx >
#include < fun>
#include < hamsandwich >
#include < zombieplague >

#define AUTHOR "Javivi & sunx"


new const ITEM_COST = 180;

new g_itemID;

new cvar_duration;

new g_HaveImmunity[ 33 ], Time[ 33 ], Limit[ 33 ];

public plugin_init( )
{
	register_plugin( "[ZP] Extra Item: Immunity", "3.0", AUTHOR )
	
	cvar_duration = register_cvar( "zp_immunity_duration", "20" );	

	g_itemID = zp_register_extra_item( "Nesmrtelnost [ExtraVIP]", ITEM_COST , ZP_TEAM_HUMAN );
	
	register_dictionary( "zp_extra_immunity.txt" );	

	RegisterHam( Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1 );
}

public client_connect( id )
{
	Limit[ id ] = 0;
}

public zp_extra_item_selected( id, itemid )
{
	if(itemid == g_itemID)
	{
		if ( !zp_has_round_started( ) )
		{
			new Temp[ 32 ];
			formatex( Temp, 31 , "!g[ZP] !y%L", id, "WAIT" );
			chat_color( id, Temp );
			zp_set_user_ammo_packs( id, zp_get_user_ammo_packs( id ) + ITEM_COST );
			
			return;
		}
		if ( Limit[ id ] == 1 )
		{
			client_print( id, print_center, "V tomto kole jsi uz nesmrtelnost pouzil" );
			zp_set_user_ammo_packs( id, zp_get_user_ammo_packs( id ) + ITEM_COST );
			
			return;
		}
		if ( zp_get_zombie_count( ) < 3 )
		{
			zp_set_user_ammo_packs( id, zp_get_user_ammo_packs( id ) + ITEM_COST );
			client_print(id, print_center, "Musis pockat az budou alespon 4 zombie !")
			return;
		}	
		if( !g_HaveImmunity[ id ] )
		{
			Limit[ id ] = 1;
			set_user_godmode( id, 1 );
			
			
			g_HaveImmunity[id] = true
			
			client_print(id, print_center, "%L", id, "IMMUME")

			Limit[ id ] = 1;
			Time[ id ] = get_pcvar_num( cvar_duration );
			CountDown( id );
		}else{
			new Temp[ 32 ];
			formatex( Temp, 31, "!g[ZP] !y%L", id, "ALREADY" );
			chat_color( id, Temp );	
			zp_set_user_ammo_packs( id, zp_get_user_ammo_packs( id ) + ITEM_COST );	
			return;
		}
		
	}
}

public CountDown( id )
{
	if( Time[ id ] <= 0 )
	{		
		remove_task( id );
		
		client_print( id, print_center, "Immunity expired." );
		set_user_godmode( id, 0 );
		g_HaveImmunity[id] = false;
		return;
	}
	Time[ id ] --;

	client_print(id, print_center, "Immunity remaining: %d seconds", Time[id]);

	set_task( 1.0, "CountDown", id );
}

public zp_user_infected_post( id )
{
	Limit[ id ] = 0;
	
	if( g_HaveImmunity[ id ] )
	{
		Time[ id ] = 0;
		remove_task( id );
		set_user_godmode( id, 0 );
		g_HaveImmunity[ id ] = false;
	}
}

public fw_PlayerSpawn_Post( id )
{
	if( g_HaveImmunity[ id ] )
	{
		Time[ id ] = 0;
		Limit[ id ] = 0;

		client_print( id, print_center, "%L", id, "EXPIRED" );
		remove_task( id );
		set_user_godmode( id, 0 );
		g_HaveImmunity[ id ] = false;
	}
}

stock chat_color( const id, const input[], any:... )
{
	static msg[ 191 ], iSayText;
	vformat( msg, 190, input, 3 );
	
	if( !iSayText ) iSayText = get_user_msgid( "SayText" );
	
	replace_all( msg, 190, "!g", "^4" );
	replace_all( msg, 190, "!y", "^1" );
	
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iSayText, _, id ? id : find_player("j") );
	write_byte( id ? id : find_player("j") );
	write_string( msg );
	message_end( );
} 
