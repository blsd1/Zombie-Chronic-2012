# Zombie Chronic 2012 - Counter-Strike 1.6 Mod

![Version](https://img.shields.io/badge/Version-4.3-green.svg)
![AMX%20Mod%20X](https://img.shields.io/badge/AMX%20Mod%20X-1.10.0+-blue.svg)
![CS](https://img.shields.io/badge/CS-1.6-orange.svg)

## 📋 Overview

**Zombie Chronic 2012** is a zombie survival modification for Counter-Strike 1.6.

## 🎮 Game Modes

The mod features several exciting game modes that are randomly selected:

- **Infection Mode** - 
- **Nemesis Mode** - 
- **Survivor Mode** - 
- **Zombies vs Humans** -
- **Multi Infection** -
- **Plague Mode** 

## 🧟 Zombie Classes

### Classic Zombie Classes

| Class | Health | Speed | Gravity | Knockback | Special Ability |
|-------|--------|-------|---------|-----------|----------------|
| **Ghost Zombie** | 1350 HP | 275 | 0.89 | 1.0 | invisibility |
| **Spider Zombie** | 1100 HP | 240 | 1.49 | 1.0 | hook |
| **Crab Zombie** | 600 HP | 900 | 0.60 | 1.13 | crit damage |
| **Jump Zombie** | 2100 HP | 280 | 0.80 | 1.0 | high jumps |
| **Speed Zombie** | 2100 HP | 300 | 1.0 | 2.49 | speed boost) |
| **Sleep Zombie** | 2000 HP | 280 | 0.68 | 0.23 | blinding humans |
| **Biger Zombie** | 2700 HP | 250 | 1.0 | 1.0 | hp boost |

### Special Zombies

- **Nemesis** - 
  - Health: (default based on player count)
  - Speed: 250
  - Gravity: 0.5
  - Damage: 250 per hit
  - Can leap (cooldown: 5.0 seconds)
  - Red glow and aura effects

## 👨‍🔬 Human Classes & Extras

### Base Human Stats
- **Health**: 150 HP
- **Speed**: 250
- **Gravity**: 1.0

### Special Humans

- **Terminator** [ExtraVIP]
  - Cost: 200 Ammo Packs
  - Health: 550 HP
  - Armor: 550
  - Gains 5 armor per kill
  - Multiple jumps: 4 jumps

- **Hannibal** [ExtraVIP]
  - Cost: 200 Ammo Packs
  - Health: 999 HP
  - Armor: 999 (max)
  - Multiple jumps: 4 jumps
  - Gains 5 armor per hit with chainsaw
  - Gains 30 armor per kill

## 🔫 Extra Items & Weapons

### Human Extra Items

| Item | Cost | Description |
|------|------|-------------|
| **Chainsaw** | 10 AP | Powerful melee weapon with 8.4x damage multiplier |
| **MiniGUN [VIP]** | 120 AP | Heavy machine gun with high fire rate |
| **Bazooka [VIP]** | 120 AP 
| **M79 Grenade Launcher [ExtraVIP]** | 200 AP | Explosive weapon |
| **Special Gun [ExtraVIP]** | 200 AP | High-powered weapon for EVIP players |
| **Immunity [ExtraVIP]** | 180 AP | Temporary protection from infection |
| **AntiDote Nade [ExtraVIP]** | 200 AP | Restore health |
| **Terminator [ExtraVIP]** | 200 AP | Special Class, armor + hp + 5 armor per kill |
| **Hannibal Lector [ExtraVIP]** | 200 AP | Restore health |


### Zombie Extra Items

| Item | Cost | Description |
|------|------|-------------|
| **Antidote** | Variable | Cure zombie infection |
| **Madness** | Variable | Temporary invincibility with increased damage |
| **Infection Bomb** | Variable | Infect nearby humans |
| **+2000 HP** | 50 AP | Increases zombie health by 2000 |


### Fire Grenades
- **Fire Damage**: 7 HP per tick
- **Fire Duration**: 10 seconds
- **Slowdown Effect**: 0.5 movement speed

### Frost Grenades
- **Freeze Duration**: 3 seconds
- **Effect**: Complete immobilization

## 🌟 Leap

- **Survivor Leap**: Disabled by default
  - Force: 500
  - Height: 300
  - Cooldown: 5.0 seconds

### Custom Grenades
- **Fire Grenades**: Enabled - Burns zombies over time
- **Frost Grenades**: Enabled - Freezes zombies temporarily
- **Infection Grenades**: Infects humans in blast radius

## ⚙️ Requirements

### Server Requirements
- **AMX Mod X**: Version 1.8.2 or 1.10/higher
- **Metamod**: Latest version

### Required Modules
- `amxmodx` - Core AMX Mod X
- `amxmisc` - Miscellaneous functions
- `cstrike` - Counter-Strike specific functions
- `fakemeta` - FakeMeta functions
- `hamsandwich` - Ham Sandwich module
- `engine` - Engine module
- `fun` - Fun module
- `xs` - Extra Stock functions

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


## 📄 License

This is a community modification for Counter-Strike 1.6. All custom content and modifications are provided as-is for entertainment purposes.

