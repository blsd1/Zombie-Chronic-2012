#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <zombieplague>

#define CUSTOM_MODELS  1
#define MAX_KNIFE_SNDS 9

#if (CUSTOM_MODELS)
	new MODEL_PLAYER[] 	= "models/ch2012/ch2012_v_knife.mdl"
#endif

#define PLUGIN	"Knife Knockback"
#define VERSION	"3.0"
#define AUTHOR	"ketamine"


new cvar_knife , cvar_knock , cvar_jump , cvar_survivor , cvar_jump_maxspeed;

public plugin_init()
{
	register_plugin(PLUGIN , VERSION , AUTHOR);
	register_cvar("zp_knife", VERSION, FCVAR_SERVER);
	register_event("Damage" , "event_Damage" , "b" , "2>0");
	register_event( "CurWeapon", "Event_CurWeapon", "be", "1=1" );
	register_forward(FM_EmitSound, "fw_EmitSound");

	cvar_knife         = register_cvar("zp_knife_knock" , "1");
	cvar_knock	   = register_cvar("zp_knife_power" , "10");
	cvar_jump          = register_cvar("zp_knife_jump", "380.0");
	cvar_jump_maxspeed = register_cvar("zp_knife_jump_maxspeed", "290.0");
        cvar_survivor      = register_cvar("zp_knife_survivor" , "1");
}

public event_Damage(id)
{
	if(!get_pcvar_num(cvar_knife))
		return PLUGIN_CONTINUE;

	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;

	if(zp_get_user_survivor(id) && get_pcvar_num(cvar_survivor) == 0)
		return PLUGIN_CONTINUE;

	new weapon , attacker = get_user_attacker(id , weapon);

	if(!is_user_alive(attacker))
		return PLUGIN_CONTINUE;

	if(weapon == CSW_KNIFE)
	{
		new Float:vec[3];
		new Float:oldvelo[3];
		get_user_velocity(id, oldvelo);
		create_velocity_vector(id , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_user_velocity(id , vec);
	}

	return PLUGIN_CONTINUE;
}

public Event_CurWeapon( id )
{
	if (!is_user_connected(id) || !is_user_alive(id) || zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
	
	new WeaponID = read_data(2)
	if (WeaponID != CSW_KNIFE)
		return  PLUGIN_CONTINUE
	
	#if (CUSTOM_MODELS)
		if(zp_has_user_chainsaw(id))
			return PLUGIN_CONTINUE
			
		entity_set_string(id, EV_SZ_viewmodel, MODEL_PLAYER)
	#endif
	
	return PLUGIN_CONTINUE;
} 

stock create_velocity_vector(victim,attacker,Float:velocity[3])
{
	if(!zp_get_user_zombie(victim) || !is_user_alive(attacker))
		return 0;

	new Float:vicorigin[3];
	new Float:attorigin[3];
	entity_get_vector(victim   , EV_VEC_origin , vicorigin);
	entity_get_vector(attacker , EV_VEC_origin , attorigin);

	new Float:origin2[3]
	origin2[0] = vicorigin[0] - attorigin[0];
	origin2[1] = vicorigin[1] - attorigin[1];

	new Float:largestnum = 0.0;

	if(floatabs(origin2[0])>largestnum) largestnum = floatabs(origin2[0]);
	if(floatabs(origin2[1])>largestnum) largestnum = floatabs(origin2[1]);

	origin2[0] /= largestnum;
	origin2[1] /= largestnum;

	velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_knock) * 3000) ) / get_entity_distance(victim , attacker);
	velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_knock) * 3000) ) / get_entity_distance(victim , attacker);
	if(velocity[0] <= 20.0 || velocity[1] <= 20.0)
		velocity[2] = random_float(200.0 , 275.0);

	return 1;
}

public plugin_precache()
{
	#if (CUSTOM_MODELS)
		precache_model(MODEL_PLAYER)
	#endif
}


public fw_EmitSound(id, channel, const sound[])
{
	return FMRES_IGNORED
}

public client_PreThink(id)
{
	if (!is_user_connected(id) || !is_user_alive(id) || zp_get_user_zombie(id))
		return PLUGIN_CONTINUE

	new temp[2], weapon = get_user_weapon(id, temp[0], temp[1])
	if (weapon != CSW_KNIFE)
		return PLUGIN_CONTINUE
		
	if ((get_user_button(id) & IN_JUMP) && !(get_user_oldbutton(id) & IN_JUMP))
	{
		new flags = entity_get_int(id, EV_INT_flags)
		new waterlvl = entity_get_int(id, EV_INT_waterlevel)
		
		if (!(flags & FL_ONGROUND))
			return PLUGIN_CONTINUE
		if (flags & FL_WATERJUMP)
			return PLUGIN_CONTINUE
		if (waterlvl > 1)
			return PLUGIN_CONTINUE
				
		new Float:fVelocity[3]
		entity_get_vector(id, EV_VEC_velocity, fVelocity)
		
		new Float:fHorizontalSpeed = floatsqroot(fVelocity[0] * fVelocity[0] + fVelocity[1] * fVelocity[1])
		
		if (fHorizontalSpeed < get_pcvar_float(cvar_jump_maxspeed))
		{
			fVelocity[2] += get_pcvar_float(cvar_jump)
		}
		
		entity_set_vector(id, EV_VEC_velocity, fVelocity)
		entity_set_int(id, EV_INT_gaitsequence, 6)
	}
	return PLUGIN_CONTINUE;
}  

