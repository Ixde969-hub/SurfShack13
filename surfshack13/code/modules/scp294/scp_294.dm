// SCP-294, the strange coffee machine. Ported from the old /tg/ ruin removed in tgstation#37326.
// Type any liquid and it pours 10u of it into a paper cup.

/area/ruin/space/has_grav/powered/scp_294
	name = "Abandoned SCP-294 Containment"
	icon_state = "yellow"

/datum/map_template/ruin/space/scp_294
	id = "scp_294"
	suffix = "scp_294.dmm"
	name = "Space-Ruin SCP-294 Containment"
	description = "An abandoned asteroid base that contains several EMP-proof turrets, and a valuable artifact. Should you get past the heavy laser turrets, a valuable treasure awaits."

/obj/machinery/chem_dispenser/scp_294
	name = "\improper strange coffee machine"
	desc = "It appears to be a standard coffee vending machine, the only noticeable difference being an entry touchpad with buttons corresponding to a Galactic Common QWERTY keyboard."
	icon = 'surfshack13/icons/obj/scp/scp.dmi'
	icon_state = "294_bottom"
	base_icon_state = "294_bottom"
	amount = 10
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	use_power = NO_POWER_USE
	working_state = null
	nopower_state = null
	has_panel_overlay = FALSE
	/// Shorthand names that don't match a reagent's real name
	var/static/list/shortcuts = list(
		"meth" = /datum/reagent/drug/methamphetamine,
	)
	/// Lowercase, space-less reagent name -> reagent typepath, built on first use
	var/static/list/name_lookup
	/// Message shown under the touchpad
	var/status_text
	/// Whether status_text is an error
	var/status_error = FALSE

/obj/machinery/chem_dispenser/scp_294/Destroy()
	QDEL_NULL(beaker)
	return ..()

/obj/machinery/chem_dispenser/scp_294/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "294_top", layer = ABOVE_ALL_MOB_LAYER)

/obj/machinery/chem_dispenser/scp_294/display_beaker()
	return null

/obj/machinery/chem_dispenser/scp_294/screwdriver_act(mob/living/user, obj/item/tool)
	return NONE

/obj/machinery/chem_dispenser/scp_294/crowbar_act(mob/living/user, obj/item/tool)
	return NONE

/obj/machinery/chem_dispenser/scp_294/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Scp294", name)
		ui.open()

/obj/machinery/chem_dispenser/scp_294/ui_data(mob/user)
	. = ..()
	.["amount"] = amount
	.["cup_color"] = beaker?.reagents?.total_volume ? mix_color_from_reagents(beaker.reagents.reagent_list) : null
	.["status"] = status_text
	.["status_error"] = status_error

/obj/machinery/chem_dispenser/scp_294/handle_ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	switch(action)
		if("dispense")
			if(QDELETED(beaker))
				return FALSE
			var/input = copytext(params["name"], 1, MAX_NAME_LEN)
			if(!input)
				return FALSE
			var/reagent_type = find_reagent(input)
			if(!reagent_type)
				status_text = "OUT OF RANGE"
				status_error = TRUE
				say("OUT OF RANGE")
				return TRUE
			beaker.reagents.add_reagent(reagent_type, amount)
			var/datum/reagent/reagent = reagent_type
			status_text = "Dispensed [initial(reagent.name)]."
			status_error = FALSE
			return TRUE
		if("makecup")
			if(beaker)
				return FALSE
			beaker = new /obj/item/reagent_containers/cup/glass/sillycup(src)
			status_text = null
			visible_message(span_notice("[src] dispenses a small, paper cup."))
			update_appearance()
			return TRUE

/// Finds a synthesizable reagent typepath from what the user typed, or null
/obj/machinery/chem_dispenser/scp_294/proc/find_reagent(input)
	input = replacetext(lowertext(input), " ", "") // 95% of the time this matches a lowercase, space-less reagent name
	if(!name_lookup)
		name_lookup = list()
		for(var/reagent_name in GLOB.name2reagent)
			var/datum/reagent/reagent_type = GLOB.name2reagent[reagent_name]
			if(!(initial(reagent_type.chemical_flags) & REAGENT_CAN_BE_SYNTHESIZED))
				continue
			name_lookup[replacetext(lowertext(reagent_name), " ", "")] = reagent_type
	return shortcuts[input] || name_lookup[input]
