#include <amxmodx>
#include <amxmisc>

new g_cvar_enabled
new g_cvar_message
new g_cvar_pos_x
new g_cvar_pos_y
new g_cvar_color_r
new g_cvar_color_g
new g_cvar_color_b
new g_cvar_holdtime
new g_cvar_channel
new g_cvar_update_interval

public plugin_init()
{
	register_plugin("Custom HUD Message", "1.0", "GitHub Copilot")
	
	g_cvar_enabled = register_cvar("hud_custom_enabled", "1")
	g_cvar_message = register_cvar("hud_custom_message", "Welcome to the Server!")
	g_cvar_pos_x = register_cvar("hud_custom_x", "-1.0")
	g_cvar_pos_y = register_cvar("hud_custom_y", "0.3")
	g_cvar_color_r = register_cvar("hud_custom_r", "0")
	g_cvar_color_g = register_cvar("hud_custom_g", "255")
	g_cvar_color_b = register_cvar("hud_custom_b", "0")
	g_cvar_holdtime = register_cvar("hud_custom_holdtime", "2.0")
	g_cvar_channel = register_cvar("hud_custom_channel", "1")
	g_cvar_update_interval = register_cvar("hud_custom_interval", "3.0")
	
	set_task(1.0, "task_show_hud", 0, _, _, "b")
}

public task_show_hud()
{
	if(!get_pcvar_num(g_cvar_enabled))
		return
	
	new szMessage[256]
	get_pcvar_string(g_cvar_message, szMessage, charsmax(szMessage))
	
	if(szMessage[0] == 0)
		return
	
	new Float:fPosX = get_pcvar_float(g_cvar_pos_x)
	new Float:fPosY = get_pcvar_float(g_cvar_pos_y)
	new iColorR = get_pcvar_num(g_cvar_color_r)
	new iColorG = get_pcvar_num(g_cvar_color_g)
	new iColorB = get_pcvar_num(g_cvar_color_b)
	new Float:fHoldTime = get_pcvar_float(g_cvar_holdtime)
	new iChannel = get_pcvar_num(g_cvar_channel)
	
	set_hudmessage(iColorR, iColorG, iColorB, fPosX, fPosY, 0, 0.0, fHoldTime, 0.1, 0.1, iChannel)
	show_hudmessage(0, "%s", szMessage)
}
