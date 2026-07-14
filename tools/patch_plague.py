import re

with open(r"C:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Main Core Plugins\epic_zombie_core_new.sma", "r", encoding="utf-8") as f:
    text = f.read()

# 1. Global flag
text = text.replace(
    'new g_respawn_as_zombie[33]',
    'new bool:g_respawn_as_nemesis[33]\nnew g_respawn_as_zombie[33]'
)

# 2. Respawn checks
text = text.replace(
    'if (g_respawn_as_zombie[id] && !g_newround)',
    '''if (g_respawn_as_nemesis[id] && !g_newround)
	{
		reset_vars(id, 0) // reset player vars
		g_spawning_as_zombie[id] = true
		zombieme(id, 0, 1, 0, 0) // make him nemesis right away
		return;
	}
	
	if (g_respawn_as_zombie[id] && !g_newround)'''
)

text = text.replace(
    '''	if (g_respawn_as_zombie[id])
		fm_cs_set_user_team(id, FM_CS_TEAM_T)
	else
		fm_cs_set_user_team(id, FM_CS_TEAM_CT)''',
    '''	if (g_respawn_as_zombie[id] || g_respawn_as_nemesis[id])
		fm_cs_set_user_team(id, FM_CS_TEAM_T)
	else
		fm_cs_set_user_team(id, FM_CS_TEAM_CT)'''
)

text = text.replace(
    'g_respawn_as_zombie[id] = false',
    'g_respawn_as_zombie[id] = false\n\tg_respawn_as_nemesis[id] = false'
)

text = text.replace(
    '''	if (g_zombie[ID_SPAWN]) g_respawn_as_zombie[ID_SPAWN] = true
	else g_respawn_as_zombie[ID_SPAWN] = false''',
    '''	if (g_zombie[ID_SPAWN])
	{
		g_respawn_as_zombie[ID_SPAWN] = true
		if (g_nemesis[ID_SPAWN])
		{
			g_respawn_as_nemesis[ID_SPAWN] = true
			g_respawn_as_zombie[ID_SPAWN] = false
		}
	}
	else 
	{
		g_respawn_as_zombie[ID_SPAWN] = false
		g_respawn_as_nemesis[ID_SPAWN] = false
	}'''
)

new_block = '''	else if ((mode == MODE_NONE && (!get_pcvar_num(cvar_preventconsecutive) || g_lastmode != MODE_PLAGUE) && random_num(1, get_pcvar_num(cvar_plaguechance)) == get_pcvar_num(cvar_plague) && floatround(iPlayersnum*0.4, floatround_ceil) >= 1 && floatround(iPlayersnum*0.6, floatround_floor) >= 1 && iPlayersnum >= get_pcvar_num(cvar_plagueminplayers)) || mode == MODE_PLAGUE)
	{
		// Plague Mode
		g_plagueround = true
		g_lastmode = MODE_PLAGUE

		// 40% Zombies, 60% Survivors
		static iZombies, iMaxZombies
		static iSurvivors, iMaxSurvivors

		iMaxZombies = floatround(iPlayersnum * 0.40, floatround_ceil)
		iMaxSurvivors = floatround(iPlayersnum * 0.60, floatround_floor)
		
		// Fallback defaults
		if (iMaxZombies < 1) iMaxZombies = 1;
		if (iMaxSurvivors < 1) iMaxSurvivors = 1;

		iSurvivors = 0
		while (iSurvivors < iMaxSurvivors)
		{
			id = fnGetRandomAlive(random_num(1, iPlayersnum))
			
			if (g_survivor[id])
				continue;
				
			humanme(id, 1, 0)
			iSurvivors++
			
			fm_set_user_health(id, floatround(float(pev(id, pev_health)) * get_pcvar_float(cvar_plaguesurvhpmulti)))
		}

		// Remaining players become zombies
		for (id = 1; id <= g_maxplayers; id++)
		{
			if (!g_isalive[id] || g_survivor[id])
				continue;
				
			zombieme(id, 0, 0, 1, 0)
		}

		// Play plague sound'''

# We find the exact location line by line for the plague mode block
lines = text.split('\n')
start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if 'else if ((mode == MODE_NONE && (!get_pcvar_num(cvar_preventconsecutive)' in line and 'get_pcvar_num(cvar_plaguechance)' in line:
        # verify it's the plague mode block, containing MODE_PLAGUE
        if 'MODE_PLAGUE' in line or 'MODE_PLAGUE' in lines[i+1]:
            start_idx = i
            break

if start_idx != -1:
    for j in range(start_idx, len(lines)):
        if '// Play plague sound' in lines[j]:
            end_idx = j
            break

if start_idx != -1 and end_idx != -1:
    lines[start_idx:end_idx+1] = new_block.split('\n')
    text = '\n'.join(lines)
    print("Plague block replaced successfully.")
else:
    print("Could not find Plague Mode boundaries")
    print(f"start: {start_idx}, end: {end_idx}")

# 4. Plague Respawn handling in fw_PlayerKilled_Post
kill_pattern_spot = '''	// Always respawn players who joined mid-round'''
kill_respawn_plague = '''	if (g_plagueround && g_zombie[victim] && attacker != victim && is_user_valid_alive(attacker) && !g_zombie[attacker])
	{
		g_respawn_as_nemesis[victim] = (random_num(1, 100) <= 50) ? true : false;
		g_respawn_as_zombie[victim] = !g_respawn_as_nemesis[victim];
		set_task(get_pcvar_float(cvar_spawndelay), "respawn_player_task", victim+TASK_SPAWN);
	}

	// Always respawn players who joined mid-round'''

text = text.replace(kill_pattern_spot, kill_respawn_plague)

with open(r"C:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Main Core Plugins\epic_zombie_core_new.sma", "w", encoding="utf-8") as f:
    f.write(text)

print("Patcher script finished")
