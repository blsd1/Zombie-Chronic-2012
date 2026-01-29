#include <amxmodx>
#include <amxmisc>

#define PLUGIN "VIP Permanent message"
#define VERSION "1.0"
#define AUTHOR "EFFx"

#define EVIP ADMIN_LEVEL_G
#define VIP ADMIN_LEVEL_H

new Huds[2]
new VarDeathHud

public plugin_init() 
{
   register_plugin(PLUGIN, VERSION, AUTHOR)
   
   VarDeathHud = register_cvar("permament_message","1")
   
   register_event("DeathMsg", "fadedead", "a")
   
   Huds[0] = CreateHudSyncObj()
   Huds[1] = CreateHudSyncObj()
}
public fadedead()
{
   if(!get_pcvar_num(VarDeathHud))
      return PLUGIN_HANDLED
      
   new iMorto = read_data(2)
   
   if(!is_user_alive(iMorto))
   {         
      if(get_user_flags(iMorto) & EVIP)
      {
         return PLUGIN_HANDLED
      }
      else if(get_user_flags(iMorto) & ADMIN_IMMUNITY)
      {
         return PLUGIN_HANDLED
      }
   }
   
   return PLUGIN_HANDLED
}