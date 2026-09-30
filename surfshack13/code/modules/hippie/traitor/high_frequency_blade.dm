// High Frequency Blade - ported from HippieStation.
// Surf already has a high frequency blade; this is a subtype with Hippie's sprites, sheath and multitool easter egg.

/obj/item/highfrequencyblade/hippie
	desc = "An electric katana that weakens the molecular bonds of whatever it touches. RULES OF NATURE."
	icon = 'surfshack13/icons/hippie/hfblade.dmi'
	icon_state = "hfblade"
	inhand_icon_state = "hfblade"
	worn_icon_state = null
	lefthand_file = 'surfshack13/icons/hippie/hfblade_lefthand.dmi'
	righthand_file = 'surfshack13/icons/hippie/hfblade_righthand.dmi'
	slot_flags = NONE // carried in its sheath, Hippie had no back sprite for it
	/// Whether the buttrock speakers have been enabled with a multitool
	var/brazil = FALSE

/obj/item/highfrequencyblade/hippie/update_icon_state()
	. = ..()
	icon_state = brazil ? "hfblade-red" : "hfblade"
	inhand_icon_state = icon_state

/obj/item/highfrequencyblade/hippie/multitool_act(mob/living/user, obj/item/tool)
	if(brazil)
		to_chat(user, span_notice("Don't get edgier than this, son."))
		return ITEM_INTERACT_BLOCKING
	to_chat(user, span_notice("You enable the buttrock speakers on the sword. Its new red color faintly reminds you of Brazil, for some reason."))
	desc = "Said to have been passed down from several British weeaboos, and one of them outfitted the sword with speakers to play music. Come to Brazil."
	brazil = TRUE
	slash_color = COLOR_RED
	pickup_sound = 'surfshack13/sound/hippie/hfblade-music1.ogg'
	drop_sound = 'surfshack13/sound/hippie/hfblade-music2.ogg'
	set_light(7, 1, COLOR_RED)
	update_appearance()
	playsound(user, 'sound/vehicles/clowncar_fart.ogg', 50, TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/item/storage/belt/sabre/hfblade
	name = "edgelord's sheath"
	desc = "A strange sheath designed to hold an electric blade of some sort. One could only imagine how edgy this guy's musical preference is."
	icon = 'surfshack13/icons/hippie/hfblade.dmi'
	worn_icon = 'surfshack13/icons/hippie/hfblade_worn.dmi'

/obj/item/storage/belt/sabre/hfblade/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/highfrequencyblade/hippie)
	atom_storage.max_specific_storage = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/sabre/hfblade/PopulateContents()
	new /obj/item/highfrequencyblade/hippie(src)
	update_appearance()

/datum/uplink_item/dangerous/high_frequency_blade
	name = "High Frequency Blade"
	desc = "An electric katana that weakens the molecular bonds of whatever it touches. Perfect for slicing off the limbs of your coworkers. \
		Avoid using a multitool on it."
	item = /obj/item/storage/belt/sabre/hfblade
	cost = 9
	surplus = 15
	purchasable_from = UPLINK_TRAITORS | UPLINK_SERIOUS_OPS
