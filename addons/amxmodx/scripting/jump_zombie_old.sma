/*================================================================================
	
	*********************************************
	******** [Jump Zombie Class] ***************
	*********************************************
	
	Zombie class with special jump ability
	- HP: 2000
	- Gravity: 0.9
	- Special Ability: Press G for super jump (0.2 gravity for 10 seconds)
	- Cooldown: 20 seconds
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

/*================================================================================
 [Plugin Info]
================================================================================*/

#define PLUGIN "Jump Zombie Class"
#define VERSION "1.0"
#define AUTHOR "ketamine"

/*================================================================================
 [Zombie Class Settings]
================================================================================*/

#define JUMP_ZOMBIE_HEALTH 2000
#define JUMP_ZOMBIE_GRAVITY 0.9
#define SUPER_JUMP_GRAVITY 0.2
#define SUPER_JUMP_DURATION 10.0
#define ABILITY_COOLDOWN 20.0

// Jump Zombie Models - customize these paths
#define JUMP_ZOMBIE_PLAYERMODEL "jump_zombie"                    // Player model name (without .mdl)
#define JUMP_ZOMBIE_CLAWMODEL "models/ch_2012/jump_zombie_claw.mdl"     // Claw/knife model path

// Jump Zombie Sounds
#define SOUND_ABILITY_START "ch_2012/jump_start.wav"             // Sound when ability starts
#define SOUND_ABILITY_END "ch_2012/jump_inf1.wav"               // Sound when ability ends
#define SOUND_SPAWN "ch_2012/jump_inf1.wav"                     // Sound on spawn
#define SOUND_IDLE "ch_2012/jump_idle.wav"                      // Idle sound every 2 seconds

/*================================================================================
 [Model Customization Instructions]
================================================================================*/

/*
 * PLAYERMODEL: Change "zombie_source" to any model name you want
 * - Examples: "zombie_plague", "my_custom_zombie", etc.
 * - Model files should be in: cstrike/models/player/modelname/
 * 
 * CLAWMODEL: Change "v_knife_zombie.mdl" to any knife/claw model
 * - Examples: "v_knife_custom.mdl", "models/my_claws.mdl", etc.
 * - Model file should be in: cstrike/models/ folder
 * 
 * After changing, recompile the plugin and restart the server!
 */

/*================================================================================
 [Global Variables]
================================================================================*/

new g_zclass_jump_zombie
new bool:g_ability_active[33]
new Float:g_ability_cooldown[33]
new g_msgScreenFade, g_msgScreenShake, g_msg_sync

/*================================================================================
 [Plugin Init]
================================================================================*/

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Register key binding for ability - G key (drop command)
	register_clcmd("drop", "cmd_ability")
	
	// Hook weapon deploy to set custom claw model
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_knife_deploy_post", 1)
	
	// Get message IDs
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msg_sync = CreateHudSyncObj()
}

public plugin_precache()
{
	// Precache models
	precache_model(JUMP_ZOMBIE_CLAWMODEL)
	
	// Precache sounds
	precache_sound(SOUND_ABILITY_START)
	precache_sound(SOUND_ABILITY_END)  
	precache_sound(SOUND_SPAWN)
	precache_sound(SOUND_IDLE)
	
	// Register zombie class with custom models
	g_zclass_jump_zombie = zp_register_zombie_class("Jump Zombie", "gravity", JUMP_ZOMBIE_PLAYERMODEL, JUMP_ZOMBIE_CLAWMODEL, JUMP_ZOMBIE_HEALTH, 250, JUMP_ZOMBIE_GRAVITY, 1.0)
}

/*================================================================================
 [HAM Forwards]
================================================================================*/

public fw_knife_deploy_post(weapon_ent)
{
	new id = get_pdata_cbase(weapon_ent, 41, 4)
	
	// Check if player is alive, has jump zombie class and is NOT nemesis
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_jump_zombie || zp_get_user_nemesis(id))
		return HAM_IGNORED
		
	// Force set the custom claw model
	set_pev(id, pev_viewmodel2, JUMP_ZOMBIE_CLAWMODEL)
	set_pev(id, pev_weaponmodel2, "")
	
	return HAM_IGNORED
}

/*================================================================================
 [ZP Class Events]
================================================================================*/

public zp_user_infected_post(id, infector)
{
	if (!is_user_alive(id))
		return
		
	// Check if player has jump zombie class and is NOT nemesis
	if (zp_get_user_zombie_class(id) == g_zclass_jump_zombie && !zp_get_user_nemesis(id))
	{
		// Reset ability state
		g_ability_active[id] = false
		g_ability_cooldown[id] = 0.0
		
		// Set zombie attributes (ZP handles models automatically)
		set_user_health(id, JUMP_ZOMBIE_HEALTH)
		set_user_gravity(id, JUMP_ZOMBIE_GRAVITY)
		
		// Play spawn sound with 1 second delay
		set_task(1.0, "play_spawn_sound", id)
		
		// Start idle sound loop with 2 second delay
		set_task(2.0, "play_idle_sound", id + 2000, _, _, "b")
		
		// Show class info in chat
		client_print_color(id, print_chat, "^x04[Jump Zombie]^x01 Stlač G pre super skok!")
	}
}

public zp_user_humanized_post(id)
{
	// Remove tasks and reset state
	remove_task(id)
	remove_task(id + 1000)
	remove_task(id + 2000) // Remove idle sound task
	g_ability_active[id] = false
	g_ability_cooldown[id] = 0.0
	set_user_gravity(id, 1.0)
}

public play_spawn_sound(id)
{
	// Check if player is still alive and has jump zombie class
	if (is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_jump_zombie)
	{
		emit_sound(id, CHAN_VOICE, SOUND_SPAWN, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

/*================================================================================
 [Ability Command]
================================================================================*/

public cmd_ability(id)
{
	// Check if player is alive and zombie but NOT nemesis
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id))
		return PLUGIN_CONTINUE
		
	// Check if player has jump zombie class
	if (zp_get_user_zombie_class(id) != g_zclass_jump_zombie)
		return PLUGIN_CONTINUE
	
	// Check if ability is on cooldown
	new Float:current_time = get_gametime()
	if (g_ability_cooldown[id] > current_time)
	{
		return PLUGIN_HANDLED // Just ignore the keypress, don't show anything
	}
	
	// Check if ability is already active
	if (g_ability_active[id])
	{
		client_print_color(id, print_chat, "^x03[Jump Zombie]^x01 Schopnosť je už aktívna!")
		return PLUGIN_HANDLED
	}
	
	// Activate super jump
	activate_super_jump(id)
	
	return PLUGIN_HANDLED
}

/*================================================================================
 [Super Jump Functions]
================================================================================*/

activate_super_jump(id)
{
	// Set ability as active
	g_ability_active[id] = true
	
	// Set super jump gravity
	set_user_gravity(id, SUPER_JUMP_GRAVITY)
	
	// Play ability start sound
	emit_sound(id, CHAN_VOICE, SOUND_ABILITY_START, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Visual and audio effects
	set_user_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 20)
	
	// Chat message with colors
	client_print(id, print_chat, "^x03[Jump Zombie]^x01 - ^x04Aktivoval si svoju schopnosť!")
	
	// Screen shake effect
	message_begin(MSG_ONE, g_msgScreenShake, _, id)
	write_short(1<<12) // amplitude
	write_short(1<<10) // duration
	write_short(1<<12) // frequency
	message_end()
	
	// Orange screen fade for 3 seconds
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short(1<<12) // duration (3 seconds)
	write_short(1<<10) // hold time
	write_short(0x0000) // fade type (fade in)
	write_byte(255) // red
	write_byte(165) // green (orange color)
	write_byte(0) // blue
	write_byte(100) // alpha
	message_end()
	
	// Set task to deactivate ability
	set_task(SUPER_JUMP_DURATION, "deactivate_super_jump", id + 1000)
	
	// Set cooldown
	g_ability_cooldown[id] = get_gametime() + ABILITY_COOLDOWN
}

public deactivate_super_jump(taskid)
{
	new id = taskid - 1000
	
	if (!is_user_connected(id))
		return
	
	// Deactivate ability
	g_ability_active[id] = false
	
	// Check if player is still jump zombie
	if (is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_jump_zombie)
	{
		// Play ability end sound
		emit_sound(id, CHAN_VOICE, SOUND_ABILITY_END, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		// Restore normal gravity
		set_user_gravity(id, JUMP_ZOMBIE_GRAVITY)
		
		// Remove visual effects
		set_user_rendering(id)
		
		// Show deactivation message in chat
		client_print(id, print_chat, "^x03[Jump Zombie]^x01 Schopnosť skončila!")
		
		// Start cooldown HUD display
		set_task(1.0, "task_show_cooldown", id, _, _, "b")
	}
}

/*================================================================================
 [Cooldown HUD Display]
================================================================================*/

public task_show_cooldown(id)
{
	// Check if player is valid and jump zombie
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_jump_zombie)
	{
		remove_task(id)
		return
	}
	
	new Float:current_time = get_gametime()
	
	// Check if cooldown is still active
	if (g_ability_cooldown[id] > current_time)
	{
		new remaining_time = floatround(g_ability_cooldown[id] - current_time)
		
		// Show cooldown HUD in orange, bottom right
		set_hudmessage(255, 165, 0, 0.7, 0.9, 0, 0.0, 1.1, 0.0, 0.0)
		ShowSyncHudMsg(id, g_msg_sync, "[Jump Zombie]^nCooldown: %d sek", remaining_time)
	}
}

/*================================================================================
 [Client Connect/Disconnect]
================================================================================*/

public client_connect(id)
{
	g_ability_active[id] = false
	g_ability_cooldown[id] = 0.0
}

public client_disconnected(id)
{
	remove_task(id + 1000)
	remove_task(id + 2000) // Remove idle sound task
	g_ability_active[id] = false
	g_ability_cooldown[id] = 0.0
}

// Play idle sound function
public play_idle_sound(taskid)
{
	new id = taskid - 2000
	
	// Check if player is still alive and jump zombie
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_jump_zombie || zp_get_user_nemesis(id))
		return
		
	// Play idle sound
	emit_sound(id, CHAN_VOICE, SOUND_IDLE, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
