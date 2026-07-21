#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <beams>
#include <fakemeta>
#include <zombieplague>

new g_MsgBarTime
new Float:g_PlantingStart[33]
new bool:g_IsPlanting[33]
#define PLANT_TIME 1.3

//Uncomment 'OnlyOwnerCanDestroy' to block humans from destroying your tripmine (only owner can destroy).
//#define OnlyOwnerCanDestroy

//dont change please.. changing will result in error.
#define PevTripmineOwner pev_iuser2
#define PevBeamOwner pev_iuser3
#define PevBeamTripOwner pev_iuser4
#define TripmineBeamEndPoint pev_vuser1
#define TRIPMINE_WORLD 7
new const ClassnameTripmine[] = "n4d_tripmine"
new const ClassnameBreakable[] = "func_breakable"
new const ClassnameBeam[] = "n4d_beam"
new const Float:Minz[3] = {-8.0, -8.0, -8.0}
new const Float:Maxz[3] = {8.0, 8.0, 8.0}

//can change
new const ModelTripmine[] = "models/ch2012/v_laser_mine.mdl"
new const SoundDeploy[] = "weapons/mine_deploy.wav"
new const SoundCharge[]	= "weapons/mine_charge.wav"
new const SoundActive[]	= "weapons/mine_activate.wav"
new const SoundBeamStart[] = "debris/beamstart9.wav"
new const SoundGunPickup[] = "items/gunpickup2.wav"
new const SoundGlass[] = "debris/bustglass1.wav"
new const SoundGlass2[] = "debris/bustglass2.wav"
new const SprBeam[] = "sprites/laserbeam.spr"
new const ItemName[] = "Tripmine"
const TripmineCost = 5

new SprBoom, ItemTripmine, iPlayerTripmine[33], iPlayerDeployed[33], bool:bRoundEnd
new CvarDamage, CvarRadius, CvarKbForce, CvarMaxAmmo, CvarMaxPlant, CvarDoorRadius, CvarHealth

public plugin_precache()
{
	SprBoom = precache_model("sprites/zerogxplode.spr")
	precache_model(ModelTripmine)
	precache_sound(SoundDeploy)
	precache_sound(SoundCharge)
	precache_sound(SoundActive)
	precache_sound(SoundBeamStart)
	precache_sound(SoundGunPickup)
	precache_sound(SoundGlass)
	precache_sound(SoundGlass2)
}

public plugin_init()
{
	register_plugin(ItemName, "0.0.7", "+ARUKARI-,wbyokomo")
	register_dictionary("zp_extra_mine.txt")

	register_event("HLTV", "OnNewRound", "a", "1=0", "2=0")
	register_logevent("OnEndRound", 2, "1=Round_End")
	
	RegisterHam(Ham_Killed, "player", "OnPlayerKilled")
	#if defined OnlyOwnerCanDestroy
	RegisterHam(Ham_TakeDamage, ClassnameBreakable, "OnMineTakeDamage", 0)
	#endif
	RegisterHam(Ham_TakeDamage, ClassnameBreakable, "OnMineTakeDamagePost", 1)
	
	register_think(ClassnameTripmine, "OnThinkTripmine")
	register_touch(ClassnameBeam, "player", "OnTouchBeam")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	g_MsgBarTime = get_user_msgid("BarTime")

	
	#if defined IM_USING_ZP50
	ItemTripmine = zp_items_register(ItemName, TripmineCost)
	#else
	ItemTripmine = zp_register_extra_item(ItemName, TripmineCost, ZP_TEAM_HUMAN)
	#endif
	
	CvarDamage = register_cvar("tripmine_damage", "1200")
	CvarRadius = register_cvar("tripmine_radius", "300")
	CvarKbForce = register_cvar("tripmine_kb_force", "5")
	CvarMaxAmmo = register_cvar("tripmine_maxammo", "2")
	CvarMaxPlant = register_cvar("tripmine_maxplant", "1")
	CvarDoorRadius = register_cvar("tripmine_radius_door", "12")
	CvarHealth = register_cvar("tripmine_health", "200")
}

public CSBot_Init(id)
{
	RegisterHamFromEntity(Ham_Killed, id, "OnPlayerKilled")
}

public client_putinserver(id)
{
	ResetValues(id)
}

public client_disconnect(id)
{
	ResetValues(id)
	RemovePlayerTripMines(id)
}

public OnNewRound()
{
	RemoveAllTripmines()
	
	// Daj všetkým humanom lasermíny po 5 sekundách (po freezetime)
	set_task(9.0, "GiveTripmineToHumans")
}

public OnEndRound()
{
	bRoundEnd = true
	//RemoveAllTripmines()
}

public GiveTripmineToHumans()
{
	for(new id = 1; id <= MaxClients; id++)
	{
		if(!is_user_alive(id)) continue
		
		#if defined IM_USING_ZP50
		if(zp_core_is_zombie(id)) continue
		#else
		if(zp_get_user_zombie(id)) continue
		#endif
		
		// Daj lasermínu každému humanovi
		if(iPlayerTripmine[id] < get_pcvar_num(CvarMaxAmmo))
		{
			iPlayerTripmine[id]++
			client_print(id, print_chat, "[LaserMine] %L", id, "FREE_MINE")
			client_print(id, print_center, "%L", id, "RECEIVED_CENTER")
		}
	}
}

public OnPlayerKilled(id)
{
	iPlayerTripmine[id] = 0
}

#if defined OnlyOwnerCanDestroy
public OnMineTakeDamage(ent, inflictor, attacker, Float:damage, damagebits)
{
	//make sure it 'n4d_tripmine'
	new szClass[8]
	pev(ent, pev_classname, szClass, 7)
	if(!(szClass[0]=='n' && szClass[4]=='t')) return HAM_IGNORED;
	if(!is_user_connected(attacker)) return HAM_IGNORED;
	#if defined IM_USING_ZP50
	if(zp_core_is_zombie(attacker)) return HAM_IGNORED;
	#else
	if(zp_get_user_zombie(attacker)) return HAM_IGNORED;
	#endif
	
	static Owner; Owner = pev(ent, PevTripmineOwner);
	if((attacker != Owner) && is_user_connected(Owner)) return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}
#endif

public OnMineTakeDamagePost(ent, inflictor, attacker, Float:damage, damagebits)
{
	//make sure it 'n4d_tripmine'
	new szClass[8]
	entity_get_string(ent, EV_SZ_classname, szClass, 7)
	if(szClass[0]=='n' && szClass[4]=='t')
	{
		#if defined YOKO_DEBUG
		client_print(0, print_chat, "OnMineTakeDamagePost(%d, %d, %d, %f, %d)", ent, inflictor, attacker, damage, damagebits)
		#endif
		if(pev(ent, pev_health) <= 0.0)
		{
			set_pev(ent, pev_nextthink, 0.0)
			TripmineExplode(ent)
		}
	}
}

public OnThinkTripmine(ent)
{
	if(is_valid_ent(ent))
	{
		#if defined YOKO_DEBUG
		client_print(0, print_chat, "CALL: OnThinkTripmine(%d)", ent)
		#endif
		emit_sound(ent, CHAN_VOICE, SoundActive, 0.5, ATTN_NORM, 0, 75)
		set_pev(ent, pev_solid, SOLID_NOT) // Všetci môžu prechádzať cez lasermínu
		set_pev(ent, pev_takedamage, 2.0)
		
		new Owner = pev(ent, PevTripmineOwner)
		if(!is_user_connected(Owner))
		{
			RemoveEntitySafe(ent)
			return;
		}
		
		new beam = Beam_Create(SprBeam, 5.0)
		if(!is_valid_ent(beam))
		{
			RemoveEntitySafe(ent)
			return;
		}
			
		set_pev(beam, PevBeamOwner, Owner) //mark beam owner (player)
		set_pev(beam, PevBeamTripOwner, ent) //mark beam owner (mine)
		set_pev(ent, PevBeamTripOwner, beam) //mark mine owner (beam)
		set_pev(beam, pev_classname, ClassnameBeam)
			
		new Float:startOrigin[3], Float:endOrigin[3], Float:Color[3]
		pev(ent, pev_origin, startOrigin)
		pev(ent, TripmineBeamEndPoint, endOrigin)
		Beam_PointsInit(beam, startOrigin, endOrigin)
			
		// Iba zelený beam
		Color[0] = 0.0
		Color[1] = 255.0
		Color[2] = 0.0
		Beam_SetColor(beam, Color)
		Beam_SetNoise(beam, 0)
		// Odstránenie glow efektu
		// set_pev(ent, pev_renderfx, kRenderFxGlowShell)
		// set_pev(ent, pev_rendercolor, Color)
		set_pev(ent, pev_rendermode, kRenderNormal)
		set_pev(ent, pev_renderamt, 0.0)
		
		// Nekonečné HP - nedá sa zničiť
		set_pev(ent, pev_health, 999999.0)
		set_pev(ent, pev_takedamage, 0.0)
			
		set_pev(beam, pev_solid, SOLID_TRIGGER)
		set_pev(beam, pev_movetype, MOVETYPE_FLY)
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id)) return FMRES_IGNORED
	if(bRoundEnd) return FMRES_IGNORED
	if(!iPlayerTripmine[id]) return FMRES_IGNORED
	
	// Read the CURRENT command's buttons from the usercmd. In a pre-CmdStart
	// hook pev_button isn't updated yet (it still equals pev_oldbuttons), so
	// the rising-edge +use check would never fire and planting would do nothing.
	new buttons = get_uc(uc_handle, UC_Buttons)
	new oldbuttons = pev(id, pev_oldbuttons)
	
	// Stlačenie +Use
	if(buttons & IN_USE && !(oldbuttons & IN_USE))
	{
		if(iPlayerDeployed[id] >= get_pcvar_num(CvarMaxPlant))
		{
			client_print(id, print_chat, "[LaserMine] %L", id, "MAX_PLANTED", get_pcvar_num(CvarMaxPlant))
			return FMRES_IGNORED
		}
		if(!IsOnWall(id))
		{
			client_print(id, print_chat, "[LaserMine] %L", id, "MUST_WALL")
			return FMRES_IGNORED
		}
		
		// Začni plantovanie
		g_IsPlanting[id] = true
		g_PlantingStart[id] = get_gametime()
		
		// Zobraz progress bar
		message_begin(MSG_ONE, g_MsgBarTime, _, id)
		write_byte(floatround(PLANT_TIME))
		write_byte(0)
		message_end()
	}
	// Pustenie +Use
	else if(!(buttons & IN_USE) && (oldbuttons & IN_USE))
	{
		if(g_IsPlanting[id])
		{
			// Zruš plantovanie
			g_IsPlanting[id] = false
			
			// Skry progress bar
			message_begin(MSG_ONE, g_MsgBarTime, _, id)
			write_byte(0)
			write_byte(0)
			message_end()
			
		}
	}
	// Drží +Use
	else if(buttons & IN_USE && g_IsPlanting[id])
	{
		new Float:elapsed = get_gametime() - g_PlantingStart[id]
		
		// Kontrola či stále pozerá na stenu
		if(!IsOnWall(id))
		{
			g_IsPlanting[id] = false
			message_begin(MSG_ONE, g_MsgBarTime, _, id)
			write_byte(0)
			write_byte(0)
			message_end()
			return FMRES_IGNORED
		}
		
		if(elapsed >= PLANT_TIME)
		{
			// Zasaď mínu
			g_IsPlanting[id] = false
			
			// Skry progress bar
			message_begin(MSG_ONE, g_MsgBarTime, _, id)
			write_byte(0)
			write_byte(0)
			message_end()
			
			CreateTripmine(id)
			client_print(id, print_chat, "[LaserMine] %L", id, "PLANTED")
		}
	}
	
	return FMRES_IGNORED
}

public OnTouchBeam(ent, id)
{
	// Vypnuté - všetci môžu prechádzať cez laser beam
	
	if(is_valid_ent(ent))
	{
		#if defined IM_USING_ZP50
		if(is_user_alive(id) && zp_core_is_zombie(id) && (pev(id, pev_takedamage) == 2.0))
		#else
		if(is_user_alive(id) && zp_get_user_zombie(id) && (pev(id, pev_takedamage) == 2.0))
		#endif
		{
			#if defined YOKO_DEBUG
			client_print(0, print_chat, "CALL: OnTouchBeam(%d, %d)", ent, id)
			#endif
			new tm = pev(ent, PevBeamTripOwner) //get tripmine
			if(is_valid_ent(tm))
			{
				set_pev(tm, pev_nextthink, 0.0)
				TripmineExplodeOnTouch(tm)
			}
			
			RemoveEntitySafe(ent)
		}
	}
	
}



#if defined IM_USING_ZP50
public zp_fw_gamemodes_start()
{
	bRoundEnd = false
}

public zp_fw_core_infect_post(id)
{
	iPlayerTripmine[id] = 0
}

public zp_fw_items_select_pre(id, item, igcost)
{
	if(item != ItemTripmine) return ZP_ITEM_AVAILABLE;
	if(zp_core_is_zombie(id)) return ZP_ITEM_DONT_SHOW;
	if(bRoundEnd) return ZP_ITEM_NOT_AVAILABLE;
	if(iPlayerTripmine[id] >= get_pcvar_num(CvarMaxAmmo)) return ZP_ITEM_NOT_AVAILABLE;
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, item, igcost)
{
	if(item != ItemTripmine) return;
	
	iPlayerTripmine[id]++
	if(iPlayerTripmine[id] == 1) client_print(id, print_chat, "[LaserMine] %L", id, "BOUGHT");
	emit_sound(id, CHAN_STREAM, SoundGunPickup, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
#else
public zp_round_started()
{
	bRoundEnd = false
}

public zp_user_infected_post(id)
{
	iPlayerTripmine[id] = 0
}

public zp_extra_item_selected(id, item)
{
	if(item == ItemTripmine)
	{
		if(bRoundEnd) return ZP_PLUGIN_HANDLED;
		if(iPlayerTripmine[id] >= get_pcvar_num(CvarMaxAmmo)) return ZP_PLUGIN_HANDLED;
		
		iPlayerTripmine[id]++
		if(iPlayerTripmine[id] == 1) client_print(id, print_chat, "[LaserMine] %L", id, "BOUGHT");
		emit_sound(id, CHAN_STREAM, SoundGunPickup, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	return PLUGIN_CONTINUE;
}
#endif

public CmdBuyTripMine(id)
{
	if(bRoundEnd) return PLUGIN_HANDLED;
	if(!is_user_alive(id)) return PLUGIN_HANDLED;
	#if defined IM_USING_ZP50
	if(zp_core_is_zombie(id)) return PLUGIN_HANDLED;
	if(zp_class_survivor_get(id)) return PLUGIN_HANDLED;
	#else
	if(zp_get_user_zombie(id)) return PLUGIN_HANDLED;
	if(zp_get_user_survivor(id)) return PLUGIN_HANDLED;
	#endif
	if(iPlayerTripmine[id] >= get_pcvar_num(CvarMaxAmmo)) return PLUGIN_HANDLED;
	
	#if defined IM_USING_ZP50
	static ap; ap = zp_ammopacks_get(id);
	#else
	static ap; ap = zp_get_user_ammo_packs(id);
	#endif
	if(ap < TripmineCost) return PLUGIN_HANDLED;
	
	iPlayerTripmine[id]++
	if(iPlayerTripmine[id] == 1) client_print(id, print_chat, "[LaserMine] %L", id, "BOUGHT");
	emit_sound(id, CHAN_STREAM, SoundGunPickup, 1.0, ATTN_NORM, 0, PITCH_NORM)
	#if defined IM_USING_ZP50
	zp_ammopacks_set(id, ap-TripmineCost)
	#else
	zp_set_user_ammo_packs(id, ap-TripmineCost)
	#endif
	
	return PLUGIN_HANDLED;
}

CreateTripmine(id)
{
	new Float:vOrigin[3], Float:vNewOrigin[3], Float:vNormal[3], Float:vTraceDirection[3], Float:vTraceEnd[3], Float:vEntAngles[3]
	pev(id, pev_origin, vOrigin)
	velocity_by_aim(id, 128, vTraceDirection)
	xs_vec_add(vTraceDirection, vOrigin, vTraceEnd)
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, DONT_IGNORE_MONSTERS, id, 0)
	
	new Float:fFraction
	get_tr2(0, TR_flFraction, fFraction)
	if(fFraction < 1.0)
	{
		get_tr2(0, TR_vecEndPos, vTraceEnd)
		get_tr2(0, TR_vecPlaneNormal, vNormal)
	}
	
	xs_vec_mul_scalar(vNormal, 8.0, vNormal)
	xs_vec_add(vTraceEnd, vNormal, vNewOrigin)
	
	if(IsOriginNearDoor(vNewOrigin))
	{
		client_print(id, print_chat, "[TRIPMINE] %L", id, "DOOR_CLOSE")
		return;
	}
	
	new ent = create_entity(ClassnameBreakable)
	if(!is_valid_ent(ent)) return;
	
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_takedamage, 0.0)
	set_pev(ent, pev_classname, ClassnameTripmine)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	entity_set_model(ent, ModelTripmine)
	set_pev(ent, pev_frame, 0)
	set_pev(ent, pev_body, 3)
	set_pev(ent, pev_sequence, TRIPMINE_WORLD)
	set_pev(ent, pev_framerate, 0)
	entity_set_size(ent, Minz, Maxz)
	entity_set_origin(ent, vNewOrigin)
	vector_to_angle(vNormal, vEntAngles)
	set_pev(ent, pev_angles, vEntAngles)
	set_pev(ent, pev_health, get_pcvar_float(CvarHealth))
	set_pev(ent, PevTripmineOwner, id)
	new Float:vBeamEnd[3], Float:vTracedBeamEnd[3]
	xs_vec_mul_scalar(vNormal, 8192.0, vNormal)
	xs_vec_add(vNewOrigin, vNormal, vBeamEnd)
	engfunc(EngFunc_TraceLine, vNewOrigin, vBeamEnd, IGNORE_MONSTERS, -1, 0)
	get_tr2(0, TR_vecPlaneNormal, vNormal)
	get_tr2(0, TR_vecEndPos, vTracedBeamEnd)
	set_pev(ent, TripmineBeamEndPoint, vTracedBeamEnd)
	emit_sound(ent, CHAN_VOICE, SoundDeploy, 1.0, ATTN_NORM, 0, PITCH_NORM)
	emit_sound(ent, CHAN_BODY, SoundCharge, 0.2, ATTN_NORM, 0, PITCH_NORM)
	set_pev(ent, pev_nextthink, get_gametime()+2.5)
	iPlayerDeployed[id]++
	iPlayerTripmine[id]--
}

//since i'm using 'func_breakable' so no need to manually remove tripmine entity 'ent' because TripmineExplode(ent) is in Ham_TakeDamage post forward.
TripmineExplode(ent)
{
	if(!is_valid_ent(ent)) return;
	
	emit_sound(ent, CHAN_BODY, SoundCharge, 0.2, ATTN_NORM, SND_STOP, PITCH_NORM)
	emit_sound(ent, CHAN_VOICE, SoundActive, 0.5, ATTN_NORM, SND_STOP, 75)
	
	new beam = pev(ent, PevBeamTripOwner)
	if(is_valid_ent(beam)) RemoveEntitySafe(beam);
	
	new id2 = pev(ent, PevTripmineOwner)
	if(!is_user_connected(id2)) return;
	
	if(iPlayerDeployed[id2] > 0) iPlayerDeployed[id2]--;
	
	new Float:vOrigin[3]
	pev(ent, pev_origin, vOrigin)
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(SprBoom)
	write_byte(40)
	write_byte(30)
	write_byte(10)
	message_end()
	
	#if defined YOKO_DEBUG
	client_print(0, print_chat, "TripmineExplode(%d)--Atk:%d", ent, id2)
	#endif
	
	new victim = -1
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, vOrigin, get_pcvar_float(CvarRadius))) != 0)
	{
		if(!is_user_alive(victim)) continue;
		#if defined IM_USING_ZP50
		if((victim != id2) && !zp_core_is_zombie(victim)) continue;
		#else
		if((victim != id2) && !zp_get_user_zombie(victim)) continue;
		#endif
		
		new Float:fOrigin[3], Float:fDistance, Float:fDamage
		pev(victim, pev_origin, fOrigin)
		fDistance = get_distance_f(fOrigin, vOrigin)
		fDamage = get_pcvar_float(CvarDamage) - floatmul(get_pcvar_float(CvarDamage), floatdiv(fDistance, get_pcvar_float(CvarRadius)))
		fDamage *= EstimateTakeHurt(vOrigin, victim, 0)
		if(fDamage < 0.1) continue;
		
		ManageEffectAction(victim, fOrigin, vOrigin, fDistance, fDamage * get_pcvar_float(CvarKbForce))
		#if defined IM_USING_ZP50
		if(zp_core_is_zombie(victim) && (pev(victim, pev_takedamage) == 2.0))
		#else
		if(zp_get_user_zombie(victim) && (pev(victim, pev_takedamage) == 2.0))
		#endif
		{
			// Check if damage would kill the zombie
			new Float:current_health = float(pev(victim, pev_health))
			if(current_health <= fDamage)
			{
				// Set health to 1 instead of killing
				set_pev(victim, pev_health, 1.0)
			}
			else
			{
				// Normal damage
				ExecuteHamB(Ham_TakeDamage, victim, ent, id2, fDamage, DMG_BULLET)
			}
		}
	}
}

//manually remove tripmine entity.
TripmineExplodeOnTouch(ent)
{
	if(!is_valid_ent(ent)) return;
	
	emit_sound(ent, CHAN_BODY, SoundCharge, 0.2, ATTN_NORM, SND_STOP, PITCH_NORM)
	emit_sound(ent, CHAN_VOICE, SoundActive, 0.5, ATTN_NORM, SND_STOP, 75)
	
	new id2 = pev(ent, PevTripmineOwner)
	if(!is_user_connected(id2))
	{
		RemoveEntitySafe(ent)
		return;
	}
	
	if(iPlayerDeployed[id2] > 0) iPlayerDeployed[id2]--;
	
	new Float:vOrigin[3]
	pev(ent, pev_origin, vOrigin)
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(SprBoom)
	write_byte(40)
	write_byte(30)
	write_byte(10)
	message_end()
	
	new victim = -1
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, vOrigin, get_pcvar_float(CvarRadius))) != 0)
	{
		if(!is_user_alive(victim)) continue;
		#if defined IM_USING_ZP50
		if((victim != id2) && !zp_core_is_zombie(victim)) continue;
		#else
		if((victim != id2) && !zp_get_user_zombie(victim)) continue;
		#endif
		
		new Float:fOrigin[3], Float:fDistance, Float:fDamage
		pev(victim, pev_origin, fOrigin)
		fDistance = get_distance_f(fOrigin, vOrigin)
		fDamage = get_pcvar_float(CvarDamage) - floatmul(get_pcvar_float(CvarDamage), floatdiv(fDistance, get_pcvar_float(CvarRadius)))
		fDamage *= EstimateTakeHurt(vOrigin, victim, 0)
		if(fDamage < 0.1) continue;
		
		ManageEffectAction(victim, fOrigin, vOrigin, fDistance, fDamage * get_pcvar_float(CvarKbForce))
		#if defined IM_USING_ZP50
		if(zp_core_is_zombie(victim) && (pev(victim, pev_takedamage) == 2.0))
		#else
		if(zp_get_user_zombie(victim) && (pev(victim, pev_takedamage) == 2.0))
		#endif
		{
			ExecuteHamB(Ham_TakeDamage, victim, ent, id2, fDamage, DMG_BULLET)
		}
	}
	
	RemoveEntitySafe(ent)
}

TotalDeployedCount()
{
	new iCount=0, j
	for(j=1;j<=MaxClients;j++)
	{
		if(is_user_connected(j)) iCount += iPlayerDeployed[j];
	}

	return iCount;
}

bool:IsOnWall(id)
{
	new Float:vOrigin[3], Float:vTraceDirection[3], Float:vTraceEnd[3]
	pev(id, pev_origin, vOrigin)
	velocity_by_aim(id, 128, vTraceDirection)
	xs_vec_add(vTraceDirection, vOrigin, vTraceEnd)
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, DONT_IGNORE_MONSTERS, id, 0)
	
	new Float:fFraction, Float:vTraceNormal[3]
	get_tr2(0, TR_flFraction, fFraction)
	if(fFraction < 1.0)
	{
		get_tr2(0, TR_vecEndPos, vTraceEnd)
		get_tr2(0, TR_vecPlaneNormal, vTraceNormal)
		return true;
	}
	
	return false;
}

IsOriginNearDoor(const Float:origin[3])
{
	//func_door, func_door_rotating, momentary_door, n4d_tripmine
	new find, ent
	find = 0
	ent = -1
	
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, origin, get_pcvar_float(CvarDoorRadius))) != 0)
	{
		//non-player ent
		if(is_valid_ent(ent) && !is_user_connected(ent))
		{
			new cn[12]; pev(ent, pev_classname, cn, 11);
			if((cn[0] == 'n' && cn[4] == 't') || (cn[0] == 'f' && cn[5] == 'd') || (cn[0] == 'm' && cn[10] == 'd'))
			{
				find = 1
				break;
			}
		}
	}
	
	return find;
}

Float:EstimateTakeHurt(Float:fPoint[3], ent, ignored) 
{
	new Float:fOrigin[3], Float:fFraction, tr
	
	pev(ent, pev_origin, fOrigin)
	engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, ignored, tr)
	get_tr2(tr, TR_flFraction, fFraction)
	
	if(fFraction == 1.0 || get_tr2(tr, TR_pHit) == ent) return 1.0;
	
	return 0.6;
}

ManageEffectAction(iEnt, Float:fEntOrigin[3], Float:fPoint[3], Float:fDistance, Float:fDamage)
{
	new Float:Velocity[3]
	pev(iEnt, pev_velocity, Velocity)
	
	new Float:fTime = floatdiv(fDistance, fDamage)
	new Float:fVelocity[3]
	
	fVelocity[0] = floatdiv((fEntOrigin[0] - fPoint[0]), fTime) + Velocity[0]*0.5
	fVelocity[1] = floatdiv((fEntOrigin[1] - fPoint[1]), fTime) + Velocity[1]*0.5
	fVelocity[2] = floatdiv((fEntOrigin[2] - fPoint[2]), fTime) + Velocity[2]*0.5
	
	set_pev(iEnt, pev_velocity, fVelocity)
	return 1;
}

RemovePlayerTripMines(id)
{
	new ent = -1
	while((ent = find_ent_by_class(ent, ClassnameTripmine)))
	{
		if(!is_valid_ent(ent)) continue;
		if(pev(ent, PevTripmineOwner) == id) RemoveEntitySafe(ent);
	}
	
	new ent2 = -1
	while((ent2 = find_ent_by_class(ent2, ClassnameBeam)))
	{
		if(!is_valid_ent(ent2)) continue;
		if(pev(ent2, PevBeamOwner) == id) RemoveEntitySafe(ent2);
	}
}

RemoveAllTripmines()
{
	remove_entity_name(ClassnameTripmine)
	remove_entity_name(ClassnameBeam)
	
	new id
	for(id = 1; id <= MaxClients; id++)
	{
		if(is_user_connected(id)) iPlayerDeployed[id] = 0;
	}
}

ResetValues(id)
{
	iPlayerTripmine[id] = 0
	iPlayerDeployed[id] = 0
	g_IsPlanting[id] = false
	g_PlantingStart[id] = 0.0
	
	// Skry progress bar
	message_begin(MSG_ONE, g_MsgBarTime, _, id)
	write_byte(0)
	write_byte(0)
	message_end()
}

RemoveEntitySafe(ent)
{
	set_pev(ent, pev_flags, FL_KILLME)
	dllfunc(DLLFunc_Think, ent)
}
