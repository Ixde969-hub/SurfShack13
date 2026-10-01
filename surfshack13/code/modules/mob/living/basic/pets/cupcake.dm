/// Blackboard key, set while Cupcake has gone feral and is hunting her former owners
#define BB_CUPCAKE_FERAL "BB_cupcake_feral"

/**
 * # Cupcake
 *
 * A tanky, mean pitbull that lurks in maintenance. Anyone can tame her with meat (assistants have a knack for it),
 * after which she'll follow, attack and neck bite on command. Meat also patches her up.
 * Owners need to keep feeding her though - let her go hungry for too long and she turns feral and goes for them.
 */
/mob/living/basic/pitbull
	name = "Cupcake"
	desc = "A stocky, scarred pitbull with a mouth full of teeth and a name that is clearly someone's idea of a joke."
	icon = 'surfshack13/icons/mob/cupcake.dmi'
	icon_state = "cupcake"
	icon_living = "cupcake"
	icon_dead = "cupcake_dead"
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	gold_core_spawnable = NO_SPAWN
	faction = list("pitbull")
	speak_emote = list("growls", "snarls", "barks")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoves"
	response_disarm_simple = "shove"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"

	maxHealth = 220
	health = 220
	damage_coeff = list(BRUTE = 0.8, BURN = 1, TOX = 1, STAMINA = 0, OXY = 1)
	obj_damage = 20
	melee_damage_lower = 12
	melee_damage_upper = 16
	wound_bonus = 0
	sharpness = SHARP_POINTY
	melee_attack_cooldown = 1.2 SECONDS
	attack_verb_continuous = "mauls"
	attack_verb_simple = "maul"
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	death_message = "lets out a final whimper and goes still."
	move_force = MOVE_FORCE_STRONG
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG

	butcher_results = list(/obj/item/food/meat/slab = 3)
	ai_controller = /datum/ai_controller/basic_controller/pitbull

	/// Is someone currently looking after us
	var/tamed = FALSE
	/// Have we turned on our owners
	var/feral = FALSE
	/// world.time we last ate
	var/last_fed = 0
	/// Have our owners been warned that we're getting hungry
	var/hunger_warned = FALSE
	/// How long after eating until we start getting irritable
	var/hunger_warning_time = 5 MINUTES
	/// How long after eating until we turn on our owners
	var/feral_time = 7 MINUTES
	/// How much health a single piece of meat restores
	var/meat_heal = 30
	/// Our neck bite ability
	var/datum/action/cooldown/mob_cooldown/neck_bite/neck_bite

	/// What we eat, and what tames us
	var/static/list/food_types = list(
		/obj/item/food/meat,
	)
	/// Commands we listen to while tamed
	var/static/list/pet_commands = list(
		/datum/pet_command/idle,
		/datum/pet_command/free,
		/datum/pet_command/follow/cupcake,
		/datum/pet_command/point_targeting/attack,
		/datum/pet_command/point_targeting/use_ability/neck_bite,
		/datum/pet_command/protect_owner,
	)

/mob/living/basic/pitbull/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/footstep, FOOTSTEP_MOB_CLAW)
	AddElement(/datum/element/ai_retaliate)
	AddElement(/datum/element/basic_eating, heal_amt = meat_heal, food_types = food_types)
	make_tameable()

	neck_bite = new(src)
	neck_bite.Grant(src)
	ai_controller.set_blackboard_key(BB_TARGETED_ACTION, neck_bite)

	RegisterSignal(src, COMSIG_MOB_ATE, PROC_REF(on_ate))
	RegisterSignal(src, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, PROC_REF(on_pre_attack))

/mob/living/basic/pitbull/Destroy()
	QDEL_NULL(neck_bite)
	return ..()

/mob/living/basic/pitbull/proc/make_tameable()
	AddComponent(/datum/component/tameable/cupcake, food_types = food_types, tame_chance = 20, bonus_tame_chance = 10)

/mob/living/basic/pitbull/examine(mob/user)
	. = ..()
	if(stat == DEAD)
		return
	if(feral)
		. += span_danger("[p_Their()] eyes are wild and [p_theyre()] foaming at the mouth. Some meat might calm [p_them()] down... if you can get close.")
		return
	if(!tamed || !(user in ai_controller?.blackboard[BB_FRIENDS_LIST]))
		return
	var/time_since_fed = world.time - last_fed
	if(time_since_fed >= hunger_warning_time)
		. += span_warning("[p_Theyre()] starving and getting snappy. Feed [p_them()] meat, now!")
	else if(time_since_fed >= hunger_warning_time / 2)
		. += span_notice("[p_They()] [p_are()] eyeing your pockets for a snack.")
	else
		. += span_notice("[p_They()] look[p_s()] well fed and content.")

/mob/living/basic/pitbull/tamed(mob/living/tamer, atom/food)
	. = ..()
	tamed = TRUE
	last_fed = world.time
	hunger_warned = FALSE
	if(feral)
		calm_down()
	new /obj/effect/temp_visual/heart(loc)
	if(!GetComponent(/datum/component/obeys_commands))
		AddComponent(/datum/component/obeys_commands, pet_commands)
	ai_controller.ai_traits |= STOP_MOVING_WHEN_PULLED
	visible_message(span_notice("[src] wolfs down the meat and starts wagging [p_their()] stumpy tail at [tamer]."))

/mob/living/basic/pitbull/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!tamed || stat == DEAD)
		return
	var/time_since_fed = world.time - last_fed
	if(time_since_fed >= feral_time)
		go_feral()
		return
	if(time_since_fed < hunger_warning_time)
		return
	if(!hunger_warned)
		hunger_warned = TRUE
		for(var/mob/living/friend in ai_controller.blackboard[BB_FRIENDS_LIST])
			to_chat(friend, span_warning("[src] is getting hungry and irritable. Feed [p_them()] some meat before [p_they()] turn[p_s()] on you!"))
		growl()
	else if(SPT_PROB(4, seconds_per_tick))
		growl()

/mob/living/basic/pitbull/proc/growl()
	playsound(src, pick('sound/mobs/non-humanoids/dog/growl1.ogg', 'sound/mobs/non-humanoids/dog/growl2.ogg'), 50, TRUE)
	visible_message(span_warning("[src] growls hungrily, baring [p_their()] teeth."))

/// Feeding us keeps us loyal (and healing is handled by basic_eating)
/mob/living/basic/pitbull/proc/on_ate(datum/source, atom/food, mob/living/feeder)
	SIGNAL_HANDLER
	if(!tamed)
		return
	last_fed = world.time
	hunger_warned = FALSE
	if(feeder)
		balloon_alert(feeder, "wags tail")

/// Our owners let us starve, time to bite the hand that (didn't) feed us
/mob/living/basic/pitbull/proc/go_feral()
	tamed = FALSE
	feral = TRUE
	hunger_warned = FALSE
	var/list/friends_list = ai_controller.blackboard[BB_FRIENDS_LIST]
	var/list/former_owners = friends_list?.Copy()
	for(var/mob/living/former_owner as anything in former_owners)
		unfriend(former_owner)
	qdel(GetComponent(/datum/component/obeys_commands))
	ai_controller.ai_traits &= ~STOP_MOVING_WHEN_PULLED
	ai_controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
	ai_controller.clear_blackboard_key(BB_CURRENT_PET_TARGET)
	ai_controller.set_blackboard_key(BB_CUPCAKE_FERAL, TRUE)

	var/mob/living/first_victim
	for(var/mob/living/former_owner as anything in former_owners)
		if(QDELETED(former_owner) || former_owner.stat == DEAD)
			continue
		ai_controller.insert_blackboard_key_lazylist(BB_BASIC_MOB_RETALIATE_LIST, former_owner)
		to_chat(former_owner, span_userdanger("[src] has gone feral from hunger and is coming for you!"))
		if(isnull(first_victim) || get_dist(src, former_owner) < get_dist(src, first_victim))
			first_victim = former_owner
	if(first_victim)
		ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, first_victim)

	add_atom_colour("#ffb0b0", FIXED_COLOUR_PRIORITY)
	playsound(src, 'sound/mobs/non-humanoids/dog/growl2.ogg', 80, TRUE)
	visible_message(span_danger("[src]'s eyes go wild as hunger takes over. [p_They()] [p_are()] feral!"))
	// she can be won back, if you're brave enough to get close with some meat
	make_tameable()

/// Someone was brave enough to feed us while we were feral
/mob/living/basic/pitbull/proc/calm_down()
	feral = FALSE
	remove_atom_colour(FIXED_COLOUR_PRIORITY, "#ffb0b0")
	ai_controller.clear_blackboard_key(BB_CUPCAKE_FERAL)
	ai_controller.clear_blackboard_key(BB_BASIC_MOB_RETALIATE_LIST)
	ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)

/// The AI goes for the throat whenever the neck bite is ready
/mob/living/basic/pitbull/proc/on_pre_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(client || !proximity || !isliving(target) || !neck_bite?.IsAvailable())
		return NONE
	var/mob/living/victim = target
	if(victim.stat == DEAD)
		return NONE
	INVOKE_ASYNC(neck_bite, TYPE_PROC_REF(/datum/action, Trigger), NONE, victim)
	return COMPONENT_HOSTILE_NO_ATTACK

/// Tameable, with assistants getting a bonus. Something about kindred spirits.
/datum/component/tameable/cupcake
	/// Bonus tame chance for assistants
	var/assistant_bonus = 25

/datum/component/tameable/cupcake/try_tame(atom/source, obj/item/food, mob/living/attacker)
	var/bonus = is_assistant_job(attacker?.mind?.assigned_role) ? assistant_bonus : 0
	current_tame_chance += bonus
	. = ..()
	current_tame_chance -= bonus

/**
 * # Neck Bite
 * Go for the throat, leaving the victim bleeding heavily.
 */
/datum/action/cooldown/mob_cooldown/neck_bite
	name = "Neck Bite"
	desc = "Lunge for your prey's throat and tear it open, leaving them bleeding heavily."
	button_icon = 'icons/effects/effects.dmi'
	button_icon_state = "bite"
	cooldown_time = 25 SECONDS
	shared_cooldown = NONE
	/// Brute damage dealt by the bite
	var/bite_damage = 20

/datum/action/cooldown/mob_cooldown/neck_bite/Activate(atom/target)
	if(!isliving(target) || target == owner)
		return FALSE
	var/mob/living/victim = target
	if(victim.stat == DEAD)
		return FALSE
	if(!owner.Adjacent(victim))
		if(owner.client)
			owner.balloon_alert(owner, "too far!")
		return FALSE

	owner.face_atom(victim)
	owner.do_attack_animation(victim, ATTACK_EFFECT_BITE)
	playsound(owner, 'sound/items/weapons/bite.ogg', 70, TRUE)
	victim.visible_message(
		span_danger("[owner] lunges at [victim]'s neck and tears into it!"),
		span_userdanger("[owner] clamps down on your neck and rips it open!"),
	)
	if(iscarbon(victim))
		var/mob/living/carbon/carbon_victim = victim
		var/obj/item/bodypart/neck = carbon_victim.get_bodypart(BODY_ZONE_HEAD) || carbon_victim.get_bodypart(BODY_ZONE_CHEST)
		carbon_victim.apply_damage(bite_damage, BRUTE, neck, wound_bonus = CANT_WOUND)
		var/severity = prob(40) ? WOUND_SEVERITY_CRITICAL : WOUND_SEVERITY_SEVERE
		carbon_victim.cause_wound_of_type_and_severity(list(WOUND_PIERCE, WOUND_SLASH), neck, severity, wound_source = "pitbull bite")
	else
		// no neck to bleed from, so it just hurts a lot more
		victim.apply_damage(bite_damage * 2, BRUTE)
	StartCooldown()
	return TRUE

/datum/ai_controller/basic_controller/pitbull
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_PET_TARGETING_STRATEGY = /datum/targeting_strategy/basic/not_friends,
		BB_TARGET_MINIMUM_STAT = HARD_CRIT,
		BB_OWNER_SELF_HARM_RESPONSES = list(
			"*me whines.",
			"*me growls in disapproval.",
			"*me tugs at your sleeve.",
		),
	)
	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/pet_planning,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/simple_find_target/cupcake_feral,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Only goes looking for victims on its own while feral, otherwise it just defends itself
/datum/ai_planning_subtree/simple_find_target/cupcake_feral

/datum/ai_planning_subtree/simple_find_target/cupcake_feral/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(!controller.blackboard[BB_CUPCAKE_FERAL])
		return
	return ..()

/// Recall, come back to your owner
/datum/pet_command/follow/cupcake
	command_name = "Heel"
	command_desc = "Recall your pitbull to your side."
	speech_commands = list("heel", "follow", "come", "here", "recall")

/// Order a neck bite on whatever you point at
/datum/pet_command/point_targeting/use_ability/neck_bite
	command_name = "Neck bite"
	command_desc = "Command your pitbull to go for someone's throat."
	radial_icon = 'icons/effects/effects.dmi'
	radial_icon_state = "bite"
	speech_commands = list("throat", "neck", "rip")
	command_feedback = "snarl"
	pointed_reaction = "and snarls"
	pet_ability_key = BB_TARGETED_ACTION
	ability_behavior = /datum/ai_behavior/pet_use_ability/then_attack

/datum/pet_command/point_targeting/use_ability/neck_bite/set_command_target(mob/living/parent, atom/target)
	if(!target)
		return
	var/datum/targeting_strategy/targeter = GET_TARGETING_STRATEGY(parent.ai_controller.blackboard[targeting_strategy_key])
	if(!targeter?.can_attack(parent, target))
		parent.balloon_alert_to_viewers("shakes head!")
		return FALSE
	return ..()

#undef BB_CUPCAKE_FERAL
