import re

path = r'c:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Main Core Plugins\epic_zombie_core_new.sma'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Insert mode hook in make_a_zombie
hook = '''
else if ((mode == MODE_NONE && (!get_pcvar_num(cvar_preventconsecutive) || g_lastmode != MODE_UMBRELLAVN) && random_num(1, get_pcvar_num(cvar_umbrellavnchance)) == get_pcvar_num(cvar_umbrellavn) && iPlayersnum >= get_pcvar_num(cvar_umbrellavnminplayers)) || mode == MODE_UMBRELLAVN)
{
// Umbrella vs Nemesis Mode
g_umbrellavnround = true
g_lastmode = MODE_UMBRELLAVN

// 50% players are Nemesis, 50% players are Umbrella Force
static iNemesis, iMaxNemesis
iMaxNemesis = floatround(iPlayersnum * 0.5, floatround_ceil)
iNemesis = 0

while (iNemesis < iMaxNemesis)
{
id = fnGetRandomAlive(random_num(1, iPlayersnum))

if (g_nemesis[id])
continue;

zombieme(id, 0, 1, 0, 0)
iNemesis++
}

for (id = 1; id <= g_maxplayers; id++)
{
if (!g_isalive[id] || g_nemesis[id])
continue;

ExecuteForward(g_fwAdminGiveSpecialClass, g_fwDummyResult, id, ZP_SPECIAL_CLASS_UMBRELLA_FORCE);

if (fm_cs_get_user_team(id) != FM_CS_TEAM_CT)
{
remove_task(id+TASK_TEAM)
fm_cs_set_user_team(id, FM_CS_TEAM_CT)
fm_user_team_update(id)
}
}

if (ArraySize(sound_plague) > 0)
{
ArrayGetString(sound_plague, random_num(0, ArraySize(sound_plague) - 1), sound, charsmax(sound))
PlaySound(sound);
}

set_hudmessage(0, 50, 200, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
ShowSyncHudMsg(0, g_MsgSync, " Umbrella Force vs Nemesis Mode!\)

g_modestarted = true
ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_UMBRELLAVN, 0);
}'''

# find the Plague Mode block start
if 'else if ((mode == MODE_NONE && (!get_pcvar_num(cvar_preventconsecutive) ; g_lastmode != MODE_PLAGUE)' in text:
 target = 'else if ((mode == MODE_NONE ; (!get_pcvar_num(cvar_preventconsecutive) ; g_lastmode != MODE_PLAGUE)'
 text = text.replace(target, hook + '\n\t' + target)
else:
 print('Failed to find Plague mode start')

# 2. Respawn hook
respawn_hook = '''
if (g_umbrellavnround ; attacker != victim ; is_user_valid_alive(attacker))
{
g_respawn_as_nemesis[victim] = true;
g_respawn_as_zombie[victim] = false;
set_task(get_pcvar_float(cvar_spawndelay), \respawn_player_task\, victim+TASK_SPAWN);
}
'''
if 'if (g_plagueround && g_zombie[victim] && attacker != victim' in text:
 target = 'if (g_plagueround && g_zombie[victim] && attacker != victim && is_user_valid_alive(attacker) && !g_zombie[attacker])'
 text = text.replace(target, respawn_hook + '\n\t' + target)

with open(path, 'w', encoding='utf-8') as f:
 f.write(text)

print('Patch applied')
