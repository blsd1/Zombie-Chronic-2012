#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <zombieplague>

const chainsaw_ap_cost = 30
new const chainsaw_viewmodel[] = "models/chainsaw/v_chainsaw.mdl"
new const chainsaw_playermodel[] = "models/chainsaw/p_chainsaw.mdl"
new const chainsaw_worldmodel[] = "models/chainsaw/w_chainsaw.mdl"

new const chainsaw_sounds[][] =
{
	"chainsaw/chainsaw_deploy.wav",
	"chainsaw/chainsaw_hit1.wav",
	"chainsaw/chainsaw_hit2.wav",
	"chainsaw/chainsaw_hit1.wav",
	"chainsaw/chainsaw_hit2.wav",
	"chainsaw/chainsaw_hitwall.wav",
	"chainsaw/chainsaw_miss.wav",
	"chainsaw/chainsaw_miss.wav",
	"chainsaw/chainsaw_stab.wav"
}

new Float:chainsaw_mins[3] = { -2.0, -2.0, -2.0 }
new Float:chainsaw_maxs[3] = { 2.0, 2.0, 2.0 }

new g_iItemID, g_msgCurWeapon, g_msgSayText

new g_iHasChainsaw[33], g_iCurrentWeapon[33]

new cvar_enable, cvar_dmgmult, cvar_oneround, cvar_sounds, cvar_dmggore, cvar_dropflags,
cvar_pattack_rate, cvar_sattack_rate, cvar_pattack_recoil, cvar_sattack_recoil, cvar_body_xplode

const DROPFLAG_NORMAL = 		(1<<0)
const DROPFLAG_INDEATH =	(1<<1)
const DROPFLAG_INFECTED =	(1<<2)
const DROPFLAG_SURVHUMAN =	(1<<3)

const m_pPlayer = 		41
const m_flNextPrimaryAttack = 	46
const m_flNextSecondaryAttack =	47
const m_flTimeWeaponIdle = 	48

new const oldknife_sounds[][] =
{
	"weapons/knife_deploy1.wav",
	"weapons/knife_hit1.wav",
	"weapons/knife_hit2.wav",
	"weapons/knife_hit3.wav",
	"weapons/knife_hit4.wav",
	"weapons/knife_hitwall1.wav",
	"weapons/knife_slash1.wav",
	"weapons/knife_slash2.wav",
	"weapons/knife_stab.wav"
}

#define PLUG_VERSION "0.9"
#define PLUG_AUTH "meTaLiCroSS"

public plugin_init()
{
	register_plugin("[ZP] Extra Item: Chainsaw", PLUG_VERSION, PLUG_AUTH)
	
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
	register_event("CurWeapon", "event_CurWeapon", "b", "1=1")
	
	cvar_enable = register_cvar("zp_chainsaw_enable", "1")
	cvar_sounds = register_cvar("zp_chainsaw_custom_sounds", "1")
	cvar_dmgmult = register_cvar("zp_chainsaw_damage_mult", "14.19")
	cvar_dmggore = register_cvar("zp_chainsaw_gore_in_damage", "1")
	cvar_oneround = register_cvar("zp_chainsaw_oneround", "0")
	cvar_dropflags = register_cvar("zp_chainsaw_drop_flags", "abcd")
	cvar_body_xplode = register_cvar("zp_chainsaw_victim_explode", "1")
	cvar_pattack_rate = register_cvar("zp_chainsaw_attack1_rate", "0.6")
	cvar_sattack_rate = register_cvar("zp_chainsaw_attack2_rate", "1.2")
	cvar_pattack_recoil = register_cvar("zp_chainsaw_attack1_recoil", "-5.6")
	cvar_sattack_recoil = register_cvar("zp_chainsaw_attack2_recoil", "-8.0")
	
	new szCvar[30]
	formatex(szCvar, charsmax(szCvar), "v%s by %s", PLUG_VERSION, PLUG_AUTH)
	register_cvar("zp_extra_chainsaw", szCvar, FCVAR_SERVER|FCVAR_SPONLY)
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	register_touch("cs_chainsaw", "player", "fw_Chainsaw_Touch")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Knife_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Knife_SecondaryAttack_Post", 1)
	
	g_iItemID = zp_register_extra_item("Chainsaw", chainsaw_ap_cost, ZP_TEAM_HUMAN)
	
	g_msgSayText = get_user_msgid("SayText")
	g_msgCurWeapon = get_user_msgid("CurWeapon")
	
	register_clcmd("drop", "clcmd_drop")
}

public plugin_natives()
{
	register_library("zp_chainsaw")
	register_native("zp_give_user_chainsaw", "native_give_user_chainsaw", 1)
	register_native("zp_has_user_chainsaw", "native_has_user_chainsaw", 1)
}

public plugin_precache()
{
	precache_model(chainsaw_viewmodel)
	precache_model(chainsaw_playermodel)
	precache_model(chainsaw_worldmodel)
	
	for(new i = 0; i < sizeof chainsaw_sounds; i++)
		precache_sound(chainsaw_sounds[i])
		
	precache_sound("items/gunpickup2.wav")
}

public event_RoundStart()
{
	remove_entity_name("cs_chainsaw")
}

public event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
		
	g_iCurrentWeapon[id] = read_data(2)
	
	if(zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return PLUGIN_CONTINUE
		
	if(!g_iHasChainsaw[id] || g_iCurrentWeapon[id] != CSW_KNIFE) 
		return PLUGIN_CONTINUE
		
	entity_set_string(id, EV_SZ_viewmodel, chainsaw_viewmodel)
	entity_set_string(id, EV_SZ_weaponmodel, chainsaw_playermodel)
		
	return PLUGIN_CONTINUE
}

public clcmd_drop(id)
{
	if(g_iHasChainsaw[id] && g_iCurrentWeapon[id] == CSW_KNIFE)
	{
		if(check_drop_flag(DROPFLAG_NORMAL))
		{
			drop_chainsaw(id)
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}

public drop_chainsaw(id) 
{
	static Float:flAim[3], Float:flOrigin[3]
	VelocityByAim(id, 64, flAim)
	entity_get_vector(id, EV_VEC_origin, flOrigin)
	
	flOrigin[0] += flAim[0]
	flOrigin[1] += flAim[1]
	
	new iEnt = create_entity("info_target")
	
	entity_set_string(iEnt, EV_SZ_classname, "cs_chainsaw")
	
	entity_set_origin(iEnt, flOrigin)
	
	entity_set_model(iEnt, chainsaw_worldmodel)
	
	set_size(iEnt, chainsaw_mins, chainsaw_maxs)
	entity_set_vector(iEnt, EV_VEC_mins, chainsaw_mins)
	entity_set_vector(iEnt, EV_VEC_maxs, chainsaw_maxs)
	
	// Solid Type
	entity_set_int(iEnt, EV_INT_solid, SOLID_TRIGGER)
	
	// Movetype
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_TOSS)
	
	// Var's
	g_iHasChainsaw[id] = false
	
	// Model bugfix
	reset_user_knife(id)
}

public reset_user_knife(id)
{
	// Execute weapon Deploy
	if(user_has_weapon(id, CSW_KNIFE))
		ExecuteHamB(Ham_Item_Deploy, find_ent_by_owner(-1, "weapon_knife", id))
		
	// Updating Model
	engclient_cmd(id, "weapon_knife")
	emessage_begin(MSG_ONE, g_msgCurWeapon, _, id)
	ewrite_byte(1) // active
	ewrite_byte(CSW_KNIFE) // weapon
	ewrite_byte(-1) // clip
	emessage_end()
}

/*================================================================================
 [ZombiePlague Forwards]
=================================================================================*/

public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_iItemID)
	{
		// Check cvar
		if(get_pcvar_num(cvar_enable))
		{
			// Already has a Chainsaw
			if (g_iHasChainsaw[id])
			{
				// Don't refund if player is Hannibal
				if(!zp_get_user_hannibal(id))
					zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + chainsaw_ap_cost)
				client_printcolor(id, "/g[ZP]/y You already have a /gChainsaw")
			}
			else 
			{
				// Boolean
				g_iHasChainsaw[id] = true
				
				// Emiting Sound
				emit_sound(id, CHAN_WEAPON, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				// Client Print
				client_printcolor(id, "/g[ZP]/y You now have a /gChainsaw")
				
				// Change weapon to Knife
				reset_user_knife(id)
			}
		}
		// Isn't enabled...
		else
		{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + chainsaw_ap_cost)
			client_printcolor(id, "/g[ZP]/y Chainsaw item has been disabled. /gContact Admin")
		}
	}
}

public zp_user_infected_pre(id, infector)
{
	// Drop in infection
	if (g_iHasChainsaw[id])
	{
		if(check_drop_flag(DROPFLAG_INFECTED))
			drop_chainsaw(id)
		else
		{
			g_iHasChainsaw[id] = false
			reset_user_knife(id)
		}
	}
}

public zp_user_humanized_post(id)
{
	// Is survivor
	if(zp_get_user_survivor(id) && g_iHasChainsaw[id])
	{
		if(check_drop_flag(DROPFLAG_SURVHUMAN))
			drop_chainsaw(id)
		else
		{
			g_iHasChainsaw[id] = false
			reset_user_knife(id)
		}
	}
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public client_putinserver(id)
{
	g_iHasChainsaw[id] = false
}

public client_disconnected(id)
{
	g_iHasChainsaw[id] = false
}
	
public fw_PlayerSpawn_Post(id)
{
	// Check Oneround Cvar and Strip all the Chainsaws
	if(get_pcvar_num(cvar_oneround) || !get_pcvar_num(cvar_enable))
	{
		// Has Chainsaw
		if(g_iHasChainsaw[id])
		{
			// Var's
			g_iHasChainsaw[id] = false

			// Update Knife
			reset_user_knife(id)
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_bits)
{	
	// Check
	if(victim == attacker || !attacker)
		return HAM_IGNORED
		
	// Attacker is not a Player
	if(!is_user_connected(attacker))
		return HAM_IGNORED
		
	// Has chainsaw and Weapon is knife
	if(g_iHasChainsaw[attacker] && g_iCurrentWeapon[attacker] == CSW_KNIFE)
	{
		// Gore
		if(get_pcvar_num(cvar_dmggore))
			a_lot_of_blood(victim)
			
		// Damage mult.
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult))	

	}

	return HAM_IGNORED
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Check
	if(victim == attacker || !attacker)
		return HAM_IGNORED
		
	// Attacker is not a Player
	if(!is_user_connected(attacker))
		return HAM_IGNORED
		
	// Attacker Has a Chainsaw
	if(g_iHasChainsaw[attacker] && g_iCurrentWeapon[attacker] == CSW_KNIFE && !zp_get_user_nemesis(victim) && get_pcvar_num(cvar_body_xplode))
		SetHamParamInteger(3, 2) // Body Explodes
	
	// Victim Has a Chainsaw
	if(g_iHasChainsaw[victim])
	{
		if(check_drop_flag(DROPFLAG_INDEATH))
			drop_chainsaw(victim)
		else
		{
			g_iHasChainsaw[victim] = false
			reset_user_knife(victim)
		}
	}
	
	return HAM_IGNORED
}

public fw_Chainsaw_Touch(saw, player)
{
	// Entities are not valid
	if(!is_valid_ent(saw) || !is_valid_ent(player))
		return PLUGIN_CONTINUE
		
	// Is a valid player?
	if(!is_user_connected(player))
		return PLUGIN_CONTINUE
		
	// Alive, Zombie or Survivor
	if(!is_user_alive(player) || zp_get_user_zombie(player) || zp_get_user_survivor(player) || g_iHasChainsaw[player])
		return PLUGIN_CONTINUE
		
	// Var's
	g_iHasChainsaw[player] = true
	
	// Emiting Sound
	emit_sound(player, CHAN_WEAPON, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Knife Deploy
	reset_user_knife(player)
	
	// Remove dropped chainsaw
	remove_entity(saw)
		
	return PLUGIN_CONTINUE
}

public fw_EmitSound(id, channel, const sound[])
{
	// Non-player entity
	if(!is_user_connected(id))
		return FMRES_IGNORED
		
	// Not Alive / Zombie / Doesn't have a Chainsaw
	if(!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id) || !g_iHasChainsaw[id] || !get_pcvar_num(cvar_sounds))
		return FMRES_IGNORED
		
	// Check sound
	for(new i = 0; i < sizeof chainsaw_sounds; i++)
	{
		if(equal(sound, oldknife_sounds[i]))
		{
			// Emit New sound and Stop old Sound
			emit_sound(id, channel, chainsaw_sounds[i], 1.0, ATTN_NORM, 0, PITCH_NORM)
			return FMRES_SUPERCEDE
		}
	}
			
	return FMRES_IGNORED
}

public fw_Knife_PrimaryAttack_Post(knife)
{	
	// Get knife owner
	static id
	id = get_pdata_cbase(knife, m_pPlayer, 4)
	
	// has a Chainsaw
	if(is_user_connected(id) && g_iHasChainsaw[id])
	{
		// Get new fire rate
		static Float:flRate
		flRate = get_pcvar_float(cvar_pattack_rate)
		
		// Set new rates
		set_pdata_float(knife, m_flNextPrimaryAttack, flRate, 4)
		set_pdata_float(knife, m_flNextSecondaryAttack, flRate, 4)
		set_pdata_float(knife, m_flTimeWeaponIdle, flRate, 4)
		
		// Get new recoil
		static Float:flPunchAngle[3]
		flPunchAngle[0] = get_pcvar_float(cvar_pattack_recoil)
		
		// Punch their angles
		entity_set_vector(id, EV_VEC_punchangle, flPunchAngle)
		
	}
	
	return HAM_IGNORED
}

public fw_Knife_SecondaryAttack_Post(knife)
{	
	// Get knife owner
	static id
	id = get_pdata_cbase(knife, m_pPlayer, 4)
	
	// has a Chainsaw
	if(is_user_connected(id) && g_iHasChainsaw[id])
	{
		// Get new fire rate
		static Float:flRate
		flRate = get_pcvar_float(cvar_sattack_rate)
		
		// Set new rates
		set_pdata_float(knife, m_flNextPrimaryAttack, flRate, 4)
		set_pdata_float(knife, m_flNextSecondaryAttack, flRate, 4)
		set_pdata_float(knife, m_flTimeWeaponIdle, flRate, 4)
		
		// Get new recoil
		static Float:flPunchAngle[3]
		flPunchAngle[0] = get_pcvar_float(cvar_sattack_recoil)
		
		// Punch their angles
		entity_set_vector(id, EV_VEC_punchangle, flPunchAngle)
	}
	
	return HAM_IGNORED
}

/*================================================================================
 [Internal Functions]
=================================================================================*/

check_drop_flag(flag)
{
	new szFlags[10]
	get_pcvar_string(cvar_dropflags, szFlags, charsmax(szFlags))
	
	if(read_flags(szFlags) & flag)
		return true
		
	return false
}

a_lot_of_blood(id) // ROFL, thanks to jtp10181 for his AMX Ultimate Gore plugin.
{
	// Get user origin
	static iOrigin[3]
	get_user_origin(id, iOrigin)
	
	// Blood spray
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin)
	write_byte(TE_BLOODSTREAM)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2]+10)
	write_coord(random_num(-360, 360)) // x
	write_coord(random_num(-360, 360)) // y
	write_coord(-10) // z
	write_byte(70) // color
	write_byte(random_num(50, 100)) // speed
	message_end()
	
	// Write Small splash decal
	for (new j = 0; j < 4; j++) 
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin)
		write_byte(TE_WORLDDECAL)
		write_coord(iOrigin[0]+random_num(-100, 100))
		write_coord(iOrigin[1]+random_num(-100, 100))
		write_coord(iOrigin[2]-36)
		write_byte(random_num(190, 197)) // index
		message_end()
	}
}

/*================================================================================
 [Native Functions]
=================================================================================*/

public native_give_user_chainsaw(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CHAINSAW] Invalid Player (%d)", id)
		return false;
	}
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[CHAINSAW] Player is not alive (%d)", id)
		return false;
	}
	
	// Give chainsaw
	g_iHasChainsaw[id] = true
	
	// Emiting Sound
	emit_sound(id, CHAN_WEAPON, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Change weapon to Knife
	reset_user_knife(id)
	
	return true;
}

public native_has_user_chainsaw(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CHAINSAW] Invalid Player (%d)", id)
		return false;
	}
	
	return g_iHasChainsaw[id];
}

/*================================================================================
 [Stocks]
=================================================================================*/

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
