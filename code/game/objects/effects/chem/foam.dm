// Foam
// Similar to smoke, but spreads out more
// metal foams leave behind a foamed metal wall

/obj/effect/foam
	name = "foam"
	icon = 'icons/effects/effects.dmi'
	icon_state = "foam"
	opacity = 0
	anchored = 1
	density = 0
	layer = OBJ_LAYER + 0.9
	mouse_opacity = 0
	animate_movement = 0
	var/amount = 3
	var/expand = 1
	var/metal = 0
	var/dries = 1
	var/slips = 0

/obj/effect/foam/Initialize(mapload, ismetal = FALSE)
	. = ..()
	metal = ismetal
	playsound(src, 'sound/effects/bubbles2.ogg', 80, 1, -3)
	if(dries)
		addtimer(CALLBACK(src, PROC_REF(post_spread)), 3 + metal * 3)
		addtimer(CALLBACK(src, PROC_REF(pre_harden)), 12 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(harden)), 15 SECONDS)

/obj/effect/foam/proc/post_spread()
	process()
	checkReagents()

/obj/effect/foam/proc/pre_harden()
	return
/obj/effect/foam/proc/harden()
	if(metal)
		var/obj/structure/foamedmetal/M = new(src.loc)
		M.metal = metal
		M.updateicon()
	flick("[icon_state]-disolve", src)
	QDEL_IN(src, 5)

/obj/effect/foam/proc/checkReagents() // transfer any reagents to the floor
	if(!metal && reagents)
		var/turf/T = get_turf(src)
		reagents.touch_turf(T)
		for(var/obj/O in T)
			reagents.touch_obj(O)

/obj/effect/foam/process()
	if(--amount < 0)
		return

	for(var/direction in GLOB.cardinal)
		var/turf/T = get_step(src, direction)
		if(!T)
			continue

		if(!T.Enter(src))
			continue

		var/obj/effect/foam/F = locate() in T
		if(F)
			continue

		F = new(T, metal)
		F.amount = amount
		if(!metal)
			F.create_reagents(10)
			if(reagents)
				for(var/datum/reagent/R in reagents.reagent_list)
					F.reagents.add_reagent(R.id, 1, safety = 1) //added safety check since reagents in the foam have already had a chance to react

/obj/effect/foam/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume) // foam disolves when heated, except metal foams
	if(!metal && prob(max(0, exposed_temperature - 475)))
		flick("[icon_state]-disolve", src)

		spawn(5)
			qdel(src)

/obj/effect/foam/Crossed(var/atom/movable/AM)
	. = ..()
	if(AM.is_incorporeal())
		return
	if(metal)
		return
	if(slips && istype(AM, /mob/living))
		var/mob/living/M = AM
		M.slip("the foam", 6)

/datum/effect_system/foam_spread
	/// The size of the foam spread.
	var/amount = 5
	/// The IDs of reagents present when the foam was mixed.
	var/list/carried_reagents
	/// 0 = foam, 1 = metalfoam, 2 = ironfoam.
	var/metal = 0

/datum/effect_system/foam_spread/set_up(amt=5, loca, var/datum/reagents/carry = null, var/metalfoam = 0)
	amount = round(sqrt(amt / 3), 1)
	if(istype(loca, /turf/))
		location = loca
	else
		location = get_turf(loca)

	carried_reagents = list()
	metal = metalfoam

	// bit of a hack here. Foam carries along any reagent also present in the glass it is mixed with (defaults to water if none is present). Rather than actually transfer the reagents, this makes a list of the reagent ids and spawns 1 unit of that reagent when the foam disolves.

	if(carry && !metal)
		for(var/datum/reagent/R in carry.reagent_list)
			carried_reagents += R.id

/datum/effect_system/foam_spread/start()
	spawn(0)
		var/obj/effect/foam/F = locate() in location
		if(F)
			F.amount += amount
			return

		F = new /obj/effect/foam(location, metal)
		F.amount = amount

		if(!metal) // don't carry other chemicals if a metal foam
			F.create_reagents(10)

			if(carried_reagents)
				for(var/id in carried_reagents)
					F.reagents.add_reagent(id, 1, safety = 1) //makes a safety call because all reagents should have already reacted anyway
			else
				F.reagents.add_reagent("water", 1, safety = 1)

// wall formed by metal foams, dense and opaque, but easy to break

/obj/structure/foamedmetal
	icon = 'icons/effects/effects.dmi'
	icon_state = "metalfoam"
	density = TRUE
	opacity = TRUE
	anchored = TRUE
	rad_insulation = RAD_INSULATION_MEDIUM
	rad_stickiness = 0.5
	name = "foamed metal"
	desc = "A lightweight foamed metal wall."
	CanAtmosPass = ATMOS_PASS_DENSITY
	var/metal = 1 // 1 = aluminum, 2 = iron

/obj/structure/foamedmetal/Initialize(mapload)
	. = ..()
	update_nearby_tiles(1)

/obj/structure/foamedmetal/Destroy()
	density = FALSE
	update_nearby_tiles(1)
	return ..()

/obj/structure/foamedmetal/proc/updateicon()
	if(metal == 1)
		icon_state = "metalfoam"
	else
		icon_state = "ironfoam"

/obj/structure/foamedmetal/legacy_ex_act(severity)
	qdel(src)

/obj/structure/foamedmetal/bullet_act(var/obj/projectile/P)
	if(istype(P, /obj/projectile/test))
		return
	else if(metal == 1 || prob(50))
		qdel(src)

/obj/structure/foamedmetal/attack_hand(mob/user, list/params)
	if ((MUTATION_HULK in user.mutations) || (prob(75 - metal * 25)))
		user.visible_message("<span class='warning'>[user] smashes through the foamed metal.</span>", "<span class='notice'>You smash through the metal foam wall.</span>")
		qdel(src)
	else
		to_chat(user, "<span class='notice'>You hit the metal foam but bounce off it.</span>")
	return

/obj/structure/foamedmetal/attackby(var/obj/item/I, var/mob/user)
	if(istype(I, /obj/item/grab))
		var/obj/item/grab/G = I
		G.affecting.forceMove(loc)
		visible_message("<span class='warning'>[G.assailant] smashes [G.affecting] through the foamed metal wall.</span>")
		qdel(I)
		qdel(src)
		return

	if(prob(I.damage_force * 20 - metal * 25))
		user.visible_message("<span class='warning'>[user] smashes through the foamed metal.</span>", "<span class='notice'>You smash through the foamed metal with \the [I].</span>")
		qdel(src)
	else
		to_chat(user, "<span class='notice'>You hit the metal foam to no effect.</span>")
