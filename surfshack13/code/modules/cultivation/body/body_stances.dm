/**
 * Body Molding stances. From Steel Sinew (stage 3) a body cultivator can settle into one of two stances,
 * which change how their existing arts work rather than adding new ones:
 *
 * Thunderclap: commit to the attack. Hundred Fist Barrage, Raging Bull Charge and Blood Boil come back a quarter faster
 * and you move a little faster, but you take 10% more damage.
 * Immovable Mountain: hold the line. Iron Shirt and the Vajra Golden Body last half as long again, Earth-Shattering Stomp
 * throws enemies back instead of just flattening them, and nothing can shove you while you stand still, but you move slower.
 *
 * Changing stance takes two seconds standing still, and both stances share one cooldown.
 */

/// Body arts that recover faster in Thunderclap stance
GLOBAL_LIST_INIT(thunderclap_arts, typecacheof(list(
	/datum/action/cooldown/spell/pointed/body_art/hundred_fists,
	/datum/action/cooldown/spell/pointed/body_art/bull_charge,
	/datum/action/cooldown/spell/body_art/blood_boil,
)))

/datum/action/cooldown/spell/body_art/stance
	name = "Stance"
	desc = "Settle into a stance."
	cooldown_time = 20 SECONDS
	/// The stance we put you in
	var/datum/status_effect/body_stance/stance_type

/datum/action/cooldown/spell/body_art/stance/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	if(istype(body_stance_of(user), stance_type))
		user.remove_status_effect(stance_type)
		to_chat(user, span_notice("You relax out of your stance."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/body_art/stance/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(settle), cast_on)

/datum/action/cooldown/spell/body_art/stance/proc/settle(mob/living/user)
	user.visible_message(span_notice("[user] shifts [user.p_their()] weight and sinks into a new stance."))
	if(!do_after(user, 2 SECONDS, user, IGNORE_HELD_ITEM))
		reset_spell_cooldown()
		return
	// Both stances share an id, so the new one replaces the old
	user.apply_status_effect(stance_type)
	// Both stances share the one cooldown
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	for(var/datum/action/cooldown/spell/body_art/stance/other in body_datum?.techniques)
		if(other != src)
			other.StartCooldown()

/datum/action/cooldown/spell/body_art/stance/thunderclap
	name = "Thunderclap Stance"
	desc = "Commit to the attack. Hundred Fist Barrage, Raging Bull Charge and Blood Boil recover a quarter faster and you move a little faster, \
		but you take 10% more damage. Takes two seconds to settle into; use again to leave it. Shares a cooldown with Immovable Mountain Stance."
	stance_type = /datum/status_effect/body_stance/thunderclap

/datum/action/cooldown/spell/body_art/stance/mountain
	name = "Immovable Mountain Stance"
	desc = "Hold the line. Iron Shirt and the Vajra Golden Body last half as long again, Earth-Shattering Stomp throws enemies back, \
		and nothing can shove you while you stand still, but you move slower. Takes two seconds to settle into; use again to leave it. \
		Shares a cooldown with Thunderclap Stance."
	stance_type = /datum/status_effect/body_stance/mountain

/datum/status_effect/body_stance
	id = "body_stance"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	/// Outline colour while in this stance
	var/stance_color = "#ffffff"

/datum/status_effect/body_stance/on_apply()
	owner.add_filter("body_stance", 2, list("type" = "outline", "color" = stance_color, "size" = 1, "alpha" = 140))
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(get_turf(owner))
	return TRUE

/datum/status_effect/body_stance/on_remove()
	owner.remove_filter("body_stance")

/// Which stance someone is in, or null
/proc/body_stance_of(mob/living/user)
	return user?.has_status_effect(/datum/status_effect/body_stance)

// ----- Thunderclap -----

/datum/status_effect/body_stance/thunderclap
	stance_color = "#ffd84a"

/datum/status_effect/body_stance/thunderclap/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/body_thunderclap)
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(open_guard))
	to_chat(owner, span_notice("You drop into the Thunderclap stance: everything forward, nothing held back."))
	playsound(owner, 'sound/effects/magic/lightningbolt.ogg', 30, TRUE, frequency = 1.5)

/datum/status_effect/body_stance/thunderclap/on_remove()
	. = ..()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/body_thunderclap)
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)

/datum/status_effect/body_stance/thunderclap/proc/open_guard(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype == BRUTE || damagetype == BURN)
		damage_mods += 1.1

/datum/movespeed_modifier/body_thunderclap
	multiplicative_slowdown = -0.15

// ----- Immovable Mountain -----

/datum/status_effect/body_stance/mountain
	stance_color = "#a07a45"
	tick_interval = 0.5 SECONDS
	/// When we last moved, so standing still roots us
	var/last_moved = 0
	var/rooted = FALSE

/datum/status_effect/body_stance/mountain/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/body_mountain)
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	last_moved = world.time
	to_chat(owner, span_notice("You sink into the Immovable Mountain stance. Let them come."))

/datum/status_effect/body_stance/mountain/on_remove()
	. = ..()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/body_mountain)
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	unroot()

/datum/status_effect/body_stance/mountain/proc/on_moved(datum/source)
	SIGNAL_HANDLER
	last_moved = world.time
	unroot()

/datum/status_effect/body_stance/mountain/tick(seconds_between_ticks)
	if(!rooted && world.time - last_moved >= 1 SECONDS)
		rooted = TRUE
		ADD_TRAIT(owner, TRAIT_PUSHIMMUNE, TRAIT_STATUS_EFFECT(id))
		owner.move_resist = MOVE_FORCE_OVERPOWERING

/datum/status_effect/body_stance/mountain/proc/unroot()
	if(!rooted)
		return
	rooted = FALSE
	REMOVE_TRAIT(owner, TRAIT_PUSHIMMUNE, TRAIT_STATUS_EFFECT(id))
	owner.move_resist = initial(owner.move_resist)

/datum/movespeed_modifier/body_mountain
	multiplicative_slowdown = 0.25
