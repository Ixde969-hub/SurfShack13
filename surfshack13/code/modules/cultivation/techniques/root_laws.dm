/**
 * Root Laws. A cultivator holds at most two laws, and the first one they ever learned shapes everything:
 * it gives one of that law's techniques a signature twist (see each law's root_text).
 * The second, Complementary Law can be let go of with a long meditation and replaced.
 */

/// Allies for techniques that help "friends": yourself, your sect, your sworn siblings, your pets and beasts
/proc/cultivation_is_ally(mob/living/user, mob/living/other)
	if(!user || !other)
		return FALSE
	if(user == other)
		return TRUE
	if(user.mind && other.mind)
		var/datum/jianghu_sect/sect = jianghu_sect_of(user.mind)
		if(sect && jianghu_sect_of(other.mind) == sect)
			return TRUE
		if(sworn_siblings(user, other))
			return TRUE
	return (REF(user) in other.faction)

// ===================== Metal: the circling artifact =====================

/// Returning Iron root: the bound artifact circles its master and answers the next melee blow
/datum/status_effect/iron_guard
	id = "iron_guard"
	alert_type = null
	duration = 15 SECONDS
	tick_interval = STATUS_EFFECT_NO_TICK
	/// The circling artifact, held in nullspace while it orbits
	var/obj/item/artifact
	var/obj/effect/abstract/cultivation_orbit/orbit

/datum/status_effect/iron_guard/on_creation(mob/living/new_owner, obj/item/artifact)
	src.artifact = artifact
	return ..()

/datum/status_effect/iron_guard/on_apply()
	if(QDELETED(artifact))
		return FALSE
	if(ismob(artifact.loc))
		var/mob/holder = artifact.loc
		if(!holder.temporarilyRemoveItemFromInventory(artifact, force = TRUE))
			return FALSE
	artifact.moveToNullspace()
	RegisterSignal(artifact, COMSIG_QDELETING, PROC_REF(on_artifact_deleted))
	orbit = new()
	var/image/circling = image(artifact.icon, artifact.icon_state)
	circling.pixel_y = 22
	orbit.add_overlay(circling)
	owner.vis_contents += orbit
	RegisterSignal(owner, COMSIG_LIVING_CHECK_BLOCK, PROC_REF(intercept))
	owner.visible_message(span_notice("[artifact] rises from [owner]'s hand and begins to circle [owner.p_them()]."))
	playsound(owner, 'sound/items/unsheath.ogg', 40, TRUE)
	return TRUE

/datum/status_effect/iron_guard/on_remove()
	UnregisterSignal(owner, COMSIG_LIVING_CHECK_BLOCK)
	owner.vis_contents -= orbit
	QDEL_NULL(orbit)
	if(!QDELETED(artifact))
		UnregisterSignal(artifact, COMSIG_QDELETING)
		if(!artifact.loc)
			artifact.forceMove(owner.drop_location())
			INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob, put_in_hands), artifact)
	artifact = null

/datum/status_effect/iron_guard/proc/on_artifact_deleted(datum/source)
	SIGNAL_HANDLER
	artifact = null
	qdel(src)

/// The next melee blow is caught by the circling artifact, which then flies at whoever threw it
/datum/status_effect/iron_guard/proc/intercept(mob/living/source, atom/hit_by, damage, attack_text, attack_type, armour_penetration, damage_type)
	SIGNAL_HANDLER
	if(!(attack_type in list(MELEE_ATTACK, UNARMED_ATTACK)) || QDELETED(artifact))
		return NONE
	var/mob/living/attacker = isliving(hit_by) ? hit_by : (isliving(hit_by?.loc) ? hit_by.loc : null)
	source.visible_message(span_danger("[artifact] whips around and catches [attack_text]!"))
	playsound(source, 'sound/items/weapons/parry.ogg', 50, TRUE)
	var/obj/item/striker = artifact
	artifact = null
	UnregisterSignal(striker, COMSIG_QDELETING)
	striker.forceMove(get_turf(source))
	var/datum/component/cultivation_artifact/bond = striker.GetComponent(/datum/component/cultivation_artifact)
	if(attacker && bond)
		INVOKE_ASYNC(bond, TYPE_PROC_REF(/datum/component/cultivation_artifact, launch), attacker, source)
	qdel(src)
	return SUCCESSFUL_BLOCK

// ===================== Water: the returning wave =====================

/// Still Water root: the ward's stored force crashes back out when it ends
/proc/cultivation_ward_wave(mob/living/warded, stored)
	if(QDELETED(warded) || stored < 5)
		return
	var/turf/center = get_turf(warded)
	warded.visible_message(span_boldwarning("The still water around [warded] heaves and crashes outward!"))
	playsound(center, 'sound/effects/splash.ogg', 70, TRUE, frequency = 0.7)
	new /obj/effect/temp_visual/circle_wave/cultivation/water(center)
	cultivation_distortion_wave(warded, 2, 0.4 SECONDS, 160)
	var/damage = min(stored, 30)
	for(var/mob/living/victim in orange(1, center))
		if(victim.stat == DEAD || cultivation_is_ally(warded, victim))
			continue
		victim.apply_damage(damage, BRUTE)
		if(!HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
			victim.throw_at(get_edge_target_turf(victim, get_dir(center, victim) || pick(GLOB.alldirs)), 2, 2, warded)

// ===================== Earth: shielding an ally =====================

/// Rooted Mountain root: an ally beside the stance takes half damage, the guardian takes the rest
/datum/status_effect/rooted_guarded
	id = "rooted_guarded"
	alert_type = null
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = 0.5 SECONDS
	var/datum/weakref/guardian_ref

/datum/status_effect/rooted_guarded/on_creation(mob/living/new_owner, mob/living/guardian)
	guardian_ref = WEAKREF(guardian)
	return ..()

/datum/status_effect/rooted_guarded/on_apply()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(share_blow))
	owner.add_filter("rooted_guarded", 2, list("type" = "outline", "color" = "#c79a5a", "size" = 1))
	return TRUE

/datum/status_effect/rooted_guarded/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	owner.remove_filter("rooted_guarded")

/// The guard only holds while the guardian is still rooted beside us
/datum/status_effect/rooted_guarded/tick(seconds_between_ticks)
	var/mob/living/guardian = guardian_ref?.resolve()
	if(!guardian || guardian.stat != CONSCIOUS || !guardian.has_status_effect(/datum/status_effect/rooted_stance) || get_dist(guardian, owner) > 1)
		qdel(src)

/// Guarding passes damage along, and must never pass it back and forth forever
GLOBAL_VAR_INIT(rooted_guard_transferring, FALSE)

/datum/status_effect/rooted_guarded/proc/share_blow(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(GLOB.rooted_guard_transferring || damage <= 0 || !(damagetype in list(BRUTE, BURN)))
		return
	var/mob/living/guardian = guardian_ref?.resolve()
	if(!guardian || guardian == owner)
		return
	damage_mods += 0.5
	GLOB.rooted_guard_transferring = TRUE
	guardian.apply_damage(damage * 0.5, damagetype)
	GLOB.rooted_guard_transferring = FALSE
	new /obj/effect/temp_visual/cultivation_spark(get_turf(guardian), "#c79a5a", rand(-6, 6), rand(0, 8))

// ===================== Letting go of the Complementary Law =====================

/datum/action/cooldown/spell/cultivation/forget_law
	name = "Release Complementary Law"
	desc = "Spend thirty seconds of quiet meditation letting your Complementary Law drain out of your meridians, freeing the slot for another. \
		You must be out of combat, on a cultivation mat, in a gathering array or at your sect's plaque. Your Root Law can never be released."
	cooldown_time = 1 MINUTES
	qi_cost = 0

/datum/action/cooldown/spell/cultivation/forget_law/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	if(length(cultivator.laws) < 2)
		to_chat(user, span_warning("You have no Complementary Law to release."))
		return . | SPELL_CANCEL_CAST
	if(user.combat_mode)
		to_chat(user, span_warning("You can't let go of a law in the middle of a fight."))
		return . | SPELL_CANCEL_CAST
	if(!cultivation_quiet_place(user))
		to_chat(user, span_warning("You need a cultivation mat, a gathering array or your sect's plaque to do this safely."))
		return . | SPELL_CANCEL_CAST

/// A mat under you, a gathering array around you, or your own sect's plaque nearby
/proc/cultivation_quiet_place(mob/living/user)
	var/turf/here = get_turf(user)
	if(locate(/obj/structure/cultivation_mat) in here)
		return TRUE
	if(locate(/obj/effect/cultivation_formation/gathering) in range(1, here))
		return TRUE
	var/datum/jianghu_sect/sect = jianghu_sect_of(user.mind)
	var/obj/structure/sect_plaque/plaque = sect?.get_plaque()
	return plaque && plaque.z == user.z && get_dist(plaque, user) <= 5

/datum/action/cooldown/spell/cultivation/forget_law/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(release), cast_on)

/datum/action/cooldown/spell/cultivation/forget_law/proc/release(mob/living/user)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	var/datum/cultivation_law/complementary = length(cultivator?.laws) >= 2 ? cultivator.laws[2] : null
	if(!complementary || tgui_alert(user, "Release [complementary.name]? You'll lose its techniques until you learn it again.", "Release Complementary Law", list("Release it", "Keep it")) != "Release it")
		reset_spell_cooldown()
		return
	user.visible_message(span_notice("[user] closes [user.p_their()] eyes. A thin stream of [complementary.element]-coloured qi drifts away from [user.p_them()]."))
	var/obj/effect/abstract/particle_holder/motes = cultivation_particles(user, /particles/cultivation)
	var/finished = do_after(user, 30 SECONDS, user, IGNORE_HELD_ITEM)
	qdel(motes)
	if(!finished || QDELETED(cultivator) || !(complementary in cultivator.laws))
		return
	cultivator.forget_law(complementary)

/// Lose a law and every technique only it (or a combination needing it) granted
/datum/antagonist/cultivator/proc/forget_law(datum/cultivation_law/lost)
	laws -= lost
	var/mob/living/body = owner.current
	if(body)
		lost.on_body_lost(body, src)
	for(var/datum/action/technique as anything in techniques.Copy())
		if(!(technique.type in lost.techniques) && !combo_needs(technique.type, lost.element))
			continue
		var/still_known = FALSE
		for(var/datum/cultivation_law/law as anything in laws)
			if(technique.type in law.techniques)
				still_known = TRUE
				break
		if(!still_known)
			qdel(technique)
	to_chat(body, span_notice("[lost.name] drains out of your meridians. There is room for a new Complementary Law."))
	qdel(lost)
	refresh_techniques()
	update_hud()

/// Is this technique a combination that needs an element we no longer have?
/datum/antagonist/cultivator/proc/combo_needs(technique_type, element)
	for(var/datum/cultivation_combo/combo as anything in GLOB.cultivation_combos)
		if(combo.technique == technique_type && (combo.element_one == element || combo.element_two == element) && !has_element(element))
			return TRUE
	return FALSE
