// Core #undefs these after its own tests, so modular tests bring their own copies
#define TEST_ASSERT(assertion, reason) if (!(assertion)) { return Fail("Assertion failed: [reason || "No reason"]", __FILE__, __LINE__) }
#define TEST_ASSERT_EQUAL(a, b, message) do { 	var/lhs = ##a; 	var/rhs = ##b; 	if (lhs != rhs) { 		return Fail("Expected [isnull(lhs) ? "null" : lhs] to be equal to [isnull(rhs) ? "null" : rhs].[message ? " [message]" : ""]", __FILE__, __LINE__); 	} } while (FALSE)

/// Walks a cultivator through awakening, laws, insight, a realm up and a body swap.
/datum/unit_test/cultivation

/datum/unit_test/cultivation/Run()
	var/mob/living/carbon/human/consistent/disciple = allocate(/mob/living/carbon/human/consistent)
	disciple.mind_initialize()
	var/datum/antagonist/cultivator/cultivator = disciple.mind.add_antag_datum(/datum/antagonist/cultivator)
	TEST_ASSERT_NOTNULL(cultivator, "Failed to awaken a cultivator.")
	TEST_ASSERT_NOTNULL(disciple.get_organ_slot(ORGAN_SLOT_DANTIAN), "Awakening didn't give a dantian.")
	TEST_ASSERT_EQUAL(cultivator.effective_realm(), REALM_QI_CONDENSATION, "New cultivator isn't at Qi Condensation.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/cultivation/meditate) in disciple.actions, "No Meditate technique.")

	// Admin heals and organ regeneration must not delete the dantian
	disciple.fully_heal(HEAL_ALL)
	TEST_ASSERT_NOTNULL(disciple.get_organ_slot(ORGAN_SLOT_DANTIAN), "A full heal deleted the dantian.")

	// Laws and slots
	TEST_ASSERT(cultivator.learn_law(/datum/cultivation_law/returning_iron, feedback = FALSE), "Couldn't learn a first law.")
	TEST_ASSERT(!cultivator.learn_law(/datum/cultivation_law/evergreen_spring, feedback = FALSE), "Learned a second law with only one slot.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/cultivation/bind_artifact) in disciple.actions, "Law didn't grant its techniques.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/spell/pointed/cultivation/sword_qi) in disciple.actions, "Foundation technique granted too early.")

	// Insight: per-source cooldowns and consolidation
	TEST_ASSERT_EQUAL(cultivator.gain_insight(10, "test_source", silent = TRUE), 10, "Insight gain failed.")
	TEST_ASSERT_EQUAL(cultivator.gain_insight(10, "test_source", silent = TRUE), 0, "Same insight source paid out twice in a row.")
	cultivator.consolidate(1)
	TEST_ASSERT_EQUAL(cultivator.progress, 10, "Meditation didn't consolidate insight.")

	// Realm up: new techniques, another law slot, combination technique, element clash
	cultivator.advance_realm()
	TEST_ASSERT_EQUAL(cultivator.realm, REALM_FOUNDATION, "Didn't advance realm.")
	var/obj/item/organ/dantian/dantian = disciple.get_organ_slot(ORGAN_SLOT_DANTIAN)
	TEST_ASSERT_EQUAL(dantian.grade, REALM_FOUNDATION, "Dantian grade didn't follow the realm.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/pointed/cultivation/sword_qi) in disciple.actions, "Foundation technique missing after realm up.")
	var/instability_before = cultivator.instability
	TEST_ASSERT(cultivator.learn_law(/datum/cultivation_law/evergreen_spring, feedback = FALSE), "Couldn't learn a second law at Foundation.")
	TEST_ASSERT(cultivator.instability > instability_before, "Metal and wood didn't clash.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/pointed/cultivation/thousand_thorns) in disciple.actions, "Metal + wood combo wasn't granted.")

	// Artifact refinement: grades rise and stop at the cap
	var/obj/item/kitchen/rollingpin/artifact = allocate(/obj/item/kitchen/rollingpin)
	var/datum/component/cultivation_artifact/bond = artifact.AddComponent(/datum/component/cultivation_artifact, disciple.mind)
	TEST_ASSERT(bond.add_refinement(bond.points_for_next_grade(), disciple), "Enough refinement didn't raise the artifact's grade.")
	TEST_ASSERT_EQUAL(bond.refinement, 1, "Artifact didn't reach Spirit grade.")
	bond.add_refinement(1000, disciple)
	TEST_ASSERT_EQUAL(bond.refinement, MAX_ARTIFACT_REFINEMENT, "Artifact refinement didn't stop at the cap.")

	// Cauldron recipes pick the most specific match
	var/datum/cauldron_recipe/nine = new /datum/cauldron_recipe/nine_revolutions
	var/datum/cauldron_recipe/foundation_recipe = new /datum/cauldron_recipe/foundation
	var/list/pot = list(
		allocate(/obj/item/food/grown/ambrosia/gaia),
		allocate(/obj/item/food/grown/mushroom/reishi),
		allocate(/obj/item/food/grown/mushroom/reishi),
		allocate(/obj/item/food/grown/mushroom/libertycap),
	)
	TEST_ASSERT(nine.matches(pot), "Nine Revolutions recipe didn't match its ingredients.")
	TEST_ASSERT(foundation_recipe.matches(pot), "Gaia should count as ambrosia for the Foundation recipe.")
	TEST_ASSERT(nine.total_ingredients() > foundation_recipe.total_ingredients(), "The more specific recipe should win.")
	qdel(nine)
	qdel(foundation_recipe)
	var/obj/item/cultivation_pill/qi_gathering/graded = allocate(/obj/item/cultivation_pill/qi_gathering)
	graded.set_grade(PILL_GRADE_SPIRIT)
	TEST_ASSERT_EQUAL(graded.potency, 1.5, "Spirit-grade pills aren't stronger.")
	TEST_ASSERT_EQUAL(graded.toxicity, round(initial(graded.toxicity) * 0.5), "Spirit-grade pills aren't gentler.")
	graded.set_grade(PILL_GRADE_LOW)
	TEST_ASSERT_EQUAL(graded.potency, 0.75, "Regrading a pill didn't reset its potency.")

	// The Demonic Path: only real antagonists can comprehend the scripture, masters can transmit, disciples can't
	TEST_ASSERT(!cultivation_is_true_antag(disciple.mind), "A plain cultivator counted as a real antagonist.")
	cultivator.become_demonic(DEMONIC_DISCIPLE)
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/pointed/cultivation/devouring_art) in disciple.actions, "Demonic disciple didn't get the Devouring Art.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/spell/pointed/cultivation/transmit_forbidden) in disciple.actions, "A demonic disciple can transmit the arts.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/spell/pointed/cultivation/corpse_puppet) in disciple.actions, "Golden Core forbidden art granted at Foundation.")
	cultivator.become_demonic(DEMONIC_MASTER)
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/pointed/cultivation/transmit_forbidden) in disciple.actions, "A demonic master can't transmit the arts.")

	// Body Molding Art: mortals reach Copper Skin, committing goes further and closes qi
	var/mob/living/carbon/human/consistent/trainee = allocate(/mob/living/carbon/human/consistent)
	trainee.mind_initialize()
	var/base_health = trainee.maxHealth
	TEST_ASSERT(body_cultivation_train(trainee, 20, BODY_TRAINING_GYM, can_start = TRUE), "Gym training didn't start a mortal on body cultivation.")
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(trainee)
	TEST_ASSERT_NOTNULL(body_datum, "No body cultivator datum after gym training.")
	var/obj/item/bodypart/trainee_chest = trainee.get_bodypart(BODY_ZONE_CHEST)
	body_datum.tempering = BODY_TEMPERING_CAP
	body_datum.forge_part(trainee_chest, BODY_TEMPERING_CAP)
	TEST_ASSERT_EQUAL(body_part_level(trainee, BODY_ZONE_CHEST), 1, "Forging pushed a limb past its cap.")
	TEST_ASSERT_EQUAL(body_datum.tempering, BODY_TEMPERING_CAP - (BODY_PART_COST(1) + BODY_PART_COST(2) - 1), "Forging a capped limb threw away tempering it couldn't hold.")
	body_datum.admin_stage_up()
	TEST_ASSERT_EQUAL(body_datum.stage, 1, "Mortal didn't reach Copper Skin.")
	TEST_ASSERT(!body_datum.can_attempt_tribulation(), "A mortal can go past Copper Skin.")
	body_datum.commit()
	body_datum.admin_stage_up()
	TEST_ASSERT_EQUAL(body_datum.stage, 2, "Committed body cultivator didn't reach Iron Bone.")
	TEST_ASSERT_EQUAL(trainee.maxHealth, base_health + 20, "Body stages didn't raise max health.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/body_art/iron_shirt) in trainee.actions, "Iron Bone didn't grant Iron Shirt.")
	TEST_ASSERT(HAS_TRAIT(trainee, TRAIT_NIGHT_VISION), "Level 1 eyes didn't grant Clear Eyes.")
	TEST_ASSERT(HAS_TRAIT(trainee, TRAIT_NOFLASH), "Level 2 eyes didn't grant Unblinking Eyes.")
	TEST_ASSERT_EQUAL(body_organ_level(trainee, ORGAN_SLOT_HEART), 2, "Stage up didn't forge the heart.")
	TEST_ASSERT(HAS_TRAIT(trainee, TRAIT_QUICKER_CARRY), "Level 2 arms didn't grant Quick Hands.")
	TEST_ASSERT(!HAS_TRAIT(trainee, TRAIT_STRONG_GRABBER), "Level 3 arm power granted at level 2.")
	TEST_ASSERT_EQUAL(cultivation_realm_of(trainee), REALM_QI_CONDENSATION, "Iron Bone doesn't compare as Qi Condensation.")
	var/obj/item/book/granter/cultivation_manual/returning_iron/qi_manual = allocate(/obj/item/book/granter/cultivation_manual/returning_iron)
	TEST_ASSERT(!qi_manual.can_learn(trainee), "A committed body cultivator can learn qi.")
	var/obj/item/book/granter/body_manual/body_book = allocate(/obj/item/book/granter/body_manual/molding_art)
	TEST_ASSERT(!body_book.can_learn(disciple), "A qi cultivator can learn the Body Molding Art.")
	trainee.mind.remove_antag_datum(/datum/antagonist/body_cultivator)
	TEST_ASSERT_EQUAL(trainee.maxHealth, base_health, "Losing body cultivation didn't remove its health.")
	TEST_ASSERT(!HAS_TRAIT(trainee, TRAIT_QUICKER_CARRY), "Body part powers survived losing body cultivation.")

	// Body swap: knowledge follows the mind, power stays in the body
	var/mob/living/carbon/human/consistent/new_body = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/organ/dantian/old_dantian = new_body.get_organ_slot(ORGAN_SLOT_DANTIAN)
	TEST_ASSERT_NULL(old_dantian, "A fresh body somehow already has a dantian.")
	disciple.mind.transfer_to(new_body)
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/cultivation/meditate) in new_body.actions, "Techniques didn't follow the mind.")
	TEST_ASSERT_EQUAL(cultivator.effective_realm(), REALM_MORTAL, "A body without a dantian can still channel qi.")
	TEST_ASSERT_EQUAL(cultivator.realm, REALM_FOUNDATION, "The mind forgot its realm in a new body.")

	// Internal injury: heavy cultivation blows stack up to three on a cultivator, one on a mortal, and pills mend them
	cultivation_heavy_blow(new_body, 30, null)
	cultivation_heavy_blow(new_body, 30, null)
	cultivation_heavy_blow(new_body, 30, null)
	cultivation_heavy_blow(new_body, 30, null)
	TEST_ASSERT_EQUAL(cultivation_internal_injury_stacks(new_body), 3, "Internal injury didn't stack to three on a cultivator.")
	cultivation_heavy_blow(new_body, 5, null)
	TEST_ASSERT_EQUAL(cultivation_internal_injury_stacks(new_body), 3, "A light blow changed internal injury.")
	TEST_ASSERT_EQUAL(cultivation_qi_regen_multiplier(new_body), 0.25, "Three stacks of internal injury didn't slow qi regeneration.")
	var/obj/item/cultivation_pill/qi_gathering/mending_pill = allocate(/obj/item/cultivation_pill/qi_gathering)
	mending_pill.set_grade(PILL_GRADE_SPIRIT)
	mending_pill.consume(new_body, new_body)
	TEST_ASSERT_EQUAL(cultivation_internal_injury_stacks(new_body), 1, "A spirit-grade pill didn't mend two stacks of internal injury.")
	cultivation_heal_internal_injury(new_body, 1)
	TEST_ASSERT_NULL(new_body.has_status_effect(/datum/status_effect/internal_injury), "Healing the last stack didn't end the internal injury.")
	cultivation_heavy_blow(trainee, 30, null)
	cultivation_heavy_blow(trainee, 30, null)
	TEST_ASSERT_EQUAL(cultivation_internal_injury_stacks(trainee), 1, "A mortal took more than one stack of internal injury.")

	// Five-Point Exploding Heart Palm: counts only the victim's own steps, bursts at zero, and can be unsealed
	var/mob/living/carbon/human/consistent/palm_victim = allocate(/mob/living/carbon/human/consistent)
	var/turf/elsewhere = get_step(palm_victim, NORTH) || get_step(palm_victim, SOUTH)
	palm_victim.apply_status_effect(/datum/status_effect/exploding_heart, new_body, 3)
	var/datum/status_effect/exploding_heart/palm = palm_victim.has_status_effect(/datum/status_effect/exploding_heart)
	TEST_ASSERT_NOTNULL(palm, "The Exploding Heart Palm didn't mark its victim.")
	palm.on_step(palm_victim, elsewhere, NORTH, TRUE)
	TEST_ASSERT_EQUAL(palm.steps_left, 3, "Being moved by force counted as a step.")
	palm.on_step(palm_victim, elsewhere, NORTH, FALSE)
	TEST_ASSERT_EQUAL(palm.steps_left, 2, "A step wasn't counted.")
	palm.unseal("Test.")
	TEST_ASSERT_NULL(palm_victim.has_status_effect(/datum/status_effect/exploding_heart), "Unsealing didn't remove the palm.")
	var/health_before = palm_victim.health
	palm_victim.apply_status_effect(/datum/status_effect/exploding_heart, new_body, 1)
	palm = palm_victim.has_status_effect(/datum/status_effect/exploding_heart)
	palm.burst()
	TEST_ASSERT(palm_victim.health < health_before, "The heart burst didn't hurt.")
	TEST_ASSERT_NULL(palm_victim.has_status_effect(/datum/status_effect/exploding_heart), "The palm lingered after bursting.")

	// Martial World Ranking: winners join, upsets take the loser's place, and the same pair can't swap twice in a row
	var/list/old_ranking = GLOB.jianghu_ranking.Copy()
	var/list/old_cooldowns = GLOB.jianghu_ranking_pair_cooldowns.Copy()
	GLOB.jianghu_ranking.Cut()
	GLOB.jianghu_ranking_pair_cooldowns.Cut()
	var/list/fighters = list()
	for(var/i in 1 to 3)
		var/mob/living/carbon/human/consistent/fighter = allocate(/mob/living/carbon/human/consistent)
		fighter.mind_initialize()
		fighters += fighter
	var/mob/living/fighter_a = fighters[1]
	var/mob/living/fighter_b = fighters[2]
	var/mob/living/fighter_c = fighters[3]
	jianghu_ranking_record(fighter_a, fighter_b)
	TEST_ASSERT_EQUAL(jianghu_rank_of(fighter_a.mind), 1, "Winning a duel didn't put an unranked fighter on the list.")
	TEST_ASSERT_EQUAL(jianghu_rank_of(fighter_b.mind), 0, "Losing an unranked duel ranked the loser.")
	jianghu_ranking_record(fighter_c, fighter_a)
	TEST_ASSERT_EQUAL(jianghu_rank_of(fighter_c.mind), 1, "Beating the top fighter didn't take their place.")
	TEST_ASSERT_EQUAL(jianghu_rank_of(fighter_a.mind), 2, "The beaten top fighter didn't slide down one place.")
	jianghu_ranking_record(fighter_a, fighter_c)
	TEST_ASSERT_EQUAL(jianghu_rank_of(fighter_c.mind), 1, "The same pair swapped places twice within the cooldown.")
	jianghu_ranking_record(fighter_b, fighter_c)
	TEST_ASSERT_EQUAL(jianghu_rank_of(fighter_b.mind), 1, "An unranked upset winner didn't take first place.")
	TEST_ASSERT_EQUAL(jianghu_rank_of(fighter_c.mind), 2, "The upset loser didn't slide down.")
	TEST_ASSERT_EQUAL(jianghu_rank_of(fighter_a.mind), 3, "Everyone below the upset didn't slide down.")
	TEST_ASSERT(jianghu_refuses_challenge(new_body, fighter_b), "First Under Heaven accepted a challenge from an unranked fighter.")
	TEST_ASSERT(!jianghu_refuses_challenge(fighter_a, fighter_b), "First Under Heaven refused a top-five challenger.")
	// Sworn brotherhood: siblings near each other fight together, and turning on one breaks the oath
	var/datum/sworn_bond/bond = new(list(fighter_a.mind, fighter_b.mind))
	TEST_ASSERT(sworn_siblings(fighter_a, fighter_b), "Swearing didn't bind the two siblings.")
	TEST_ASSERT(!sworn_siblings(fighter_a, fighter_c), "A stranger counted as a sworn sibling.")
	bond.process(1)
	TEST_ASSERT_NOTNULL(fighter_a.has_status_effect(/datum/status_effect/sworn_together), "Standing beside a sworn sibling gave no bonus.")
	bond.betrayal(fighter_a, fighter_b)
	TEST_ASSERT(QDELETED(bond), "Betrayal didn't break the oath.")
	TEST_ASSERT(!sworn_siblings(fighter_a, fighter_b), "Siblings stayed bound after a betrayal.")
	TEST_ASSERT(sworn_is_oathbreaker(fighter_a.mind), "The betrayer wasn't marked as an oathbreaker.")
	TEST_ASSERT(fighter_a.mind in GLOB.sworn_oath_takers, "The betrayer can swear again.")
	GLOB.sworn_oathbreakers -= fighter_a.mind
	GLOB.sworn_oath_takers -= list(fighter_a.mind, fighter_b.mind)

	// Inheritance: a master's death fills the heir's foundation, guarantees their breakthrough, and empties the master
	var/datum/antagonist/cultivator/master_datum = IS_CULTIVATOR(new_body)
	master_datum.disciples |= fighter_c.mind
	TEST_ASSERT(fighter_c.mind in cultivation_heir_candidates(new_body.mind), "A disciple couldn't be named heir.")
	GLOB.cultivation_heirs[new_body.mind] = fighter_c.mind
	TEST_ASSERT(cultivation_pass_on(new_body, FALSE), "The cultivation didn't pass on.")
	var/datum/antagonist/cultivator/heir_datum = IS_CULTIVATOR(fighter_c)
	TEST_ASSERT_NOTNULL(heir_datum, "Inheriting didn't awaken a mortal heir.")
	TEST_ASSERT(heir_datum.progress > 0, "The heir's foundation didn't fill.")
	TEST_ASSERT_NOTNULL(fighter_c.has_status_effect(/datum/status_effect/inheritance_blessing), "The heir's next breakthrough isn't guaranteed.")
	TEST_ASSERT_EQUAL(master_datum.realm, REALM_QI_CONDENSATION, "The master kept their realm after passing it on.")
	TEST_ASSERT_NULL(GLOB.cultivation_heirs[new_body.mind], "The heir stayed named after inheriting.")

	GLOB.jianghu_ranking = old_ranking
	GLOB.jianghu_ranking_pair_cooldowns = old_cooldowns

	// Removal cleans up techniques
	new_body.mind.remove_antag_datum(/datum/antagonist/cultivator)
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/spell/cultivation/meditate) in new_body.actions, "Techniques survived losing cultivation.")

#undef TEST_ASSERT
#undef TEST_ASSERT_EQUAL
