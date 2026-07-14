import re

with open(r"C:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Sub Plugins\Human Plugins\Extra Items\zp_extra_item_antidote_fixed.sma", "r", encoding="utf-8") as f:
    text = f.read()

# Add native and globals
text = text.replace(
    'new item_id',
    'native zp_reset_infbomb_limit()\n\nnew g_global_antidote_buys = 0\nnew g_global_antidote_throws = 0\nnew item_id'
)

# Add event_round_start to init
text = text.replace(
    'register_forward(FM_SetModel, "fw_SetModel")',
    'register_forward(FM_SetModel, "fw_SetModel")\n\tregister_event("HLTV", "event_round_start", "a", "1=0", "2=0")'
)

# Add event_round_start function
text = text.replace(
    'public plugin_precache()',
    'public event_round_start()\n{\n\tg_global_antidote_buys = 0\n\tg_global_antidote_throws = 0\n}\n\npublic plugin_precache()'
)

# Modify the purchase check
text = text.replace(
    'if(itemid == item_id)\n        {',
    '''if(itemid == item_id)
        {
                if (zp_get_zombie_count() < 6)
                {
                        client_print(player, print_chat, "[ZP] Na jeho zakupenie je potrebnych aspon 6 zombie!")
                        return ZP_PLUGIN_HANDLED
                }
                
                if (zp_get_human_count() > 1 && g_global_antidote_buys >= 2)
                {
                        client_print(player, print_chat, "[ZP] Za jedno kolo je mozne zakupit maximalne 2 tieto granaty! (Server limit)")
                        return ZP_PLUGIN_HANDLED
                }
                
                g_global_antidote_buys++
                '''
)

# Modify explode count logic
text = text.replace(
    'has_bomb[attacker] = 0',
    'has_bomb[attacker] = 0\n\n\tg_global_antidote_throws++\n\tnew revived_count = 0\n'
)

# Add revived_count inside the loop
# We replace zp_disinfect_user(victim) with and add a generic loop modification
text = text.replace(
    'zp_disinfect_user(victim)',
    'zp_disinfect_user(victim)\n\t\trevived_count++\n'
)

# After the loop
text = text.replace(
    'engfunc(EngFunc_RemoveEntity, ent)',
    '''if (revived_count > 0 && g_global_antidote_throws >= 2)
        {
                zp_reset_infbomb_limit()
                
                for (new i = 1; i <= get_maxplayers(); i++)
                {
                        if (is_user_connected(i) && zp_get_user_zombie(i))
                        {
                                client_print(i, print_chat, "[ZP] Infection bomb aktivna")
                        }
                }
        }

        engfunc(EngFunc_RemoveEntity, ent)'''
)

with open(r"C:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Sub Plugins\Human Plugins\Extra Items\zp_extra_item_antidote_fixed.sma", "w", encoding="utf-8") as f:
    f.write(text)

print("Patched!")
