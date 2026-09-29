// Original HippieStation CryNet presentation assets on the modern MODsuit port.

/obj/item/mod/control/pre_equipped/crynet/faithful
	icon = 'surfshack13/icons/hippie/nanosuit.dmi'
	icon_state = "nanosuit"

/datum/mod_theme/elite/crynet/set_skin(obj/item/mod/control/mod, skin)
	. = ..()
	mod.icon = 'surfshack13/icons/hippie/nanosuit.dmi'
	mod.icon_state = "nanosuit"
	for(var/obj/item/clothing/part as anything in mod.get_parts())
		if(istype(part, /obj/item/clothing/suit/mod))
			part.icon = 'surfshack13/icons/hippie/nanosuit.dmi'
			part.worn_icon = 'surfshack13/icons/hippie/nanosuit_worn.dmi'
			part.icon_state = "nanosuit"
			part.worn_icon_state = "nanosuit"
		else if(istype(part, /obj/item/clothing/head/mod))
			part.icon = 'surfshack13/icons/hippie/nanosuit.dmi'
			part.worn_icon = 'surfshack13/icons/hippie/nanosuit_worn.dmi'
			part.icon_state = "nanohelmet"
			part.worn_icon_state = "nanohelmet"

/obj/item/mod/module/crynet_mode/armor
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "armor_mode"

/obj/item/mod/module/crynet_mode/cloak
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "cloak_mode"

/obj/item/mod/module/crynet_mode/speed
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "speed_mode"

/obj/item/mod/module/crynet_mode/strength
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "strength_mode"

/obj/item/mod/module/visor/night/crynet
	name = "CryNet night vision visor"
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "toggle_goggle"
