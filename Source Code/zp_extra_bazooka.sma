#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

static const plugin[] = "[ZP] Extra Item: Bazooka";

static const mrocket[] = "models/rpgrocket.mdl";
static const mrpg_w[] = "models/w_rpg.mdl";
static const mrpg_v[] = "models/v_rpg.mdl";
static const mrpg_p[] = "models/p_rpg.mdl";
static const sfire[] = "weapons/rocketfire1.wav";
static const sfly[] = "weapons/nuke_fly.wav";
static const shit[] = "weapons/mortarhit.wav";
static const spickup[] = "items/gunpickup2.wav";

static const g_item_name[] = "Bazooka";
const g_item_cost = 120;
new g_itemid;


new prebijeci_doba[33]
new zkracene_prebijeni[33]
new Float:LastShoot[33]
// Others
new Saytxt

new gmsg_screenshake, gmsg_death, gmsg_damage, pcvar_delay, pcvar_maxdmg, pcvar_radius, pcvar_map;
new rocketsmoke, explosion, bazsmoke, white; 
new bool:has_baz[33], bool:CanShoot[33];
new dmgcount[33], pcvar_dmgforpacks, pcvar_award;

public plugin_init()
{
	register_plugin(plugin, "0.6", "Random1");
	register_dictionary("zp_extra_bazooka.txt");

	pcvar_delay = register_cvar("zp_baz_delay", "40.0");
	pcvar_maxdmg = register_cvar("zp_baz_dmg", "1200");
	pcvar_radius = register_cvar("zp_baz_radius", "950");
	pcvar_map = register_cvar("zp_baz_map", "0");
	pcvar_dmgforpacks = get_cvar_pointer("zp_human_damage_reward");
	pcvar_award = register_cvar("zp_baz_awardpacks", "1");
	
	if ( pcvar_dmgforpacks == 0 ) {
		set_pcvar_num(pcvar_award, 0);	//if we couldn't read the dmg cvar from zp then set a stop state on dmg reward
		log_amx("[%s] error reading zp_human_damage_reward cvar from zombie plague, turning award for damage off", plugin);
	}
	
	g_itemid = zp_register_extra_item(g_item_name, g_item_cost, ZP_TEAM_HUMAN);
	
	register_concmd("zp_bazooka", "give_bazooka", ADMIN_KICK, "<name/@all> gives a bazooka to the spcified target");
	register_event("CurWeapon","switch_to_knife","be","1=1","2=29");
	register_event("HLTV", "event_HLTV", "a", "1=0", "2=0")	// New Round
	register_clcmd("drop", "drop_call");
	
	//supports 2 methods of firing, attacking while holding knife and a bind
	register_clcmd("baz_fire", "fire_call");
	register_forward(FM_PlayerPreThink, "fw_prethink");
		Saytxt = get_user_msgid("SayText")
	register_forward(FM_Touch, "fw_touch");
		
	gmsg_screenshake = get_user_msgid("ScreenShake");
	gmsg_death = get_user_msgid("DeathMsg");
	gmsg_damage = get_user_msgid("Damage");
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
public event_HLTV()
{
	//remove entities regardless of cvar
	new rpg_temp = engfunc(EngFunc_FindEntityByString, -1, "classname", "rpg_temp");
	while( rpg_temp > 0) {
		engfunc(EngFunc_RemoveEntity, rpg_temp);
		rpg_temp = engfunc(EngFunc_FindEntityByString, -1, "classname", "rpg_temp");
	}
	
	if ( get_pcvar_num(pcvar_map) ) return;
	
	// Nové kolo - ak má hráč bazooku, daj cooldown 60s
	for( new id = 1; id <= 32; id++ )
	{
		if(has_baz[id] && is_user_connected(id) && is_user_alive(id))
		{
			CanShoot[id] = false
			remove_task(id)
			set_task(60.0, "rpg_reload", id)
			prebijeci_doba[id] = 60
			set_task(1.0, "hud_prebijeni", id)
			client_print(id, print_chat, "[Bazooka] %L", id, "BAZ_COOLDOWN_ROUND")
		}
		else
		{
			has_baz[id] = false
		}
	}
}

public aktivovat_zkracene(id)
{
	zkracene_prebijeni[id] = 1
}

public get_outbz( id )
{ 
if ( has_baz[id] )
	{
		drop_rpg_temp(id);
               LastShoot[id] = 0.0
               	CanShoot[id] = false
                remove_task( id );
	}
}

public zp_extra_item_selected(player, itemid)
{
	if (itemid == g_itemid)
	{
		if ( has_baz[player] )
		{
			zp_set_user_ammo_packs( player, zp_get_user_ammo_packs(player) + g_item_cost );
			client_print(player, print_chat, "%L", player, "BAZ_ALREADY_HAVE");
		}
		else {
			has_baz[player] = true;
			
			CanShoot[player] = true
                         remove_task( player );
                       LastShoot[player] = 0.0;
			//bazooka_message(player, "^x04[ZP]^x01 You bought Bazooka! [Attack2: Change modes] [Reload:^x04 %2.1f^x01 seconds]", get_pcvar_float(pcvar_delay))
			ChatColor(player, "!t[DarTom] !g%L", player, "BAZ_FIRE_HINT");
			emit_sound(player, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
	}
}

public client_putinserver(id)
{
	has_baz[id] = false
	LastShoot[id] = 0.0
}

public give_bazooka(id,level,cid)
{
	if (!cmd_access(id,level,cid,1)) {
		console_print(id,"You have no access to that command");
		return;
	}
	if (read_argc() > 2) {
		console_print(id,"Too many arguments supplied.");
		return;
	}
	new arg1[32];
	read_argv(1, arg1, sizeof(arg1) - 1);
	new player = cmd_target(id, arg1, 10);
	if ( !player ) {
		if ( arg1[0] == '@' ) {
			for ( new i = 1; i <= 32; i++ ) {
				if ( is_user_connected(i) && !has_baz[i] && !zp_get_user_zombie(i) ) {
					has_baz[i] = true;
					CanShoot[i] = true;
					client_print(i, print_chat, "[ZP BAZ] %L", i, "BAZ_GOT_BAZOOKA", get_pcvar_float(pcvar_delay));
				}
			}
		} else {
			client_print(id, print_chat, "%L", id, "BAZ_NO_TARGET");
			return;
		}
	} else if ( !has_baz[player] && !zp_get_user_zombie(player) ) {
		has_baz[player] = true;
		CanShoot[player] = true;
		client_print(player, print_chat, "[ZP BAZ] %L", player, "BAZ_GOT_BAZOOKA", get_pcvar_float(pcvar_delay));
	}
}

public zp_user_infected_post(id, infector)
{
	if ( has_baz[id] )
             {
		drop_rpg_temp(id)
       	CanShoot[id] = false
   LastShoot[id] = 0.0
                remove_task( id )
 }
}


public plugin_precache()
{
	precache_model(mrocket);	

	precache_model(mrpg_w);
	precache_model(mrpg_v);
	precache_model(mrpg_p);

	precache_sound(sfire);
	precache_sound(sfly);
	precache_sound(shit);
	precache_sound(spickup);
	
	rocketsmoke = precache_model("sprites/smoke.spr");
	explosion = precache_model("sprites/fexplo.spr");
	bazsmoke  = precache_model("sprites/steam1.spr");
	white = precache_model("sprites/white.spr");
}

public switch_to_knife(id)
{
	if ( !is_user_alive(id) ) return;
	
	if ( has_baz[id] && get_user_weapon(id) == CSW_KNIFE )
	{
		// Vynútiť nastavenie viewmodelu
		set_pev(id, pev_viewmodel2, mrpg_v);
		set_pev(id, pev_weaponmodel2, mrpg_p);
		
		// Refresh modelu
		set_task(0.1, "refresh_viewmodel", id)
	}
}

public refresh_viewmodel(id)
{
	if(!is_user_alive(id) || !has_baz[id] || get_user_weapon(id) != CSW_KNIFE)
		return
		
	set_pev(id, pev_viewmodel2, mrpg_v);
	set_pev(id, pev_weaponmodel2, mrpg_p);
}

public hud_prebijeni(id)
{
	if(prebijeci_doba[id] > 1)
	{
		set_task(1.0, "hud_prebijeni", id)
		has_baz[id] = true
		prebijeci_doba[id] = prebijeci_doba[id] - 1;
		set_hudmessage(216, 216, 216, 0.75, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1)
		show_hudmessage(id, "%L", id, "BAZ_RELOADING", prebijeci_doba[id])
	}
}
 
public rpg_reload(id)
{
	if (!has_baz[id]) return;
	
	if ( get_user_weapon(id) == CSW_KNIFE ) switch_to_knife(id);
	{
		CanShoot[id] = true
                remove_task( id );
		client_print(id, print_center, "%L", id, "BAZ_ROCKET_LOADED")
		emit_sound(id, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
}


public fw_prethink(id)
{
	static button;
	button = pev(id, pev_button);
	if ( button & IN_ATTACK )
		fire_call(id);
}
public fire_call(id)
{
	if ( !is_user_alive(id) || !has_baz[id] || !CanShoot[id] ) return;
	
	new weapon = get_user_weapon(id);
	if ( weapon == CSW_KNIFE ) fire_rocket(id);	
}

fire_rocket(id) {
	if ( !CanShoot[id] ) return;
	
	CanShoot[id] = false;
	engclient_cmd(id, "weapon_knife");	//attempt to force model to reset

	new Float:StartOrigin[3], Float:Angle[3];
	pev(id, pev_origin, StartOrigin);
	pev(id, pev_angles, Angle);

	LastShoot[id] = get_gametime();
	
	// Cooldown 50 sekúnd
	set_task(50.0, "rpg_reload", id);
	prebijeci_doba[id] = 50
	CanShoot[id] = false
	set_task(1.0, "hud_prebijeni", id)

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	set_pev(ent, pev_classname, "rpgrocket");
	engfunc(EngFunc_SetModel, ent, mrocket);
	set_pev(ent, pev_mins, {-1.0, -1.0, -1.0});
	set_pev(ent, pev_maxs, {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, ent, StartOrigin);
	set_pev(ent, pev_angles, Angle);


	set_pev(ent, pev_solid, 2);
	set_pev(ent, pev_movetype, 5);
	set_pev(ent, pev_owner, id);

	new Float:nVelocity[3];
	velocity_by_aim(id, 1500, nVelocity);
	set_pev(ent, pev_velocity, nVelocity);

	emit_sound(ent, CHAN_WEAPON, sfire, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	emit_sound(ent, CHAN_VOICE, sfly, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(22);
	write_short(ent);
	write_short(rocketsmoke);
	write_byte(30);
	write_byte(3);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	message_end();
}
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
public fw_touch(ent, touched)
{
	if ( !pev_valid(ent) ) return FMRES_IGNORED;
	static entclass[32];
	pev(ent, pev_classname, entclass, 31);
	if ( equali(entclass, "rpg_temp") )
	{
		static touchclass[32];
		pev(touched, pev_classname, touchclass, 31);
		if ( !equali(touchclass, "player") ) return FMRES_IGNORED;
		
		if( !is_user_alive(touched) || zp_get_user_zombie(touched) ) return FMRES_IGNORED;
			
		CanShoot[touched] = false
		remove_task(touched)
		set_task(50.0, "rpg_reload", touched)
		set_task(1.0, "hud_prebijeni", touched)
		prebijeci_doba[touched] = 50

		emit_sound(touched, CHAN_VOICE, spickup, 1.0, ATTN_NORM, 0, PITCH_NORM);
		has_baz[touched] = true;
		
		// Nastav viewmodel
		if(get_user_weapon(touched) == CSW_KNIFE)
		{
			set_pev(touched, pev_viewmodel2, mrpg_v);
			set_pev(touched, pev_weaponmodel2, mrpg_p);
		}
		
		engfunc(EngFunc_RemoveEntity, ent);
	
		return FMRES_HANDLED;
	}
	else if ( equali(entclass, "rpgrocket") )
	{
		new Float:EndOrigin[3];
		pev(ent, pev_origin, EndOrigin);
		new NonFloatEndOrigin[3];
		NonFloatEndOrigin[0] = floatround(EndOrigin[0]);
		NonFloatEndOrigin[1] = floatround(EndOrigin[1]);
		NonFloatEndOrigin[2] = floatround(EndOrigin[2]);
	
		emit_sound(ent, CHAN_WEAPON, shit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		emit_sound(ent, CHAN_VOICE, shit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0]);
		write_coord(NonFloatEndOrigin[1]);
		write_coord(NonFloatEndOrigin[2] + 128);
		write_short(explosion);
		write_byte(60);
		write_byte(255);
		message_end();
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(5);
		write_coord(NonFloatEndOrigin[0]);
		write_coord(NonFloatEndOrigin[1]);
		write_coord(NonFloatEndOrigin[2] + 256);
		write_short(bazsmoke);
		write_byte(125);
		write_byte(5);
		message_end();
	
		new maxdamage = get_pcvar_num(pcvar_maxdmg);
		new damageradius = get_pcvar_num(pcvar_radius);
	
		new PlayerPos[3], distance, damage;
		for (new i = 1; i <= 32; i++) {
			if ( is_user_alive(i)) 
				{	
					new id = pev(ent, pev_owner)
					 if  ((zp_get_user_zombie(id)) || (zp_get_user_nemesis(id))) 
						if ((zp_get_user_zombie(i)) || (zp_get_user_nemesis(i))) continue;
						
					if  ((!zp_get_user_zombie(id)) && (!zp_get_user_nemesis(id))) 
						if ((!zp_get_user_zombie(i)) && (!zp_get_user_nemesis(i))) continue;
						
					get_user_origin(i, PlayerPos);
		
					distance = get_distance(PlayerPos, NonFloatEndOrigin);
					if (distance <= damageradius) {	
					message_begin(MSG_ONE, gmsg_screenshake, {0,0,0}, i);
					write_short(1<<14);
					write_short(1<<14);
					write_short(1<<14);
					message_end();
		
					damage = maxdamage - floatround(floatmul(float(maxdamage), floatdiv(float(distance), float(damageradius))));
					new attacker = pev(ent, pev_owner);
		
					baz_damage(i, attacker, damage, "bazooka");
				}
			}
		}
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(21);
		write_coord(NonFloatEndOrigin[0]);
		write_coord(NonFloatEndOrigin[1]);
		write_coord(NonFloatEndOrigin[2]);
		write_coord(NonFloatEndOrigin[0]);
		write_coord(NonFloatEndOrigin[1]);
		write_coord(NonFloatEndOrigin[2] + 320);
		write_short(white);
		write_byte(0);
		write_byte(0);
		write_byte(16);
		write_byte(128);
		write_byte(0);
		write_byte(255);
		write_byte(255);
		write_byte(192);
		write_byte(128);
		write_byte(0);
		message_end();
	
		engfunc(EngFunc_RemoveEntity, ent);
		
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}
//---------------------------------------------------------------------------------------
public drop_call(id)
{
	if ( has_baz[id] && get_user_weapon(id) == CSW_KNIFE )
	{
		drop_rpg_temp(id);
		return PLUGIN_HANDLED;	//attempt to block can't drop knife message
	}
	return PLUGIN_CONTINUE;
}

drop_rpg_temp(id) {
	new Float:fAim[3] , Float:fOrigin[3];
	velocity_by_aim(id , 64 , fAim);
	pev(id , pev_origin , fOrigin);

	fOrigin[0] += fAim[0];
	fOrigin[1] += fAim[1];

	new rpg = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	set_pev(rpg, pev_classname, "rpg_temp");
	engfunc(EngFunc_SetModel, rpg, mrpg_w);

	set_pev(rpg, pev_mins, { -16.0, -16.0, -16.0 } );
	set_pev(rpg, pev_maxs, { 16.0, 16.0, 16.0 } );

	set_pev(rpg , pev_solid , 1);
	set_pev(rpg , pev_movetype , 6);

	engfunc(EngFunc_SetOrigin, rpg, fOrigin);

	has_baz[id] = false;
}
//---------------------------------------------------------------------------------------
baz_damage(id, attacker, damage, weaponDescription[])
{
	if ( pev(id, pev_takedamage) == DAMAGE_NO ) return;
	if ( damage <= 0 ) return;

	new userHealth = get_user_health(id);
	if (userHealth - damage <= 0 ) {
		dmgcount[attacker] += userHealth - damage;
		set_msg_block(gmsg_death, BLOCK_SET);
		ExecuteHamB(Ham_Killed, id, attacker, 2);
		set_msg_block(gmsg_death, BLOCK_NOT);
	
		
		message_begin(MSG_BROADCAST, gmsg_death);
		write_byte(attacker);
		write_byte(id);
		write_byte(0);
		write_string(weaponDescription);
		message_end();
		
		set_pev(attacker, pev_frags, float(get_user_frags(attacker) + 1));
			
		new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10];
	
		get_user_name(attacker, kname, 31);
		get_user_team(attacker, kteam, 9);
		get_user_authid(attacker, kauthid, 31);
	 
		get_user_name(id, vname, 31);
		get_user_team(id, vteam, 9);
		get_user_authid(id, vauthid, 31);
			
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
		kname, get_user_userid(attacker), kauthid, kteam, 
	 	vname, get_user_userid(id), vauthid, vteam, weaponDescription);
	}
	else {
		dmgcount[attacker] += damage;
		new origin[3];
		get_user_origin(id, origin);
		
		message_begin(MSG_ONE,gmsg_damage,{0,0,0},id);
		write_byte(21);
		write_byte(20);
		write_long(DMG_BLAST);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2]);
		message_end();
		
		set_pev(id, pev_health, pev(id, pev_health) - float(damage));
	}
	if ( !get_pcvar_num(pcvar_award) ) return;
	
	new breaker = get_pcvar_num(pcvar_dmgforpacks);
	if ( dmgcount[attacker] > breaker )
	{
		new temp = dmgcount[attacker] / breaker
		if ( temp * breaker > dmgcount[attacker] ) return; //should never be possible
		dmgcount[attacker] -= temp * breaker;
		zp_set_user_ammo_packs( attacker, zp_get_user_ammo_packs(attacker) + temp );
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
