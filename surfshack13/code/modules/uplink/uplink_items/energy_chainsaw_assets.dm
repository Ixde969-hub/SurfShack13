/obj/item/chainsaw/energy
	icon = 'surfshack13/icons/hippie/energy_chainsaw.dmi'
	icon_state = "echainsaw_off"
	inhand_icon_state = "echainsaw_off"
	lefthand_file = 'surfshack13/icons/hippie/energy_chainsaw_lefthand.dmi'
	righthand_file = 'surfshack13/icons/hippie/energy_chainsaw_righthand.dmi'
	w_class = WEIGHT_CLASS_HUGE

/obj/item/chainsaw/energy/Initialize(mapload)
	. = ..()
	var/datum/component/transforming/transform_comp = GetComponent(/datum/component/transforming)
	if(transform_comp)
		transform_comp.hitsound_on = pick(
			'surfshack13/sound/hippie/echainsawhit1.ogg',
			'surfshack13/sound/hippie/echainsawhit2.ogg',
		)

/obj/item/chainsaw/energy/on_transform(obj/item/source, mob/user, active)
	. = ..()
	icon_state = active ? "echainsaw_on" : "echainsaw_off"
	inhand_icon_state = icon_state
	if(active)
		hitsound = pick(
			'surfshack13/sound/hippie/echainsawhit1.ogg',
			'surfshack13/sound/hippie/echainsawhit2.ogg',
		)
	else
		hitsound = initial(hitsound)
	playsound(src, active ? 'surfshack13/sound/hippie/echainsawon.ogg' : 'surfshack13/sound/hippie/echainsawoff.ogg', 50, TRUE)
	update_inhand_icon()
	return COMPONENT_NO_DEFAULT_MESSAGE
