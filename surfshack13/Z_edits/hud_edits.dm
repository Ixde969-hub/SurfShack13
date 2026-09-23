/mob/New()
	// add our nanite huds to everyone so they can (if possible) actually see nanites.
	hud_possible += list(NANITE_HUD, DIAG_NANITE_FULL_HUD)
	return ..()

/datum/atom_hud/data/human/medical/New()
	. = ..()
	hud_icons += list(NANITE_HUD)

/datum/atom_hud/data/human/security/advanced/New()
	. = ..()
	hud_icons += list(NANITE_HUD)

/datum/atom_hud/data/diagnostic/New()
	. = ..()
	hud_icons += list(DIAG_NANITE_FULL_HUD)

// Surf Shack: lets the implantee identify hypnotized victims using their antagonist HUD icon.
#define HYPNO_TRACKER_REFRESH_INTERVAL (1 SECONDS)
#define HYPNO_TRACKER_HUD_KEY "hypno_tracker"

/obj/item/implant/hypno_tracker
	name = "hypnotic telemetry implant"
	desc = "An implant of Syndicate origin that allows an agent to visually identify hypnotized victims."
	icon = 'icons/hud/implants.dmi'
	icon_state = "generic"
	actions_types = null
	implant_color = "r"
	allow_multiple = FALSE
	implant_flags = NONE
	/// Associative list of hypnotized mobs to their one-person alternate-appearance HUD datums.
	var/list/hypno_overlays = list()
	/// Stoppable timer used to keep the HUD synchronized with hypnosis changes and body transfers.
	var/hypno_refresh_timer

/obj/item/implant/hypno_tracker/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	if(!.)
		return FALSE

	refresh_hypno_hud()
	schedule_hypno_refresh()
	to_chat(target, span_notice("You feel a faint, cool pulse behind your eyes as your neural pathways align with hypnotic telemetry."))
	return TRUE

/obj/item/implant/hypno_tracker/removed(mob/living/source, silent = FALSE, special = 0)
	stop_hypno_refresh()
	clear_hypno_hud()
	return ..()

/obj/item/implant/hypno_tracker/proc/schedule_hypno_refresh()
	if(QDELETED(src) || isnull(imp_in))
		return
	if(hypno_refresh_timer)
		deltimer(hypno_refresh_timer)
	hypno_refresh_timer = addtimer(CALLBACK(src, PROC_REF(on_hypno_refresh_timer)), HYPNO_TRACKER_REFRESH_INTERVAL, TIMER_STOPPABLE)

/obj/item/implant/hypno_tracker/proc/stop_hypno_refresh()
	if(!hypno_refresh_timer)
		return
	deltimer(hypno_refresh_timer)
	hypno_refresh_timer = null

/obj/item/implant/hypno_tracker/proc/on_hypno_refresh_timer()
	hypno_refresh_timer = null
	if(QDELETED(src) || isnull(imp_in))
		return
	refresh_hypno_hud()
	schedule_hypno_refresh()

/obj/item/implant/hypno_tracker/proc/refresh_hypno_hud()
	if(isnull(imp_in))
		return

	var/list/current_targets = list()
	for(var/mob/living/hypnotized_target as anything in GLOB.mob_living_list)
		if(QDELETED(hypnotized_target))
			continue

		var/datum/antagonist/hypnotized/hypno_datum = hypnotized_target.mind?.has_antag_datum(/datum/antagonist/hypnotized)
		if(!hypno_datum)
			continue

		current_targets[hypnotized_target] = TRUE
		var/datum/atom_hud/alternate_appearance/basic/one_person/existing_overlay = hypno_overlays[hypnotized_target]
		if(existing_overlay && !QDELETED(existing_overlay))
			continue

		var/image/hypno_image = hypno_datum.hud_image_on(hypnotized_target)
		var/datum/atom_hud/alternate_appearance/basic/one_person/new_overlay = hypnotized_target.add_alt_appearance(
			/datum/atom_hud/alternate_appearance/basic/one_person,
			"[HYPNO_TRACKER_HUD_KEY]_[REF(src)]",
			hypno_image,
			NONE,
			imp_in,
		)
		if(new_overlay)
			hypno_overlays[hypnotized_target] = new_overlay

	for(var/mob/living/tracked_target as anything in hypno_overlays.Copy())
		if(current_targets[tracked_target] && !QDELETED(tracked_target))
			continue
		remove_hypno_overlay(tracked_target)

/obj/item/implant/hypno_tracker/proc/remove_hypno_overlay(mob/living/target)
	var/datum/atom_hud/alternate_appearance/basic/one_person/overlay = hypno_overlays[target]
	hypno_overlays -= target
	if(overlay && !QDELETED(overlay))
		qdel(overlay)

/obj/item/implant/hypno_tracker/proc/clear_hypno_hud()
	for(var/tracked_target in hypno_overlays.Copy())
		var/datum/atom_hud/alternate_appearance/basic/one_person/overlay = hypno_overlays[tracked_target]
		if(overlay && !QDELETED(overlay))
			qdel(overlay)
	hypno_overlays.Cut()

#undef HYPNO_TRACKER_REFRESH_INTERVAL
#undef HYPNO_TRACKER_HUD_KEY
