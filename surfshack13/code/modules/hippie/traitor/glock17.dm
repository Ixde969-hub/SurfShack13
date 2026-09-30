// Glock 17 - ported from HippieStation.
// Built on Surf's 9mm pistol; Hippie drew empty/suppressed variants as whole sprites instead of overlays,
// so the dmi has no "_suppressor" overlay state and the suppressed look comes from update_icon_state().

/obj/item/gun/ballistic/automatic/pistol/g17
	name = "Glock 17"
	desc = "A classic 9mm handgun with a large magazine capacity. Used by security teams everywhere."
	icon = 'surfshack13/icons/hippie/glock17.dmi'
	icon_state = "glock17"
	base_icon_state = "glock17"
	accepted_magazine_type = /obj/item/ammo_box/magazine/g17
	show_bolt_icon = FALSE
	mag_display = FALSE
	/// Hippie's two alternating shot sounds
	var/list/glock_fire_sounds = list('surfshack13/sound/hippie/pistol_glock17_1.ogg', 'surfshack13/sound/hippie/pistol_glock17_2.ogg')

/obj/item/gun/ballistic/automatic/pistol/g17/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state][bolt_locked ? "-e" : ""][suppressed ? "-suppressed" : ""]"

/obj/item/gun/ballistic/automatic/pistol/g17/fire_sounds()
	if(suppressed)
		return ..()
	playsound(src, pick(glock_fire_sounds), fire_sound_volume, vary_fire_sound)

/obj/item/gun/ballistic/automatic/pistol/g17/no_mag
	spawnwithmagazine = FALSE

/obj/item/ammo_box/magazine/g17
	name = "Glock 17 magazine (9mm)"
	desc = "A 14-round 9mm magazine for the Glock 17."
	icon = 'surfshack13/icons/hippie/glock17.dmi'
	icon_state = "g17-full"
	base_icon_state = "g17"
	ammo_type = /obj/item/ammo_casing/c9mm
	caliber = CALIBER_9MM
	max_ammo = 14
	multiple_sprites = AMMO_BOX_FULL_EMPTY
	multiple_sprite_use_base = TRUE

/obj/item/storage/box/syndie_kit/glock17
	name = "Glock Seventeen with spare ammo"

/obj/item/storage/box/syndie_kit/glock17/PopulateContents()
	new /obj/item/gun/ballistic/automatic/pistol/g17(src)
	for(var/i in 1 to 3)
		new /obj/item/ammo_box/magazine/g17(src)

/datum/uplink_item/dangerous/g17
	name = "Glock 17 Handgun with three magazines"
	desc = "A simple yet popular handgun chambered in 9mm. Made out of strong but lightweight polymer. \
		The standard magazine can hold up to 14 9mm cartridges. Compatible with a universal suppressor. This pack comes with three spare magazines."
	item = /obj/item/storage/box/syndie_kit/glock17
	cost = 10
	surplus = 15
	purchasable_from = UPLINK_TRAITORS | UPLINK_SERIOUS_OPS

/datum/uplink_item/ammo/g17
	name = "9mm Glock Magazine"
	desc = "An additional 14-round 9mm magazine; compatible with the Glock 17 pistol."
	item = /obj/item/ammo_box/magazine/g17
	cost = 1
	purchasable_from = UPLINK_TRAITORS | UPLINK_SERIOUS_OPS
