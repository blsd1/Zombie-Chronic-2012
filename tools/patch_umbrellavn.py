import re

path = r'c:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Main Core Plugins\epic_zombie_core_new.sma'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

def repl(old, new):
    global text
    if old not in text:
        print(f'Cannot find: {old[:50]}...')
    text = text.replace(old, new)


repl('ACCESS_MODE_PLAGUE,', 'ACCESS_MODE_PLAGUE,\n\tACCESS_MODE_UMBRELLAVN,')
repl('MODE_PLAGUE\n}', 'MODE_PLAGUE,\n\tMODE_UMBRELLAVN\n}')
repl('ACTION_MODE_PLAGUE,', 'ACTION_MODE_PLAGUE,\n\tACTION_MODE_UMBRELLAVN,')
repl('new g_plagueround // plague round', 'new g_plagueround // plague round\nnew g_umbrellavnround // umbrella vs nemesis round')
repl('cvar_allowrespawnplague,', 'cvar_allowrespawnplague, cvar_umbrellavn, cvar_umbrellavnchance, cvar_umbrellavnminplayers, cvar_allowrespawnumbrellavn,')

repl('cvar_plagueminplayers = register_cvar(" zp_plague_min_players\, \0\)',
'''cvar_plagueminplayers = register_cvar(\zp_plague_min_players\, \0\)
\tcvar_umbrellavn = register_cvar(\zp_umbrellavn\, \1\)
\tcvar_umbrellavnchance = register_cvar(\zp_umbrellavn_chance\, \20\)
\tcvar_umbrellavnminplayers = register_cvar(\zp_umbrellavn_min_players\, \0\)
\tcvar_allowrespawnumbrellavn = register_cvar(\zp_deathmatch_respawn_umbrellavn\, \1\)''')

repl('else if (equal(key, \START MODE PLAGUE\))\\n\\t\\t\\t\\t\\t\\tg_access_flag[ACCESS_MODE_PLAGUE] = read_flags(value)',
'''else if (equal(key, \START MODE PLAGUE\))\\n\\t\\t\\t\\t\\t\\tg_access_flag[ACCESS_MODE_PLAGUE] = read_flags(value)
\\t\\t\\t\\t\\telse if (equal(key, \START MODE UMBRELLAVN\))
\\t\\t\\t\\t\\t\\tg_access_flag[ACCESS_MODE_UMBRELLAVN] = read_flags(value)''')

repl('if (g_survround || g_nemround || g_swarmround || g_plagueround || fnGetHumans() == 1)', 'if (g_survround || g_nemround || g_swarmround || g_plagueround || g_umbrellavnround || fnGetHumans() == 1)')
repl('g_endround || g_swarmround || g_nemround || g_survround || g_plagueround || fnGetZombies() <= 1 ', 'g_endround || g_swarmround || g_nemround || g_survround || g_plagueround || g_umbrellavnround || fnGetZombies() <= 1 ')
repl('g_endround || g_swarmround || g_nemround || g_survround || g_plagueround || fnGetHumans() == 1', 'g_endround || g_swarmround || g_nemround || g_survround || g_plagueround || g_umbrellavnround || fnGetHumans() == 1')
repl('if (g_endround || g_swarmround || g_nemround || g_survround || g_plagueround)', 'if (g_endround || g_swarmround || g_nemround || g_survround || g_plagueround || g_umbrellavnround)')

repl('g_plagueround = false', 'g_plagueround = false\\n\\tg_umbrellavnround = false')


repl('g_survround, g_nemround, g_swarmround, g_plagueround,', 'g_survround, g_nemround, g_swarmround, g_plagueround, g_umbrellavnround,')

repl('if (g_respawn_as_nemesis[ID_SPAWN] || g_respawn_as_zombie[ID_SPAWN] || ((!g_survround || get_pcvar_num(cvar_allowrespawnsurv)) && (!g_swarmround || get_pcvar_num(cvar_allowrespawnswarm)) && (!g_nemround || get_pcvar_num(cvar_allowrespawnnem)) && (!g_plagueround || get_pcvar_num(cvar_allowrespawnplague))))',
'if (g_respawn_as_nemesis[ID_SPAWN] || g_respawn_as_zombie[ID_SPAWN] || ((!g_survround || get_pcvar_num(cvar_allowrespawnsurv)) && (!g_swarmround || get_pcvar_num(cvar_allowrespawnswarm)) && (!g_nemround || get_pcvar_num(cvar_allowrespawnnem)) && (!g_plagueround || get_pcvar_num(cvar_allowrespawnplague)) && (!g_umbrellavnround || get_pcvar_num(cvar_allowrespawnumbrellavn))))')

repl('!g_survround && !g_nemround && !g_swarmround && !g_plagueround)', '!g_survround && !g_nemround && !g_swarmround && !g_plagueround && !g_umbrellavnround)')

repl('if (g_plagueround || g_nemround || g_survround || g_swarmround || g_endround)', 'if (g_plagueround || g_nemround || g_survround || g_swarmround || g_umbrellavnround || g_endround)')

with open(path, 'w', encoding='utf-8') as f:
 f.write(text)

print('Done applying basic var patches!')
