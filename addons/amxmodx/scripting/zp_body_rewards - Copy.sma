#include <amxmodx>
#include <amxmisc>
#include <zombieplague>

#define PLUGIN "ZP Body Rewards"
#define VERSION "1.0"
#define AUTHOR "ketamine"

// Globalne premenne - presne ako ammopacks
new g_body[33] // body count pre kazdeho hraca

// CVAR pointery pre nastavenie odmien
new cvar_body_infect, cvar_body_kill, cvar_body_limit

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    // Zaregistrujeme cvary s defaultnymi hodnotami
    cvar_body_infect = register_cvar("zp_body_infect", "60")      // body za nakazenie/zabite humana
    cvar_body_kill = register_cvar("zp_body_kill", "50")         // body za zabite zombika  
    cvar_body_limit = register_cvar("zp_body_limit", "400")      // max limit bodov
    
    // Eventy pre zachytenie smrti hracov
    register_event("DeathMsg", "event_death", "a")
    
    // Admin prikazy
    register_concmd("amx_setbody", "cmd_set_body", ADMIN_KICK, "<nick> <amount>")
    register_concmd("amx_addbody", "cmd_add_body", ADMIN_KICK, "<nick> <amount>")
    
    register_cvar("zp_body_rewards_version", VERSION, FCVAR_SERVER)
}

// Native funkcie pre ine pluginy (ako ammopacks)
public plugin_natives()
{
    register_native("zp_get_user_body", "native_get_user_body", 1)
    register_native("zp_set_user_body", "native_set_user_body", 1)
}

// Reset bodov pri pripojeni
public client_connect(id)
{
    g_body[id] = 0
}

// Reset bodov pri odpojeni
public client_disconnected(id)
{
    g_body[id] = 0
}

// Death event - presne ako v zombie_plague40_new.sma pre ammopacks
public event_death()
{
    new killer = read_data(1)
    new victim = read_data(2)
    
    if (!is_user_connected(killer) || !is_user_connected(victim) || killer == victim)
        return
        
    // Ak human zabije zombika - dostane body (presne ako pre ammopacks damage)
    if (!zp_get_user_zombie(killer) && zp_get_user_zombie(victim))
    {
        new reward = get_pcvar_num(cvar_body_kill)
        add_body(killer, reward)
    }
    // Ak zombie zabije/nakazi humana - dostane body (presne ako v zombie_plague40_new.sma line 2431)
    else if (zp_get_user_zombie(killer) && !zp_get_user_zombie(victim))
    {
        new reward = get_pcvar_num(cvar_body_infect)
        add_body(killer, reward)
    }
}

// Prida body s kontrolou limitu (ako ammopacks)
stock add_body(id, amount)
{
    if (!is_user_connected(id) || amount <= 0)
        return
        
    // EVIP+ (admin level H) ma limit 500, ostatni podla cvaru
    new limit = (get_user_flags(id) & ADMIN_LEVEL_H) ? 500 : get_pcvar_num(cvar_body_limit)
    g_body[id] += amount
    
    // Kontrola limitu
    if (g_body[id] > limit)
        g_body[id] = limit
}

// Nastavi body s kontrolou limitu
stock set_body(id, amount)
{
    if (!is_user_connected(id))
        return
        
    // EVIP+ (admin level H) ma limit 500, ostatni podla cvaru
    new limit = (get_user_flags(id) & ADMIN_LEVEL_H) ? 500 : get_pcvar_num(cvar_body_limit)
    g_body[id] = amount
    
    if (g_body[id] > limit)
        g_body[id] = limit
    else if (g_body[id] < 0)
        g_body[id] = 0
}

// Vrati pocet bodov hraca
stock get_body(id)
{
    if (!is_user_connected(id))
        return 0
        
    return g_body[id]
}

// Admin prikazy
public cmd_set_body(id, level, cid)
{
    if (!cmd_access(id, level, cid, 3))
        return PLUGIN_HANDLED
        
    new arg1[32], arg2[16]
    read_argv(1, arg1, charsmax(arg1))
    read_argv(2, arg2, charsmax(arg2))
    
    new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)
    if (!target)
        return PLUGIN_HANDLED
        
    new amount = str_to_num(arg2)
    set_body(target, amount)
    
    new admin_name[32], target_name[32]
    get_user_name(id, admin_name, charsmax(admin_name))
    get_user_name(target, target_name, charsmax(target_name))
    
    console_print(id, "[ZP Body] Nastavil si %s na %d bodov", target_name, amount)
    client_print(target, print_chat, "[ZP Body] Admin %s ti nastavil %d bodov", admin_name, amount)
    
    return PLUGIN_HANDLED
}

public cmd_add_body(id, level, cid)
{
    if (!cmd_access(id, level, cid, 3))
        return PLUGIN_HANDLED
        
    new arg1[32], arg2[16]
    read_argv(1, arg1, charsmax(arg1))
    read_argv(2, arg2, charsmax(arg2))
    
    new target = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)
    if (!target)
        return PLUGIN_HANDLED
        
    new amount = str_to_num(arg2)
    add_body(target, amount)
    
    new admin_name[32], target_name[32]
    get_user_name(id, admin_name, charsmax(admin_name))
    get_user_name(target, target_name, charsmax(target_name))
    
    console_print(id, "[ZP Body] Pridal si %s %d bodov (celkom: %d)", target_name, amount, g_body[target])
    client_print(target, print_chat, "[ZP Body] Admin %s ti pridal %d bodov (celkom: %d)", admin_name, amount, g_body[target])
    
    return PLUGIN_HANDLED
}

// Native funkcie pre ine pluginy (ako zp_get_user_ammo_packs a zp_set_user_ammo_packs)
public native_get_user_body(plugin, params)
{
    new id = get_param(1)
    return get_body(id)
}

public native_set_user_body(plugin, params)
{
    new id = get_param(1)
    new amount = get_param(2)
    set_body(id, amount)
    return g_body[id]
}
