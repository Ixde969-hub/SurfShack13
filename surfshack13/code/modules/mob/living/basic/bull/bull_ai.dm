/datum/ai_controller/basic_controller/bull
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_TARGET_MINIMUM_STAT = HARD_CRIT,
	)
	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate/check_faction,
		/datum/ai_planning_subtree/simple_find_target,
		// Charge whenever it's off cooldown; missed charges come back quickly so it just lines up again
		/datum/ai_planning_subtree/targeted_mob_ability,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)
