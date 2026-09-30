// Gangtool: the gang leadership's shop, messenger and shuttle recaller.

/obj/item/gangtool
	name = "suspicious device"
	desc = "A strange device of sorts. Hard to really make out what it actually does if you don't know how to operate it."
	icon = 'surfshack13/icons/hippie/gang_items.dmi'
	icon_state = "gangtool"
	inhand_icon_state = "radio"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	obj_flags = CONDUCTS_ELECTRICITY
	/// Which gang this is registered to
	var/datum/team/gang/gang
	/// Whether a recall is in progress
	var/recalling = FALSE
	/// The next recruitment pen from this tool is free
	var/free_pen = FALSE
	/// Registering this tool promotes a gangster to lieutenant
	var/promotable = FALSE
	/// category = list(id = /datum/gang_item)
	var/list/buyable_items = list()

/obj/item/gangtool/Initialize(mapload)
	. = ..()
	for(var/datum/gang_item/item_type as anything in subtypesof(/datum/gang_item))
		var/id = initial(item_type.id)
		if(!id)
			continue
		var/category = initial(item_type.category)
		LAZYINITLIST(buyable_items[category])
		buyable_items[category][id] = new item_type()
	update_appearance()

/obj/item/gangtool/Destroy()
	gang?.gangtools -= src
	gang = null
	for(var/category in buyable_items)
		QDEL_LIST_ASSOC_VAL(buyable_items[category])
	buyable_items.Cut()
	return ..()

/obj/item/gangtool/update_overlays()
	. = ..()
	var/mutable_appearance/light = mutable_appearance(icon, "[icon_state]-overlay")
	if(gang)
		light.color = gang.color
	. += light

/obj/item/gangtool/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return
	if(!can_use(user))
		return TRUE
	show_menu(user)
	return TRUE

/obj/item/gangtool/proc/show_menu(mob/user)
	var/datum/antagonist/gang/boss/leader = user.mind.has_antag_datum(/datum/antagonist/gang/boss)
	var/list/dat = list()
	if(!gang)
		dat += "This device is not registered.<br><br>"
		if(leader)
			if(promotable && length(leader.gang.leaders) < leader.gang.max_leaders)
				dat += "Give this device to another member of your organization to use to promote them to Lieutenant.<br><br>"
				dat += "If this is meant as a spare device for yourself:<br>"
			dat += "<a href='byond://?src=[REF(src)];register=1'>Register Device as Spare</a><br>"
		else if(promotable)
			var/datum/antagonist/gang/member = user.mind.has_antag_datum(/datum/antagonist/gang)
			if(length(member.gang.leaders) < member.gang.max_leaders)
				dat += "You have been selected for a promotion!<br>"
				dat += "<a href='byond://?src=[REF(src)];register=1'>Accept Promotion</a><br>"
			else
				dat += "No promotions available: All positions filled.<br>"
		else
			dat += "This device is not authorized to promote.<br>"
	else
		if(gang.domination_time != GANG_NOT_DOMINATING)
			dat += "<center><font color='red'>Takeover In Progress:<br><b>[DisplayTimeText(gang.domination_time_remaining() SECONDS)] remain</b></font></center>"
		dat += "Registration: <b>[gang.name] Gang Boss</b><br>"
		dat += "Organization Size: <b>[length(gang.members)]</b> | Station Control: <b>[length(gang.territories)] territories under control.</b> | Influence: <b>[gang.influence]</b><br>"
		dat += "Time until Influence grows: <b>[time2text(max(0, gang.next_point_time - world.time), "mm:ss", 0)]</b><br>"
		dat += "<a href='byond://?src=[REF(src)];commute=1'>Send message to Gang</a><br>"
		dat += "<a href='byond://?src=[REF(src)];recall=1'>Recall shuttle</a><br>"
		dat += "<hr>"
		for(var/category in buyable_items)
			dat += "<b>[category]</b><br>"
			for(var/id in buyable_items[category])
				var/datum/gang_item/item = buyable_items[category][id]
				if(!item.can_see(user, gang, src))
					continue
				var/cost = item.get_cost_display(user, gang, src)
				if(cost)
					dat += "[cost] "
				var/item_name = item.get_name_display(user, gang, src)
				if(item.can_buy(user, gang, src))
					item_name = "<a href='byond://?src=[REF(src)];purchase=1;id=[id];cat=[url_encode(category)]'>[item_name]</a>"
				dat += item_name
				var/extra = item.get_extra_info(user, gang, src)
				if(extra)
					dat += "<br><i>[extra]</i>"
				dat += "<br>"
			dat += "<br>"
	dat += "<a href='byond://?src=[REF(src)];refresh=1'>Refresh</a><br>"
	var/datum/browser/popup = new(user, "gangtool", "Welcome to GangTool v4.0", 340, 625)
	popup.set_content(dat.Join())
	popup.open()

/obj/item/gangtool/Topic(href, href_list)
	. = ..()
	var/mob/user = usr
	if(!can_use(user))
		return
	add_fingerprint(user)
	if(href_list["register"])
		register_device(user)
	else if(!gang)
		return
	if(href_list["purchase"])
		var/list/category = buyable_items[url_decode(href_list["cat"])]
		var/datum/gang_item/item = category?[href_list["id"]]
		if(item?.can_buy(user, gang, src))
			item.purchase(user, gang, src)
	if(href_list["commute"])
		ping_gang(user)
	if(href_list["recall"])
		recall(user)
	show_menu(user)

/// Sends a gang-wide message
/obj/item/gangtool/proc/ping_gang(mob/user)
	var/message = tgui_input_text(user, "Discreetly send a gang-wide message.", "Send Message")
	if(!message || !can_use(user))
		return
	if(!is_station_level(user.z))
		to_chat(user, span_info("[icon2html(src, user)]Error: Station out of range."))
		return
	var/datum/antagonist/gang/sender = user.mind.has_antag_datum(/datum/antagonist/gang)
	if(!sender)
		return
	var/ping = span_danger("<b><i>[gang.name] [sender.message_name] [user.real_name]</i>: [message]</b>")
	for(var/datum/mind/gangster as anything in gang.members)
		if(gangster.current && is_station_level(gangster.current.z) && gangster.current.stat == CONSCIOUS)
			to_chat(gangster.current, ping)
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		to_chat(ghost, "[FOLLOW_LINK(ghost, user)] [ping]")
	user.log_talk(message, LOG_SAY, tag = "[gang.name] gangster")

/obj/item/gangtool/proc/register_device(mob/user)
	if(gang)
		return
	var/datum/antagonist/gang/member = user.mind?.has_antag_datum(/datum/antagonist/gang)
	if(!member)
		to_chat(user, span_warning("ACCESS DENIED: Unauthorized user."))
		return
	gang = member.gang
	gang.gangtools += src
	update_appearance()
	if(promotable && !(user.mind in gang.leaders))
		member.promote()
		free_pen = TRUE
		gang.message_gangtools("[user] has been promoted to Lieutenant.")
		to_chat(user, "The <b>Gangtool</b> you registered will allow you to purchase weapons and equipment, and send messages to your gang.")
		to_chat(user, "Unlike regular gangsters, you may use <b>recruitment pens</b> to add recruits to your gang. Use them on unsuspecting crew members to recruit them. Don't forget to get your one free pen from the gangtool.")

/obj/item/gangtool/proc/recall(mob/user)
	if(!recall_checks(user))
		return
	if(recalling)
		to_chat(user, span_warning("Error: Recall already in progress."))
		return
	gang.message_gangtools("[user] is attempting to recall the emergency shuttle.")
	recalling = TRUE
	to_chat(user, span_info("[icon2html(src, user)]Generating shuttle recall order with codes retrieved from last call signal..."))
	addtimer(CALLBACK(src, PROC_REF(recall_step), user, 1), rand(10 SECONDS, 30 SECONDS))

/obj/item/gangtool/proc/recall_step(mob/user, step)
	if(!recall_checks(user))
		recalling = FALSE
		return
	switch(step)
		if(1)
			to_chat(user, span_info("[icon2html(src, user)]Shuttle recall order generated. Accessing station long-range communication arrays..."))
		if(2)
			var/living_crew = 0
			for(var/mob/player as anything in GLOB.player_list)
				if(player.mind && player.stat != DEAD && isliving(player) && !isbrain(player))
					living_crew++
			if(living_crew / max(1, length(GLOB.joined_player_list)) <= 0.7) // Hippie read this ratio from config; Surf no longer has that entry
				to_chat(user, span_warning("[icon2html(src, user)]Error: Station communication systems compromised. Unable to establish connection."))
				recalling = FALSE
				return
			to_chat(user, span_info("[icon2html(src, user)]Comm arrays accessed. Broadcasting recall signal..."))
		if(3)
			recalling = FALSE
			log_game("[key_name(user)] has tried to recall the shuttle with a gangtool.")
			message_admins("[ADMIN_LOOKUPFLW(user)] has tried to recall the shuttle with a gangtool.")
			if(SSshuttle.cancelEvac(user))
				gang.recalls--
			else
				to_chat(user, span_info("[icon2html(src, user)]No response received. Emergency shuttle cannot be recalled at this time."))
			return
	addtimer(CALLBACK(src, PROC_REF(recall_step), user, step + 1), rand(10 SECONDS, 30 SECONDS))

/obj/item/gangtool/proc/recall_checks(mob/user)
	if(!can_use(user) || SSshuttle.emergency_no_recall)
		return FALSE
	if(!gang.recalls || !gang.dom_attempts)
		to_chat(user, span_warning("Error: Unable to access communication arrays. Firewall has logged our signature and is blocking all further attempts."))
		return FALSE
	if(SSshuttle.emergency.mode != SHUTTLE_CALL)
		to_chat(user, span_warning("[icon2html(src, user)]Emergency shuttle cannot be recalled at this time."))
		return FALSE
	if(!is_station_level(user.z))
		to_chat(user, span_warning("[icon2html(src, user)]Error: Device out of range of station communication arrays."))
		return FALSE
	return TRUE

/obj/item/gangtool/proc/can_use(mob/living/carbon/human/user)
	if(!istype(user) || user.incapacitated || !user.mind || !(src in user.get_all_contents()))
		return FALSE
	var/datum/antagonist/gang/member = user.mind.has_antag_datum(/datum/antagonist/gang)
	if(!member)
		to_chat(user, span_notice("Huh, what's this?"))
		return FALSE
	if(gang && member.gang != gang)
		to_chat(user, span_danger("You cannot use gang tools owned by enemy gangs!"))
		return FALSE
	return TRUE

/// Spare gangtools bought from the shop
/obj/item/gangtool/spare

/// Spares that promote whoever registers them
/obj/item/gangtool/spare/lieutenant
	promotable = TRUE
