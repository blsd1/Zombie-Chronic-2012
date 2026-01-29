#include <amxmodx>
#include <fun>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "Kill Green Fade"
#define VERSION "1.0"
#define AUTHOR "AMXX Community"

#define IsPlayer(%1)    ( 1 <= %1 <= g_iMaxPlayers )

new g_iMaxPlayers, msgScreenFade, amx_kill_fade_amount, amx_kill_health

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    amx_kill_fade_amount = register_cvar("amx_kill_fade_amount", "75")
    amx_kill_health = register_cvar("amx_kill_health", "0")
    
    register_event("DeathMsg", "death_event", "a", "1>0")
    
    msgScreenFade = get_user_msgid("ScreenFade")
    g_iMaxPlayers = get_maxplayers()
}

public death_event()
{
    new iKiller = read_data(1)

    if(IsPlayer(iKiller) && is_user_alive(iKiller))
    {
        screenfade(iKiller, get_pcvar_num(amx_kill_fade_amount))
        set_user_health(iKiller, get_user_health(iKiller) + get_pcvar_num(amx_kill_health))

    }
}



stock screenfade(id, ammount)
{    
    //FADE OUT FROM GREEN
    if (ammount > 255)
    ammount = 255
    
    message_begin(MSG_ONE_UNRELIABLE, msgScreenFade, {0,0,0}, id)
    write_short(ammount * 100)    //Durration
    write_short(0)        //Hold
    write_short(0)        //Type
    write_byte(255)    //R
    write_byte(255)    //G
    write_byte(255)    //B
    write_byte(ammount)    //B
    message_end()
} 