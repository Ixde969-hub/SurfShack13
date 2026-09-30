// Interdimensional Sword - ported from HippieStation.
// A huge flaming sword punches out of a portal in front of the caster, tearing through walls,
// annihilating objects and burning, cutting or dismembering anyone in the way.

#define BFS_LENGTH 11

/datum/action/cooldown/spell/interdimensional_sword
	name = "Interdimensional Sword"
	desc = "Summons a humungous, flaming sword from another dimension."
	sound = 'sound/effects/magic/clockwork/invoke_general.ogg'
	school = SCHOOL_EVOCATION
	cooldown_time = 25 SECONDS
	cooldown_reduction_per_rank = 3.5 SECONDS
	spell_requirements = SPELL_REQUIRES_HUMAN|SPELL_REQUIRES_NO_ANTIMAGIC

/datum/action/cooldown/spell/interdimensional_sword/cast(atom/cast_on)
	. = ..()
	var/mob/living/caster = owner
	var/direction = caster.dir
	var/turf/start = get_turf(caster)
	caster.visible_message(span_bolddanger("[caster] summons the Interdimensional Sword!"))
	var/turf/tip_turf = get_ranged_target_turf(start, direction, BFS_LENGTH)
	var/turf/hilt_turf = get_ranged_target_turf(tip_turf, REVERSE_DIR(direction), BFS_LENGTH - 1)
	var/obj/effect/bfs_portal/start_portal = new(hilt_turf, REVERSE_DIR(direction))
	var/obj/effect/bfs_portal/end_portal = new(tip_turf, direction)
	QDEL_IN(start_portal, BFS_LENGTH * 2)
	QDEL_IN(end_portal, BFS_LENGTH * 2)
	extend_sword(start, direction, 1, FALSE)

/// Grows the blade one tile per tick until full length, then retracts it back into the portal.
/datum/action/cooldown/spell/interdimensional_sword/proc/extend_sword(turf/origin, direction, amount, retracting)
	var/turf/tip = get_ranged_target_turf(origin, direction, amount)
	var/turf/full_tip = get_ranged_target_turf(origin, direction, BFS_LENGTH)
	var/turf/hilt = get_ranged_target_turf(full_tip, REVERSE_DIR(direction), amount)
	if(!retracting)
		INVOKE_ASYNC(src, PROC_REF(damage_turf), tip)
		new /obj/effect/temp_visual/bfs/tip(tip, direction)
		for(var/turf/blade_turf as anything in get_line(get_step(origin, direction), tip) - tip)
			new /obj/effect/temp_visual/bfs/blade(blade_turf, direction)
		addtimer(CALLBACK(src, PROC_REF(extend_sword), origin, direction, amount < BFS_LENGTH ? amount + 1 : amount, amount >= BFS_LENGTH), 0.1 SECONDS)
		return
	for(var/turf/blade_turf as anything in get_line(hilt, full_tip) - hilt)
		new /obj/effect/temp_visual/bfs/blade(blade_turf, direction)
	new /obj/effect/temp_visual/bfs/hilt(hilt, direction)
	if(amount > 0)
		addtimer(CALLBACK(src, PROC_REF(extend_sword), origin, direction, amount - 1, TRUE), 0.1 SECONDS)

/datum/action/cooldown/spell/interdimensional_sword/proc/damage_turf(turf/target_turf)
	for(var/mob/living/victim in target_turf)
		if(victim == owner)
			continue
		if(victim.can_block_magic(antimagic_flags))
			victim.visible_message(span_danger("The Interdimensional Sword phases through [victim]!"))
			continue
		victim.visible_message(span_danger("[victim] is hit by the Interdimensional Sword!"), span_userdanger("The Interdimensional Sword slams into you!"))
		victim.adjustFireLoss(12.5)
		victim.adjustBruteLoss(12.5)
		if(prob(35) && try_ash_limb(victim))
			continue
		burn_and_cut(victim)
	for(var/obj/thing in target_turf)
		if(iseffect(thing))
			continue
		thing.visible_message(span_danger("[thing] is annihilated by the Interdimensional Sword!"))
		thing.take_damage(INFINITY)
	if(isclosedturf(target_turf))
		target_turf.visible_message(span_danger("[target_turf] is torn away by the Interdimensional Sword!"))
		target_turf.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)

/// Turns a random arm or leg to ash. Returns TRUE if a limb was taken.
/datum/action/cooldown/spell/interdimensional_sword/proc/try_ash_limb(mob/living/victim)
	if(!iscarbon(victim))
		return FALSE
	var/mob/living/carbon/carbon_victim = victim
	var/list/limbs = list()
	for(var/obj/item/bodypart/limb as anything in carbon_victim.bodyparts)
		if(limb.body_zone == BODY_ZONE_HEAD || limb.body_zone == BODY_ZONE_CHEST)
			continue
		if(limb.can_dismember())
			limbs += limb
	if(!length(limbs))
		return FALSE
	var/obj/item/bodypart/doomed = pick(limbs)
	var/limb_name = doomed.plaintext_zone
	doomed.drop_limb()
	qdel(doomed)
	new /obj/effect/decal/cleanable/ash(get_turf(carbon_victim))
	carbon_victim.visible_message(span_danger("[carbon_victim]'s [limb_name] is turned to ashes by the Interdimensional Sword!"), span_userdanger("Your [limb_name] is turned to ashes by the Interdimensional Sword!"))
	return TRUE

/datum/action/cooldown/spell/interdimensional_sword/proc/burn_and_cut(mob/living/victim)
	victim.adjust_fire_stacks(3)
	victim.ignite_mob()
	if(!ishuman(victim))
		return
	var/mob/living/carbon/human/human_victim = victim
	human_victim.cause_wound_of_type_and_severity(WOUND_SLASH, human_victim.get_bodypart(BODY_ZONE_CHEST), WOUND_SEVERITY_MODERATE, wound_source = "interdimensional sword")
	human_victim.blood_volume = max(human_victim.blood_volume - 10, 0)
	human_victim.spray_blood(pick(GLOB.alldirs), rand(1, 3))
	playsound(human_victim, 'surfshack13/sound/hippie/splash.ogg', 40, TRUE, -1)

/obj/effect/temp_visual/bfs
	icon = 'surfshack13/icons/hippie/interdimensional_sword.dmi'
	randomdir = FALSE
	duration = 1
	density = TRUE // it's a bigass sword
	layer = LYING_MOB_LAYER + 0.1

/obj/effect/temp_visual/bfs/Initialize(mapload, direction)
	. = ..()
	setDir(direction)

/obj/effect/temp_visual/bfs/tip
	icon_state = "tip"

/obj/effect/temp_visual/bfs/blade
	icon_state = "blade"

/obj/effect/temp_visual/bfs/hilt
	icon_state = "hilt"

/obj/effect/bfs_portal
	icon = 'surfshack13/icons/hippie/interdimensional_sword.dmi'
	icon_state = "portal"
	layer = LYING_MOB_LAYER + 0.15
	density = TRUE
	anchored = TRUE

/obj/effect/bfs_portal/Initialize(mapload, direction)
	. = ..()
	setDir(direction)
	flick("portal_open", src)

/datum/spellbook_entry/interdimensional_sword
	name = "Interdimensional Sword"
	desc = "A massive flaming sword, capable of crushing walls, igniting enemies, and cutting rooms in half."
	spell_type = /datum/action/cooldown/spell/interdimensional_sword
	category = "Offensive"
	cost = 3

#undef BFS_LENGTH
