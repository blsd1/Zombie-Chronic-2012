
# Zombie Chronic 2012 - mode that was on gaming portal

![Version](https://img.shields.io/badge/Version-4.3-blue.svg)
![AMX%20Mod%20X](https://img.shields.io/badge/AMX%20Mod%20X-1.8.2+-green.svg)
![CS](https://img.shields.io/badge/CS-1.6-orange.svg)

## 📋 Overview

**Zombie Chronic 2012** is a comprehensive zombie survival modification for Counter-Strike 1.6, based on Zombie Plague 4.3. This mod transforms the classic Counter-Strike gameplay into an intense zombie apocalypse experience with custom zombie classes, special weapons, and unique game modes.

## 🎮 Game Modes

The mod features several exciting game modes that are randomly selected:

- **Infection Mode** - Classic zombie infection gameplay
- **Nemesis Mode** - A powerful zombie boss appears
- **Survivor Mode** - An armed human survivor fights against zombies
- **Swarm Mode** - Multiple zombies spawn at once
- **Multi Infection** - Multiple first zombies
- **Plague Mode** - Combination of Nemesis and Survivor modes

## 🧟 Zombie Classes

### Classic Zombie Classes

| Class | Health | Speed | Gravity | Knockback | Special Ability |
|-------|--------|-------|---------|-----------|----------------|
| **Ghost Zombie** | 1350 HP | 275 | 0.89 | 1.0 | Invisibility (Press E) |
| **Spider Zombie** | 1100 HP | 240 | 1.49 | 1.0 | Grappling hook web |
| **Crab Zombie** | 600 HP | 900 | 0.60 | 1.13 | High damage output |
| **Jump Zombie** | 2100 HP | 280 | 0.80 | 1.0 | Extra high jumps |
| **Speed Zombie** | 2100 HP | 300 | 1.0 | 2.49 | Speed boost (Press R) |
| **Sleep Zombie** | 2000 HP | 280 | 0.68 | 0.23 | Blinds humans |
| **Biger Zombie** | 2700 HP | 250 | 1.0 | 1.0 | HP boost ability (Press R) |

### Special Zombies

- **Nemesis** - Boss zombie with massive health and damage output
  - Health: Configurable (default based on player count)
  - Speed: 250
  - Gravity: 0.5
  - Damage: 250 per hit
  - Can leap (cooldown: 5.0 seconds)
  - Red glow and aura effects

## 👨‍🔬 Human Classes & Extras

### Base Human Stats
- **Health**: 100 HP
- **Speed**: 240
- **Gravity**: 1.0
- **Armor Protection**: Enabled

### Special Humans

- **Survivor** - Elite human with heavy weapons
  - Health: Configurable (default based on player count)
  - Speed: 230
  - Gravity: 1.25
  - Default Weapon: M249
  - Unlimited Ammo: Available
  - Glow and aura effects

- **Terminator** [ExtraVIP]
  - Cost: 200 Ammo Packs
  - Health: 555 HP
  - Armor: 555
  - Multiple jumps: 4 jumps
  - Jump height: 300

- **Hannibal** [ExtraVIP]
  - Cost: 350 Ammo Packs
  - Health: 800 HP
  - Armor: 900 (max)
  - Gains 5 armor per kill

## 🔫 Extra Items & Weapons

### Human Extra Items

| Item | Cost | Description |
|------|------|-------------|
| **Chainsaw** | 30 AP | Powerful melee weapon with 8.4x damage multiplier |
| **MiniGUN** | 30 AP | Heavy machine gun with high fire rate |
| **M79 Grenade Launcher** | 25 AP | Explosive weapon |
| **ChainSaw v1.0** | 15 AP | Alternative chainsaw version |
| **Special Gun** [ExtraVIP] | 300 AP | High-powered weapon for VIP players |
| **Immunity** [ExtraVIP] | 180 AP | Temporary protection from infection |
| **Healing** [ExtraVIP] | 200 AP | Restore health |
| **Night Vision** | Variable | Custom night vision goggles |
| **Antidote** | Variable | Cure zombie infection |
| **Madness** | Variable | Temporary invincibility with increased damage |
| **Infection Bomb** | Variable | Infect nearby humans |

### Zombie Extra Items

| Item | Cost | Description |
|------|------|-------------|
| **+2000 HP** | 50 AP | Increases zombie health by 2000 |

## ⚔️ Damage System

### Human Damage
- **Base Damage Reward**: 500 damage = 1 Ammo Pack
- **Kill Reward**: 1 frag per zombie kill
- **Last Human Bonus**: Extra HP when last human alive

### Zombie Damage
- **Infection Reward**: 1 Ammo Pack per human infected
- **Infect Health Bonus**: +100 HP per infection
- **First Zombie HP Multiplier**: 2.0x base health
- **Zombie Armor**: 0.75 (25% damage reduction)
- **Damage Reward**: 0 (configurable)

### Nemesis
- **Damage Output**: 250 per hit
- **Knockback Resistance**: 0.25 (takes 75% less knockback)

### Fire Grenades
- **Fire Damage**: 5 HP per tick
- **Fire Duration**: 10 seconds
- **Slowdown Effect**: 0.5 movement speed

### Frost Grenades
- **Freeze Duration**: 3 seconds
- **Effect**: Complete immobilization

## 🎯 Knockback System

The mod features a sophisticated knockback system:

- **Knockback Enabled**: Yes (configurable)
- **Knockback Power**: 1x (configurable)
- **Knockback Distance**: 500 units
- **Knockback on Damage**: Enabled
- **Ducking Knockback Reduction**: 0.25 (75% reduction when crouched)
- **Knockback Z-Velocity**: 0 (no vertical knockback)
- **Nemesis Knockback**: 0.25 (Nemesis takes reduced knockback)

## 🌟 Special Features

### Leap System
- **Zombie Leap**: Disabled by default (configurable)
  - Force: 500
  - Height: 300
  - Cooldown: 5.0 seconds

- **Nemesis Leap**: Enabled
  - Force: 500
  - Height: 300
  - Cooldown: 5.0 seconds

- **Survivor Leap**: Disabled by default
  - Force: 500
  - Height: 300
  - Cooldown: 5.0 seconds

### Custom Grenades
- **Fire Grenades**: Enabled - Burns zombies over time
- **Frost Grenades**: Enabled - Freezes zombies temporarily
- **Flare Grenades**: Enabled - Provides lighting for 60 seconds
- **Infection Grenades**: Infects humans in blast radius

### Deathmatch System
- **Respawn Enabled**: Configurable
- **Spawn Delay**: 5 seconds
- **Spawn Protection**: 5 seconds
- **Respawn on Suicide**: Configurable
- **Random Spawn Points**: Enabled

### Visual Effects
- **Infection Screen Shake**: Enabled
- **Infection Sparkle Effect**: Enabled
- **Infection Tracers**: Enabled
- **Infection Particles**: Enabled
- **HUD Icons**: Enabled
- **Custom Night Vision**: Enabled
  - Zombie NVG Color: RGB(0, 150, 0) - Green
  - Human NVG Color: RGB(0, 150, 0) - Green
  - Nemesis NVG Color: RGB(150, 0, 0) - Red
- **Flashlight**: Custom flashlight system with battery drain

### Sound System
- Custom sounds for:
  - Zombie infections
  - Pain sounds per class
  - Death sounds
  - Ability activation
  - Round start announcements
  - Ambient background music
  - Grenade explosions
  - Special character spawn

## 📊 Ammo Pack System

Players earn **Ammo Packs** which serve as the in-game currency:

- **Starting Ammo Packs**: 5
- **Earn as Human**: Deal 500 damage to zombies = 1 AP
- **Earn as Zombie**: Infect a human = 1 AP
- **Spend on**: Extra items, weapons, and special abilities
- **Stats Saving**: Enabled (ammo packs saved between maps)

## ⚙️ Requirements

### Server Requirements
- **AMX Mod X**: Version 1.8.2 or higher
- **Metamod**: Latest version
- **Counter-Strike**: Version 1.6

### Required Modules
- `amxmodx` - Core AMX Mod X
- `amxmisc` - Miscellaneous functions
- `cstrike` - Counter-Strike specific functions
- `fakemeta` - FakeMeta functions
- `hamsandwich` - Ham Sandwich module
- `engine` - Engine module
- `fun` - Fun module
- `xs` - Extra Stock functions

### Recommended Modules
- `nvault` - For data storage
- `fakemeta_util` - Utility functions

## 📦 Installation

1. **Extract Files**: Extract all files from the archive to your Counter-Strike 1.6 server directory
2. **Configure Metamod**: Ensure Metamod is properly installed and configured
3. **Install AMX Mod X**: Install AMX Mod X 1.8.2 or higher
4. **Copy Addons**: The addon structure should be:
   ```
   cstrike/
   ├── addons/
   │   ├── amxmodx/
   │   │   ├── configs/
   │   │   ├── data/
   │   │   ├── dlls/
   │   │   ├── modules/
   │   │   ├── plugins/
   │   │   └── scripting/
   │   ├── metamod/
   │   └── yapb/
   ├── maps/
   ├── models/
   ├── sounds/
   └── sprites/
   ```

5. **Configure Plugins**:
   - Edit `addons/amxmodx/configs/plugins-zplague.ini` to enable/disable plugins
   - Edit `addons/amxmodx/configs/zombieplague.ini` for main mod settings
   - Edit `addons/amxmodx/configs/zp_extraitems.ini` for extra items
   - Edit `addons/amxmodx/configs/zp_zombieclasses.ini` for zombie classes

6. **Restart Server**: Restart your Counter-Strike server

## 🎮 Admin Commands

Access flags required are defined in `zombieplague.ini`:

- **zp_toggle** - Enable/Disable Zombie Plague (Access: l)
- **Admin Menu** - Access full admin controls (Access: d)
- **Force Game Modes**:
  - Start Infection Mode (Access: d)
  - Start Nemesis Mode (Access: d)
  - Start Survivor Mode (Access: d)
  - Start Swarm Mode (Access: d)
  - Start Multi Mode (Access: d)
  - Start Plague Mode (Access: d)
- **Player Control**:
  - Make Zombie (Access: d)
  - Make Human (Access: d)
  - Make Nemesis (Access: d)
  - Make Survivor (Access: d)
  - Respawn Players (Access: d)
- **Admin Models** - Special VIP models (Access: d)

## 🎲 Game Balance

### Mode Chances (Default)
- **Nemesis Mode**: 20% chance
- **Survivor Mode**: 20% chance
- **Swarm Mode**: 20% chance
- **Multi Infection**: 20% chance
- **Plague Mode**: 30% chance

### Player Requirements
- **Nemesis Mode**: 0 minimum players (configurable)
- **Survivor Mode**: 0 minimum players (configurable)
- **Swarm Mode**: 0 minimum players (configurable)
- **Multi Infection**: 0 minimum players (configurable)
- **Plague Mode**: 0 minimum players (configurable)

### Plague Mode Configuration
- **Plague Ratio**: 0.5 (50% of players)
- **Nemesis Number**: 1
- **Nemesis HP Multiplier**: 0.5x
- **Survivor Number**: 1
- **Survivor HP Multiplier**: 0.5x

## 🗺️ Supported Maps

The mod includes custom zombie maps:
- zm_* maps (zombie mod specific)
- All standard CS 1.6 maps (de_*, cs_*, as_*)
- Custom maps optimized for zombie gameplay

See the `maps/` directory for the complete list (50+ maps included).

## 📝 Configuration Tips

### Balancing Tips
1. **For More Zombie Action**: Increase zombie speed and reduce knockback
2. **For Harder Zombie Gameplay**: Increase human damage and knockback
3. **For Longer Rounds**: Increase zombie HP and reduce fire damage
4. **For Faster Rounds**: Enable respawn and reduce spawn delay

### Performance Optimization
- Disable unused visual effects in `zombieplague.ini`
- Reduce ambient sound count for lower bandwidth
- Disable model consistency checks if trusted server

### Custom Classes
- Edit `zp_zombieclasses.ini` to modify zombie class stats
- Add new zombie class plugins to `plugins-zplague.ini`
- Adjust extra item costs in `zp_extraitems.ini`

## 🐛 Known Issues & Solutions

1. **Bot Support**: CZ bots are supported with special Ham forward handling
2. **Model Consistency**: Can be toggled in config (0=off, 1=bounds check, 2=CRC check)
3. **Spawn Points**: Uses CSDM-style spawn points for better distribution
4. **Suicide Prevention**: Block suicide command is configurable

## 📜 Credits

- **Zombie Chronic 2012 Version**: 4.3
- **Base Mod**: Zombie Plague by MeRcyLeZZ
- **Custom Content**: ketamine, Laoming, DarTom, sefik, and other contributors
- **Zombie Classes**: Custom classes with ch2012 models and sounds
- **Extra Items**: Various authors (see individual plugin headers)

## 📄 License

This is a community modification for Counter-Strike 1.6. All custom content and modifications are provided as-is for entertainment purposes.

## 🔗 Support & Community

For issues, suggestions, or custom modifications, refer to the AMX Mod X community forums and documentation.

---

**Version**: 4.3  

**Compatible with**: Counter-Strike 1.6, AMX Mod X 1.10.0

=======
>>>>>>> fc008a0e3b2bf8485e5360c01b92793d3ab9ac10
