// Arts of the hidden and the reckless: concealing your cultivation, forcing your meridians past their limits,
// and, at Nascent Soul, stepping out of your own body.

// ===================== Concealment Art =====================

/datum/action/cooldown/spell/cultivation/concealment
	name = "Concealment Art"
	desc = "Draw your qi deep inside until you look like a mortal. Other cultivators see no realm on examine and Spiritual Sense finds nothing, \
		demonic qi included. Using any other technique or striking anyone reveals you, and that first strike staggers them. Use again to stop."
	cooldown_time = 20 SECONDS
	qi_cost = 15

/datum/action/cooldown/spell/cultivation/concealment/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	if(user.has_status_effect(/datum/status_effect/concealed_cultivation))
		user.remove_status_effect(/datum/status_effect/concealed_cultivation)
		to_chat(user, span_notice("You let your qi rise back to the surface."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/cultivation/concealment/cast(mob/living/cast_on)
	. = ..()
	cast_on.apply_status_effect(/datum/status_effect/concealed_cultivation)

/proc/cultivation_is_concealed(mob/living/target)
	return target?.has_status_effect(/datum/status_effect/concealed_cultivation)

/datum/status_effect/concealed_cultivation
	id = "concealed_cultivation"
	alert_type = /atom/movable/screen/alert/status_effect/concealed_cultivation
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK

/datum/status_effect/concealed_cultivation/on_apply()
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack))
	RegisterSignal(owner, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	to_chat(owner, span_notice("You draw your qi inward until not a wisp of it shows. To other cultivators, you are a mortal."))
	cultivation_afterimage(owner, 0.4 SECONDS)
	return TRUE

/datum/status_effect/concealed_cultivation/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_UNARMED_ATTACK))

/datum/status_effect/concealed_cultivation/proc/on_item_attack(mob/living/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	reveal(target)

/datum/status_effect/concealed_cultivation/proc/on_unarmed_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(proximity && isliving(target) && target != owner)
		reveal(target)

/// The hidden master strikes: the first blow staggers, and everyone sees what they really are
/datum/status_effect/concealed_cultivation/proc/reveal(mob/living/victim)
	if(isliving(victim) && victim.stat != DEAD)
		victim.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
		victim.Shake(2, 2, 0.3 SECONDS)
		to_chat(victim, span_userdanger("The 'mortal' in front of you suddenly blazes with qi!"))
	owner.visible_message(span_boldwarning("[owner]'s hidden cultivation bursts into the open!"))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(owner))
	qdel(src)

/atom/movable/screen/alert/status_effect/concealed_cultivation
	name = "Concealed"
	desc = "Your cultivation is hidden. Other cultivators see a mortal. Any technique or strike reveals you."
	icon_state = "hypnosis"

// ===================== Forced Circulation =====================

/datum/action/cooldown/spell/cultivation/forced_circulation
	name = "Forced Circulation"
	desc = "Toggle. While on, you drive your qi past the safe limit when you meditate: every cycle consolidates twice the insight, \
		but each one risks a qi deviation (an internal injury and instability, or your heart demon tearing loose)."
	cooldown_time = 2 SECONDS
	qi_cost = 0

/datum/action/cooldown/spell/cultivation/forced_circulation/cast(mob/living/cast_on)
	. = ..()
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(cast_on)
	cultivator.forcing_circulation = !cultivator.forcing_circulation
	if(cultivator.forcing_circulation)
		to_chat(cast_on, span_warning("You resolve to force your qi past its limits when you meditate. Fortune favours the bold. Usually."))
		name = "Forced Circulation (on)"
	else
		to_chat(cast_on, span_notice("You return to safe, steady circulation."))
		name = initial(name)
	build_all_button_icons(UPDATE_BUTTON_NAME)

/datum/antagonist/cultivator
	/// Meditation pushes past the safe limit: double insight, risk of qi deviation
	var/forcing_circulation = FALSE

/// One forced meditation cycle's gamble. Returns the extra multiplier it earned.
/proc/cultivation_forced_cycle(mob/living/user, datum/antagonist/cultivator/cultivator)
	if(!cultivator.forcing_circulation)
		return 0
	if(prob(25))
		user.visible_message(span_danger("[user] shudders violently, qi spraying from [user.p_them()] in wild sparks!"), span_userdanger("Your qi deviates!"))
		do_sparks(3, FALSE, user)
		if(prob(30) && !GLOB.cultivation_heart_demons[user.mind])
			cultivation_summon_heart_demon(user)
		else
			cultivation_add_internal_injury(user)
			cultivator.adjust_instability(15)
		return 0
	to_chat(user, span_notice("You force your qi through every meridian. It holds."))
	return 1

// ===================== Body Outside the Body =====================

/datum/action/cooldown/spell/cultivation/body_outside_body
	name = "Body Outside the Body"
	desc = "Your nascent soul steps out of your body as a small golden figure for 30 seconds. It flies over tables and through crowds and glass, \
		can see and speak, but can't fight or touch anything. Your body is left helpless: if it's hurt, your soul snaps back early."
	cooldown_time = 2 MINUTES
	qi_cost = 50

/datum/action/cooldown/spell/cultivation/body_outside_body/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	if(!ishuman(user) || user.buckled || user.pulledby)
		user.balloon_alert(user, "can't concentrate!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/cultivation/body_outside_body/cast(mob/living/carbon/human/cast_on)
	. = ..()
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(cultivation_project_soul), cast_on)

/proc/cultivation_project_soul(mob/living/carbon/human/body)
	if(QDELETED(body) || !body.mind)
		return
	var/mob/living/basic/nascent_projection/soul = new(get_turf(body))
	soul.take_form(body)
	body.visible_message(span_boldnotice("A small golden figure, a perfect miniature of [body], rises out of [body.p_them()] and floats away! [body.p_They()] slump[body.p_s()], eyes empty."), span_boldnotice("You step out of your body."))
	cultivation_temple_sound(body, 40)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(body))
	body.mind.transfer_to(soul)
	body.apply_status_effect(/datum/status_effect/soul_departed, soul)

/// The body left behind. Hurting it calls the soul home.
/datum/status_effect/soul_departed
	id = "soul_departed"
	alert_type = null
	duration = 31 SECONDS
	tick_interval = STATUS_EFFECT_NO_TICK
	var/datum/weakref/soul_ref

/datum/status_effect/soul_departed/on_creation(mob/living/new_owner, mob/living/basic/nascent_projection/soul)
	soul_ref = WEAKREF(soul)
	return ..()

/datum/status_effect/soul_departed/on_apply()
	owner.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))
	owner.add_filter("soul_departed", 2, list("type" = "outline", "color" = "#5a5070", "size" = 1))
	RegisterSignal(owner, COMSIG_MOB_AFTER_APPLY_DAMAGE, PROC_REF(on_damaged))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(owner, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	return TRUE

/datum/status_effect/soul_departed/on_remove()
	owner.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))
	owner.remove_filter("soul_departed")
	UnregisterSignal(owner, list(COMSIG_MOB_AFTER_APPLY_DAMAGE, COMSIG_LIVING_DEATH, COMSIG_ATOM_EXAMINE))
	// Whatever ended this, the soul goes home
	var/mob/living/basic/nascent_projection/soul = soul_ref?.resolve()
	if(!QDELETED(soul))
		INVOKE_ASYNC(soul, TYPE_PROC_REF(/mob/living/basic/nascent_projection, return_to_body))

/datum/status_effect/soul_departed/proc/on_damaged(mob/living/source, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damage >= 5)
		qdel(src)

/datum/status_effect/soul_departed/proc/on_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/soul_departed/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("[owner.p_They()] [owner.p_are()] completely still, eyes empty, as if nobody is home.")

/// A nascent soul walking outside its body
/mob/living/basic/nascent_projection
	name = "nascent soul"
	desc = "A tiny golden figure floating in the air, glowing softly."
	icon = 'icons/mob/simple/simple_human.dmi'
	icon_state = ""
	mob_biotypes = MOB_SPIRIT
	maxHealth = 40
	health = 40
	speed = -0.6
	density = FALSE
	movement_type = FLYING
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB | PASSGLASS
	melee_damage_lower = 0
	melee_damage_upper = 0
	unsuitable_atmos_damage = 0
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	basic_mob_flags = DEL_ON_DEATH
	death_message = "flickers and is pulled back towards its body!"
	ai_controller = null
	light_system = OVERLAY_LIGHT
	light_range = 2
	light_power = 1
	light_color = "#ffe27a"
	/// The body we came out of
	var/datum/weakref/body_ref
	var/returning = FALSE

/mob/living/basic/nascent_projection/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NO_FLOATING_ANIM, INNATE_TRAIT)
	var/datum/action/nascent_return/return_action = new(src)
	return_action.Grant(src)
	addtimer(CALLBACK(src, PROC_REF(return_to_body)), 30 SECONDS)
	animate(src, pixel_z = 4, time = 1 SECONDS, loop = -1, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
	animate(pixel_z = 0, time = 1 SECONDS, easing = SINE_EASING)

/mob/living/basic/nascent_projection/proc/take_form(mob/living/body)
	body_ref = WEAKREF(body)
	appearance = body.appearance
	name = "nascent soul of [body.real_name]"
	real_name = name
	transform = matrix().Scale(0.6)
	color = "#ffe27a"
	alpha = 190
	layer = MOB_LAYER
	SET_PLANE_IMPLICIT(src, GAME_PLANE)
	add_filter("nascent_glow", 2, list("type" = "outline", "color" = "#fff3b0", "size" = 1))
	cultivation_particles(src, /particles/cultivation/gold)

/mob/living/basic/nascent_projection/death(gibbed)
	return_to_body()
	return ..()

/mob/living/basic/nascent_projection/proc/return_to_body()
	if(returning || QDELETED(src))
		return
	returning = TRUE
	var/mob/living/body = body_ref?.resolve()
	if(mind && body && !QDELETED(body))
		visible_message(span_notice("[src] streaks back towards its body."))
		cultivation_afterimage(src, 0.5 SECONDS)
		mind.transfer_to(body)
		body.remove_status_effect(/datum/status_effect/soul_departed)
		to_chat(body, span_boldnotice("You snap back into your body."))
		new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(body))
	else if(mind)
		to_chat(src, span_userdanger("Your body is gone! Your nascent soul has nowhere to return to."))
		ghostize(FALSE)
	qdel(src)

/datum/action/nascent_return
	name = "Return to Body"
	desc = "Fly back into your body at once."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "body_outside_body"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = NONE

/datum/action/nascent_return/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/mob/living/basic/nascent_projection/soul = owner
	if(istype(soul))
		soul.return_to_body()
