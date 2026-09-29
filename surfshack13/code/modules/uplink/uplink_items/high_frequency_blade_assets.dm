/obj/item/highfrequencyblade/hippie
	name = "high frequency blade"
	desc = "RULES OF NATURE"
	icon = 'surfshack13/icons/hippie/hfblade.dmi'
	icon_state = "hfblade"
	inhand_icon_state = "hfblade"
	lefthand_file = 'surfshack13/icons/hippie/hfblade_lefthand.dmi'
	righthand_file = 'surfshack13/icons/hippie/hfblade_righthand.dmi'
	var/brazil = FALSE

/obj/item/highfrequencyblade/hippie/update_icon_state()
	. = ..()
	icon_state = brazil ? "hfblade-red" : "hfblade"
	inhand_icon_state = icon_state
	return .

/obj/item/highfrequencyblade/hippie/attackby(obj/item/used_item, mob/living/user, params)
	if(istype(used_item, /obj/item/multitool))
		if(brazil)
			to_chat(user, span_notice("Don't get edgier than this, son."))
			return TRUE
		to_chat(user, span_notice("You enable the buttrock speakers on the sword. Its new red color faintly reminds you of Brazil, for some reason."))
		desc = "Said to have been passed down from several British weeaboos, and one of them outfitted the sword with speakers to play music. Come to Brazil."
		brazil = TRUE
		pickup_sound = 'surfshack13/sound/hippie/hfblade-music1.ogg'
		drop_sound = 'surfshack13/sound/hippie/hfblade-music2.ogg'
		set_light(7, 1, "red")
		update_appearance()
		update_inhand_icon()
		playsound(user, 'sound/vehicles/clowncar_fart.ogg', 50, TRUE)
		return TRUE
	return ..()

/obj/item/storage/belt/hfblade/hippie
	name = "edgelord's sheath"
	desc = "A strange sheath designed to hold an electric blade of some sort. One could only imagine how edgy this guy's musical preference is."
	icon = 'surfshack13/icons/hippie/hfblade.dmi'
	icon_state = "sheath-sabre"
	inhand_icon_state = "sheath-sabre"
	worn_icon = 'surfshack13/icons/hippie/hfblade_worn.dmi'
	worn_icon_state = "sheath-sabre"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/hfblade/hippie/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 1
	atom_storage.max_specific_storage = WEIGHT_CLASS_HUGE
	atom_storage.max_total_storage = 16
	atom_storage.set_holdable(/obj/item/highfrequencyblade/hippie)
	atom_storage.open_sound = 'sound/items/unsheath.ogg'

/obj/item/storage/belt/hfblade/hippie/PopulateContents()
	new /obj/item/highfrequencyblade/hippie(src)
	update_appearance()

/obj/item/storage/belt/hfblade/hippie/update_icon_state()
	. = ..()
	var/new_state = length(contents) ? "sheath-sabre" : "sheath"
	icon_state = new_state
	inhand_icon_state = new_state
	worn_icon_state = new_state
