#define DAMAGE_RECIEVED
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>

new maxplayers
new health_add
new nKiller
new nKiller_hp
new nHp_add
#define Keysrod (1<<0)|(1<<1)|(1<<9) // Keys: 1234567890

public plugin_init()
{
	register_plugin("kill_healed", "1.0", "Dev!l")
	health_add = register_cvar("hp", "20")
	maxplayers = get_maxplayers()
	register_event("DeathMsg", "hook_death", "a", "1>0")	
}
public hook_death()
{
   // Killer id
   nKiller = read_data(1)
   
   if ( (read_data(3) == 1) && (read_data(5) == 0) )
   {
   }
   else
      nHp_add = get_pcvar_num (health_add)
   // Updating Killer HP
   if(!(get_user_flags(nKiller) & ADMIN_LEVEL_H))
   return;

   nKiller_hp = get_user_health(nKiller)
   nKiller_hp += nHp_add
   set_user_health(nKiller, nKiller_hp)
   // Hud message "Healed +15/+30 hp"
   set_hudmessage(255, 255, 0, -1.0, 0.15, 0, 1.0, 1.0, 0.1, 0.1, -1)
   show_hudmessage(nKiller, "Healed +%d hp", nHp_add)
   // Screen fading
   message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, nKiller)
   write_short(1<<10)
   write_short(1<<10)
   write_short(0x0000)
   write_byte(255)
   write_byte(255)
   write_byte(255)
   write_byte(75)
   message_end()
 
}


