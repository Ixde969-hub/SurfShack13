/// Big angry bovine. Paws the ground, then charges through whatever's in the way.
/mob/living/basic/bull
	name = "bull"
	desc = "A massive, short-tempered beast. Probably best not to wear red around it."
	// TODO: placeholder (Pete's goat sprite) until the real bull sprite is done
	icon = 'icons/mob/simple/animal.dmi'
	icon_state = "goat"
	icon_living = "goat"
	icon_dead = "goat_dead"
	gender = MALE
	mob_biotypes = MOB_ORGANIC | MOB_BEAST | MOB_RUMINANT
	mob_size = MOB_SIZE_LARGE
	speak_emote = list("snorts", "bellows")
	response_help_continuous = "carefully pats"
	response_help_simple = "carefully pat"
	response_disarm_continuous = "shoves"
	response_disarm_simple = "shove"
	response_harm_continuous = "punches"
	response_harm_simple = "punch"
	attack_verb_continuous = "rams"
	attack_verb_simple = "ram"
	attack_sound = 'sound/items/weapons/punch1.ogg'
	attack_vis_effect = ATTACK_EFFECT_SMASH
	butcher_results = list(/obj/item/food/meat/slab/grassfed = 8)
	faction = list(FACTION_HOSTILE)
	health = 200
	maxHealth = 200
	melee_damage_lower = 10
	melee_damage_upper = 15
	obj_damage = 40
	speed = 1
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	blood_volume = BLOOD_VOLUME_NORMAL
	ai_controller = /datum/ai_controller/basic_controller/bull
	/// Our charge ability
	var/datum/action/cooldown/mob_cooldown/bull_charge/charge

/mob/living/basic/bull/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/footstep, footstep_type = FOOTSTEP_MOB_SHOE)
	AddElement(/datum/element/ai_retaliate)
	charge = new(src)
	charge.Grant(src)
	ai_controller.set_blackboard_key(BB_TARGETED_ACTION, charge)

/mob/living/basic/bull/Destroy()
	QDEL_NULL(charge)
	return ..()
