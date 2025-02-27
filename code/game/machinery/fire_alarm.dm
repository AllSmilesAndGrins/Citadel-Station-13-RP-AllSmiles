/*
FIRE ALARM
*/
/obj/machinery/firealarm
	name = "fire alarm"
	desc = "<i>\"Pull this in case of emergency\"</i>. Thus, keep pulling it forever."
	icon = 'icons/obj/firealarm.dmi'
	icon_state = "casing"
	plane = TURF_PLANE
	layer = ABOVE_TURF_LAYER
	var/detecting = TRUE
	var/working = TRUE
	var/time = 10
	var/timing = 0
	var/lockdownbyai = FALSE
	anchored = TRUE
	use_power = TRUE
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = ENVIRON
	var/last_process = 0
	panel_open = FALSE
	var/seclevel
	circuit = /obj/item/circuitboard/firealarm
	/// If the alarms from this machine are visible on consoles.
	var/alarms_hidden = FALSE

/obj/machinery/firealarm/alarms_hidden
	alarms_hidden = TRUE

/obj/machinery/firealarm/Initialize(mapload)
	. = ..()
	if(z in (LEGACY_MAP_DATUM).contact_levels)
		set_security_level(GLOB.security_level ? get_security_level() : "green")
	setDir(dir)

/obj/machinery/firealarm/setDir(ndir)
	. = ..()
	base_pixel_x = 0
	base_pixel_y = 0
	switch(dir)
		if(NORTH)
			base_pixel_y = -21
		if(SOUTH)
			base_pixel_y = 21
		if(WEST)
			base_pixel_x = -21
		if(EAST)
			base_pixel_x = 21
	reset_pixel_offsets()

/obj/machinery/firealarm/update_icon()
	cut_overlays()
	add_overlay("casing")

	if(panel_open)
		set_light(0)
		return

	if(machine_stat & BROKEN)
		add_overlay("broken")
		set_light(0)
	else if(machine_stat & NOPOWER)
		set_light(0)
		return
	else
		if(!detecting)
			add_overlay("fire1")
			set_light(l_range = 4, l_power = 0.9, l_color = "#ff0000")
		else
			add_overlay("fire0")
			var/image/alarm_img
			switch(seclevel)
				if("green")
					alarm_img = image(icon, "alarm_normal")
					alarm_img.color = "#00ff00"
					add_overlay(alarm_img)
					set_light(l_range = 2, l_power = 0.25, l_color = "#00ff00")
				if("yellow")
					alarm_img = image(icon, "alarm_blinking")
					alarm_img.color = "#ffff00"
					add_overlay(alarm_img)
					set_light(l_range = 2, l_power = 0.25, l_color = "#ffff00")
				if("violet")
					alarm_img = image(icon, "alarm_blinking")
					alarm_img.color = "#9933ff"
					add_overlay(alarm_img)
					set_light(l_range = 2, l_power = 0.25, l_color = "#9933ff")
				if("orange")
					alarm_img = image(icon, "alarm_blinking")
					alarm_img.color = "#ff9900"
					add_overlay(alarm_img)
					set_light(l_range = 2, l_power = 0.25, l_color = "#ff9900")
				if("blue")
					alarm_img = image(icon, "alarm_blinking")
					alarm_img.color = "#1024A9"
					add_overlay(alarm_img)
					set_light(l_range = 2, l_power = 0.25, l_color = "#1024A9")
				if("red")
					alarm_img = image(icon, "alarm_blinking")
					alarm_img.color = "#ff0000"
					add_overlay(alarm_img)
					set_light(l_range = 4, l_power = 0.9, l_color = "#ff0000")
				if("delta")
					alarm_img = image(icon, "alarm_blinking_twotone1")
					alarm_img.color = COLOR_YELLOW
					var/image/alarm_img2 = image(icon, "alarm_blinking_twotone2")
					alarm_img2.color = COLOR_RED
					add_overlay(alarm_img)
					add_overlay(alarm_img2)
					set_light(l_range = 4, l_power = 0.9, l_color = "#FF6633")

/obj/machinery/firealarm/fire_act(datum/gas_mixture/air, temperature, volume)
	if(detecting)
		if(temperature > T0C + 200)
			alarm()			// added check of detector status here
	return

/obj/machinery/firealarm/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/firealarm/bullet_act()
	return alarm()

/obj/machinery/firealarm/emp_act(severity)
	if(prob(50 / severity))
		alarm(rand(30 / severity, 60 / severity))
	..()

/obj/machinery/firealarm/attackby(obj/item/W, mob/user)
	add_fingerprint(user)

	if(alarm_deconstruction_screwdriver(user, W))
		return
	if(alarm_deconstruction_wirecutters(user, W))
		return

	if(panel_open)
		if(istype(W, /obj/item/multitool))
			detecting = !(detecting)
			if(detecting)
				user.visible_message( \
					SPAN_NOTICE("\The [user] has reconnected [src]'s detecting unit!"), \
					SPAN_NOTICE("You have reconnected [src]'s detecting unit."))
			else
				user.visible_message( \
					SPAN_NOTICE("\The [user] has disconnected [src]'s detecting unit!"), \
					SPAN_NOTICE("You have disconnected [src]'s detecting unit."))
		return

	alarm()
	return

/obj/machinery/firealarm/process()//Note: this processing was mostly phased out due to other code, and only runs when needed
	if(machine_stat & (NOPOWER|BROKEN))
		return

	if(timing)
		if(time > 0)
			time = time - ((world.timeofday - last_process) / 10)
		else
			alarm()
			time = 0
			timing = 0
			STOP_PROCESSING(SSobj, src)
		updateDialog()
	last_process = world.timeofday

	if(locate(/atom/movable/fire) in src.loc)
		alarm()

	return

/obj/machinery/firealarm/power_change()
	..()
	spawn(rand(0,15))
		update_icon()

/obj/machinery/firealarm/attack_hand(mob/user, list/params)
	if(user.stat || machine_stat & (NOPOWER | BROKEN))
		return

	user.set_machine(src)
	var/area/A = src.loc
	var/d1
	var/d2
	if(istype(user, /mob/living/carbon/human) || istype(user, /mob/living/silicon))
		A = A.loc

		if(A.fire)
			d1 = "<A href='?src=\ref[src];reset=1'>Reset - Lockdown</A>"
		else
			d1 = "<A href='?src=\ref[src];alarm=1'>Alarm - Lockdown</A>"
		if(timing)
			d2 = "<A href='?src=\ref[src];time=0'>Stop Time Lock</A>"
		else
			d2 = "<A href='?src=\ref[src];time=1'>Initiate Time Lock</A>"
		var/second = round(time) % 60
		var/minute = (round(time) - second) / 60
		var/dat = "<HTML><HEAD></HEAD><BODY><TT><B>Fire alarm</B> [d1]\n<HR>The current alert level is: <b>[get_security_level()]</b><br><br>\nTimer System: [d2]<BR>\nTime Left: [(minute ? "[minute]:" : null)][second] <A href='?src=\ref[src];tp=-30'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> <A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=30'>+</A>\n</TT></BODY></HTML>"
		user << browse(dat, "window=firealarm")
		onclose(user, "firealarm")
	else
		A = A.loc
		if(A.fire)
			d1 = "<A href='?src=\ref[src];reset=1'>[stars("Reset - Lockdown")]</A>"
		else
			d1 = "<A href='?src=\ref[src];alarm=1'>[stars("Alarm - Lockdown")]</A>"
		if(timing)
			d2 = "<A href='?src=\ref[src];time=0'>[stars("Stop Time Lock")]</A>"
		else
			d2 = "<A href='?src=\ref[src];time=1'>[stars("Initiate Time Lock")]</A>"
		var/second = round(time) % 60
		var/minute = (round(time) - second) / 60
		var/dat = "<HTML><HEAD></HEAD><BODY><TT><B>[stars("Fire alarm")]</B> [d1]\n<HR><b>The current alert level is: [stars(get_security_level())]</b><br><br>\nTimer System: [d2]<BR>\nTime Left: [(minute ? "[minute]:" : null)][second] <A href='?src=\ref[src];tp=-30'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> <A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=30'>+</A>\n</TT></BODY></HTML>"
		user << browse(dat, "window=firealarm")
		onclose(user, "firealarm")
	return

/obj/machinery/firealarm/Topic(href, href_list)
	..()
	if(usr.stat || machine_stat & (BROKEN | NOPOWER))
		return

	if((usr.contents.Find(src) || ((get_dist(src, usr) <= 1) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.set_machine(src)
		if(href_list["reset"])
			reset()
		else if(href_list["alarm"])
			alarm()
		else if(href_list["time"])
			timing = text2num(href_list["time"])
			last_process = world.timeofday
			START_PROCESSING(SSobj, src)
		else if(href_list["tp"])
			var/tp = text2num(href_list["tp"])
			time += tp
			time = min(max(round(time), 0), 120)

		updateUsrDialog()

		add_fingerprint(usr)
	else
		usr << browse(null, "window=firealarm")
		return
	return

/obj/machinery/firealarm/proc/reset()
	if(!(working))
		return
	var/area/area = get_area(src)
	for(var/obj/machinery/firealarm/FA in area)
		fire_alarm.clearAlarm(src.loc, FA)
	update_icon()
	return

/obj/machinery/firealarm/proc/alarm(var/duration = 0)
	if(!(working))
		return
	var/area/area = get_area(src)
	for(var/obj/machinery/firealarm/FA in area)
		fire_alarm.triggerAlarm(loc, FA, duration, hidden = alarms_hidden)
	update_icon()
	playsound(src.loc, 'sound/machines/airalarm.ogg', 25, 0, 4)
	return

/obj/machinery/firealarm/proc/set_security_level(var/newlevel)
	if(seclevel != newlevel)
		seclevel = newlevel
		update_icon()

/*
FIRE ALARM CIRCUIT
Just a object used in constructing fire alarms
/obj/item/firealarm_electronics
	name = "fire alarm electronics"
	icon = 'icons/obj/doors/door_assembly.dmi'
	icon_state = "door_electronics"
	desc = "A circuit. It has a label on it, it says \"Can handle heat levels up to 40 degrees celsius!\""
	w_class = ITEMSIZE_SMALL
	materials = list(MAT_STEEL = 50, MAT_GLASS = 50)
*/
/obj/machinery/partyalarm
	name = "\improper PARTY BUTTON"
	desc = "Cuban Pete is in the house!"
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire0"
	var/detecting = TRUE
	var/working = TRUE
	var/time = 10
	var/timing = 0
	var/lockdownbyai = FALSE
	anchored = TRUE
	use_power = TRUE
	idle_power_usage = 2
	active_power_usage = 6

/obj/machinery/partyalarm/attack_hand(mob/user, list/params)
	if(user.stat || machine_stat & (NOPOWER|BROKEN))
		return

	user.machine = src
	var/area/A = get_area(src)
	ASSERT(isarea(A))
	var/d1
	var/d2
	if(istype(user, /mob/living/carbon/human) || istype(user, /mob/living/silicon/ai))

		if(A.party)
			d1 = "<A href='?src=\ref[src];reset=1'>No Party :(</A>"
		else
			d1 = "<A href='?src=\ref[src];alarm=1'>PARTY!!!</A>"
		if(timing)
			d2 = "<A href='?src=\ref[src];time=0'>Stop Time Lock</A>"
		else
			d2 = "<A href='?src=\ref[src];time=1'>Initiate Time Lock</A>"
		var/second = time % 60
		var/minute = (time - second) / 60
		var/dat = "<HTML><HEAD></HEAD><BODY><TT><B>Party Button</B> [d1]\n<HR>\nTimer System: [d2]<BR>\nTime Left: [(minute ? "[minute]:" : null)][second] <A href='?src=\ref[src];tp=-30'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> <A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=30'>+</A>\n</TT></BODY></HTML>"

		user << browse(dat, "window=partyalarm")
		onclose(user, "partyalarm")
	else
		if(A.fire)
			d1 = "<A href='?src=\ref[src];reset=1'>[stars("No Party :(")]</A>"
		else
			d1 = "<A href='?src=\ref[src];alarm=1'>[stars("PARTY!!!")]</A>"
		if(timing)
			d2 = "<A href='?src=\ref[src];time=0'>[stars("Stop Time Lock")]</A>"
		else
			d2 = "<A href='?src=\ref[src];time=1'>[stars("Initiate Time Lock")]</A>"
		var/second = time % 60
		var/minute = (time - second) / 60
		var/dat = "<HTML><HEAD></HEAD><BODY><TT><B>[stars("Party Button")]</B> [d1]\n<HR>\nTimer System: [d2]<BR>\nTime Left: [(minute ? "[minute]:" : null)][second] <A href='?src=\ref[src];tp=-30'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> <A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=30'>+</A>\n</TT></BODY></HTML>"

		user << browse(dat, "window=partyalarm")
		onclose(user, "partyalarm")
	return

/obj/machinery/partyalarm/proc/reset()
	if(!(working))
		return
	var/area/A = get_area(src)
	ASSERT(isarea(A))
	A.partyreset()
	return

/obj/machinery/partyalarm/proc/alarm()
	if(!(working))
		return
	var/area/A = get_area(src)
	ASSERT(isarea(A))
	A.partyalert()
	return

/obj/machinery/partyalarm/Topic(href, href_list)
	..()
	if(usr.stat || machine_stat & (BROKEN|NOPOWER))
		return
	if((usr.contents.Find(src) || ((get_dist(src, usr) <= 1) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon/ai)))
		usr.machine = src
		if(href_list["reset"])
			reset()
		else if(href_list["alarm"])
			alarm()
		else if(href_list["time"])
			timing = text2num(href_list["time"])
		else if(href_list["tp"])
			var/tp = text2num(href_list["tp"])
			time += tp
			time = min(max(round(time), 0), 120)
		updateUsrDialog()

		add_fingerprint(usr)
	else
		usr << browse(null, "window=partyalarm")
		return
	return
