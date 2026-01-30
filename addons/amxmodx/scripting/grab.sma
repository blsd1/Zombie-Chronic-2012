//#define engine

#include <amxmodx>
#include <amxmisc>
#include <fun>
#if defined engine
#include <engine>
#else
#include <fakemeta>
#endif

#define ADMIN_LEVEL_Q	ADMIN_LEVEL_C

//Used for Grab
new maxplayers
new grab[33]
new Float:grab_totaldis[33]
new grab_speed_cvar
new grab_enabled_cvar
new bool:has_grab[33]

//Used for Hook
new bool:hook[33]
new hook_to[33][3]
new hook_speed_cvar
new hook_enabled_cvar
new bool:has_hook[33]

//Used for Rope
new bool:rope[33]
new rope_to[33][3]
new Float:rope_totaldis[33]
new rope_speed_cvar
new rope_enabled_cvar
new bool:has_rope[33]

//Used for All
new beamsprite


/****************************
 Register Commands and CVARs
****************************/

public plugin_init()
{
	register_plugin("Grab + Hook + Rope","1.0","GHW_Chronic")
	register_concmd("+grab","grab_on",ADMIN_LEVEL_Q," - Use: bind key +grab")
	register_concmd("-grab","grab_off")
	register_concmd("grab_toggle","grab_toggle",ADMIN_LEVEL_Q,"Toggles your grab on and off")
	register_concmd("+hook","hook_on",ADMIN_LEVEL_Q," - Use: bind key +hook")
	register_concmd("-hook","hook_off")
	register_concmd("hook_toggle","hook_toggle",ADMIN_LEVEL_Q,"Toggles your hook on and off")
	register_concmd("+rope","rope_on",ADMIN_LEVEL_Q," - Use: bind key +rope")
	register_concmd("-rope","rope_off")
	register_concmd("rope_toggle","rope_toggle",ADMIN_LEVEL_Q,"Toggles your rope on and off")

	register_concmd("amx_give_grab","cmd_givetake",ADMIN_LEVEL_Q,"Give a player the ability to grab <nick>")
	register_concmd("amx_give_hook","cmd_givetake",ADMIN_LEVEL_Q,"Give a player the ability to hook <nick>")
	register_concmd("amx_give_rope","cmd_givetake",ADMIN_LEVEL_Q,"Give a player the ability to rope <nick>")

	register_concmd("amx_take_grab","cmd_givetake",ADMIN_LEVEL_Q,"Take a player's ability to grab <nick>")
	register_concmd("amx_take_hook","cmd_givetake",ADMIN_LEVEL_Q,"Take a player's ability to hook <nick>")
	register_concmd("amx_take_rope","cmd_givetake",ADMIN_LEVEL_Q,"Take a player's ability to rope <nick>")

	register_concmd("amx_ghr_menu","menu_cmd",ADMIN_LEVEL_Q,"Shows a menu that allows you to turn on/off non-admin use of grab, hook, or rope")

	register_menucmd(register_menuid("ghr_menu"),(1<<0)|(1<<1)|(1<<2)|(1<<9), "Pressedghr")

	grab_speed_cvar = register_cvar("grab_speed","5")
	grab_enabled_cvar = register_cvar("grab_enabled","0")

	hook_speed_cvar = register_cvar("hook_speed","5")
	hook_enabled_cvar = register_cvar("hook_enabled","0")

	rope_speed_cvar = register_cvar("rope_speed","5")
	rope_enabled_cvar = register_cvar("rope_enabled","0")

	maxplayers = get_maxplayers()

	//CVAR that is only used for tracking servers that use this plugin.
	register_cvar("GHW_GHW","1",FCVAR_SERVER)
}


/**********************************
 Register beam sprite + Hook Sound
**********************************/

public plugin_precache()
{
	beamsprite = precache_model("sprites/dot.spr")
	precache_sound("weapons/xbow_hit2.wav")
	precache_sound("weapons/xbow_fire1.wav")
}


/*****************************
 Reset VARs on client connect
*****************************/

public client_putinserver(id)
{
	has_grab[id]=false
	has_hook[id]=false
	has_rope[id]=false
}


/*****
 Menu
*****/

public menu_cmd(id,level,cid)
{
	if(cmd_access(id,level,cid,1))
	{
		show_ghr(id)
		console_print(id,"[AMXX] Menu launched.")
	}
}

public show_ghr(id)
{
	static aaa[32]
	static bbb[32]
	static ccc[32]
	if(get_pcvar_num(grab_enabled_cvar)==0) format(aaa,31,"No")
	else format(aaa,31,"Yes")
	if(get_pcvar_num(hook_enabled_cvar)==0) format(bbb,31,"No")
	else format(bbb,31,"Yes")
	if(get_pcvar_num(rope_enabled_cvar)==0) format(ccc,31,"No")
	else format(ccc,31,"Yes")

	new menuBody[576]

	if(colored_menus())
	{
		new len = format(menuBody,575,"\bAllow Players To Use:^n^n")
		len += format(menuBody[len],575-len, "\w1. Grab\R\w%s^n",aaa)
		len += format(menuBody[len],575-len, "\w2. Hook\R\w%s^n",bbb)
		len += format(menuBody[len],575-len, "\w3. Rope\R\w%s^n",ccc)
		len += format(menuBody[len],575-len, "\r0. Exit")
	}
	else
	{
		new len = format(menuBody,575,"Allow Players To Use:^n^n")
		len += format(menuBody[len],575-len, "1. Grab\R%s^n",aaa)
		len += format(menuBody[len],575-len, "2. Hook\R%s^n",bbb)
		len += format(menuBody[len],575-len, "3. Rope\R%s^n",ccc)
		len += format(menuBody[len],575-len, "0. Exit")
	}
	show_menu(id,(1<<0)|(1<<1)|(1<<2)|(1<<9),menuBody,-1,"ghr_menu")

	return PLUGIN_CONTINUE
}

public Pressedghr(id,key)
{
	switch(key)
	{
		case 0:
		{
			if(get_pcvar_num(grab_enabled_cvar)==0)
			{
				set_pcvar_num(grab_enabled_cvar,1)
				client_print(0,print_chat,"[AMXX] Admin has enabled Grab for all clients. Use: bind key +grab")
			}
			else
			{
				set_pcvar_num(grab_enabled_cvar,0)
				client_print(0,print_chat,"[AMXX] Admin has disabled Grab for all non-admins.")
			}
			show_ghr(id)
		}
		case 1:
		{
			if(get_pcvar_num(hook_enabled_cvar)==0)
			{
				set_pcvar_num(hook_enabled_cvar,1)
				client_print(0,print_chat,"[AMXX] Admin has enabled Hook for all clients. Use: bind key +hook")
			}
			else
			{
				set_pcvar_num(hook_enabled_cvar,0)
				client_print(0,print_chat,"[AMXX] Admin has disabled Hook for all non-admins.")
			}
			show_ghr(id)
		}
		case 2:
		{
			if(get_pcvar_num(rope_enabled_cvar)==0)
			{
				set_pcvar_num(rope_enabled_cvar,1)
				client_print(0,print_chat,"[AMXX] Admin has enabled Rope for all clients. Use: bind key +rope")
			}
			else
			{
				set_pcvar_num(rope_enabled_cvar,0)
				client_print(0,print_chat,"[AMXX] Admin has disabled Rope for all non-admins.")
			}
			show_ghr(id)
		}
	}
}


/****************
 Handle Commands
****************/

public cmd_givetake(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))
	{
		return PLUGIN_HANDLED
	}

	new arg1[32]
	read_argv(1,arg1,31)

	new target = cmd_target(id,arg1,9)
	if(!target)
	{
		return PLUGIN_HANDLED
	}

	new name[32]
	get_user_name(target,name,31)
	if(get_user_flags(target) & ADMIN_LEVEL_Q)
	{
		console_print(id,"[AMXX] Cannot give/take grab/hook/rope from admin %s.",name)
		return PLUGIN_HANDLED
	}

	new arg0[32]
	read_argv(0,arg0,31)
	if(containi(arg0,"give")!=-1)
	{
		if(containi(arg0,"grab")!=-1)
		{
			if(has_grab[target])
			{
				console_print(id,"[AMXX] %s already has grab",name)
			}
			else
			{
				has_grab[target]=true
				console_print(id,"[AMXX] %s has been given grab",name)
				client_print(target,print_chat,"[AMXX] An admin has given you grab. Use: bind key +grab")
			}
		}
		else if(containi(arg0,"hook")!=-1)
		{
			if(has_hook[target])
			{
				console_print(id,"[AMXX] %s already has hook",name)
			}
			else
			{
				has_hook[target]=true
				console_print(id,"[AMXX] %s has been given hook",name)
				client_print(target,print_chat,"[AMXX] An admin has given you hook. Use: bind key +hook")
			}
		}
		else if(containi(arg0,"rope")!=-1)
		{
			if(has_rope[target])
			{
				console_print(id,"[AMXX] %s already has rope",name)
			}
			else
			{
				has_rope[target]=true
				console_print(id,"[AMXX] %s has been given rope",name)
				client_print(target,print_chat,"[AMXX] An admin has given you hook. Use: bind key +rope")
			}
		}
	}
	if(containi(arg0,"take")!=-1)
	{
		if(containi(arg0,"grab")!=-1)
		{
			if(!has_grab[target])
			{
				console_print(id,"[AMXX] %s doesn't have grab",name)
			}
			else
			{
				has_grab[target]=false
				console_print(id,"[AMXX] %s's grab has been taken away.",name)
				client_print(target,print_chat,"[AMXX] An admin has taken your grab away.")
			}
		}
		if(containi(arg0,"hook")!=-1)
		{
			if(!has_hook[target])
			{
				console_print(id,"[AMXX] %s doesn't have hook",name)
			}
			else
			{
				has_hook[target]=false
				console_print(id,"[AMXX] %s's hook has been taken away.",name)
				client_print(target,print_chat,"[AMXX] An admin has taken your hook away.")
			}
		}
		if(containi(arg0,"rope")!=-1)
		{
			if(!has_rope[target])
			{
				console_print(id,"[AMXX] %s doesn't have rope",name)
			}
			else
			{
				has_rope[target]=false
				console_print(id,"[AMXX] %s's rope has been taken away.",name)
				client_print(target,print_chat,"[AMXX] An admin has taken your rope away.")
			}
		}
	}
	return PLUGIN_HANDLED
}


/*****
 Grab
*****/

public grab_toggle(id,level,cid)
{
	if(grab[id]) grab_off(id)
	else grab_on(id,level,cid)
	return PLUGIN_HANDLED
}

public grab_on(id,level,cid)
{
	if(!has_grab[id] && !get_pcvar_num(grab_enabled_cvar) && !cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if(grab[id])
	{
		return PLUGIN_HANDLED
	}
	grab[id]=-1
	static target, trash
	target=0
	get_user_aiming(id,target,trash)
	if(target && is_valid_ent2(target) && target!=id)
	{
		if(target<=maxplayers)
		{
			if(is_user_alive(target) && !(get_user_flags(target) & ADMIN_IMMUNITY))
			{
				client_print(id,print_chat,"[AMXX] Found Target")
				grabem(id,target)
			}
		}
		else if(get_solidity(target)!=4)
		{
			client_print(id,print_chat,"[AMXX] Found Target")
			grabem(id,target)
		}
	}
	else
	{
		client_print(id,print_chat,"[AMXX] Searching for Target")
		set_task(0.1,"grab_on2",id)
	}
	return PLUGIN_HANDLED
}

public grab_on2(id)
{
	if(is_user_connected(id))
	{
		static target, trash
		target=0
		get_user_aiming(id,target,trash)
		if(target && is_valid_ent2(target) && target!=id)
		{
			if(target<=maxplayers)
			{
				if(is_user_alive(target) && !(get_user_flags(target) & ADMIN_IMMUNITY))
				{
					client_print(id,print_chat,"[AMXX] Found Target")
					grabem(id,target)
				}
			}
			else if(get_solidity(target)!=4)
			{
				client_print(id,print_chat,"[AMXX] Found Target")
				grabem(id,target)
			}
		}
		else
		{
			set_task(0.1,"grab_on2",id)
		}
	}
}

public grabem(id,target)
{
	grab[id]=target
	set_rendering2(target,kRenderFxGlowShell,255,0,0,kRenderTransAlpha,70)
	if(target<=maxplayers) set_user_gravity(target,0.0)
	grab_totaldis[id] = 0.0
	set_task(0.1,"grab_prethink",id+1000,"",0,"b")
	grab_prethink(id+1000)
	emit_sound(id,CHAN_VOICE,"weapons/xbow_fire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public grab_off(id)
{
	if(is_user_connected(id))
	{
		if(grab[id]==-1)
		{
			client_print(id,print_chat,"[AMXX] No Target Found")
			grab[id]=0
		}
		else if(grab[id])
		{
			client_print(id,print_chat,"[AMXX] Target Released")
			set_rendering2(grab[id])
			if(grab[id]<=maxplayers && is_user_alive(grab[id])) set_user_gravity(grab[id],1.0)
			grab[id]=0
		}
	}
	return PLUGIN_HANDLED
}

public grab_prethink(id)
{
	id -= 1000
	if(!is_user_connected(id) && grab[id]>0)
	{
		set_rendering2(grab[id])
		if(grab[id]<=maxplayers && is_user_alive(grab[id])) set_user_gravity(grab[id],1.0)
		grab[id]=0
	}
	if(!grab[id] || grab[id]==-1)
	{
		remove_task(id+1000)
		return PLUGIN_HANDLED
	}

	//Get Id's, target's, and Where Id is looking's origins
	static origin1[3]
	get_user_origin(id,origin1)
	static Float:origin2_F[3], origin2[3]
	get_origin(grab[id],origin2_F)
	origin2[0] = floatround(origin2_F[0])
	origin2[1] = floatround(origin2_F[1])
	origin2[2] = floatround(origin2_F[2])
	static origin3[3]
	get_user_origin(id,origin3,3)

	//Create red beam
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)		//TE_BEAMENTPOINT
	write_short(id)		// start entity
	write_coord(origin2[0])
	write_coord(origin2[1])
	write_coord(origin2[2])
	write_short(beamsprite)
	write_byte(1)		// framestart
	write_byte(1)		// framerate
	write_byte(1)		// life in 0.1's
	write_byte(5)		// width
	write_byte(0)		// noise
	write_byte(255)		// red
	write_byte(0)		// green
	write_byte(0)		// blue
	write_byte(200)		// brightness
	write_byte(0)		// speed
	message_end()

	//Convert to floats for calculation
	static Float:origin1_F[3]
	static Float:origin3_F[3]
	origin1_F[0] = float(origin1[0])
	origin1_F[1] = float(origin1[1])
	origin1_F[2] = float(origin1[2])
	origin3_F[0] = float(origin3[0])
	origin3_F[1] = float(origin3[1])
	origin3_F[2] = float(origin3[2])

	//Calculate target's new velocity
	static Float:distance[3]

	if(!grab_totaldis[id])
	{
		distance[0] = floatabs(origin1_F[0] - origin2_F[0])
		distance[1] = floatabs(origin1_F[1] - origin2_F[1])
		distance[2] = floatabs(origin1_F[2] - origin2_F[2])
		grab_totaldis[id] = floatsqroot(distance[0]*distance[0] + distance[1]*distance[1] + distance[2]*distance[2])
	}
	distance[0] = origin3_F[0] - origin1_F[0]
	distance[1] = origin3_F[1] - origin1_F[1]
	distance[2] = origin3_F[2] - origin1_F[2]

	static Float:grab_totaldis2
	grab_totaldis2 = floatsqroot(distance[0]*distance[0] + distance[1]*distance[1] + distance[2]*distance[2])

	static Float:que
	que = grab_totaldis[id] / grab_totaldis2

	static Float:origin4[3]
	origin4[0] = ( distance[0] * que ) + origin1_F[0]
	origin4[1] = ( distance[1] * que ) + origin1_F[1]
	origin4[2] = ( distance[2] * que ) + origin1_F[2]

	static Float:velocity[3]
	velocity[0] = (origin4[0] - origin2_F[0]) * (get_pcvar_float(grab_speed_cvar) / 1.666667)
	velocity[1] = (origin4[1] - origin2_F[1]) * (get_pcvar_float(grab_speed_cvar) / 1.666667)
	velocity[2] = (origin4[2] - origin2_F[2]) * (get_pcvar_float(grab_speed_cvar) / 1.666667)

	set_velo(grab[id],velocity)

	return PLUGIN_CONTINUE
}


/*****
 Hook
*****/

public hook_toggle(id,level,cid)
{
	if(hook[id]) hook_off(id)
	else hook_on(id,level,cid)
	return PLUGIN_HANDLED
}

public hook_on(id,level,cid)
{
	if(!has_hook[id] && !get_pcvar_num(hook_enabled_cvar) && !cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if(hook[id])
	{
		return PLUGIN_HANDLED
	}
	set_user_gravity(id,0.0)
	set_task(0.1,"hook_prethink",id+10000,"",0,"b")
	hook[id]=true
	hook_to[id][0]=999999
	hook_prethink(id+10000)
	emit_sound(id,CHAN_VOICE,"weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	return PLUGIN_HANDLED
}

public hook_off(id)
{
	if(is_user_alive(id)) set_user_gravity(id)
	hook[id]=false
	return PLUGIN_HANDLED
}

public hook_prethink(id)
{
	id -= 10000
	if(!is_user_alive(id))
	{
		hook[id]=false
	}
	if(!hook[id])
	{
		remove_task(id+10000)
		return PLUGIN_HANDLED
	}

	//Get Id's origin
	static origin1[3]
	get_user_origin(id,origin1)

	if(hook_to[id][0]==999999)
	{
		static origin2[3]
		get_user_origin(id,origin2,3)
		hook_to[id][0]=origin2[0]
		hook_to[id][1]=origin2[1]
		hook_to[id][2]=origin2[2]
	}

	//Create blue beam
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)		//TE_BEAMENTPOINT
	write_short(id)		// start entity
	write_coord(hook_to[id][0])
	write_coord(hook_to[id][1])
	write_coord(hook_to[id][2])
	write_short(beamsprite)
	write_byte(1)		// framestart
	write_byte(1)		// framerate
	write_byte(2)		// life in 0.1's
	write_byte(5)		// width
	write_byte(0)		// noise
	write_byte(0)		// red
	write_byte(0)		// green
	write_byte(255)		// blue
	write_byte(200)		// brightness
	write_byte(0)		// speed
	message_end()

	//Calculate Velocity
	static Float:velocity[3]
	velocity[0] = (float(hook_to[id][0]) - float(origin1[0])) * 3.0
	velocity[1] = (float(hook_to[id][1]) - float(origin1[1])) * 3.0
	velocity[2] = (float(hook_to[id][2]) - float(origin1[2])) * 3.0

	static Float:y
	y = velocity[0]*velocity[0] + velocity[1]*velocity[1] + velocity[2]*velocity[2]

	static Float:x
	x = (get_pcvar_float(hook_speed_cvar) * 120.0) / floatsqroot(y)

	velocity[0] *= x
	velocity[1] *= x
	velocity[2] *= x

	set_velo(id,velocity)

	return PLUGIN_CONTINUE
}


/*****
 Rope
*****/

public rope_toggle(id,level,cid)
{
	if(rope[id]) rope_off(id)
	else rope_on(id,level,cid)
	return PLUGIN_HANDLED
}

public rope_on(id,level,cid)
{
	if(!has_rope[id] && !get_pcvar_num(rope_enabled_cvar) && !cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if(rope[id])
	{
		return PLUGIN_HANDLED
	}
	set_task(0.1,"rope_prethink",id+100000,"",0,"b")
	rope[id]=true
	rope_to[id][0]=999999
	rope_prethink(id+100000)
	emit_sound(id,CHAN_VOICE,"weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	return PLUGIN_HANDLED
}

public rope_off(id)
{
	rope[id]=false
	return PLUGIN_HANDLED
}

public rope_prethink(id)
{
	id -= 100000
	if(!is_user_alive(id))
	{
		rope[id]=false
	}
	if(!rope[id])
	{
		remove_task(id+100000)
		return PLUGIN_HANDLED
	}

	//Get Id's origin
	static origin1[3]
	get_user_origin(id,origin1)

	static Float:origin1_F[3]
	origin1_F[0] = float(origin1[0])
	origin1_F[1] = float(origin1[1])
	origin1_F[2] = float(origin1[2])

	//Check to see if this is the first time prethink is being run
	if(rope_to[id][0]==999999)
	{
		static origin2[3]
		get_user_origin(id,origin2,3)
		rope_to[id][0]=origin2[0]
		rope_to[id][1]=origin2[1]
		rope_to[id][2]=origin2[2]

		static Float:origin2_F[3]
		origin2_F[0] = float(origin2[0])
		origin2_F[1] = float(origin2[1])
		origin2_F[2] = float(origin2[2])

		static Float:distance[3]
		distance[0] = floatabs(origin1_F[0] - origin2_F[0])
		distance[1] = floatabs(origin1_F[1] - origin2_F[1])
		distance[2] = floatabs(origin1_F[2] - origin2_F[2])
		rope_totaldis[id] = floatsqroot(distance[0]*distance[0] + distance[1]*distance[1] + distance[2]*distance[2])
	}

	//Create green beam
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)		//TE_BEAMENTPOINT
	write_short(id)		// start entity
	write_coord(rope_to[id][0])
	write_coord(rope_to[id][1])
	write_coord(rope_to[id][2])
	write_short(beamsprite)
	write_byte(1)		// framestart
	write_byte(1)		// framerate
	write_byte(1)		// life in 0.1's
	write_byte(5)		// width
	write_byte(0)		// noise
	write_byte(0)		// red
	write_byte(255)		// green
	write_byte(0)		// blue
	write_byte(200)		// brightness
	write_byte(0)		// speed
	message_end()

	//Calculate Velocity
	static Float:velocity[3]
	get_velo(id,velocity)

	static Float:velocity2[3]
	velocity2[0] = (rope_to[id][0] - origin1_F[0]) * 3.0
	velocity2[1] = (rope_to[id][1] - origin1_F[1]) * 3.0

	static Float:y
	y = velocity2[0]*velocity2[0] + velocity2[1]*velocity2[1]

	static Float:x
	x = (get_pcvar_float(rope_speed_cvar) * 20.0) / floatsqroot(y)

	velocity[0] += velocity2[0]*x
	velocity[1] += velocity2[1]*x

	if(rope_to[id][2] - origin1_F[2] >= rope_totaldis[id] && velocity[2]<0.0) velocity[2] *= -1

	set_velo(id,velocity)

	return PLUGIN_CONTINUE
}

public get_origin(ent,Float:origin[3])
{
#if defined engine
	return entity_get_vector(id,EV_VEC_origin,origin)
#else
	return pev(ent,pev_origin,origin)
#endif
}

public set_velo(id,Float:velocity[3])
{
#if defined engine
	return set_user_velocity(id,velocity)
#else
	return set_pev(id,pev_velocity,velocity)
#endif
}

public get_velo(id,Float:velocity[3])
{
#if defined engine
	return get_user_velocity(id,velocity)
#else
	return pev(id,pev_velocity,velocity)
#endif
}

public is_valid_ent2(ent)
{
#if defined engine
	return is_valid_ent(ent)
#else
	return pev_valid(ent)
#endif
}

public get_solidity(ent)
{
#if defined engine
	return entity_get_int(ent,EV_INT_solid)
#else
	return pev(ent,pev_solid)
#endif
}

stock set_rendering2(index, fx=kRenderFxNone, r=255, g=255, b=255, render=kRenderNormal, amount=16)
{
#if defined engine
	return set_rendering(index,fx,r,g,b,render,amount)
#else
	set_pev(index, pev_renderfx, fx);
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);
	set_pev(index, pev_rendercolor, RenderColor);
	set_pev(index, pev_rendermode, render);
	set_pev(index, pev_renderamt, float(amount));
	return 1;
#endif
}
