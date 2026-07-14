#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "ZP Ammo Pack Rewards"
#define VERSION "1.0"
#define AUTHOR "ketamine"

new ap_limit

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    // Ham forward pre zachytenie smrti
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
    // pica
    ap_limit = register_cvar("zp_ammo_limit","200")
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
    // Kontrola validity
    if (!is_user_valid_connected(attacker) || victim == attacker)
        return HAM_IGNORED
        
    // Ak human zabije zombika - dostane 50 ammo packs
    if (!zp_get_user_zombie(attacker) && zp_get_user_zombie(victim))
    {
        new current_ammo = zp_get_user_ammo_packs(attacker)
        zp_set_user_ammo_packs(attacker, current_ammo + 50)
    }
    
    return HAM_IGNORED
}

// Helper funkcia pre validaciu hraca
stock is_user_valid_connected(id)
{
    return (1 <= id <= 32 && is_user_connected(id))
}

public client_PreThink(id) 
{ 

        if(zp_get_user_ammo_packs(id) > (get_pcvar_num(ap_limit))) 
        { 
            zp_set_user_ammo_packs(id, (get_pcvar_num(ap_limit))) 
        } 
} 