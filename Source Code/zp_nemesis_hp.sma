#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN_NAME "Show Nemesis Hp!"
#define PLUGIN_VERS "1.0"
#define PLUGIN_AUTH "Dare-Devil"

new id_nemesis
new hud_nsp
new g_maxplayers

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH)

    // Fwd's
    RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn_Post", 1)
    RegisterHam(Ham_Killed, "player", "Fwd_PlayerKilled_Pre", 0)
    register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

    g_maxplayers = get_maxplayers()
}

public event_round_start()
{
	hud_nsp = 0
}

public Fwd_PlayerSpawn_Post(id)
{
	if (id_nemesis != 0 && id == id_nemesis)
	{
		hud_nsp = 0
		id_nemesis = 0
	}
}

public Fwd_PlayerKilled_Pre(victim, attacker, shouldgib)
{
	if (id_nemesis != 0 && victim == id_nemesis)
	{
		hud_nsp = 0
		id_nemesis = 0
	}
}

public client_disconnect(id)
{
	if (id_nemesis != 0 && id == id_nemesis)
	{
		hud_nsp = 0
		id_nemesis = 0
		check_again_nsp()
	}
}

public zp_round_started(mode, id)
{
	// Nemesis exists in both Nemesis and Plague rounds - show only its HP
	if (mode == MODE_NEMESIS || mode == MODE_PLAGUE)
	{
		hud_nsp = 1
		check_status_event_nsp()
		set_task(1.0, "hud_nsp_notice")
		return
	}
}

public check_again_nsp()
{
	if (zp_is_nemesis_round() || zp_is_plague_round())
	{
		hud_nsp = 0
		check_status_event_nsp()
		set_task(1.0, "hud_nsp_notice")
		hud_nsp = 1
	}
}

public check_status_event_nsp()
{
	if (ZPGetNemesis() == 1)
		id_nemesis = ZPGetRandomNemesis(1)
}

public zp_round_ended()
{
	hud_nsp = 0
}

public hud_nsp_notice()
{
	if (zp_is_nemesis_round() || zp_is_plague_round())
	{
		if (hud_nsp == 1 && id_nemesis != 0 && is_user_alive(id_nemesis))
		{
			set_hudmessage(237, 28, 36, -1.0, 0.03, 0, 1.0, 1.0, 0.1, 0.2, -1)
			show_hudmessage(0, "NEMESIS HP: %d", get_user_health(id_nemesis))
		}
	}
	else // Bug fix
	{
		hud_nsp = 0
	}

	// Make it call every time when hudnsp is on
	if (hud_nsp == 1)
		set_task(1.0, "hud_nsp_notice")
}


// Now get id or value (bug fix)
ZPGetNemesis()
{
	new iNemesis = 0

	for (new id = 1; id <= g_maxplayers; id++)
	{
		if (is_user_alive(id) && zp_get_user_nemesis(id))
			iNemesis++
	}

	return iNemesis;
}

ZPGetRandomNemesis(n)
{
	new iAlive = 0

	for (new id = 1; id <= g_maxplayers; id++)
	{
		if (is_user_alive(id) && zp_get_user_nemesis(id))
			iAlive++

		if (iAlive == n)
			return id;
	}

	return -1;
}
