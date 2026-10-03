/**
 * # Martial World Ranking
 *
 * The station's ten strongest fighters, decided only by honor duels. Win an honor duel against someone ranked above you and you take
 * their place; beat someone unranked and you join the list. Rank one is First Under Heaven, and the whole station hears when that title
 * changes hands. Whoever holds the Dragon Slaying Saber is First Under Heaven no matter what the list says.
 *
 * The top three cultivate a little faster. The same two fighters can only move each other up or down once every five minutes,
 * so friends can't farm swaps, and fleeing a duel counts as losing it.
 */

/// How many places the ranking has
#define JIANGHU_RANKING_SIZE 10
/// Insight bonus for the top three
#define JIANGHU_RANKING_INSIGHT_BONUS 0.1

/// Ranked minds, best first
GLOBAL_LIST_EMPTY(jianghu_ranking)
/// "ref-ref" pair key -> world.time the pair can change places again
GLOBAL_LIST_EMPTY(jianghu_ranking_pair_cooldowns)

/// 1 for the best, 0 for the unranked
/proc/jianghu_rank_of(datum/mind/mind)
	return mind ? GLOB.jianghu_ranking.Find(mind) : 0

/// The Dragon Slaying Saber's holder, if a living person with a mind holds it
/proc/jianghu_saber_holder()
	for(var/obj/item/cultivation_artifact/dragon_saber/saber as anything in GLOB.jianghu_dragon_sabers)
		var/mob/living/holder = saber.loc
		if(isliving(holder) && holder.mind && holder.stat != DEAD)
			return holder.mind
	return null

/// Whoever the jianghu currently calls First Under Heaven
/proc/jianghu_first_under_heaven()
	return jianghu_saber_holder() || (length(GLOB.jianghu_ranking) ? GLOB.jianghu_ranking[1] : null)

/// An honor duel is over: winner may climb
/proc/jianghu_ranking_record(mob/living/winner, mob/living/loser)
	var/datum/mind/winner_mind = winner?.mind
	var/datum/mind/loser_mind = loser?.mind
	if(!winner_mind || !loser_mind || winner_mind == loser_mind)
		return
	var/winner_ref = REF(winner_mind)
	var/loser_ref = REF(loser_mind)
	var/pair_key = sorttext(winner_ref, loser_ref) == 1 ? "[winner_ref]-[loser_ref]" : "[loser_ref]-[winner_ref]"
	if(world.time < GLOB.jianghu_ranking_pair_cooldowns[pair_key])
		to_chat(winner, span_notice("<i>The jianghu has already weighed you two against each other recently. The ranking doesn't change.</i>"))
		return
	var/old_first = jianghu_first_under_heaven()
	var/winner_rank = jianghu_rank_of(winner_mind)
	var/loser_rank = jianghu_rank_of(loser_mind)
	var/list/ranking = GLOB.jianghu_ranking
	var/changed = FALSE
	if(loser_rank && (!winner_rank || winner_rank > loser_rank))
		// Take the loser's place; everyone between slides down one
		if(winner_rank)
			ranking.Cut(winner_rank, winner_rank + 1)
		ranking.Insert(loser_rank, winner_mind)
		changed = TRUE
	else if(!winner_rank && length(ranking) < JIANGHU_RANKING_SIZE)
		ranking += winner_mind
		changed = TRUE
	if(!changed)
		return
	GLOB.jianghu_ranking_pair_cooldowns[pair_key] = world.time + 5 MINUTES
	if(length(ranking) > JIANGHU_RANKING_SIZE)
		ranking.Cut(JIANGHU_RANKING_SIZE + 1)
	winner.AddElement(/datum/element/jianghu_examine)
	var/new_rank = jianghu_rank_of(winner_mind)
	to_chat(winner, span_boldnotice("You are now ranked <b>#[new_rank]</b> in the Martial World Ranking!"))
	if(loser_rank)
		to_chat(loser, span_warning("You have fallen to [jianghu_rank_of(loser_mind) ? "#[jianghu_rank_of(loser_mind)]" : "outside the top ten"] in the Martial World Ranking."))
	jianghu_refresh_ranking_bonuses()
	var/datum/mind/new_first = jianghu_first_under_heaven()
	if(new_first != old_first && new_first == winner_mind)
		jianghu_announce_first_under_heaven(winner)

/// Station-wide fanfare for a new First Under Heaven
/proc/jianghu_announce_first_under_heaven(mob/living/champion, reason)
	minor_announce("[champion.real_name] [reason || "has defeated all comers"] and is now known as First Under Heaven!", "Martial World Ranking")
	new /obj/effect/temp_visual/cultivation_realm_banner(get_turf(champion), "First Under Heaven")
	cultivation_great_bell(champion, 60)

/// The top three cultivate a little faster
/proc/jianghu_refresh_ranking_bonuses()
	for(var/datum/antagonist/cultivator/cultivator in GLOB.antagonists)
		var/rank = jianghu_rank_of(cultivator.owner)
		if(rank && rank <= 3)
			cultivator.insight_bonuses["martial_ranking"] = JIANGHU_RANKING_INSIGHT_BONUS
		else
			cultivator.insight_bonuses -= "martial_ranking"

/// One line per ranked fighter, best first
/proc/jianghu_ranking_lines()
	. = list()
	var/datum/mind/saber = jianghu_saber_holder()
	if(saber)
		. += "<b>First Under Heaven:</b> [saber.name] (holds the Dragon Slaying Saber)"
	for(var/i in 1 to length(GLOB.jianghu_ranking))
		var/datum/mind/fighter = GLOB.jianghu_ranking[i]
		. += "#[i] [fighter.name][(i == 1 && !saber) ? " <i>(First Under Heaven)</i>" : ""]"
	if(!length(.))
		. += "<i>Nobody has made a name in the jianghu yet. Win an honor duel to claim a place.</i>"

/// Rank one is beneath challenges from anyone outside the top five
/proc/jianghu_refuses_challenge(mob/living/challenger, mob/living/opponent)
	if(jianghu_first_under_heaven() != opponent.mind)
		return FALSE
	var/challenger_rank = jianghu_rank_of(challenger.mind)
	return !challenger_rank || challenger_rank > 5

#undef JIANGHU_RANKING_SIZE
#undef JIANGHU_RANKING_INSIGHT_BONUS
