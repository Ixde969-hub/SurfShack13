/**
 * # Internal injury
 *
 * Heavy qi blows bruise the meridians as well as the flesh. Each heavy hit from a cultivator, a body cultivator or a legendary
 * artifact adds a stack (up to three), and the injury keeps hurting after the fight: qi regenerates slower, you cough up blood,
 * and at three stacks your own techniques can backfire. Losing a clash costs you the next few minutes, not just health.
 *
 * Meditation, pills, Spring Mending, Myriad Spring Revival and Breath of Renewal each clear stacks.
 * Mortals can be bruised this way too, but never past one stack.
 */

/// Damage a single blow has to deal to bruise the meridians
#define INTERNAL_INJURY_THRESHOLD 15
/// Most stacks anyone can carry
#define INTERNAL_INJURY_MAX_STACKS 3

/**
 * Called by the big cultivation blows (legendary hits, body arts, sword qi, Buddha's Palm...).
 * Only blows from someone who actually cultivates count, and only heavy ones.
 */
/proc/cultivation_heavy_blow(mob/living/victim, damage, mob/living/attacker)
	if(QDELETED(victim) || victim.stat == DEAD || damage < INTERNAL_INJURY_THRESHOLD)
		return
	if(!isnull(attacker) && !IS_CULTIVATOR(attacker) && !IS_BODY_CULTIVATOR(attacker))
		return
	cultivation_add_internal_injury(victim)

/// Add one stack of internal injury (or start one)
/proc/cultivation_add_internal_injury(mob/living/victim, stacks = 1)
	if(!iscarbon(victim) || HAS_TRAIT(victim, TRAIT_GODMODE))
		return
	var/datum/status_effect/internal_injury/injury = victim.has_status_effect(/datum/status_effect/internal_injury)
	if(injury)
		injury.add_stacks(stacks)
		return
	victim.apply_status_effect(/datum/status_effect/internal_injury, stacks)

/// Heal some stacks of internal injury. Returns how many were healed.
/proc/cultivation_heal_internal_injury(mob/living/patient, stacks = 1)
	var/datum/status_effect/internal_injury/injury = patient?.has_status_effect(/datum/status_effect/internal_injury)
	if(!injury)
		return 0
	return injury.remove_stacks(stacks)

/// How many stacks someone carries
/proc/cultivation_internal_injury_stacks(mob/living/target)
	var/datum/status_effect/internal_injury/injury = target?.has_status_effect(/datum/status_effect/internal_injury)
	return injury ? injury.stacks : 0

/datum/status_effect/internal_injury
	id = "internal_injury"
	duration = 3 MINUTES
	tick_interval = 2 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	remove_on_fullheal = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/internal_injury
	/// 1 to INTERNAL_INJURY_MAX_STACKS
	var/stacks = 1
	/// Spam limiter for coughing
	COOLDOWN_DECLARE(cough_cooldown)

/datum/status_effect/internal_injury/on_creation(mob/living/new_owner, stacks = 1)
	src.stacks = stacks
	. = ..()
	if(QDELETED(src))
		return
	clamp_stacks()
	update_alert()

/datum/status_effect/internal_injury/on_apply()
	RegisterSignal(owner, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	to_chat(owner, span_userdanger("Something deep inside you tears. You've taken an internal injury!"))
	return TRUE

/datum/status_effect/internal_injury/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_EXAMINE)
	if(owner.stat != DEAD)
		to_chat(owner, span_nicegreen("The deep ache in your chest finally settles. Your internal injuries have healed."))

/// Mortals don't have meridians worth tearing twice
/datum/status_effect/internal_injury/proc/max_stacks()
	return (IS_CULTIVATOR(owner) || IS_BODY_CULTIVATOR(owner)) ? INTERNAL_INJURY_MAX_STACKS : 1

/datum/status_effect/internal_injury/proc/clamp_stacks()
	stacks = clamp(stacks, 1, max_stacks())

/datum/status_effect/internal_injury/proc/add_stacks(amount)
	var/before = stacks
	stacks += amount
	clamp_stacks()
	// A fresh blow keeps the injury open longer
	duration = world.time + initial(duration)
	if(stacks > before)
		to_chat(owner, span_userdanger("The blow drives deeper into your meridians! (internal injury [stacks]/[max_stacks()])"))
		owner.Shake(1, 1, 0.3 SECONDS)
	update_alert()

/// Returns how many stacks were actually healed
/datum/status_effect/internal_injury/proc/remove_stacks(amount)
	var/healed = min(amount, stacks)
	stacks -= healed
	if(stacks <= 0)
		qdel(src)
		return healed
	to_chat(owner, span_nicegreen("Some of the ache in your meridians fades. (internal injury [stacks]/[max_stacks()])"))
	update_alert()
	return healed

/datum/status_effect/internal_injury/proc/update_alert()
	if(!linked_alert)
		return
	linked_alert.maptext = MAPTEXT_TINY_UNICODE("<span style='text-align:center; color:#ff6a6a'>[stacks]</span>")
	linked_alert.desc = "Your meridians are bruised ([stacks]/[max_stacks()]). Qi regenerates [25 * stacks]% slower and you cough up blood. \
		[stacks >= INTERNAL_INJURY_MAX_STACKS ? "Your techniques may backfire! " : ""]Meditate, take a pill, or get Spring Mending to heal it."

/datum/status_effect/internal_injury/tick(seconds_between_ticks)
	if(owner.stat == DEAD || !COOLDOWN_FINISHED(src, cough_cooldown) || !prob(6 * stacks))
		return
	COOLDOWN_START(src, cough_cooldown, 8 SECONDS)
	owner.visible_message(span_danger("[owner] doubles over and coughs up a mouthful of blood!"), span_danger("You cough up blood. Something inside is badly hurt."))
	owner.apply_damage(stacks, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.vomit(VOMIT_CATEGORY_BLOOD, lost_nutrition = 0, distance = 0)

/datum/status_effect/internal_injury/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("[owner.p_They()] look[owner.p_s()] pale, and there's blood at the corner of [owner.p_their()] mouth.")

/// Qi regenerates slower the more bruised the meridians are
/proc/cultivation_qi_regen_multiplier(mob/living/body)
	return max(1 - 0.25 * cultivation_internal_injury_stacks(body), 0.25)

/// At full stacks, forcing a technique through torn meridians can backfire. Returns TRUE if it did.
/proc/cultivation_injury_backlash(mob/living/user)
	if(cultivation_internal_injury_stacks(user) < INTERNAL_INJURY_MAX_STACKS || !prob(25))
		return FALSE
	user.visible_message(span_danger("[user] flinches as [user.p_their()] qi twists the wrong way!"), span_userdanger("Your torn meridians backfire!"))
	user.apply_damage(5, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	user.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(user))
	return TRUE

/atom/movable/screen/alert/status_effect/internal_injury
	name = "Internal Injury"
	desc = "Your meridians are bruised."
	icon_state = "wounded"

#undef INTERNAL_INJURY_THRESHOLD
#undef INTERNAL_INJURY_MAX_STACKS

