#if defined _zp_weapons_included
  #endinput
#endif
#define _zp_weapons_included

/**
 * Registers a custom weapon for the buy menu.
 *
 * @param name		Weapon display name (e.g., "AK-47 Legend")
 * @param cost		Price in money ($)
 * @param team		Team restriction: 1 = Zombie, 2 = Human, 3 = Both
 * @return		Weapon ID, or -1 on failure
 */
native zp_register_custom_weapon(const name[], cost, team)

/**
 * Gives a custom weapon to a player.
 *
 * @param id		Player index
 * @param weapon_id	Weapon ID returned from zp_register_custom_weapon
 * @return		True on success, false otherwise
 */
native zp_give_custom_weapon(id, weapon_id)

/**
 * Returns the number of registered custom weapons.
 *
 * @return		Total custom weapons count
 */
native zp_get_custom_weapons_count()

/**
 * Gets the name of a custom weapon.
 *
 * @param weapon_id	Weapon ID
 * @param name		Buffer to store weapon name
 * @param len		Buffer size
 */
native zp_get_custom_weapon_name(weapon_id, name[], len)

/**
 * Gets the cost of a custom weapon.
 *
 * @param weapon_id	Weapon ID
 * @return		Weapon cost in $
 */
native zp_get_custom_weapon_cost(weapon_id)

/**
 * Gets the team restriction of a custom weapon.
 *
 * @param weapon_id	Weapon ID
 * @return		Team: 1 = Zombie, 2 = Human, 3 = Both
 */
native zp_get_custom_weapon_team(weapon_id)

/**
 * Forward called when a player buys a custom weapon.
 * Return PLUGIN_HANDLED to block the purchase.
 *
 * @param id		Player index
 * @param weapon_id	Weapon ID being purchased
 */
forward zp_custom_weapon_bought(id, weapon_id)
