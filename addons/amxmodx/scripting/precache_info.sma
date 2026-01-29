/**
*	Simple plugin to display used precaches by type.
*
*	Home post:
*	  http://c-s.net.ua/forum/index.php?act=findpost&pid=879945
*
*	Last update:
*	  1/6/2016
*
*	Hint:
*	- first number in a line of detailed info shows unique index in corresponding resource array
*/

/*	Copyright 2016  Safety1st

	'Precache Info' is free software;
	you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <amxmodx>
#include <fakemeta>

#define PLUGIN "Precache Info"
#define VERSION "0.1"
#define AUTHOR "Safety1st"

/*----------------------EDIT ME-------------------------*/
//#define SHOW_DETAILED_INFO	// uncomment to enable
/*------------------------------------------------------*/

new giFwdModel, giFwdSound, giFwdGeneric
new giModelCount, giSoundCount, giGenericCount

public plugin_init() {
	register_plugin( PLUGIN, VERSION, AUTHOR )

	unregister_forward( FM_PrecacheModel, giFwdModel )
	unregister_forward( FM_PrecacheSound, giFwdSound )
	unregister_forward( FM_PrecacheGeneric, giFwdGeneric )

	server_print( "************************************^n[Precache info]" )
	server_print( " %d models (models, sprites); 512 max allowed", giModelCount )
	server_print( " %d sounds; 512 max allowed", giSoundCount )
	server_print( " %3d generic (images, mp3, txt, res, ...); 512 max allowed", giGenericCount )
	server_print( " %d total", giModelCount + giSoundCount + giGenericCount )
	server_print( "************************************" )
}

public plugin_precache() {
	giFwdModel = register_forward( FM_PrecacheModel, "FM_PrecacheModel_Post", ._post = 1 )
	giFwdSound = register_forward( FM_PrecacheSound, "FM_PrecacheSound_Post", ._post = 1 )
	giFwdGeneric = register_forward( FM_PrecacheGeneric, "FM_PrecacheGeneric_Post", ._post = 1 )
}

public FM_PrecacheModel_Post( const model[] ) {
	giModelCount++

#if defined SHOW_DETAILED_INFO
	server_print( "%3d: MODEL ^"%s^"", get_orig_retval(), model )
#endif
}

public FM_PrecacheSound_Post( const sound[] ) {
	giSoundCount++

#if defined SHOW_DETAILED_INFO
	server_print( "%3d: SOUND ^"%s^"", get_orig_retval(), sound )
#endif
}

public FM_PrecacheGeneric_Post( const generic[] ) {
	giGenericCount++

#if defined SHOW_DETAILED_INFO
	server_print( "%3d: GENERIC ^"%s^"", get_orig_retval(), generic )
#endif
}