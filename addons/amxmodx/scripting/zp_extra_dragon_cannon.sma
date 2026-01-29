#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <fakemeta_util>
#include <zombieplague>

//#define BUYMENU

#if defined BUYMENU
native zp_cs_get_user_money(id)
native zp_cs_set_user_money(id, value)
#endif

#define PLUGIN "[ZP]ExtraDragonCannon"
#define VERSION "1.0"
#define AUTHOR "Arwel"

#define CONFIG_CFG_FILE "weapons/dragon_cannon.cfg"

#define pev_weaponkey pev_impulse
#define weaponkey_value 231721

#define OFFSET_LINUX		5
#define OFFSET_LINUX_WEAPONS	4

#define m_flNextAttack		83
#define m_flNextPrimaryAttack 	46
#define m_flTimeWeaponIdle	48
#define m_LastHitGroup 		75
#define m_bDelayFire 		60

#define CSW_CANNON CSW_M249

new g_orig_event_cannon

new kokotcannon[33];

new const g_weapon_entity[]="weapon_m249"
new const g_weapon_event[]="events/m249.sc"
new const g_weaponbox_model[]="models/w_m249.mdl"

new const weapon_list_txt[]="weapon_cannon_zp_cso"

new const weapon_list_sprites[][]=
{	
	"sprites/zm/640hud69.spr",
	"sprites/zm/640hud2_cso.spr"
}

new const g_flame_classname[]="cannon_flame"

new const ViewModel[]="models/ch2012/v_cannon.mdl"
new const PlayerModel[]="models/ch2012/p_cannon.mdl"
new const WorldModel[]="models/ch2012/w_cannon.mdl"

new const FlameModel[]="sprites/fire_cannon.spr"

new const Sounds[][]=
{
	"weapons/cannon-1.wav",
	"weapons/cannon_draw.wav"	
}

new g_HasCannon[33], g_ammo[33]

new pcvar_item_name, pcvar_fire_time, pcvar_damage, pcvar_flame_speed_mins
new pcvar_flame_num, pcvar_flame_speed_maxs, pcvar_flame_dist_mins, pcvar_flame_dist_maxs

new g_item, gMsg_CurWeapon, gMsg_AmmoX, gMsg_AmmoPickup

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd(weapon_list_txt, "Redirect")
	
	pcvar_item_name=register_cvar("cannon_item_name", "Dragon Cannon")
	register_cvar("cannon_cost", "120")
	pcvar_fire_time=register_cvar("cannon_fire_time", "3.5")
	pcvar_damage=register_cvar("cannon_damage", "650.0")
	pcvar_flame_num=register_cvar("cannon_flame_num", "10")
	pcvar_flame_speed_mins=register_cvar("cannon_flame_speed_mins", "850")
	pcvar_flame_speed_maxs=register_cvar("cannon_flame_speed_maxs", "1150")
	pcvar_flame_dist_mins=register_cvar("cannon_flame_dist_mins", "200.0")
	pcvar_flame_dist_maxs=register_cvar("cannon_flame_dist_maxs", "350.0")

	
	ReadSettings()
	
	RegisterHam(Ham_Item_AddToPlayer, g_weapon_entity, "fwAddToPlayer", 1)
	RegisterHam(Ham_Item_Deploy, g_weapon_entity, "fwDeployPost", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, g_weapon_entity, "fwPrimaryAttackPre")
	RegisterHam(Ham_RemovePlayerItem, "player", "fwRemoveItem")
	RegisterHam(Ham_Item_PostFrame, g_weapon_entity, "fwItemPostFrame")
	
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")  
	register_forward(FM_UpdateClientData, "fwUpdateClientDataPost", 1)
	register_forward(FM_SetModel, "fwSetModel")
	register_event( "ResetHUD", "playerSpawn", "be" ) 
	register_event( "HLTV", "event_round_start", "a", "1=0", "2=0" )	
	RegisterHam( Ham_Killed, "player", "fw_PlayerKilled" )
	register_think(g_flame_classname, "fwThink")
	register_touch(g_flame_classname, "*", "fwTouch")
	
	register_clcmd("buyammo1", "CmdBuyAmmo")
	
	new item_name[64]
	
	get_pcvar_string(pcvar_item_name, item_name, 63)
	
	g_item=zp_register_extra_item(item_name, 120, ZP_TEAM_HUMAN)
	register_clcmd( "get_outdragonzp", "get_outdragon" );	

	gMsg_CurWeapon=get_user_msgid("CurWeapon")
	gMsg_AmmoX=get_user_msgid("AmmoX")	
	gMsg_AmmoPickup=get_user_msgid("AmmoPickup")	
	
	register_message(gMsg_AmmoX, "Message_AmmoX")
	register_message(gMsg_CurWeapon, "Message_CurWeapon")
	register_clcmd("get_spermdartomcannon", "give_cannon")
}

public get_outdragon( id )
{
	g_HasCannon[ id ] = false;
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		kokotcannon[id] = false
	}
}

public playerSpawn( player )
{
kokotcannon[ player ] = false;
}

public event_round_start( )
{
for (new player; player <= 32; player++)
 kokotcannon[ player ] = false   	
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	//player die
      kokotcannon[ victim ] = false  
}

public plugin_precache()
{	
	precache_model(ViewModel)
	precache_model(PlayerModel)
	precache_model(WorldModel)
	
	precache_model(FlameModel)
	
	for(new i; i<=charsmax(Sounds); i++)
	{
		precache_sound(Sounds[i])	
	}
	
	new tmp[128]
	
	formatex(tmp, charsmax(tmp), "sprites/%s.txt", weapon_list_txt)
	
	precache_generic(tmp)
	
	for(new i; i<=charsmax(weapon_list_sprites); i++)
	{
		precache_generic(weapon_list_sprites[i])
		
	}	

	register_forward(FM_PrecacheEvent, "fwPrecachePost", 1)
}

public ReadSettings()
{
	
	new confdir[64], path[128]
	
	get_configsdir(confdir, charsmax(confdir))
	
	formatex(path, charsmax(path), "%s/%s", confdir, CONFIG_CFG_FILE)
	
	server_cmd("exec %s", path)
	server_exec()
	
}

public zp_extra_item_selected(id, itemid)
{

	if(itemid!=g_item)
		return
	kokotcannon[ id ] = true	
	give_cannon(id)	
}

public give_cannon(id)
{ 
	// Neodstráňuj zbrane - nechaj loadout
	// drop_weapons(id)
	
	g_HasCannon[id]=true
	client_cmd( id, "get_outminigunzp" );
	
	g_ammo[id]=999999
	
	fm_give_item(id, g_weapon_entity)
	
	Msg_CurWeapon(id, 1, CSW_CANNON, -1)
	
	Msg_AmmoX(id, 3, g_ammo[id])
	
	WeapListSpr(id, weapon_list_txt)
}

public Message_AmmoX(msg_id, msg_dest, msg_entity)
{
	if(!g_HasCannon[msg_entity])
		return
		
	if(get_user_weapon(msg_entity)!=CSW_CANNON)
		return
		
	set_msg_arg_int(1, ARG_BYTE, g_ammo[msg_entity])	
}

public Message_CurWeapon(msg_id, msg_dest, msg_entity)
{
	if(!g_HasCannon[msg_entity])
		return
		
	if(get_msg_arg_int(2)!=CSW_CANNON)
		return
		
	set_msg_arg_int(3, ARG_BYTE, -1)		
}

public CmdBuyAmmo(id)
{
	if(!g_HasCannon[id])
		return PLUGIN_CONTINUE
		
	if(g_ammo[id]>=20)
		return PLUGIN_HANDLED
	
	new money
	
	#if defined BUYMENU
	
	if(money<0)
		return PLUGIN_HANDLED
		
	zp_cs_set_user_money(id, money)	
	
	#else
	
	
	if(money<0)
		return PLUGIN_HANDLED
		
	cs_set_user_money(id, money)		
	
	#endif
	
	g_ammo[id]++
	
	Msg_AmmoX(id, 3, g_ammo[id])
	Msg_AmmoPickup(id, 3, 1)
	
	emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	return PLUGIN_HANDLED
}

public client_connect(id)
{
 kokotcannon[id] = false
}

public client_disconnected(id)
{
	kokotcannon[id] = false
	g_HasCannon[id]= false	
}

public fwPrecachePost(type, const name[])
{
	if (equal(g_weapon_event, name))
	{
		g_orig_event_cannon=get_orig_retval()
		
		return FMRES_HANDLED
	}
	
	return FMRES_IGNORED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_cannon))
		return FMRES_IGNORED
		
	if (!is_valid_player(invoker))
		return FMRES_IGNORED
	
	fm_playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	return FMRES_SUPERCEDE
}

public fwUpdateClientDataPost(id, SendWeapons, CD_Handle)
{
	if (!is_valid_player(id))
		return FMRES_IGNORED
	
	if(get_user_weapon(id)!=CSW_CANNON)
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001)
	
	return FMRES_HANDLED
}

public fwSetModel(ent, model[])
{
	if(!pev_valid(ent))
		return FMRES_IGNORED;

	if(!equal(model, g_weaponbox_model)) 
		return FMRES_IGNORED;

	static classname[33]
	pev(ent, pev_classname, classname, charsmax(classname))
		
	if(!equal(classname, "weaponbox"))
		return FMRES_IGNORED

	static owner, weap
	
	owner=pev(ent, pev_owner)
	weap=fm_find_ent_by_owner(-1, g_weapon_entity, ent)
		
	if(g_HasCannon[owner]&&pev_valid(weap))
	{
		set_pev(weap, pev_weaponkey, weaponkey_value)
		
		g_HasCannon[owner]=false
		
		engfunc(EngFunc_SetModel, ent, WorldModel)
		
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public fwAddToPlayer(ent, id)
{
	if(pev_valid(ent)&&is_user_connected(id)&&pev(ent, pev_weaponkey)==weaponkey_value)
	{
		WeapListSpr(id, weapon_list_txt)
		
		g_HasCannon[id]=true
		
		set_pev(ent, pev_weaponkey, 0)
		
		return HAM_HANDLED
	}
	
	return HAM_IGNORED
}

public fwDeployPost(ent)
{
	new id=fm_get_weapon_owner(ent)
	
	if(!is_valid_player(id))
		return	
		
	playanim(id, 3)	
		
	set_pev(id, pev_viewmodel2, ViewModel)
	set_pev(id, pev_weaponmodel2, PlayerModel)
}

public fwPrimaryAttackPre(ent)
{
	new id=fm_get_weapon_owner(ent)
	
	if(!is_valid_player(id))
		return HAM_IGNORED
			
	if(g_ammo[id]<=0)
	{
		ExecuteHamB(Ham_Weapon_PlayEmptySound, ent)
		
		set_pdata_float(ent, m_flNextPrimaryAttack, 0.5, OFFSET_LINUX_WEAPONS)
		
		return HAM_SUPERCEDE
	}
	
	set_pev(id,pev_punchangle,Float:{0.0, 0.0, 0.0})	
	
	playanim(id, 1)
	
	CreateFlame(id)
	
	emit_sound(id, CHAN_WEAPON, Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	static Float:next_attack;next_attack=get_pcvar_float(pcvar_fire_time)
	
	set_pdata_float(id, m_flNextAttack, next_attack, OFFSET_LINUX)
	set_pdata_float(ent, m_flNextPrimaryAttack, next_attack, OFFSET_LINUX_WEAPONS)
	set_pdata_float(ent, m_flTimeWeaponIdle, next_attack, OFFSET_LINUX_WEAPONS)
	
	set_pdata_int(ent, m_bDelayFire, 1, OFFSET_LINUX_WEAPONS)
	
	return HAM_SUPERCEDE
}

public fwItemPostFrame(ent)
{
	new id=fm_get_weapon_owner(ent)
	
	if(!is_valid_player(id))
		return
		
	if(get_pdata_int(ent, m_bDelayFire, OFFSET_LINUX_WEAPONS))
	{
		g_ammo[id]--
		
		Msg_AmmoX(id, 3, g_ammo[id])
		
		set_pdata_int(ent, m_bDelayFire, 0, OFFSET_LINUX_WEAPONS)
	}
}

public CreateAnimationSprite(owner, const classname[], const model[], Float:scale)
{
	new ent=fm_create_entity("info_target")
	
	if(!pev_valid(ent))
		return 0

	set_pev(ent, pev_model, model)

	set_pev(ent, pev_owner, owner)
	set_pev(ent, pev_classname, classname)
	
	fm_entity_set_model(ent, model)
	fm_set_rendering(ent, kRenderFxNoDissipation, 255, 255, 255, kRenderGlow, 255)

	set_pev(ent, pev_scale, scale)

	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_solid, SOLID_BBOX)
	
	entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})	
	
	set_pev(ent, pev_fuser1, 255.0)
	
	set_pev(ent, pev_nextthink, get_gametime()+random_float(0.001, 0.2))
	
	return ent
}


public CreateFlame(id)
{	
	if(!is_user_alive(id))
		return
		
	static Float:fVec[3], Float:fVec2[3], Float:fVec3[3], Float:fOrigin[3], Float:Angles[3], Float:pVel[3]
	
	static Float:right, Float:dist_add, ent, Float:speed_mins, Float:speed_maxs, num
	
	speed_mins=get_pcvar_float(pcvar_flame_speed_mins)
	speed_maxs=get_pcvar_float(pcvar_flame_speed_maxs)
	
	num=get_pcvar_num(pcvar_flame_num)
		
	pev(id, pev_v_angle, Angles)
	pev(id, pev_velocity, pVel)
	
	get_weapon_position(id, fOrigin, .add_forward=20.0, .add_right=10.0, .add_up=-2.0)
	
	dist_add=random_float(get_pcvar_float(pcvar_flame_dist_mins), get_pcvar_float(pcvar_flame_dist_maxs))
	
	right=dist_add/-2.0
	
	for(new i; i<num; i++)
	{
		ent=CreateAnimationSprite(id, g_flame_classname, FlameModel, 1.5)
		
		if(!pev_valid(ent))
			continue
			
		angle_vector(Angles, ANGLEVECTOR_FORWARD, fVec)
		angle_vector(Angles, ANGLEVECTOR_RIGHT, fVec2)
		angle_vector(Angles, ANGLEVECTOR_UP, fVec3)
		
		xs_vec_mul_scalar(fVec, random_float(speed_mins, speed_maxs), fVec)
		xs_vec_mul_scalar(fVec2, right, fVec2)
		xs_vec_mul_scalar(fVec3, random_float(-50.0, 5.0), fVec3)		
		
		fVec[0]=fVec[0]+fVec2[0]+fVec3[0]+pVel[0]
		fVec[1]=fVec[1]+fVec2[1]+fVec3[1]+pVel[1]
		fVec[2]=fVec[2]+fVec2[2]+fVec3[2]+pVel[2]
		
		set_pev(ent, pev_origin, fOrigin)
		set_pev(ent, pev_velocity, fVec)
		
		right+=dist_add/num
	}
}

public fwThink(ent)
{
	if(!pev_valid(ent))
		return
		
	set_pev(ent, pev_nextthink, get_gametime()+0.035)
	
	static Float:amt
	
	pev(ent, pev_fuser1, amt)
	
	if(amt<=30.0)
	{
		fm_remove_entity(ent)
		
		return 
	}
	
	amt-=6.0
	
	set_pev(ent, pev_fuser1, amt)
	set_pev(ent, pev_renderamt, amt)
	
	static Float:frame
	
	pev(ent, pev_frame, frame)
	
	frame+=0.25
	
	if(frame>=2.5)
	{
		static Float:scale
		
		pev(ent, pev_scale, scale)
		
		scale+=0.13
		
		set_pev(ent, pev_scale, scale)
	}
	
	
	set_pev(ent, pev_frame, frame)
}

public fwTouch(ent, id)
{
	if(!pev_valid(ent))
		return PLUGIN_CONTINUE
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
	
	if(pev(ent, pev_fuser1)<10.0)
		return PLUGIN_CONTINUE
	
	new owner=pev(ent, pev_owner)
	
	if(!is_user_connected(owner))
		return PLUGIN_CONTINUE
	
	new Float:Origin[3], victim
	
	pev(ent, pev_origin, Origin)
	
	while((victim=fm_find_ent_in_sphere(victim, Origin, 20.0))!=0)
	{	
		if(!pev_valid(victim))
			continue
			
		if(pev(victim, pev_takedamage)!=DAMAGE_NO&&pev(victim, pev_solid)!=SOLID_NOT)
		{
			if(is_user_alive(victim))
			{
				if(zp_get_user_zombie(victim))
				{
					ExecuteHamB( Ham_TakeDamage, victim , ent ,owner, get_pcvar_float(pcvar_damage), DMG_BURN)
					
					set_pdata_int(victim, m_LastHitGroup, HIT_GENERIC)
				}
			}
			else
				ExecuteHamB( Ham_TakeDamage, victim , ent ,owner, get_pcvar_float(pcvar_damage), DMG_BURN)
		}
	}
	
	return  PLUGIN_HANDLED
}


public Redirect(id)
	client_cmd(id, g_weapon_entity)	


public fwRemoveItem(id, ent)
{
	if(!is_valid_player(id))
		return
		
	if(cs_get_weapon_id(ent)!=CSW_CANNON)
		return
	
	WeapListSpr(id, g_weapon_entity)
}

public WeapListSpr(id, const weapon[])
{
	message_begin( MSG_ONE, get_user_msgid("WeaponList"), .player=id )
	write_string(weapon) 
	write_byte(3)
	write_byte(200)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(4)
	write_byte(CSW_CANNON)
	write_byte(0)
	message_end()	
}


stock is_valid_player(id)
{
	if(!is_user_alive(id))
		return false
	
	if(!g_HasCannon[id])
		return false
	
	return true
}

stock get_weapon_position(id, Float:fOrigin[3], Float:add_forward=0.0, Float:add_right=0.0, Float:add_up=0.0)
{
	static Float:Angles[3],Float:ViewOfs[3], Float:vAngles[3]
	static Float:Forward[3], Float:Right[3], Float:Up[3]
	
	pev(id, pev_v_angle, vAngles)
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, ViewOfs)
	xs_vec_add(fOrigin, ViewOfs, fOrigin)
	
	pev(id, pev_angles, Angles)
	
	Angles[0]=vAngles[0]
	
	engfunc(EngFunc_MakeVectors, Angles)
	
	global_get(glb_v_forward, Forward)
	global_get(glb_v_right, Right)
	global_get(glb_v_up,  Up)
	
	xs_vec_mul_scalar(Forward, add_forward, Forward)
	xs_vec_mul_scalar(Right, add_right, Right)
	xs_vec_mul_scalar(Up, add_up, Up)
	
	fOrigin[0]=fOrigin[0]+Forward[0]+Right[0]+Up[0]
	fOrigin[1]=fOrigin[1]+Forward[1]+Right[1]+Up[1]
	fOrigin[2]=fOrigin[2]+Forward[2]+Right[2]+Up[2]
}

stock playanim(player,anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

stock drop_weapons(id)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
    
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
        
		if ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)
		{
			static wname[32]
			
			get_weaponname(weaponid, wname, sizeof wname - 1)
           
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock fm_get_weapon_owner(weapon)
	return get_pdata_cbase(weapon, 41, 4)

	
stock Msg_CurWeapon(id, active, weapon, ammo)
{
	message_begin(MSG_ONE, gMsg_CurWeapon, {0,0,0}, id)
	write_byte(active)
	write_byte(weapon)
	write_byte(ammo)
	message_end()
}

stock Msg_AmmoX(id, ammotype, num)
{
	message_begin(MSG_ONE, gMsg_AmmoX, {0,0,0}, id)
	write_byte(ammotype)
	write_byte(num)
	message_end()		
}

stock Msg_AmmoPickup(id, ammotype, num)
{
	message_begin(MSG_ONE, gMsg_AmmoPickup, {0,0,0}, id)
	write_byte(ammotype)
	write_byte(num)
	message_end()		
}
