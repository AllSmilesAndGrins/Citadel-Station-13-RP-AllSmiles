///////////////////
// Generic skyfall turf
// Really only works well if the map doesn't have 'indoor' areas otherwise they can fall into one.
// TODO: Fix that.
/turf/unsimulated/floor/sky
	name = "the sky"
	desc = "It's the sky! Be careful!"
	icon = 'icons/turf/floors.dmi'
	icon_state = "sky_slow"
	dir = SOUTH
	var/does_skyfall = TRUE
	var/list/skyfall_levels

/turf/unsimulated/floor/sky/Initialize(mapload)
	. = ..()
	if(does_skyfall && !LAZYLEN(skyfall_levels))
		log_world("[x],[y],[z], [get_area(src)] doesn't have skyfall_levels defined! Can't skyfall!")
	if(locate(/turf/simulated) in orange(src,1))
		set_light(2, 2, color)

/turf/unsimulated/floor/sky/Entered(atom/movable/AM,atom/oldloc)
	..()
	if(!does_skyfall)
		return //We don't do that
	if(isobserver(AM))
		return //Don't ghostport, very annoying
	if(AM.throwing)
		return //Being thrown over, not fallen yet
	if(!(AM.can_fall()))
		return // Phased shifted kin should not fall
	if(istype(AM, /obj/item/projectile))
		return // pewpew should not fall out of the sky. pew.
	if(istype(AM, /obj/effect/projectile))
		return // ...neither should the effects be falling

	var/mob/living/L
	if(isliving(AM))
		L = AM
		if(L.is_floating || L.flying)
			return //Flyers/nograv can ignore it

	do_fall(AM)

/turf/unsimulated/floor/sky/hitby(var/atom/movable/AM, var/speed)
	. = ..()

	if(!does_skyfall)
		return //We don't do that

	do_fall(AM)

/turf/unsimulated/floor/sky/proc/do_fall(atom/movable/AM)
	//Bye
	var/attempts = 100
	var/turf/simulated/T
	while(attempts && !T)
		var/turf/simulated/candidate = locate(rand(5,world.maxx-5),rand(5,world.maxy-5),pick(skyfall_levels))
		if(candidate.density)
			attempts--
			continue

		T = candidate
		break

	if(!T)
		return

	AM.forceMove(T)
	if(isliving(AM))
		var/mob/living/L = AM
		message_admins("\The [AM] fell out of the sky.")
		L.fall_impact(T, 42, 90, FALSE, TRUE)	//You will not be defibbed from this.

/turf/unsimulated/floor/sky/virgo2_sky
	name = "virgo 2 atmosphere"
	desc = "Be careful where you step!"
	color = "#eacd7c"
	VIRGO2_SET_ATMOS

/turf/unsimulated/floor/sky/virgo2_sky/Initialize(mapload)
	skyfall_levels = list(z+1)
	. = ..()

/turf/unsimulated/floor/sky/depths
	name = "darkness"
	desc = "A straight drop down into the depths below."
	skyfall_levels = "Western Caverns"
	color ="#303030"

/turf/unsimulated/floor/sky/depths/Initialize(mapload)
	. = ..()
	set_light(0, 0, "#FFFFFF")

/turf/unsimulated/floor/sky/depths/Initialize(mapload)
	skyfall_levels = list(z+1)
	. = ..()
