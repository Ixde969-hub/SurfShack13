/**
 * # Sworn brotherhood
 *
 * "We were not born on the same day, but we will die on the same day."
 *
 * Light a bundle of incense and offer it to someone beside you. If they accept, you are sworn siblings for the rest of the round
 * (up to three, like the Peach Garden Oath). Anyone can swear, cultivator or not, but only once a round.
 *
 * Within nine tiles of each other, sworn siblings tire less and hit a little harder. When one is badly hurt the others feel it
 * and know which way to run, and when one dies the others fly into a grieving rage.
 * Turning on your sworn sibling breaks the oath: you lose a great deal of face, and a cultivator's guilt tears loose as a heart demon.
 */

/// Most people one oath can bind
#define SWORN_MAX_MEMBERS 3
/// How close siblings have to stand to fight better together
#define SWORN_RANGE 9

/// mind -> their bond
GLOBAL_LIST_EMPTY(sworn_bonds)
/// Minds that have already sworn (or broken) an oath this round
GLOBAL_LIST_EMPTY(sworn_oath_takers)
/// mind -> world.time their oathbreaker shame fades
GLOBAL_LIST_EMPTY(sworn_oathbreakers)

/proc/sworn_bond_of(datum/mind/mind)
	return mind ? GLOB.sworn_bonds[mind] : null

/// Are these two sworn to each other?
/proc/sworn_siblings(mob/living/one, mob/living/two)
	var/datum/sworn_bond/bond = sworn_bond_of(one?.mind)
	return bond && two?.mind && (two.mind in bond.members)

/datum/sworn_bond
	/// Minds bound by the oath
	var/list/datum/mind/members = list()
	/// Bodies we're listening to, so a body swap moves the bond with the mind
	var/list/mob/living/listening = list()
	/// "attacker ref" -> list of world.times they struck a sibling, to tell a stray blow from betrayal
	var/list/strikes = list()
	/// mind -> world.time we can next warn the others they're hurt
	var/list/hurt_warnings = list()

/datum/sworn_bond/New(list/datum/mind/founders)
	for(var/datum/mind/founder as anything in founders)
		add_member(founder)
	START_PROCESSING(SSprocessing, src)

/datum/sworn_bond/Destroy(force)
	STOP_PROCESSING(SSprocessing, src)
	for(var/mob/living/body as anything in listening)
		stop_listening(body)
	for(var/datum/mind/member as anything in members)
		if(GLOB.sworn_bonds[member] == src)
			GLOB.sworn_bonds -= member
	members.Cut()
	return ..()

/datum/sworn_bond/proc/add_member(datum/mind/member)
	members |= member
	GLOB.sworn_bonds[member] = src
	GLOB.sworn_oath_takers |= member
	member.current?.AddElement(/datum/element/jianghu_examine)

/datum/sworn_bond/proc/living_bodies()
	. = list()
	for(var/datum/mind/member as anything in members)
		var/mob/living/body = member.current
		if(isliving(body) && body.stat != DEAD)
			. += body

/datum/sworn_bond/proc/listen_to(mob/living/body)
	listening |= body
	if(!HAS_TRAIT(body, TRAIT_RELAYING_ATTACKER))
		body.AddElement(/datum/element/relay_attackers)
	RegisterSignal(body, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(body, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(on_health_update))
	RegisterSignal(body, COMSIG_QDELETING, PROC_REF(on_body_deleted))

/datum/sworn_bond/proc/stop_listening(mob/living/body)
	listening -= body
	UnregisterSignal(body, list(COMSIG_ATOM_WAS_ATTACKED, COMSIG_LIVING_DEATH, COMSIG_LIVING_HEALTH_UPDATE, COMSIG_QDELETING))
	body.remove_status_effect(/datum/status_effect/sworn_together)

/datum/sworn_bond/proc/on_body_deleted(mob/living/source)
	SIGNAL_HANDLER
	stop_listening(source)

/// Keep signals on whatever bodies the minds are wearing, and the together-bonus on whoever has a sibling close by
/datum/sworn_bond/process(seconds_per_tick)
	var/list/current = list()
	for(var/datum/mind/member as anything in members)
		if(isliving(member.current))
			current += member.current
	for(var/mob/living/old_body as anything in listening - current)
		stop_listening(old_body)
	for(var/mob/living/new_body as anything in current - listening)
		listen_to(new_body)
	var/list/alive = living_bodies()
	for(var/mob/living/body as anything in alive)
		for(var/mob/living/sibling as anything in alive)
			if(sibling != body && sibling.z == body.z && get_dist(sibling, body) <= SWORN_RANGE)
				body.apply_status_effect(/datum/status_effect/sworn_together)
				break

/// Badly hurt: the others feel it, and which way to go
/datum/sworn_bond/proc/on_health_update(mob/living/source)
	SIGNAL_HANDLER
	if(source.stat == DEAD || source.health > source.maxHealth * 0.5 || world.time < hurt_warnings[source.mind])
		return
	hurt_warnings[source.mind] = world.time + 30 SECONDS
	for(var/mob/living/sibling as anything in living_bodies())
		if(sibling == source)
			continue
		var/where = sibling.z == source.z ? " to the [dir2text(get_dir(sibling, source))], in [get_area_name(source)]" : " somewhere far away"
		to_chat(sibling, span_userdanger("Your heart lurches. Your sworn sibling [source.real_name] is badly hurt[where]!"))
		sibling.balloon_alert(sibling, "[source.real_name] is hurt!")
		sibling.playsound_local(get_turf(sibling), 'sound/effects/singlebeat.ogg', 50, FALSE)

/// Struck by someone: a sibling raising a hand against a sibling, again and again, is betrayal
/datum/sworn_bond/proc/on_attacked(mob/living/victim, atom/attacker, attack_flags)
	SIGNAL_HANDLER
	if(!isliving(attacker) || attacker == victim)
		return
	var/mob/living/striker = attacker
	if(!striker.mind || !(striker.mind in members))
		return
	// Sparring in an honor duel is fine
	var/datum/jianghu_duel/duel = GLOB.jianghu_duels[victim]
	if(duel && GLOB.jianghu_duels[striker] == duel)
		return
	var/list/recent = strikes[REF(striker)] || list()
	recent += world.time
	for(var/time in recent.Copy())
		if(time < world.time - 20 SECONDS)
			recent -= time
	strikes[REF(striker)] = recent
	if(length(recent) == 1)
		to_chat(striker, span_warning("You strike your own sworn sibling. Again, and the oath is broken."))
	else if(length(recent) >= 3)
		INVOKE_ASYNC(src, PROC_REF(betrayal), striker, victim)

/// One of us has fallen: grief and fury for the rest. Fallen at a sibling's hand, it's betrayal.
/datum/sworn_bond/proc/on_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	for(var/mob/living/sibling as anything in living_bodies())
		if(sibling == source)
			continue
		var/list/recent = strikes[REF(sibling)]
		if(length(recent) && recent[length(recent)] > world.time - 10 SECONDS)
			INVOKE_ASYNC(src, PROC_REF(betrayal), sibling, source)
			return
	for(var/mob/living/sibling as anything in living_bodies())
		if(sibling == source)
			continue
		to_chat(sibling, span_userdanger("Your sworn sibling [source.real_name] has died! Grief turns to fury!"))
		sibling.apply_status_effect(/datum/status_effect/sworn_vengeance)

/// The oath is broken. The betrayer carries the shame.
/datum/sworn_bond/proc/betrayal(mob/living/betrayer, mob/living/betrayed)
	if(QDELETED(src))
		return
	betrayer.visible_message(span_boldwarning("[betrayer] has betrayed [betrayer.p_their()] sworn sibling [betrayed]!"), span_userdanger("You have broken your oath of brotherhood. Heaven saw it."))
	for(var/mob/living/sibling as anything in living_bodies())
		if(sibling != betrayer)
			to_chat(sibling, span_userdanger("[betrayer.real_name] has betrayed the oath! Your bond is broken."))
	GLOB.sworn_oathbreakers[betrayer.mind] = world.time + 20 MINUTES
	jianghu_adjust_face(betrayer, -10, "betrayed a sworn sibling")
	betrayer.add_mood_event("oathbreaker", /datum/mood_event/oathbreaker)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(betrayer))
	if(IS_CULTIVATOR(betrayer))
		cultivation_summon_heart_demon(betrayer)
	betrayer.log_message("broke their oath of brotherhood by attacking [key_name(betrayed)]", LOG_ATTACK)
	qdel(src)

/// Is this mind marked as an oathbreaker right now?
/proc/sworn_is_oathbreaker(datum/mind/mind)
	return mind && GLOB.sworn_oathbreakers[mind] > world.time

// ===================== The incense =====================

/obj/item/sworn_incense
	name = "bundle of incense"
	desc = "Three sticks of sandalwood incense tied with red thread. Light it and offer it to someone to swear brotherhood."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "incense"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	var/lit = FALSE

/obj/item/sworn_incense/examine(mob/user)
	. = ..()
	. += span_notice(lit ? "It's lit. Use it on someone beside you to offer an oath of brotherhood." : "Use it in hand to light it.")

/obj/item/sworn_incense/attack_self(mob/user)
	if(lit)
		return
	lit = TRUE
	icon_state = "incense_lit"
	update_appearance()
	user.visible_message(span_notice("[user] lights [src]. Fragrant smoke curls upward."))
	playsound(src, 'sound/items/match_strike.ogg', 40, TRUE)
	cultivation_particles(src, /particles/cultivation/incense, 2 MINUTES)
	addtimer(CALLBACK(src, PROC_REF(burn_down)), 2 MINUTES)

/obj/item/sworn_incense/proc/burn_down()
	visible_message(span_notice("[src] burns down to ash."))
	new /obj/effect/decal/cleanable/ash(drop_location())
	qdel(src)

/obj/item/sworn_incense/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ishuman(interacting_with) || interacting_with == user)
		return NONE
	if(!lit)
		to_chat(user, span_warning("Light the incense first."))
		return ITEM_INTERACT_BLOCKING
	INVOKE_ASYNC(src, PROC_REF(offer_oath), user, interacting_with)
	return ITEM_INTERACT_SUCCESS

/// Why someone can't swear right now, or null if they can
/proc/sworn_oath_problem(mob/living/who, datum/sworn_bond/joining)
	if(!who.mind || !who.client)
		return "[who] has no mind to swear with."
	var/datum/sworn_bond/bond = sworn_bond_of(who.mind)
	if(bond && bond != joining)
		return "[who] is already sworn to others."
	if(!bond && (who.mind in GLOB.sworn_oath_takers))
		return "[who] has already sworn an oath this round."
	return null

/obj/item/sworn_incense/proc/offer_oath(mob/living/user, mob/living/carbon/human/other)
	var/datum/sworn_bond/existing = sworn_bond_of(user.mind) || sworn_bond_of(other.mind)
	if(existing && sworn_bond_of(user.mind) && sworn_bond_of(other.mind))
		to_chat(user, span_warning(sworn_bond_of(user.mind) == sworn_bond_of(other.mind) ? "You are already sworn to [other]." : "You are both already sworn to others."))
		return
	if(existing && length(existing.members) >= SWORN_MAX_MEMBERS)
		to_chat(user, span_warning("An oath can bind no more than [SWORN_MAX_MEMBERS]."))
		return
	for(var/mob/living/swearer as anything in list(user, other))
		var/problem = sworn_oath_problem(swearer, existing)
		if(problem)
			to_chat(user, span_warning(problem))
			return
	var/joining_text = ""
	if(existing)
		var/list/names = list()
		for(var/datum/mind/member as anything in existing.members)
			names += member.name
		joining_text = " and join the oath already sworn by [english_list(names)]"
	if(tgui_alert(other, "[user] offers you lit incense and asks you to swear brotherhood[joining_text]. Sworn siblings fight better together and feel each other's pain. Betraying the oath is deeply shameful. Swear?", "Oath of Brotherhood", list("Swear the oath", "Refuse"), 30 SECONDS) != "Swear the oath")
		to_chat(user, span_warning("[other] declines your oath."))
		return
	if(QDELETED(src) || QDELETED(user) || QDELETED(other) || get_dist(user, other) > 1)
		return
	// Recheck: someone may have sworn elsewhere while the prompt was up
	existing = sworn_bond_of(user.mind) || sworn_bond_of(other.mind)
	if((existing && length(existing.members) >= SWORN_MAX_MEMBERS) || sworn_oath_problem(user, existing) || sworn_oath_problem(other, existing))
		return
	user.visible_message(span_notice("[user] and [other] kneel together before the burning incense."))
	if(!do_after(user, 3 SECONDS, other))
		return
	user.say("We were not born on the same day...", forced = "sworn oath")
	other.say("...but we will die on the same day!", forced = "sworn oath")
	if(existing)
		existing.add_member(user.mind)
		existing.add_member(other.mind)
	else
		new /datum/sworn_bond(list(user.mind, other.mind))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(user))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(other))
	cultivation_guqin_phrase(user, list(1, 3, 5, 6))
	for(var/mob/living/sworn as anything in list(user, other))
		to_chat(sworn, span_boldnotice("You are sworn siblings! Within [SWORN_RANGE] tiles of each other you tire less and strike harder. You will feel it when they are hurt."))
		sworn.add_mood_event("sworn_oath", /datum/mood_event/sworn_oath)
		sworn.log_message("swore brotherhood with [key_name(sworn == user ? other : user)]", LOG_GAME)
	burn_down()

/datum/crafting_recipe/sworn_incense
	name = "Bundle of Incense"
	result = /obj/item/sworn_incense
	reqs = list(/obj/item/stack/sheet/mineral/wood = 1, /obj/item/paper = 1)
	time = 3 SECONDS
	category = CAT_MISC

/particles/cultivation/incense
	icon_state = "qi_mote"
	color = "#d8d0c0"
	spawning = 1
	count = 20
	lifespan = 2 SECONDS
	fade = 1 SECONDS
	position = list(0, 8)
	velocity = list(0, 0.4)
	drift = generator(GEN_VECTOR, list(-0.1, 0), list(0.1, 0.05))
	scale = generator(GEN_VECTOR, list(0.4, 0.4), list(0.7, 0.7), NORMAL_RAND)

// ===================== Effects =====================

/// A sworn sibling is close: you tire less and hit harder
/datum/status_effect/sworn_together
	id = "sworn_together"
	alert_type = /atom/movable/screen/alert/status_effect/sworn_together
	duration = 3 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = STATUS_EFFECT_NO_TICK

/datum/status_effect/sworn_together/on_apply()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(steadfast))
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack))
	RegisterSignal(owner, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	return TRUE

/datum/status_effect/sworn_together/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_UNARMED_ATTACK))

/datum/status_effect/sworn_together/proc/steadfast(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype == STAMINA)
		damage_mods += 0.75

/datum/status_effect/sworn_together/proc/on_item_attack(mob/living/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	sworn_extra_blow(target, 2)

/datum/status_effect/sworn_together/proc/on_unarmed_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(proximity && !LAZYACCESS(modifiers, RIGHT_CLICK))
		sworn_extra_blow(target, 2)

/datum/status_effect/sworn_together/proc/sworn_extra_blow(atom/target, damage)
	if(!isliving(target) || target == owner || sworn_siblings(owner, target))
		return
	var/mob/living/victim = target
	if(victim.stat != DEAD)
		victim.apply_damage(damage, BRUTE)

/atom/movable/screen/alert/status_effect/sworn_together
	name = "Sworn Siblings"
	desc = "Your sworn sibling fights beside you. You tire less and strike harder."
	icon_state = "in_love"

/// A sworn sibling has died. Grief becomes fury.
/datum/status_effect/sworn_vengeance
	id = "sworn_vengeance"
	alert_type = /atom/movable/screen/alert/status_effect/sworn_vengeance
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = STATUS_EFFECT_NO_TICK

/datum/status_effect/sworn_vengeance/on_apply()
	owner.add_traits(list(TRAIT_ANALGESIA), TRAIT_STATUS_EFFECT(id))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(fury))
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack))
	RegisterSignal(owner, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	owner.add_filter("sworn_vengeance", 2, list("type" = "outline", "color" = "#c0201a", "size" = 1))
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/sworn_vengeance)
	return TRUE

/datum/status_effect/sworn_vengeance/on_remove()
	owner.remove_traits(list(TRAIT_ANALGESIA), TRAIT_STATUS_EFFECT(id))
	UnregisterSignal(owner, list(COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_UNARMED_ATTACK))
	owner.remove_filter("sworn_vengeance")
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/sworn_vengeance)
	to_chat(owner, span_notice("Your fury cools into a cold, quiet grief."))

/datum/status_effect/sworn_vengeance/proc/fury(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype == STAMINA)
		damage_mods += 0.5

/datum/status_effect/sworn_vengeance/proc/on_item_attack(mob/living/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	vengeful_blow(target)

/datum/status_effect/sworn_vengeance/proc/on_unarmed_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(proximity && !LAZYACCESS(modifiers, RIGHT_CLICK))
		vengeful_blow(target)

/datum/status_effect/sworn_vengeance/proc/vengeful_blow(atom/target)
	if(!isliving(target) || target == owner)
		return
	var/mob/living/victim = target
	if(victim.stat != DEAD)
		victim.apply_damage(5, BRUTE)
		new /obj/effect/temp_visual/cultivation_spark(get_turf(victim), "#ff3a2a", rand(-6, 6), rand(0, 10))

/datum/movespeed_modifier/status_effect/sworn_vengeance
	multiplicative_slowdown = -0.2

/atom/movable/screen/alert/status_effect/sworn_vengeance
	name = "Vengeance"
	desc = "Your sworn sibling is dead. Pain means nothing; you hit harder and move faster."
	icon_state = "blooddrunk"

/datum/mood_event/sworn_oath
	description = "I swore an oath of brotherhood. Someone has my back."
	mood_change = 4
	timeout = 20 MINUTES

/datum/mood_event/oathbreaker
	description = "I betrayed my sworn sibling. I'll never wash this off."
	mood_change = -8
	timeout = 20 MINUTES

#undef SWORN_MAX_MEMBERS
#undef SWORN_RANGE
