/datum/uplink_item/dangerous/execution_sword
	name = "Execution Sword"
	desc = "This modified energy sword has been specially designed to cleanly remove the head of a human\
			 in one well aimed swipe. It contains a hacked transmitter that will broadcast the\
			 details of your gruesome execution on the station announcement channel so everyone will know the\
			 name of the filthy pig you are about to slaughter. You may dedicate your executions to whomever you\
			 please by using the device in hand but you may only do so once. Be warned that you must remain still\
			 for a long time to execute a target so be sure to have them restrained and if you should be interrupted\
			 then news of your failure will be broadcast to the station."
	item = /obj/item/melee/execution_sword/antag
	cost = 1
	surplus = 30
	purchasable_from = ~UPLINK_INFILTRATORS

/obj/item/extra_arm
	name = "extra arm installer"
	desc = "A Syndicate surgical device that adapts the user's nervous system to support an additional arm."
	icon = 'surfshack13/icons/hippie/device.dmi'
	icon_state = "extra_arm"
	w_class = WEIGHT_CLASS_SMALL
	var/used = FALSE

/obj/item/extra_arm/attack_self(mob/living/carbon/user)
	if(used)
		balloon_alert(user, "already used!")
		return

	user.change_number_of_hands(length(user.held_items) + 1)
	used = TRUE
	icon_state = "extra_arm_none"
	desc += " It has already been used."
	user.visible_message(
		span_notice("[user] presses a button on [src], followed by a disgusting wet noise."),
		span_notice("You feel a sharp sting as [src] implants an additional arm into your body."),
	)
	to_chat(user, span_notice("You feel more dexterous."))
	playsound(user, 'sound/misc/splort.ogg', 50, vary = TRUE)

/datum/uplink_item/device_tools/additional_arm
	name = "Additional Arm"
	desc = "An additional arm prepared for rapid implantation with a Syndicate surgical installer."
	item = /obj/item/extra_arm
	cost = 4
	limited_stock = 2
	purchasable_from = UPLINK_TRAITORS
