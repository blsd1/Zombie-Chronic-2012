#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <zombieplague>

new const PLUGIN_INFO[] = 
{
	"[ZP]ZombieBomb(Jump)",
	"2.0",
	"Zombie-rus/heka"
}

#pragma tabsize 0

#define ZOMBIE_BOMB_P	 			"models/ch2012/p_zbomb.mdl"
#define ZOMBIE_BOMB_V 	 			"models/ch2012/v_zbomb.mdl"
#define ZOMBIE_BOMB_W 	 			"models/grenade.mdl"

#define ZOMBIE_BOMB_BUY 			"items/gunpickup2.wav"
#define ZOMBIE_BOMB_EXP 			"ch2012/knockback_explo.wav"

#define ZOMBIE_BOMB_EXP_SPR			"sprites/ch2012_kn_exp.spr"

#define ZOMBIE_BOMB_EXP_RADIUS		300.0
#define ZOMBIE_BOMB_EXP_POWER		450.0

#define NADE_TYPE_ZOMBIEBOMB    	26517

new g_ZombieBomb_ExpSpr
new g_ZombieBomb [33]
new g_CurrentWeapon [33]
new g_ZombieBomb_Icon[33][32]

public plugin_init ()
{
	register_plugin(PLUGIN_INFO[0],PLUGIN_INFO[1],PLUGIN_INFO[2])

	register_event("CurWeapon","EV_CurWeapon","be","1=1")
	register_event("HLTV","EV_NewRound","a","1=0","2=0")
	register_event("DeathMsg","EV_DeathMsg","a")
	register_event("CurWeapon","grenade_icon","be","1=1")
	
	register_forward(FM_SetModel,"fw_SetModel")
	RegisterHam(Ham_Think, "grenade","fw_ThinkGrenade")
}

public plugin_precache ( )
{
	precache_model(ZOMBIE_BOMB_P)
	precache_model(ZOMBIE_BOMB_V)
	precache_model(ZOMBIE_BOMB_W)

	precache_sound(ZOMBIE_BOMB_BUY)
	precache_sound(ZOMBIE_BOMB_EXP)
	
	precache_generic("sprites/weapon_zombiebomb.txt")
	precache_generic("sprites/zb/640hud61.spr")	
	precache_generic("sprites/zb/640hud7.spr")	

	g_ZombieBomb_ExpSpr = precache_model (ZOMBIE_BOMB_EXP_SPR)
	
	register_clcmd("weapon_zombiebomb","Hook_SelectWeapon")		
}



public zp_user_infected_post(id)
{
	if(zp_get_user_nemesis(id) || zp_is_survivor_round() || zp_is_nemesis_round())
		return;

	g_ZombieBomb [id] = 0
	
	give_item(id, "weapon_smokegrenade")
	engclient_cmd(id, "weapon_knife")
	cs_set_user_bpammo(id, CSW_SMOKEGRENADE, 1)
	emit_sound (id,CHAN_ITEM,ZOMBIE_BOMB_BUY,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	
	message_begin(MSG_ONE,get_user_msgid( "AmmoPickup"), _,id)
	write_byte (13)
	write_byte (1)
	message_end ()
	
	WeaponList_Change(id,true)
	
	g_ZombieBomb [id] = 1
}

public zp_round_ended(id) 
{
	for (new i = 1; i <= get_maxplayers(); i++) 
	{
		if (is_user_alive(i) && zp_get_user_zombie(i)) 
		{
			ham_strip_weapon(i , "weapon_smokegrenade")
			WeaponList_Change(i,false)
		}
	}
}

public Hook_SelectWeapon(id) engclient_cmd(id,"weapon_smokegrenade")		
public client_connect(id) g_ZombieBomb[id] = 0
public zp_user_humanized_post ( id, Survivor ) if ( Survivor ) g_ZombieBomb [ Survivor ] = 0

public EV_CurWeapon (id)
{
	if (!is_user_alive (id) || !zp_get_user_zombie (id) || zp_get_user_nemesis(id))
		return;

	g_CurrentWeapon [id] = read_data (2)
	if (g_ZombieBomb [id] > 0 && g_CurrentWeapon [id] == CSW_SMOKEGRENADE)
	{
		set_pev(id,pev_viewmodel2,ZOMBIE_BOMB_V)
		set_pev(id,pev_weaponmodel2,ZOMBIE_BOMB_P)
	}
}

public EV_NewRound() arrayset(g_ZombieBomb,0,33)
public EV_DeathMsg()
{
	new iVictim = read_data (2)

	if (!is_user_connected(iVictim) || !zp_get_user_zombie(iVictim))
		return;
		
	remove_grenade_icon(iVictim)		
	ham_strip_weapon(iVictim,"weapon_smokegrenade")
	WeaponList_Change(iVictim,false)
	g_ZombieBomb[iVictim] = 0
}

public fw_SetModel(Entity,const Model[])
{
	if (Entity < 0)
		return FMRES_IGNORED;

	if (pev(Entity,pev_dmgtime) == 0.0)
		return FMRES_IGNORED;

	new iOwner = entity_get_edict ( Entity, EV_ENT_owner )

	if ( g_ZombieBomb [ iOwner ] >= 1 && equal ( Model [ 7 ], "w_sm", 4 ) )
	{
		set_pev(Entity,pev_flTimeStepSound,0)
		set_pev(Entity,pev_flTimeStepSound,NADE_TYPE_ZOMBIEBOMB)

		g_ZombieBomb[iOwner]--
		entity_set_model(Entity, ZOMBIE_BOMB_W)

		fm_set_rendering(Entity,kRenderFxHologram,255,165,0,kRenderNormal,16)

		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_ThinkGrenade(Entity)
{
	if (!pev_valid(Entity))
		return HAM_IGNORED;

	static Float:dmg_time
	pev (Entity,pev_dmgtime,dmg_time)

	if (dmg_time > get_gametime())
		return HAM_IGNORED;

	if (pev(Entity,pev_flTimeStepSound) == NADE_TYPE_ZOMBIEBOMB)
	{
		jumping_explode (Entity)
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public jumping_explode (Entity)
{
	if(Entity < 0)
		return

	static Float:flOrigin [3]
	pev(Entity,pev_origin,flOrigin)

	new iOwner = pev(Entity, pev_owner)

	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,flOrigin,0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,flOrigin [0])
	engfunc(EngFunc_WriteCoord,flOrigin [1])
	engfunc(EngFunc_WriteCoord,flOrigin [2] + 45.0)
	write_short( g_ZombieBomb_ExpSpr )
	write_byte(35)
	write_byte(186)
	message_end()

	emit_sound (Entity,CHAN_WEAPON,ZOMBIE_BOMB_EXP,VOL_NORM,ATTN_NORM,0,PITCH_NORM)

	for (new i = 1; i < get_maxplayers (); i++)
	{
		if (!is_user_alive(i))
			continue;

		// Skip owner - no knockback, no damage, no screenshake
		if(i == iOwner)
			continue;

		new Float:flVictimOrigin [3]
		pev (i,pev_origin,flVictimOrigin)

		new Float:flDistance = get_distance_f(flOrigin,flVictimOrigin)

		if (flDistance <= ZOMBIE_BOMB_EXP_RADIUS)
		{
			// Only knockback for humans, zombies get nothing
			if(!zp_get_user_zombie(i))
			{
				static Float:flSpeed
				flSpeed = ZOMBIE_BOMB_EXP_POWER

				static Float:flNewSpeed
				flNewSpeed = flSpeed * (1.0 - ( flDistance / ZOMBIE_BOMB_EXP_RADIUS))

				static Float:flVelocity [3]
				get_speed_vector(flOrigin,flVictimOrigin,flNewSpeed,flVelocity)

				set_pev (i,pev_velocity,flVelocity)

				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, i)
				write_short((1<<12)*4) // amplitude
				write_short((1<<12)*10) // duration
				write_short((1<<12)*10) // frequency
				message_end()
			}
		}
	}
	engfunc(EngFunc_RemoveEntity,Entity)
}

public WeaponList_Change(id,bool:change)
{
	if (!is_user_connected(id))
		return;
	
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, id)
	if (bool:change)
		write_string("weapon_zombiebomb")
	else
		write_string("weapon_smokegrenade")
	write_byte(13)
	write_byte(1)
	write_byte(-1)
	write_byte(-1)
	write_byte(3)
	write_byte(3)
	write_byte(9)
	write_byte(24)
	message_end()
}

public grenade_icon(id)
{
	remove_grenade_icon(id)

	if(is_user_bot(id))
		return

	static igrenade, grenade_sprite[16], grenade_color[3]
	igrenade = get_user_weapon(id)

	switch(igrenade)
	{
		case CSW_SMOKEGRENADE:
		{
			{
				grenade_sprite = ""
				grenade_color = {0, 0, 0}
			}
		}
		default: return
	}
	g_ZombieBomb_Icon[id] = grenade_sprite

	message_begin(MSG_ONE,get_user_msgid("StatusIcon"),{0,0,0},id)
	write_byte(1)
	write_string(g_ZombieBomb_Icon[id])
	write_byte(grenade_color[0])
	write_byte(grenade_color[1])
	write_byte(grenade_color[2])
	message_end()

	return
}

public remove_grenade_icon(id)
{
	message_begin(MSG_ONE,get_user_msgid("StatusIcon"),{0,0,0},id)
	write_byte(0)
	write_string(g_ZombieBomb_Icon[id])
	message_end()
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num

	return 1;
}

stock ham_strip_weapon(id,weapon[])
{
	if(!equal(weapon,"weapon_",7)) return 0

    new wId = get_weaponid(weapon)
    if(!wId) return 0

    new wEnt
    while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname",weapon)) && pev(wEnt,pev_owner) != id) {}
    if(!wEnt) return 0

    if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt)

    if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt)) return 0
    ExecuteHamB(Ham_Item_Kill,wEnt);

    set_pev(id,pev_weapons,pev(id,pev_weapons) & ~(1<<wId))

    return 1
}