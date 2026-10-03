/**
 * # Inheritance
 *
 * A master names an heir among their disciples or sworn siblings. The moment the master dies, wherever the heir is,
 * a streak of light carries the master's cultivation to them: half of it, enough to fill the heir's foundation and guarantee their
 * next breakthrough (or Tribulation of Flesh), plus one of the master's laws if they have room. Gibbing or being devoured doesn't stop it.
 *
 * A Nascent Soul that is about to drag its owner back from death keeps everything instead. A master who passed on their cultivation
 * and is revived some other way starts again from the bottom.
 */

/// master mind -> heir mind
GLOBAL_LIST_EMPTY(cultivation_heirs)

/// Minds a master could name as heir: their disciples and sworn siblings, if they still have a body
/proc/cultivation_heir_candidates(datum/mind/master)
	. = list()
	var/datum/antagonist/cultivator/cultivator = master.has_antag_datum(/datum/antagonist/cultivator)
	var/datum/antagonist/body_cultivator/body_datum = master.has_antag_datum(/datum/antagonist/body_cultivator)
	var/list/minds = list()
	if(cultivator)
		minds |= cultivator.disciples
	if(body_datum)
		minds |= body_datum.disciples
	var/datum/sworn_bond/bond = sworn_bond_of(master)
	if(bond)
		minds |= bond.members
	minds -= master
	for(var/datum/mind/candidate as anything in minds)
		if(candidate.current)
			. += candidate

/datum/action/cooldown/name_heir
	name = "Name Your Heir"
	desc = "Choose one of your disciples or sworn siblings as your heir. The moment you die, wherever they are, half your cultivation flies to them: \
		their foundation fills, their next breakthrough is guaranteed, and they may learn one of your laws. You'd start again from nothing if revived. \
		Can't be changed while you're fighting."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "name_heir"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 10 SECONDS

/datum/action/cooldown/name_heir/Activate(atom/target)
	var/mob/living/master = owner
	if(master.combat_mode || GLOB.jianghu_duels[master])
		master.balloon_alert(master, "not while fighting!")
		return FALSE
	StartCooldown()
	INVOKE_ASYNC(src, PROC_REF(choose), master)
	return TRUE

/datum/action/cooldown/name_heir/proc/choose(mob/living/master)
	var/list/options = list()
	for(var/datum/mind/candidate as anything in cultivation_heir_candidates(master.mind))
		options["[candidate.name][GLOB.cultivation_heirs[master.mind] == candidate ? " (your heir)" : ""]"] = candidate
	if(GLOB.cultivation_heirs[master.mind])
		options["Name no heir"] = "none"
	if(!length(options))
		to_chat(master, span_warning("You have no disciples or sworn siblings to name as your heir. Accept a disciple, or swear brotherhood."))
		return
	var/choice = tgui_input_list(master, "Who will inherit your cultivation when you die?", "Name Your Heir", options)
	if(!choice || QDELETED(master))
		return
	var/datum/mind/heir = options[choice]
	if(heir == "none")
		GLOB.cultivation_heirs -= master.mind
		to_chat(master, span_notice("You name no heir. Your cultivation will die with you."))
		return
	GLOB.cultivation_heirs[master.mind] = heir
	to_chat(master, span_boldnotice("You name [heir.name] as your heir."))
	if(heir.current)
		to_chat(heir.current, span_boldnotice("You feel a thread of qi tie itself to your heart. [master.real_name] has named you [master.p_their()] heir."))
	master.log_message("named [key_name(heir)] as their cultivation heir", LOG_GAME)

/// A master died. Called from both paths' death handlers. Returns TRUE if the cultivation passed on.
/proc/cultivation_pass_on(mob/living/master, gibbed)
	var/datum/mind/master_mind = master?.mind
	var/datum/mind/heir_mind = GLOB.cultivation_heirs[master_mind]
	if(!heir_mind)
		return FALSE
	var/datum/antagonist/cultivator/master_qi = master_mind.has_antag_datum(/datum/antagonist/cultivator)
	var/datum/antagonist/body_cultivator/master_body = master_mind.has_antag_datum(/datum/antagonist/body_cultivator)
	// A Nascent Soul or Eternal Heart about to revive its owner keeps the cultivation where it is
	if(master_qi && !gibbed && master_qi.effective_realm() >= REALM_NASCENT_SOUL && COOLDOWN_FINISHED(master_qi, nascent_revival_cooldown))
		return FALSE
	if(master_body && !gibbed && body_group_level(master, "heart") >= 9 && COOLDOWN_FINISHED(master_body, eternal_heart_cooldown))
		return FALSE
	var/mob/living/heir = heir_mind.current
	if(!isliving(heir) || heir.stat == DEAD || !ishuman(heir))
		to_chat(master, span_warning("Your cultivation reaches for your heir... but finds no one living to receive it. It scatters."))
		GLOB.cultivation_heirs -= master_mind
		return FALSE
	GLOB.cultivation_heirs -= master_mind
	cultivation_inheritance_streak(master, heir)
	var/legacy_text = ""
	if(master_qi)
		legacy_text = inherit_from_qi(master_qi, heir)
	else if(master_body)
		legacy_text = inherit_from_body(master_body, heir)
	heir.apply_status_effect(/datum/status_effect/inheritance_blessing)
	to_chat(heir, span_boldnotice("A streak of light finds you and sinks into your chest. [master.real_name]'s cultivation is yours now. [legacy_text]"))
	to_chat(heir, span_notice("Your next breakthrough (or Tribulation of Flesh) cannot fail."))
	heir.log_message("inherited the cultivation of [key_name(master)]", LOG_GAME)
	master.log_message("passed their cultivation on to [key_name(heir)] on death", LOG_GAME)
	return TRUE

/// Half the master's qi cultivation goes to the heir (as tempering if the heir walks the path of the flesh)
/proc/inherit_from_qi(datum/antagonist/cultivator/master, mob/living/heir)
	var/legacy = master.total_progress() / 2
	var/datum/antagonist/body_cultivator/heir_body = IS_BODY_CULTIVATOR(heir)
	if(heir_body?.committed)
		heir_body.gain_tempering(BODY_TEMPERING_CAP, null)
		master.wipe_cultivation()
		return "It burns into your flesh as tempering."
	var/datum/antagonist/cultivator/heir_qi = IS_CULTIVATOR(heir) || heir.mind.add_antag_datum(/datum/antagonist/cultivator)
	var/next = heir_qi.next_threshold()
	if(next)
		heir_qi.progress = min(heir_qi.progress + legacy, next)
	else
		heir_qi.progress += legacy
	heir_qi.update_hud()
	var/learned = ""
	var/list/candidates = list()
	for(var/datum/cultivation_law/law as anything in master.laws)
		if(!heir_qi.has_law(law.type))
			candidates += law
	if(length(candidates) && length(heir_qi.laws) < heir_qi.law_slots())
		var/datum/cultivation_law/gift = pick(candidates)
		if(heir_qi.learn_law(gift.type, gift.counterfeit, feedback = FALSE))
			learned = " Your master's [gift.name] blooms in your meridians!"
	master.wipe_cultivation()
	return "Your foundation fills.[learned]"

/// Half the master's forged body goes to the heir as tempering, poured into their weakest parts
/proc/inherit_from_body(datum/antagonist/body_cultivator/master, mob/living/heir)
	var/legacy = round(master.total_invested() / 2)
	if(IS_CULTIVATOR(heir))
		var/datum/antagonist/cultivator/heir_qi = IS_CULTIVATOR(heir)
		var/next = heir_qi.next_threshold()
		heir_qi.progress = next ? min(heir_qi.progress + legacy, next) : heir_qi.progress + legacy
		heir_qi.update_hud()
		master.wipe_cultivation()
		return "It settles into your foundation as insight."
	var/datum/antagonist/body_cultivator/heir_body = IS_BODY_CULTIVATOR(heir) || heir.mind.add_antag_datum(/datum/antagonist/body_cultivator)
	var/poured = heir_body.pour_tempering(legacy)
	// Anything the parts can't hold yet waits as pending tempering
	heir_body.gain_tempering(legacy - poured, null, silent = TRUE)
	master.wipe_cultivation()
	return "It sinks into your bones and sinews."

/// The visible handoff: a streak of light from the body to the heir (or straight up, if they're on another level)
/proc/cultivation_inheritance_streak(mob/living/master, mob/living/heir)
	var/turf/start = get_turf(master)
	var/turf/finish = get_turf(heir)
	if(start)
		new /obj/effect/temp_visual/cultivation_ascension_pillar(start)
		master.visible_message(span_boldnotice("A streak of golden light tears free of [master]'s body and shoots away!"))
		playsound(start, 'sound/effects/magic/charge.ogg', 60, TRUE)
	if(start && finish && start.z == finish.z)
		var/obj/effect/temp_visual/inheritance_streak/streak = new(start)
		var/travel = clamp(get_dist(start, finish) * 0.08 SECONDS, 0.4 SECONDS, 2 SECONDS)
		animate(streak, pixel_x = (finish.x - start.x) * ICON_SIZE_X, pixel_y = (finish.y - start.y) * ICON_SIZE_Y, time = travel, easing = SINE_EASING | EASE_IN)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cultivation_inheritance_arrives), heir), travel)
	else
		cultivation_inheritance_arrives(heir)

/proc/cultivation_inheritance_arrives(mob/living/heir)
	if(QDELETED(heir))
		return
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(heir))
	new /obj/effect/temp_visual/cultivation_realm_banner(get_turf(heir), "Inheritance")
	cultivation_particles(heir, /particles/cultivation/gold, 3 SECONDS)
	cultivation_guqin_phrase(heir, list(6, 5, 3, 2, 1))
	heir.visible_message(span_boldnotice("A streak of golden light plunges into [heir]'s chest!"))

/obj/effect/temp_visual/inheritance_streak
	icon = 'surfshack13/icons/cultivation/cultivation_particles.dmi'
	icon_state = "gold_mote"
	duration = 2.2 SECONDS
	randomdir = FALSE
	layer = ABOVE_ALL_MOB_LAYER
	plane = ABOVE_GAME_PLANE
	light_system = OVERLAY_LIGHT
	light_range = 2
	light_power = 1.5
	light_color = "#ffe27a"

/obj/effect/temp_visual/inheritance_streak/Initialize(mapload)
	. = ..()
	transform = matrix().Scale(3)
	cultivation_particles(src, /particles/cultivation/gold)

/// The heir's next breakthrough can't fail
/datum/status_effect/inheritance_blessing
	id = "inheritance_blessing"
	alert_type = null
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK
	status_type = STATUS_EFFECT_REFRESH

// ===================== Bookkeeping on each path =====================

/datum/antagonist/cultivator
	/// Minds we've accepted as disciples
	var/list/datum/mind/disciples = list()

/datum/antagonist/body_cultivator
	/// Minds we've accepted as disciples
	var/list/datum/mind/disciples = list()

/// Every point of insight consolidated, across all the realms climbed so far
/datum/antagonist/cultivator/proc/total_progress()
	. = progress
	for(var/reached in 2 to realm)
		. += realm_thresholds[reached]

/// The cultivation has left this body: back to the very start of the path
/datum/antagonist/cultivator/proc/wipe_cultivation()
	realm = REALM_QI_CONDENSATION
	progress = 0
	pending_insight = 0
	qi = 0
	var/obj/item/organ/dantian/dantian = get_dantian()
	dantian?.set_grade(REALM_QI_CONDENSATION)
	// Only the first law the meridians ever held stays
	while(length(laws) > law_slots())
		var/datum/cultivation_law/lost = laws[length(laws)]
		laws -= lost
		var/mob/living/body = owner.current
		if(body)
			lost.on_body_lost(body, src)
		qdel(lost)
	for(var/datum/action/technique as anything in techniques.Copy())
		if(required_realm_for(technique.type) > realm)
			qdel(technique)
	update_light_body()
	update_hud()

/// Tempering already forged into every part, as a number of tempering points
/datum/antagonist/body_cultivator/proc/total_invested()
	. = 0
	var/list/parts = body_forgeable_parts(owner.current)
	for(var/part_name in parts)
		var/obj/item/part = parts[part_name]
		var/datum/component/body_tempering/part_tempering = part.GetComponent(/datum/component/body_tempering)
		if(!part_tempering)
			continue
		. += part_tempering.progress
		for(var/level in 1 to part_tempering.level)
			. += BODY_PART_COST(level)

/// Pour tempering straight into the parts with the most room (as far as the cap allows). Returns how much was used.
/datum/antagonist/body_cultivator/proc/pour_tempering(amount)
	var/mob/living/carbon/body = owner.current
	if(!istype(body) || amount <= 0)
		return 0
	// Forge from the gift alone, leaving whatever was already pending untouched
	var/pending = tempering
	tempering = amount
	for(var/safety in 1 to 100)
		var/obj/item/roomiest
		var/most_room = 0
		var/list/parts = body_forgeable_parts(body)
		for(var/part_name in parts)
			var/obj/item/part = parts[part_name]
			var/datum/component/body_tempering/part_tempering = part.GetComponent(/datum/component/body_tempering) || part.AddComponent(/datum/component/body_tempering)
			var/room = part_tempering.room_until(part_cap())
			if(room > most_room)
				most_room = room
				roomiest = part
		if(!roomiest || tempering < 1)
			break
		forge_part(roomiest, 25)
	. = amount - tempering
	tempering = pending
	update_hud()

/// The forged body has left: every part returns to plain flesh
/datum/antagonist/body_cultivator/proc/wipe_cultivation()
	stage = 0
	tempering = 0
	var/list/parts = body_forgeable_parts(owner.current)
	for(var/part_name in parts)
		var/obj/item/part = parts[part_name]
		qdel(part.GetComponent(/datum/component/body_tempering))
	for(var/datum/action/technique as anything in techniques.Copy())
		if(body_techniques[technique.type] > stage)
			qdel(technique)
	apply_stage_benefits()
	update_hud()
