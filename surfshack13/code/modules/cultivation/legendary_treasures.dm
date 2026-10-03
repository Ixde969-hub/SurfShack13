/**
 * Six more legendary treasures, joining the nine in legendary_artifacts.dm in the same spawn pool.
 * Each has one clear gimmick and one clear counter.
 */

// ===================== Xuanyuan Sword =====================

/obj/item/cultivation_artifact/xuanyuan_sword
	name = "Xuanyuan Sword"
	desc = "A broad golden jian engraved with the sun, moon and stars on one face and mountains and rivers on the other. It is unbearably heavy with authority."
	icon_state = "xuanyuan_sword"
	inhand_icon_state = "claymore_gold"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 18
	throwforce = 15
	armour_penetration = 40
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	block_chance = 25
	attack_verb_continuous = list("smites", "cleaves", "judges")
	attack_verb_simple = list("smite", "cleave", "judge")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	legend = "The sword of the Yellow Emperor, first ruler under heaven. It answers only to the one heaven has mandated."
	power_text = "In the hands of the Son of Heaven (the captain bearing the Mandate) every blow staggers and knocks down, and cuts through Iron Shirt. \
		Anyone else who picks it up is burned by its authority, and it is just a heavy sword in their hands."
	legendary_traits = LEGENDARY_BREAKS_DEFENCE

/// Is this person the one heaven has mandated?
/proc/xuanyuan_worthy(mob/living/user)
	var/datum/component/mandate_of_heaven/mandate = user?.GetComponent(/datum/component/mandate_of_heaven)
	return mandate?.son_of_heaven

/obj/item/cultivation_artifact/xuanyuan_sword/pickup(mob/user)
	. = ..()
	if(xuanyuan_worthy(user))
		to_chat(user, span_boldnotice("The Xuanyuan Sword settles into your hand as if it had been waiting for you. Heaven approves."))
		add_filter("xuanyuan_glow", 2, list("type" = "outline", "color" = "#ffd55a", "size" = 1))
		return
	if(isliving(user))
		var/mob/living/unworthy = user
		unworthy.apply_damage(15, BURN, unworthy.get_active_hand()?.body_zone || BODY_ZONE_CHEST)
		to_chat(unworthy, span_userdanger("The hilt blazes like the sun! The Xuanyuan Sword does not accept you."))
		playsound(src, 'sound/effects/wounds/sizzle1.ogg', 50, TRUE)

/obj/item/cultivation_artifact/xuanyuan_sword/dropped(mob/user, silent)
	. = ..()
	remove_filter("xuanyuan_glow")

/obj/item/cultivation_artifact/xuanyuan_sword/afterattack(atom/target, mob/user, click_parameters)
	. = ..()
	if(!isliving(target) || !xuanyuan_worthy(user))
		return
	var/mob/living/victim = target
	legendary_hit(user, victim, 14, 1 SECONDS, name, src)
	victim.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(victim))
	playsound(victim, 'sound/effects/gong.ogg', 30, TRUE, frequency = 1.4)

// ===================== Green Dragon Crescent Blade =====================

/obj/item/cultivation_artifact/green_dragon_blade
	name = "Green Dragon Crescent Blade"
	desc = "A towering guandao with a crescent blade and a green dragon coiled at its base. It weighs eighty-two jin and it is not for the dishonourable."
	icon_state = "green_dragon_blade"
	inhand_icon_state = "military_spear0"
	lefthand_file = 'icons/mob/inhands/weapons/polearms_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/polearms_righthand.dmi'
	force = 10
	throwforce = 15
	armour_penetration = 40
	w_class = WEIGHT_CLASS_HUGE
	slot_flags = ITEM_SLOT_BACK
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("cleaves", "sweeps", "hews")
	attack_verb_simple = list("cleave", "sweep", "hew")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	legend = "The blade of Guan Yu, the God of War, the most loyal man under heaven."
	power_text = "Wield it in both hands to strike two tiles away. Its blows grow with the wielder's face in the jianghu, and fade for the shamed. \
		They wear a body cultivator down."
	legendary_traits = LEGENDARY_WEARS_DOWN

/obj/item/cultivation_artifact/green_dragon_blade/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded = 10, force_wielded = 24, icon_wielded = "green_dragon_blade", wield_callback = CALLBACK(src, PROC_REF(on_wield)), unwield_callback = CALLBACK(src, PROC_REF(on_unwield)))

/obj/item/cultivation_artifact/green_dragon_blade/proc/on_wield(obj/item/source, mob/living/carbon/user)
	reach = 2
	inhand_icon_state = "military_spear1"

/obj/item/cultivation_artifact/green_dragon_blade/proc/on_unwield(obj/item/source, mob/living/carbon/user)
	reach = 1
	inhand_icon_state = "military_spear0"

/// The blade's bite follows its wielder's honour: 4 for the disgraced, up to 24 for a martial legend
/obj/item/cultivation_artifact/green_dragon_blade/proc/honour_damage(mob/living/user)
	return clamp(10 + round(jianghu_face_of(user?.mind) / 2), 4, 24)

/obj/item/cultivation_artifact/green_dragon_blade/examine(mob/user)
	. = ..()
	. += span_notice("In your hands its legendary blows would deal [honour_damage(user)] (your face: [jianghu_face_of(user?.mind)]).")

/obj/item/cultivation_artifact/green_dragon_blade/afterattack(atom/target, mob/user, click_parameters)
	. = ..()
	if(!isliving(target) || !HAS_TRAIT(src, TRAIT_WIELDED))
		return
	var/mob/living/victim = target
	legendary_hit(user, victim, honour_damage(user), 0, name, src)
	new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), "#7fe0a0")

// ===================== Seven-Star Sword =====================

/obj/item/cultivation_artifact/seven_star_sword
	name = "Seven-Star Sword"
	desc = "A dark jian inlaid with seven golden studs in the shape of the Northern Dipper. Each one glows a little brighter with every blow."
	icon_state = "seven_star_sword"
	inhand_icon_state = "katana"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 20
	throwforce = 15
	armour_penetration = 30
	w_class = WEIGHT_CLASS_NORMAL
	sharpness = SHARP_EDGED
	block_chance = 20
	attack_verb_continuous = list("slashes", "pierces", "cuts")
	attack_verb_simple = list("slash", "pierce", "cut")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	legend = "Cao Cao's treasured sword, whose seven stars are said to hold the power of the Northern Dipper."
	power_text = "Every blow on someone lights one of its seven stars. With all seven lit, click any spot to release the Seven Stars: \
		a burst of starlight that cuts everyone in a line, then the stars go dark again."
	/// Stars lit, 0 to 7
	var/stars = 0

/obj/item/cultivation_artifact/seven_star_sword/examine(mob/user)
	. = ..()
	. += span_notice("[stars] of its seven stars are lit.")

/obj/item/cultivation_artifact/seven_star_sword/proc/update_stars()
	remove_filter("seven_stars")
	if(stars)
		add_filter("seven_stars", 2, list("type" = "outline", "color" = "#ffe27a", "size" = 1, "alpha" = 30 * stars))

/obj/item/cultivation_artifact/seven_star_sword/afterattack(atom/target, mob/user, click_parameters)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/victim = target
	legendary_hit(user, victim, 8, 0, name, src)
	if(stars >= 7)
		return
	stars++
	update_stars()
	new /obj/effect/temp_visual/cultivation_spark(get_turf(user), "#ffe27a", rand(-8, 8), rand(4, 14))
	if(stars == 7)
		to_chat(user, span_boldnotice("All seven stars blaze! Click a spot to release them."))
		playsound(user, 'sound/runtime/instruments/synthesis_samples/chromatic/fluid_celeste/C5.ogg', 50, FALSE)
	else
		to_chat(user, span_notice("Star [stars] of seven lights up."))

/obj/item/cultivation_artifact/seven_star_sword/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(stars < 7)
		user.balloon_alert(user, "[stars] of 7 stars lit")
		return ITEM_INTERACT_BLOCKING
	var/direction = get_dir(user, interacting_with)
	if(!direction)
		return NONE
	stars = 0
	update_stars()
	user.say("SEVEN STARS OF THE NORTHERN DIPPER!!", forced = "seven-star sword")
	user.visible_message(span_boldwarning("[user] thrusts the Seven-Star Sword forward and a river of starlight pours out of it!"))
	playsound(user, 'sound/effects/magic/charge.ogg', 70, TRUE, frequency = 1.3)
	user.do_attack_animation(get_step(user, direction))
	var/turf/next = get_turf(user)
	for(var/i in 1 to 7)
		next = get_step(next, direction)
		if(!next || isclosedturf(next))
			break
		addtimer(CALLBACK(src, PROC_REF(starburst), user, next), i * 0.08 SECONDS)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/seven_star_sword/proc/starburst(mob/living/user, turf/where)
	new /obj/effect/temp_visual/cultivation_spark(where, "#ffe27a")
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(where)
	for(var/mob/living/victim in where)
		if(victim != user)
			legendary_hit(user, victim, 22, 1 SECONDS, "the Seven Stars", src)

// ===================== Linglong Pagoda =====================

/obj/item/cultivation_artifact/linglong_pagoda
	name = "Linglong Pagoda"
	desc = "A small golden pagoda of seven exquisite tiers, cool and heavy in the hand. Something about its doors makes you not want to look too closely."
	icon_state = "linglong_pagoda"
	w_class = WEIGHT_CLASS_SMALL
	force = 5
	throwforce = 8
	throw_range = 7
	legend = "Li Jing, the Pagoda-Bearing Heavenly King, holds it in his palm. Whoever it falls upon is sealed inside."
	power_text = "Throw it at someone: they are sealed inside for twenty seconds, harmless and unharmable, and come out dazed. Armour or a qi ward makes it miss, \
		and it needs a minute and a half to open its doors again."
	/// Who's sealed inside
	var/mob/living/sealed
	COOLDOWN_DECLARE(seal_cooldown)

/obj/item/cultivation_artifact/linglong_pagoda/Destroy()
	release()
	return ..()

/obj/item/cultivation_artifact/linglong_pagoda/examine(mob/user)
	. = ..()
	if(sealed)
		. += span_warning("Someone is sealed inside. Its doors won't open for another few seconds.")
	else if(!COOLDOWN_FINISHED(src, seal_cooldown))
		. += span_notice("Its doors are still closed.")

/obj/item/cultivation_artifact/linglong_pagoda/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!isliving(hit_atom) || sealed || !COOLDOWN_FINISHED(src, seal_cooldown))
		return
	var/mob/living/victim = hit_atom
	if(victim.has_status_effect(/datum/status_effect/still_water_ward) || victim.has_status_effect(/datum/status_effect/golden_bell) || victim.run_armor_check(BODY_ZONE_CHEST, MELEE, silent = TRUE) >= 50)
		victim.visible_message(span_warning("[src] bounces off [victim]'s defences!"))
		return
	seal(victim, throwingdatum?.get_thrower())

/obj/item/cultivation_artifact/linglong_pagoda/proc/seal(mob/living/victim, mob/living/thrower)
	COOLDOWN_START(src, seal_cooldown, 90 SECONDS)
	sealed = victim
	anchored = TRUE
	victim.visible_message(span_boldwarning("[src] swells into a towering golden pagoda and slams down over [victim]!"), span_userdanger("A golden pagoda crashes down around you! You're sealed inside!"))
	cultivation_great_bell(src, 50)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(src))
	victim.forceMove(src)
	transform = matrix().Scale(2)
	add_filter("pagoda_seal", 2, list("type" = "outline", "color" = "#ffd55a", "size" = 2))
	if(thrower)
		log_combat(thrower, victim, "sealed in the Linglong Pagoda")
	addtimer(CALLBACK(src, PROC_REF(release)), 20 SECONDS)

/obj/item/cultivation_artifact/linglong_pagoda/proc/release()
	var/mob/living/freed = sealed
	sealed = null
	anchored = FALSE
	transform = matrix()
	remove_filter("pagoda_seal")
	if(QDELETED(freed) || freed.loc != src)
		return
	freed.forceMove(drop_location())
	freed.visible_message(span_warning("The pagoda's doors swing open and [freed] staggers out!"), span_warning("The doors open. Your head is ringing."))
	freed.adjust_confusion(5 SECONDS)
	freed.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(src))

/obj/item/cultivation_artifact/linglong_pagoda/attack_hand(mob/user, list/modifiers)
	if(sealed)
		to_chat(user, span_warning("The pagoda is far too heavy to lift while it holds someone."))
		return TRUE
	return ..()

/obj/item/cultivation_artifact/linglong_pagoda/relaymove(mob/living/user, direction)
	return

/obj/item/cultivation_artifact/linglong_pagoda/container_resist_act(mob/living/user)
	to_chat(user, span_warning("You push at the golden doors. They won't move until the pagoda decides."))

// ===================== Universe Ring =====================

/obj/item/cultivation_artifact/universe_ring
	name = "Universe Ring"
	desc = "A heavy golden bracelet, as wide as a palm. It hums when it's thrown, and it always knows its way home."
	icon_state = "universe_ring"
	w_class = WEIGHT_CLASS_SMALL
	force = 8
	throwforce = 10
	throw_range = 8
	throw_speed = 3
	legend = "Nezha's Qiankun Quan, the Heaven and Earth Ring. Thrown, it smashes one demon after another and returns to his hand."
	power_text = "Throw it: after the first hit it ricochets to up to two more people nearby, then flies back to you. Keep a hand free to catch it."
	/// Who threw it this time
	var/datum/weakref/thrower_ref
	/// People already hit on this throw
	var/list/hit_this_throw = list()
	var/bounces_left = 0

/obj/item/cultivation_artifact/universe_ring/on_thrown(mob/living/carbon/user, atom/target)
	. = ..()
	if(!thrower_ref || thrower_ref.resolve() != user)
		thrower_ref = WEAKREF(user)
		hit_this_throw = list()
		bounces_left = 2

/obj/item/cultivation_artifact/universe_ring/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/mob/living/thrower = thrower_ref?.resolve()
	if(isliving(hit_atom) && thrower && hit_atom != thrower)
		var/mob/living/victim = hit_atom
		hit_this_throw += victim
		legendary_hit(thrower, victim, 12, 0.5 SECONDS, name, src)
		playsound(victim, 'sound/effects/gong.ogg', 30, TRUE, frequency = 1.8)
		new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(victim))
	addtimer(CALLBACK(src, PROC_REF(next_flight)), 0.2 SECONDS)

/// Ricochet to the next victim, or fly home
/obj/item/cultivation_artifact/universe_ring/proc/next_flight()
	if(QDELETED(src) || !isturf(loc))
		return
	var/mob/living/thrower = thrower_ref?.resolve()
	if(bounces_left > 0)
		for(var/mob/living/next_victim in view(4, src))
			if(next_victim == thrower || next_victim.stat == DEAD || (next_victim in hit_this_throw))
				continue
			bounces_left--
			throw_at(next_victim, 5, 3, thrower, spin = TRUE)
			return
	bounces_left = 0
	hit_this_throw = list()
	thrower_ref = null
	if(QDELETED(thrower) || thrower.z != z || get_dist(src, thrower) > 10)
		return
	RegisterSignal(src, COMSIG_MOVABLE_PRE_IMPACT, PROC_REF(on_return_impact), override = TRUE)
	throw_at(thrower, 10, 3, thrower, spin = TRUE, gentle = TRUE, callback = CALLBACK(src, PROC_REF(landed_home)))

/obj/item/cultivation_artifact/universe_ring/proc/on_return_impact(datum/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	UnregisterSignal(src, COMSIG_MOVABLE_PRE_IMPACT)
	if(!isliving(hit_atom))
		return NONE
	var/mob/living/catcher = hit_atom
	INVOKE_ASYNC(src, PROC_REF(caught_by), catcher)
	return COMPONENT_MOVABLE_IMPACT_NEVERMIND

/obj/item/cultivation_artifact/universe_ring/proc/caught_by(mob/living/catcher)
	if(catcher.put_in_hands(src))
		catcher.visible_message(span_notice("[catcher] snatches [src] out of the air."))
	else
		forceMove(catcher.drop_location())
		catcher.visible_message(span_warning("[src] clangs off [catcher] and drops at [catcher.p_their()] feet."))

/obj/item/cultivation_artifact/universe_ring/proc/landed_home()
	UnregisterSignal(src, COMSIG_MOVABLE_PRE_IMPACT)

// ===================== Wind Fire Wheels =====================

/obj/item/clothing/shoes/wind_fire_wheels
	name = "Wind Fire Wheels"
	desc = "A pair of spinning wheels wreathed in flame, worn on the feet. They want to go fast. They do not want to stop."
	icon = 'surfshack13/icons/cultivation/cultivation_artifacts.dmi'
	icon_state = "wind_fire_wheels"
	worn_icon_state = "wheelys"
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	clothing_traits = list(TRAIT_NO_SLIP_WATER)

/obj/item/clothing/shoes/wind_fire_wheels/Initialize(mapload)
	. = ..()
	GLOB.legendary_artifacts += src

/obj/item/clothing/shoes/wind_fire_wheels/Destroy()
	GLOB.legendary_artifacts -= src
	return ..()

/obj/item/clothing/shoes/wind_fire_wheels/examine(mob/user)
	. = ..()
	. += span_notice("Worn, you move far faster and leave burning footprints behind you, and you sometimes skid a step further than you meant to.")
	if(IS_CULTIVATOR(user) || IS_BODY_CULTIVATOR(user) || isobserver(user))
		. += span_notice("<i>Nezha's wheels of wind and fire, which carried the boy god across heaven and earth.</i>")

/obj/item/clothing/shoes/wind_fire_wheels/equipped(mob/living/user, slot, initial)
	. = ..()
	if(!(slot & ITEM_SLOT_FEET))
		return
	user.add_movespeed_modifier(/datum/movespeed_modifier/wind_fire_wheels)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_wearer_moved), override = TRUE)
	user.add_filter("wind_fire_wheels", 2, list("type" = "outline", "color" = "#ff7a2c", "size" = 1, "alpha" = 120))
	to_chat(user, span_notice("The wheels spin up with a roar of flame!"))

/obj/item/clothing/shoes/wind_fire_wheels/dropped(mob/living/user, silent)
	. = ..()
	user.remove_movespeed_modifier(/datum/movespeed_modifier/wind_fire_wheels)
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	user.remove_filter("wind_fire_wheels")

/obj/item/clothing/shoes/wind_fire_wheels/proc/on_wearer_moved(mob/living/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	var/turf/open/trail = old_loc
	if(istype(trail) && !(locate(/obj/effect/cultivation_molten_step) in trail))
		var/obj/effect/cultivation_molten_step/flames = new(trail, source)
		flames.dir = dir
	// They don't like to stop: sometimes you carry on a step further
	if(!forced && dir && prob(15) && !source.buckled && !source.pulledby)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(wind_fire_skid), source, dir), 0.1 SECONDS)

/proc/wind_fire_skid(mob/living/rider, direction)
	if(QDELETED(rider) || rider.stat != CONSCIOUS)
		return
	var/turf/next = get_step(rider, direction)
	if(!next || next.is_blocked_turf(exclude_mobs = FALSE))
		rider.visible_message(span_warning("[rider]'s wheels skid and [rider.p_they()] slam[rider.p_s()] into [next || "the wall"]!"))
		rider.Knockdown(1 SECONDS)
		return
	step(rider, direction)

/datum/movespeed_modifier/wind_fire_wheels
	multiplicative_slowdown = -0.5
