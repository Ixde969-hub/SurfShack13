/**
 * Legendary weapons and treasures from Chinese legend and the martial novels.
 * One turns up somewhere in maintenance each round. Any of them can be bound with Returning Iron.
 *
 * They are meant to stand level with (or above) a Primordial Chaos Body: every hit from a legendary artifact is true damage that ignores
 * tempered flesh and armour, and nobody braces against them by realm. Each one answers the body path in its own way (legendary_traits):
 * the swords that cut cut through Iron Shirt, the paired blades wear a body down, the saber crushes the more tempered the body is.
 * Refining a bound artifact makes it stronger still.
 */

/// Every legendary artifact in existence
GLOBAL_LIST_EMPTY(legendary_artifacts)

/obj/item/cultivation_artifact
	icon = 'surfshack13/icons/cultivation/cultivation_artifacts.dmi'
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	/// Shown on examine to cultivators
	var/legend = ""
	/// What its active power does, shown on examine to everyone
	var/power_text = ""
	/// How its blows treat body cultivators, see LEGENDARY_* defines
	var/legendary_traits = NONE

/obj/item/cultivation_artifact/Initialize(mapload)
	. = ..()
	GLOB.legendary_artifacts += src

/obj/item/cultivation_artifact/Destroy()
	GLOB.legendary_artifacts -= src
	return ..()

/obj/item/cultivation_artifact/examine(mob/user)
	. = ..()
	if(power_text)
		. += span_notice("[power_text]")
	if(force || throwforce > 5)
		. += span_notice("Its blows are true damage that ignore armour and any body's tempering.")
	if(legendary_traits & LEGENDARY_BREAKS_DEFENCE)
		. += span_notice("It cuts straight through Iron Shirt and the Vajra Golden Body.")
	if(legendary_traits & LEGENDARY_WEARS_DOWN)
		. += span_notice("Every blow knocks the breath out of a body cultivator.")
	if(legendary_traits & LEGENDARY_CRUSHES_TEMPERED)
		. += span_notice("The more tempered the body it strikes, the harder it lands.")
	if(legend && (IS_CULTIVATOR(user) || IS_BODY_CULTIVATOR(user) || isobserver(user)))
		. += span_notice("<i>[legend]</i>")

/// How much stronger a bound, refined artifact hits: +10% per refinement grade
/proc/legendary_power(obj/item/artifact)
	var/datum/component/cultivation_artifact/bond = artifact?.GetComponent(/datum/component/cultivation_artifact)
	return 1 + (bond ? 0.1 * bond.refinement : 0)

/**
 * A legendary blow. True damage (no armour, no damage reduction, no realm bracing).
 * What it does to a body cultivator depends on the artifact's legendary_traits.
 */
/proc/legendary_hit(mob/living/user, mob/living/victim, damage, knockdown = 0, source_name = "a legendary artifact", obj/item/cultivation_artifact/artifact)
	if(QDELETED(victim) || victim == user || victim.stat == DEAD)
		return FALSE
	var/traits = istype(artifact) ? artifact.legendary_traits : NONE
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(victim)
	if(body_datum?.stage)
		if(traits & LEGENDARY_CRUSHES_TEMPERED)
			damage += 3 * body_datum.stage
		if(traits & LEGENDARY_WEARS_DOWN)
			body_datum.add_exhaustion(10 + 2 * body_datum.stage)
		if(traits & LEGENDARY_BREAKS_DEFENCE)
			var/broke_defence = victim.has_status_effect(/datum/status_effect/body_iron_shirt) || victim.has_status_effect(/datum/status_effect/body_vajra)
			victim.remove_status_effect(/datum/status_effect/body_iron_shirt)
			victim.remove_status_effect(/datum/status_effect/body_vajra)
			if(broke_defence)
				victim.visible_message(span_danger("[source_name] cuts through [victim]'s golden body like silk!"), span_userdanger("[source_name] slices clean through your iron skin!"))
		if(traits)
			new /obj/effect/temp_visual/cultivation_spark(get_turf(victim), "#ffffff", rand(-6, 6), rand(0, 10))
	victim.apply_damage(damage * legendary_power(artifact), BRUTE, forced = TRUE, wound_bonus = 10)
	cultivation_heavy_blow(victim, damage * legendary_power(artifact))
	if(knockdown)
		victim.Knockdown(knockdown)
	log_combat(user, victim, "struck with [source_name]")
	return TRUE

// ===================== Ganjiang and Moye =====================

/obj/item/cultivation_artifact/twin_sword
	icon_state = "ganjiang"
	inhand_icon_state = "sabre"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 22
	throwforce = 18
	armour_penetration = 40
	w_class = WEIGHT_CLASS_NORMAL
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("slashes", "cuts", "pierces")
	attack_verb_simple = list("slash", "cut", "pierce")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	block_chance = 30
	legend = "The swordsmith Ganjiang and his wife Moye forged a pair of swords, one male and one female. Held together, they long for each other."
	power_text = "Held together (by you, or by two people standing side by side), the pair strike twice as hard, parry far more, and can be used in hand \
		to unleash the Twin Dragon Sword Storm: five seconds of slashing everything around you. Apart, use one in hand to sense where the other is."
	legendary_traits = LEGENDARY_WEARS_DOWN
	/// The other sword type of the pair
	var/partner_type = /obj/item/cultivation_artifact/twin_sword/moye
	COOLDOWN_DECLARE(storm_cooldown)

/obj/item/cultivation_artifact/twin_sword/ganjiang
	name = "Ganjiang"
	desc = "A dark blue-black jian, the male sword of the legendary pair."

/obj/item/cultivation_artifact/twin_sword/moye
	name = "Moye"
	desc = "A pale silver jian with a red tassel, the female sword of the legendary pair."
	icon_state = "moye"
	partner_type = /obj/item/cultivation_artifact/twin_sword/ganjiang

/// Is the partner sword in this person's other hand, or in the hand of someone standing right beside them?
/obj/item/cultivation_artifact/twin_sword/proc/paired(mob/living/user)
	if(!istype(user))
		return FALSE
	if(locate(partner_type) in user.held_items)
		return TRUE
	return !!partner_wielder(user)

/// Someone beside us holding the other sword, if any
/obj/item/cultivation_artifact/twin_sword/proc/partner_wielder(mob/living/user)
	for(var/mob/living/beside in orange(1, user))
		if(beside.stat == CONSCIOUS && (locate(partner_type) in beside.held_items))
			return beside
	return null

/// The other sword of the pair, wherever it is
/obj/item/cultivation_artifact/twin_sword/proc/find_partner()
	for(var/obj/item/cultivation_artifact/twin_sword/sword in GLOB.legendary_artifacts)
		if(istype(sword, partner_type))
			return sword
	return null

/// Apart, each sword pulls towards the other
/obj/item/cultivation_artifact/twin_sword/proc/sense_partner(mob/user)
	var/obj/item/cultivation_artifact/twin_sword/partner = find_partner()
	var/turf/here = get_turf(user)
	var/turf/there = get_turf(partner)
	if(!partner || !there)
		to_chat(user, span_warning("[src] is silent. Its partner is nowhere in this world."))
		return
	if(there.z != here.z)
		to_chat(user, span_notice("[src] strains faintly towards [partner], somewhere very far away."))
		return
	var/distance = get_dist(here, there)
	to_chat(user, span_notice("[src] tugs towards [partner][distance <= 1 ? ", right beside you" : ", [distance] tiles to the [dir2text(get_dir(here, there))], in [get_area_name(there)]"]."))
	new /obj/effect/temp_visual/circle_wave/cultivation(here)

/obj/item/cultivation_artifact/twin_sword/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/victim = target
	var/together = paired(user)
	legendary_hit(user, victim, together ? 12 : 5, 0, name, src)
	new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), "#9fb8ff")
	if(together && prob(25))
		user.visible_message(span_danger("Ganjiang and Moye sing in harmony as [user] strikes!"))

/obj/item/cultivation_artifact/twin_sword/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(paired(owner))
		final_block_chance += 30
	return ..()

/obj/item/cultivation_artifact/twin_sword/attack_self(mob/user)
	if(!paired(user))
		sense_partner(user)
		return
	var/obj/item/cultivation_artifact/twin_sword/partner = locate(partner_type) in user.held_items
	var/mob/living/partner_holder = partner ? null : partner_wielder(user)
	partner = partner || (locate(partner_type) in partner_holder?.held_items)
	if(!COOLDOWN_FINISHED(src, storm_cooldown) || (partner && !COOLDOWN_FINISHED(partner, storm_cooldown)))
		user.balloon_alert(user, "the swords are resting!")
		return
	COOLDOWN_START(src, storm_cooldown, 40 SECONDS)
	if(partner)
		COOLDOWN_START(partner, storm_cooldown, 40 SECONDS)
	user.say("TWIN DRAGON SWORD STORM!!", forced = "ganjiang and moye")
	playsound(user, 'sound/effects/magic/repulse.ogg', 70, TRUE, frequency = 1.4)
	// Two wielders side by side: both of them spin
	var/list/spinners = list(user)
	if(partner_holder)
		spinners += partner_holder
		partner_holder.say("TWIN DRAGON SWORD STORM!!", forced = "ganjiang and moye")
	for(var/mob/living/spinner as anything in spinners)
		spinner.visible_message(span_boldwarning("[spinner] spins into a whirlwind of blue and silver steel!"))
		var/obj/item/cultivation_artifact/twin_sword/spinner_sword = (spinner == user) ? src : partner
		for(var/i in 0 to 9)
			addtimer(CALLBACK(spinner_sword, PROC_REF(storm_tick), spinner), i * 0.5 SECONDS)

/obj/item/cultivation_artifact/twin_sword/proc/storm_tick(mob/living/user)
	if(QDELETED(user) || user.stat != CONSCIOUS || !paired(user))
		return
	user.SpinAnimation(4, 1)
	playsound(user, pick('sound/items/weapons/bladeslice.ogg', 'sound/items/weapons/slice.ogg'), 50, TRUE)
	for(var/mob/living/victim in range(2, user))
		if(victim == user || victim.stat == DEAD)
			continue
		new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), pick("#9fb8ff", "#e8e8ff"))
		legendary_hit(user, victim, 8, 0, "Ganjiang and Moye", src)
	for(var/turf/nearby in range(1, user))
		for(var/obj/structure/window/window in nearby)
			window.take_damage(40, BRUTE, MELEE)

/obj/item/cultivation_artifact/twin_sword/equipped(mob/user, slot, initial)
	. = ..()
	update_pair_glow(user)

/obj/item/cultivation_artifact/twin_sword/dropped(mob/user, silent)
	. = ..()
	remove_filter("twin_glow")
	for(var/obj/item/cultivation_artifact/twin_sword/other in user?.held_items)
		other.remove_filter("twin_glow")

/obj/item/cultivation_artifact/twin_sword/proc/update_pair_glow(mob/living/user)
	if(!paired(user))
		return
	for(var/obj/item/cultivation_artifact/twin_sword/sword in user.held_items)
		sword.add_filter("twin_glow", 2, list("type" = "outline", "color" = "#c0d0ff", "size" = 1))
	to_chat(user, span_notice("Ganjiang and Moye hum as they are reunited."))

// ===================== Heaven Reliant Sword and Dragon Slaying Saber =====================

/obj/item/cultivation_artifact/heaven_reliant
	name = "Heaven Reliant Sword"
	desc = "A long, impossibly keen sword of pale jade-white steel. It cuts iron like mud: use it on a wall to carve straight through it, \
		and doors, windows and machines fall apart under it."
	icon_state = "heaven_reliant"
	inhand_icon_state = "katana"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 30
	throwforce = 20
	armour_penetration = 80
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	block_chance = 30
	attack_verb_continuous = list("slices", "cleaves", "shears")
	attack_verb_simple = list("slice", "cleave", "shear")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	legend = "\"Supreme in the martial world is the Dragon Slaying Saber. Who dares not obey? If the Heaven Reliant Sword does not appear, who can contend with it?\""
	power_text = "Click a distant spot to loose the Heaven-Cleaving Stroke: a blade of light fourteen tiles long and three wide that slices through people, doors and even reinforced walls. \
		Its blows shred the armour of whoever they hit."
	legendary_traits = LEGENDARY_BREAKS_DEFENCE
	COOLDOWN_DECLARE(cleave_cooldown)

/obj/item/cultivation_artifact/heaven_reliant/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(isliving(target))
		legendary_hit(user, target, 12, 0, name, src)
		shred_armour(target)
		return
	// It cuts through iron like mud: doors, windows, grilles, lockers and machines barely slow it down
	if(isobj(target) && !isitem(target))
		var/obj/cut = target
		if(!cut.uses_integrity || (cut.resistance_flags & INDESTRUCTIBLE))
			return
		cut.take_damage(force * 6, BRUTE, MELEE, armour_penetration = 100)
		new /obj/effect/temp_visual/slash(get_turf(cut), cut, rand(10, 22), rand(10, 22), "#d8fff0")

/// It cuts iron like mud, and armour is only iron
/obj/item/cultivation_artifact/heaven_reliant/proc/shred_armour(mob/living/carbon/human/victim)
	if(!ishuman(victim))
		return
	for(var/obj/item/clothing/worn in list(victim.wear_suit, victim.head))
		if(worn.resistance_flags & INDESTRUCTIBLE)
			continue
		worn.take_damage(40, BRUTE, MELEE, armour_penetration = 100)
		new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), "#d8fff0")
		to_chat(victim, span_warning("The Heaven Reliant Sword slices through your [worn.name]!"))

/// Walls are carved straight through, like mud
/obj/item/cultivation_artifact/heaven_reliant/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!iswallturf(interacting_with))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(carve_wall), interacting_with, user)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/heaven_reliant/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!COOLDOWN_FINISHED(src, cleave_cooldown))
		user.balloon_alert(user, "the blade is gathering light!")
		return ITEM_INTERACT_BLOCKING
	var/direction = get_dir(user, interacting_with)
	if(!direction)
		return NONE
	COOLDOWN_START(src, cleave_cooldown, 20 SECONDS)
	user.say("HEAVEN-CLEAVING STROKE!!", forced = "heaven reliant sword")
	user.visible_message(span_boldwarning("[user] sweeps the Heaven Reliant Sword and a blade of pale light splits the air!"))
	user.do_attack_animation(get_step(user, direction))
	playsound(user, 'sound/items/weapons/bladeslice.ogg', 80, TRUE, frequency = 0.6)
	playsound(user, 'sound/effects/magic/repulse.ogg', 60, TRUE, frequency = 1.5)
	cultivation_distortion_wave(user, 3, 0.4 SECONDS, 200)
	body_art_shatter_line(user, get_turf(user), direction, 14, 1, 25, 2, name, 0.2, src)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/heaven_reliant/proc/carve_wall(turf/closed/wall/wall, mob/living/user)
	if(DOING_INTERACTION_WITH_TARGET(user, wall))
		return
	var/reinforced = istype(wall, /turf/closed/wall/r_wall)
	user.visible_message(span_warning("[user] draws the Heaven Reliant Sword across [wall]. The blade sinks into the metal like it's mud!"),
		span_notice("You begin carving through [wall]..."))
	playsound(wall, 'sound/items/weapons/bladeslice.ogg', 60, TRUE)
	var/carve_time = reinforced ? 2 SECONDS : 1 SECONDS
	if(!do_after(user, carve_time, wall))
		return
	new /obj/effect/temp_visual/slash(wall, null, 0, 0, "#d8fff0")
	do_sparks(2, FALSE, wall)
	if(QDELETED(wall) || !iswallturf(wall))
		return
	user.visible_message(span_boldwarning("[user] slices clean through [wall], which collapses into neat pieces!"))
	playsound(wall, 'sound/effects/meteorimpact.ogg', 40, TRUE)
	user.log_message("carved through [wall] at [AREACOORD(wall)] with the Heaven Reliant Sword", LOG_ATTACK)
	wall.dismantle_wall()

/obj/item/cultivation_artifact/dragon_saber
	name = "Dragon Slaying Saber"
	desc = "A massive black dao with a golden dragon coiled along the blade. Every blow lands like a falling mountain."
	icon_state = "dragon_saber"
	inhand_icon_state = "claymore"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 35
	throwforce = 25
	armour_penetration = 60
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	attack_speed = CLICK_CD_MELEE * 1.3
	attack_verb_continuous = list("hacks", "cleaves", "crushes")
	attack_verb_simple = list("hack", "cleave", "crush")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	legend = "\"Supreme in the martial world is the Dragon Slaying Saber.\" Legend says it holds a secret, revealed only when it meets the Heaven Reliant Sword."
	power_text = "Every blow hurls its target and cracks the floor. Use it in hand to wake the dragon: your next blow within ten seconds is the Dragon Slaying Strike, \
		a cataclysm that flattens everything within three tiles and brings down even reinforced walls. Whoever holds it is First Under Heaven."
	legendary_traits = LEGENDARY_CRUSHES_TEMPERED
	/// The dragon is awake: the next hit is the Dragon Slaying Strike
	var/dragon_awake = FALSE
	COOLDOWN_DECLARE(claim_cooldown)
	COOLDOWN_DECLARE(dragon_cooldown)

/// Every Dragon Slaying Saber in existence, for the Martial World Ranking
GLOBAL_LIST_EMPTY(jianghu_dragon_sabers)

/obj/item/cultivation_artifact/dragon_saber/Initialize(mapload)
	. = ..()
	GLOB.jianghu_dragon_sabers += src

/obj/item/cultivation_artifact/dragon_saber/Destroy()
	GLOB.jianghu_dragon_sabers -= src
	return ..()

/// "Whoever holds the saber rules the martial world." Picking it up makes you First Under Heaven, and the station hears of it.
/obj/item/cultivation_artifact/dragon_saber/equipped(mob/user, slot, initial)
	. = ..()
	if(!isliving(user) || !user.mind || !(slot & ITEM_SLOT_HANDS) || !COOLDOWN_FINISHED(src, claim_cooldown))
		return
	COOLDOWN_START(src, claim_cooldown, 3 MINUTES)
	to_chat(user, span_boldnotice("Whoever holds the Dragon Slaying Saber rules the martial world. You are First Under Heaven, and everyone will want it from you."))
	jianghu_announce_first_under_heaven(user, "has claimed the Dragon Slaying Saber")

/obj/item/cultivation_artifact/dragon_saber/attack_self(mob/user)
	if(dragon_awake)
		return
	if(!COOLDOWN_FINISHED(src, dragon_cooldown))
		user.balloon_alert(user, "the dragon sleeps!")
		return
	COOLDOWN_START(src, dragon_cooldown, 30 SECONDS)
	dragon_awake = TRUE
	add_filter("dragon_awake", 2, list("type" = "outline", "color" = "#ffcc33", "size" = 2))
	user.visible_message(span_boldwarning("The golden dragon on [user]'s saber opens its eyes!"))
	playsound(user, 'sound/effects/magic/demon_dies.ogg', 50, TRUE, frequency = 0.5)
	addtimer(CALLBACK(src, PROC_REF(dragon_sleeps)), 10 SECONDS)

/obj/item/cultivation_artifact/dragon_saber/proc/dragon_sleeps()
	dragon_awake = FALSE
	remove_filter("dragon_awake")

/obj/item/cultivation_artifact/dragon_saber/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/victim = target
	if(dragon_awake)
		dragon_sleeps()
		dragon_slaying_strike(user, victim)
		return
	legendary_hit(user, victim, 15, 1 SECONDS, name, src)
	body_art_crack_ground(get_turf(victim), 0, 70, crater = FALSE)
	victim.Shake(2, 2, 0.4 SECONDS)
	victim.throw_at(get_edge_target_turf(victim, get_dir(user, victim)), 4, 2, user)

/obj/item/cultivation_artifact/dragon_saber/proc/dragon_slaying_strike(mob/living/user, mob/living/victim)
	var/turf/center = get_turf(victim)
	user.say("DRAGON SLAYING STRIKE!!", forced = "dragon slaying saber")
	user.visible_message(span_boldwarning("[user] brings the Dragon Slaying Saber down and a golden dragon erupts from the blade!"))
	playsound(center, 'sound/effects/explosion/explosion_distant.ogg', 90, TRUE)
	playsound(center, 'sound/effects/meteorimpact.ogg', 90, TRUE)
	cultivation_great_bell(center, 80)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(center)
	new /obj/effect/temp_visual/cultivation_crater(center, 2.5)
	cultivation_distortion_wave(victim, 7, 1 SECONDS, 255)
	body_art_crack_ground(center, 3, 70, crater = FALSE)
	legendary_hit(user, victim, 45, 3 SECONDS, "the Dragon Slaying Strike", src)
	for(var/turf/nearby in range(3, center))
		body_art_smash(nearby, user, 150, get_dist(nearby, center) <= 1 ? 2 : 0)
		if(prob(30))
			new /obj/effect/temp_visual/cultivation_rubble(nearby)
	for(var/mob/living/bystander in range(3, center))
		if(bystander == user || bystander == victim)
			continue
		legendary_hit(user, bystander, 15, 1.5 SECONDS, "the Dragon Slaying Strike", src)
		bystander.throw_at(get_edge_target_turf(bystander, get_dir(center, bystander)), 3, 2, user)
	for(var/mob/living/viewer in range(10, center))
		shake_camera(viewer, 6, 3)

/// The legend: strike the saber with the sword and both shatter, revealing the Nine Yin Manual and the Wumu Yishu hidden inside
/obj/item/cultivation_artifact/dragon_saber/attackby(obj/item/attacking_item, mob/user, list/modifiers)
	if(!istype(attacking_item, /obj/item/cultivation_artifact/heaven_reliant))
		return ..()
	if(tgui_alert(user, "Strike the Dragon Slaying Saber with the Heaven Reliant Sword? Both will shatter.", "The Secret of the Saber", list("Strike!", "No")) != "Strike!")
		return TRUE
	var/turf/clash = get_turf(src)
	user.visible_message(span_boldwarning("[user] brings the Heaven Reliant Sword down on the Dragon Slaying Saber! Both blades shatter, and something falls from within!"))
	playsound(clash, 'sound/effects/gong.ogg', 80, TRUE)
	playsound(clash, 'sound/effects/glass/glassbr3.ogg', 70, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(clash)
	new /obj/item/book/granter/legendary_inheritance/nine_yin(clash)
	new /obj/item/book/granter/legendary_inheritance/wumu_yishu(clash)
	user.log_message("shattered the Heaven Reliant Sword and the Dragon Slaying Saber at [AREACOORD(clash)]", LOG_GAME)
	qdel(attacking_item)
	qdel(src)
	return TRUE

// ===================== Ruyi Jingu Bang =====================

/obj/item/cultivation_artifact/ruyi_jingu_bang
	name = "Ruyi Jingu Bang"
	desc = "The Monkey King's staff, shrunk to the size of a sewing needle. Use it in hand to make it grow."
	icon_state = "ruyi_needle"
	inhand_icon_state = "bostaff0"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	force = 2
	throwforce = 2
	legend = "The As-You-Will Gold-Banded Cudgel. It weighs thirteen thousand five hundred jin and grows or shrinks at its master's word."
	power_text = "Grown, it strikes three tiles away and sends people flying. Click a distant spot to stretch it to the heavens and bring it down: \
		the Thirteen-Thousand-Jin Slam smashes a three-wide path through everything, walls included, and craters where it lands. \
		Right-click someone to Pluck Hairs: two copies of you leap out and fight them for ten seconds. \
		Set down at full size, it stands upright and nobody but you can lift it."
	var/extended = FALSE
	/// Who planted it upright, the only one who can lift it again
	var/datum/weakref/planter_ref
	COOLDOWN_DECLARE(slam_cooldown)
	COOLDOWN_DECLARE(hair_cooldown)

/obj/item/cultivation_artifact/ruyi_jingu_bang/attack_self(mob/user)
	extended = !extended
	if(extended)
		name = "Ruyi Jingu Bang"
		desc = "The Monkey King's staff, grown to full size. It reaches further than any normal weapon. Use it in hand to shrink it."
		icon_state = "ruyi_staff"
		inhand_icon_state = "bostaff1"
		w_class = WEIGHT_CLASS_HUGE
		force = 30
		throwforce = 20
		armour_penetration = 50
		reach = 3
		attack_verb_continuous = list("smashes", "whacks", "sends flying")
		attack_verb_simple = list("smash", "whack", "send flying")
		hitsound = 'sound/items/weapons/genhit3.ogg'
		user.visible_message(span_warning("[user] shouts \"Grow!\" and the needle in [user.p_their()] hand becomes a mighty golden-banded staff!"))
		user.say("Grow!", forced = "ruyi jingu bang")
	else
		desc = initial(desc)
		icon_state = initial(icon_state)
		inhand_icon_state = initial(inhand_icon_state)
		w_class = initial(w_class)
		force = initial(force)
		throwforce = initial(throwforce)
		armour_penetration = 0
		reach = 1
		user.visible_message(span_notice("[user]'s staff shrinks back down into a tiny golden needle."))
		user.say("Shrink!", forced = "ruyi jingu bang")
	playsound(src, 'sound/effects/magic/charge.ogg', 40, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(user))
	cultivation_particles(user, /particles/cultivation/gold, 1 SECONDS)
	update_appearance()
	user.update_held_items()

/// Set down at full size it stands like a pillar: thirteen thousand jin that only its master can lift
/obj/item/cultivation_artifact/ruyi_jingu_bang/dropped(mob/user, silent)
	. = ..()
	if(!extended || !isturf(loc) || !user?.mind)
		return
	planter_ref = WEAKREF(user.mind)
	anchored = TRUE
	density = TRUE
	transform = matrix().Turn(-45)
	visible_message(span_warning("[src] slams down upright and stands like a pillar. The floor creaks under it."))
	playsound(src, 'sound/effects/meteorimpact.ogg', 40, TRUE)

/obj/item/cultivation_artifact/ruyi_jingu_bang/attack_hand(mob/user, list/modifiers)
	if(anchored && planter_ref)
		var/datum/mind/planter = planter_ref.resolve()
		if(planter && user.mind != planter)
			user.visible_message(span_warning("[user] heaves at [src], which doesn't budge an inch."), span_warning("It weighs thirteen thousand five hundred jin. It won't move for you."))
			return TRUE
		anchored = FALSE
		density = FALSE
		transform = matrix()
		planter_ref = null
	return ..()

/// Pluck hairs and blow on them: copies of the wielder leap out to fight
/obj/item/cultivation_artifact/ruyi_jingu_bang/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	return pluck_hairs(interacting_with, user)

/obj/item/cultivation_artifact/ruyi_jingu_bang/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	return pluck_hairs(interacting_with, user)

/obj/item/cultivation_artifact/ruyi_jingu_bang/proc/pluck_hairs(atom/target, mob/living/user)
	if(!isliving(target) || target == user)
		return NONE
	if(!COOLDOWN_FINISHED(src, hair_cooldown))
		user.balloon_alert(user, "your hairs need to regrow!")
		return ITEM_INTERACT_BLOCKING
	COOLDOWN_START(src, hair_cooldown, 45 SECONDS)
	var/mob/living/foe = target
	user.visible_message(span_boldwarning("[user] plucks a few hairs, blows on them, and two copies of [user.p_them()] leap out!"))
	user.say("Clones of the Great Sage!", forced = "ruyi jingu bang")
	playsound(user, 'sound/effects/magic/blink.ogg', 50, TRUE)
	// The copies fight for their master and never turn on them
	var/faction_token = "great_sage_[REF(user)]"
	user.faction |= faction_token
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ruyi_forget_clones), user, faction_token), 11 SECONDS)
	for(var/i in 1 to 2)
		var/turf/landing = get_step(user, pick(GLOB.alldirs))
		if(!landing || landing.is_blocked_turf(exclude_mobs = TRUE))
			landing = get_turf(user)
		var/mob/living/simple_animal/hostile/illusion/clone = new(landing)
		clone.Copy_Parent(user, 10 SECONDS, 30, 6)
		clone.faction = list(faction_token)
		clone.GiveTarget(foe)
		new /obj/effect/temp_visual/small_smoke/halfsecond(landing)
	return ITEM_INTERACT_SUCCESS

/proc/ruyi_forget_clones(mob/living/user, faction_token)
	if(!QDELETED(user))
		user.faction -= faction_token

/obj/item/cultivation_artifact/ruyi_jingu_bang/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(!extended || !isliving(target))
		return
	var/mob/living/victim = target
	// The Monkey King's own kin hit hardest
	legendary_hit(user, victim, ismonkey(user) ? 20 : 10, 0, name, src)
	if(prob(60))
		victim.throw_at(get_edge_target_turf(victim, get_dir(user, victim)), 5, 2, user)

/obj/item/cultivation_artifact/ruyi_jingu_bang/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!extended)
		return NONE
	if(!COOLDOWN_FINISHED(src, slam_cooldown))
		user.balloon_alert(user, "the staff is heavy!")
		return ITEM_INTERACT_BLOCKING
	var/turf/target_turf = get_turf(interacting_with)
	var/direction = get_dir(user, target_turf)
	var/distance = min(get_dist(user, target_turf), 10)
	if(!direction || distance < 2)
		return NONE
	COOLDOWN_START(src, slam_cooldown, 25 SECONDS)
	user.say("THIRTEEN THOUSAND JIN!!", forced = "ruyi jingu bang")
	user.visible_message(span_boldwarning("The Ruyi Jingu Bang shoots up to the heavens and comes crashing down!"))
	playsound(user, 'sound/effects/magic/charge.ogg', 70, TRUE, frequency = 0.6)
	cultivation_particles(user, /particles/cultivation/gold, 1.5 SECONDS)
	body_art_shatter_line(user, get_turf(user), direction, distance, 1, ismonkey(user) ? 35 : 25, 2, name, 0.15, src)
	addtimer(CALLBACK(src, PROC_REF(slam_end), user, target_turf), distance * 0.15 + 0.2 SECONDS)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/ruyi_jingu_bang/proc/slam_end(mob/living/user, turf/landing)
	playsound(landing, 'sound/effects/explosion/explosion_distant.ogg', 80, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(landing)
	new /obj/effect/temp_visual/cultivation_crater(landing, 2)
	body_art_crack_ground(landing, 2, 60, crater = FALSE)
	for(var/mob/living/victim in range(2, landing))
		if(victim != user)
			legendary_hit(user, victim, 15, 2 SECONDS, name, src)
	for(var/mob/living/viewer in range(8, landing))
		shake_camera(viewer, 4, 3)

// ===================== Purple-Gold Gourd =====================

/obj/item/cultivation_artifact/purple_gold_gourd
	name = "Purple-Gold Gourd"
	desc = "A purple calabash with a gold band and a red cork. Point it at someone and call their name. If they answer to it, they're inside."
	icon_state = "purple_gold_gourd"
	w_class = WEIGHT_CLASS_SMALL
	legend = "From the Journey to the West. Whoever answers when the gourd's holder calls their name is sucked inside, to be slowly dissolved."
	power_text = "No realm or body is too strong for it. Only a real answer counts (yes, what, here, their own name, a question back). \
		Whoever is inside slowly dissolves, and a body cultivator's training melts away with them. Whoever dies inside comes out as a potent elixir."
	/// Who we're waiting to hear from
	var/datum/weakref/target_ref
	/// Who's inside
	var/mob/living/prisoner
	COOLDOWN_DECLARE(call_cooldown)

/obj/item/cultivation_artifact/purple_gold_gourd/Destroy()
	release()
	return ..()

/obj/item/cultivation_artifact/purple_gold_gourd/examine(mob/user)
	. = ..()
	if(prisoner)
		. += span_warning("Something inside is thumping and shouting. Use it in hand to uncork it.")

/obj/item/cultivation_artifact/purple_gold_gourd/attack_self(mob/user)
	if(prisoner)
		user.visible_message(span_notice("[user] uncorks [src]!"))
		release()

/obj/item/cultivation_artifact/purple_gold_gourd/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	return interact_with_atom(interacting_with, user, modifiers)

/obj/item/cultivation_artifact/purple_gold_gourd/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with) || interacting_with == user)
		return NONE
	var/mob/living/victim = interacting_with
	if(prisoner)
		to_chat(user, span_warning("The gourd is already full!"))
		return ITEM_INTERACT_BLOCKING
	if(!COOLDOWN_FINISHED(src, call_cooldown))
		to_chat(user, span_warning("The gourd is still gathering its strength."))
		return ITEM_INTERACT_BLOCKING
	if(get_dist(user, victim) > 9)
		return ITEM_INTERACT_BLOCKING
	COOLDOWN_START(src, call_cooldown, 60 SECONDS)
	user.say("[uppertext(victim.real_name)]!", forced = "purple-gold gourd")
	user.visible_message(span_warning("[user] points a purple gourd at [victim] and calls [victim.p_their()] name!"))
	to_chat(victim, span_userdanger("[user] calls your name, pointing a purple gourd at you... You feel a strong urge to answer."))
	target_ref = WEAKREF(victim)
	RegisterSignal(victim, COMSIG_MOB_SAY, PROC_REF(on_answer))
	addtimer(CALLBACK(src, PROC_REF(stop_listening), victim), 6 SECONDS)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/purple_gold_gourd/proc/stop_listening(mob/living/victim)
	UnregisterSignal(victim, COMSIG_MOB_SAY)
	target_ref = null

/obj/item/cultivation_artifact/purple_gold_gourd/proc/on_answer(mob/living/victim, list/speech_args)
	SIGNAL_HANDLER
	// Only a real answer counts: words forced out of them, or chatter about something else, don't
	if(speech_args[SPEECH_FORCED] || !gourd_is_answer(speech_args[SPEECH_MESSAGE], victim))
		return
	stop_listening(victim)
	if(QDELETED(src) || get_dist(src, victim) > 11 || prisoner)
		return
	INVOKE_ASYNC(src, PROC_REF(suck_in), victim)

/// Does this sound like answering to your name? "Yes", "what?", "here", "who's asking", your own name...
/proc/gourd_is_answer(message, mob/living/victim)
	message = LOWER_TEXT("[message]")
	if(findtext(message, "?"))
		return TRUE
	var/static/list/answers = list("yes", "yeah", "yep", "what", "here", "huh", "who", "me", "aye", "present", "that's me", "speaking")
	for(var/answer in answers)
		if(findtext(message, regex("\\b[answer]\\b")))
			return TRUE
	var/name_called = LOWER_TEXT(victim.first_name())
	return name_called && findtext(message, name_called)

/obj/item/cultivation_artifact/purple_gold_gourd/proc/suck_in(mob/living/victim)
	victim.visible_message(span_boldwarning("[victim] answers, and is sucked into the purple gourd with a loud SHLOOP!"), span_userdanger("You answered! You're sucked into the gourd!"))
	playsound(victim, 'sound/effects/chipbagpop.ogg', 70, TRUE, frequency = 0.5)
	victim.Immobilize(0.5 SECONDS)
	// Stretch and shrink into the gourd's mouth
	var/obj/effect/temp_visual/decoy/sucked = new(get_turf(victim), victim)
	sucked.duration = 0.5 SECONDS
	animate(sucked, transform = matrix().Scale(0.4, 1.6), time = 0.15 SECONDS)
	animate(transform = matrix().Scale(0.05), alpha = 0, pixel_x = (x - victim.x) * 32, pixel_y = (y - victim.y) * 32, time = 0.35 SECONDS, easing = QUAD_EASING | EASE_IN)
	QDEL_IN(sucked, 0.5 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation(get_turf(src))
	victim.forceMove(src)
	prisoner = victim
	victim.remove_status_effect(/datum/status_effect/body_iron_shirt)
	victim.remove_status_effect(/datum/status_effect/body_vajra)
	to_chat(victim, span_userdanger("It's dark and smells of wine in here, and your skin is starting to sting. Resist to try to break out (it takes a while)."))
	START_PROCESSING(SSobj, src)
	// Never forever: the gourd spits them out eventually
	addtimer(CALLBACK(src, PROC_REF(release)), 2 MINUTES)

/// The gourd's wine slowly dissolves whoever is inside
/obj/item/cultivation_artifact/purple_gold_gourd/process(seconds_per_tick)
	if(!prisoner || prisoner.loc != src)
		return PROCESS_KILL
	if(prisoner.stat == DEAD)
		distill()
		return PROCESS_KILL
	prisoner.apply_damage(1.5 * seconds_per_tick, BURN, forced = TRUE)
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(prisoner)
	if(body_datum)
		body_datum.tempering = max(body_datum.tempering - 2 * seconds_per_tick, 0)
		body_datum.add_exhaustion(10 * seconds_per_tick)

/// The gourd's wine has finished its work: the remains tumble out, and so does an elixir
/obj/item/cultivation_artifact/purple_gold_gourd/proc/distill()
	var/mob/living/dissolved = prisoner
	if(ishuman(dissolved))
		var/mob/living/carbon/human/husk = dissolved
		husk.become_husk("purple_gold_gourd")
	var/obj/item/cultivation_pill/gourd_elixir/elixir = new(drop_location())
	elixir.distilled_from = dissolved.real_name
	release()
	visible_message(span_danger("[src] gurgles, and spits out a dried husk and a glowing purple pill."))
	playsound(src, 'sound/effects/magic/demon_consume.ogg', 50, TRUE)
	dissolved.log_message("was dissolved into an elixir by the Purple-Gold Gourd", LOG_ATTACK)

/obj/item/cultivation_artifact/purple_gold_gourd/container_resist_act(mob/living/user)
	if(user != prisoner)
		return
	to_chat(user, span_notice("You start squirming against the cork... (this will take 45 seconds)"))
	audible_message(span_warning("[src] wobbles and thumps!"))
	if(do_after(user, 45 SECONDS, src, timed_action_flags = IGNORE_TARGET_LOC_CHANGE | IGNORE_HELD_ITEM))
		release()

/obj/item/cultivation_artifact/purple_gold_gourd/relaymove(mob/living/user, direction)
	return

/obj/item/cultivation_artifact/purple_gold_gourd/proc/release()
	STOP_PROCESSING(SSobj, src)
	if(!prisoner)
		return
	var/mob/living/freed = prisoner
	prisoner = null
	if(QDELETED(freed) || freed.loc != src)
		return
	freed.forceMove(drop_location())
	freed.transform = matrix().Scale(0.2)
	animate(freed, transform = matrix().Scale(1.2), time = 0.2 SECONDS, easing = BACK_EASING | EASE_OUT)
	animate(transform = matrix(), time = 0.1 SECONDS)
	freed.visible_message(span_warning("[freed] tumbles out of [src] in a puff of wine-scented smoke!"))
	playsound(src, 'sound/effects/pop.ogg', 60, TRUE)
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(src))

/// What's left of someone the gourd dissolved. Grim, and extraordinarily potent.
/obj/item/cultivation_pill/gourd_elixir
	name = "Purple-Gold Elixir"
	desc = "A glowing violet pill that smells of wine. You'd rather not think about what it was made from."
	icon_state = "pill_beast"
	color = "#c890ff"
	toxicity = 20
	/// Whose essence this is
	var/distilled_from

/obj/item/cultivation_pill/gourd_elixir/examine(mob/user)
	. = ..()
	if(distilled_from)
		. += span_warning("Something in its glow looks a lot like [distilled_from].")

/obj/item/cultivation_pill/gourd_elixir/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	var/next = cultivator.next_threshold()
	cultivator.progress = next ? min(cultivator.progress + 50 * potency, next) : cultivator.progress + 50 * potency
	cultivator.adjust_qi(cultivator.max_qi())
	cultivator.update_hud()
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(eater))
	to_chat(eater, span_boldnotice("A tide of stolen essence surges into your foundation."))

/obj/item/cultivation_pill/gourd_elixir/body_effect(mob/living/eater, datum/antagonist/body_cultivator/body_datum)
	body_datum.gain_tempering(100 * potency, null)
	eater.heal_overall_damage(brute = 30, burn = 30)
	to_chat(eater, span_boldnotice("Stolen essence sinks into your bones."))

/obj/item/cultivation_pill/gourd_elixir/mortal_effect(mob/living/eater)
	eater.heal_overall_damage(brute = 40, burn = 40)
	to_chat(eater, span_nicegreen("Warmth floods through you. You feel strong, and a little sick."))

// ===================== Plantain Fan =====================

/obj/item/cultivation_artifact/plantain_fan
	name = "Plantain Fan"
	desc = "A huge fan woven from a single leaf. One wave sends a hurricane in front of you, scattering people and snuffing out flames."
	icon_state = "plantain_fan"
	w_class = WEIGHT_CLASS_NORMAL
	force = 5
	legend = "The Iron Fan Princess's treasure. One wave of it blows a man fifty thousand li away. Here, it's the length of a corridor, but still."
	power_text = "Click a direction to loose a hurricane nine tiles deep that hurls everyone (no stance can root against it) ten tiles away and shatters glass. \
		Use it in hand for a typhoon all around you. The gale snuffs out fire techniques: Sea of Flames, Furnace Burst and Molten Step die in it. \
		Right-click towards a fire to fan it the other way and whip it into a firestorm."
	COOLDOWN_DECLARE(gust_cooldown)

/obj/item/cultivation_artifact/plantain_fan/attack_self(mob/user)
	if(!COOLDOWN_FINISHED(src, gust_cooldown))
		user.balloon_alert(user, "the fan is resting!")
		return
	COOLDOWN_START(src, gust_cooldown, 15 SECONDS)
	user.say("TYPHOON!!", forced = "plantain fan")
	user.visible_message(span_boldwarning("[user] whirls the Plantain Fan overhead and a typhoon explodes outward!"))
	playsound(user, 'sound/effects/space_wind.ogg', 90, TRUE)
	user.SpinAnimation(5, 1)
	var/turf/start = get_turf(user)
	for(var/turf/gust_turf in range(5, start))
		if(gust_turf != start)
			blow(user, gust_turf, get_dir(start, gust_turf))

/obj/item/cultivation_artifact/plantain_fan/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	gust(user, interacting_with)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/plantain_fan/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	stoke(user, interacting_with)
	return ITEM_INTERACT_SUCCESS

/// Fanned the other way, a fire becomes a firestorm racing away from you
/obj/item/cultivation_artifact/plantain_fan/proc/stoke(mob/living/user, atom/towards)
	if(!COOLDOWN_FINISHED(src, gust_cooldown))
		user.balloon_alert(user, "the fan is resting!")
		return
	var/blow_dir = get_dir(user, towards) || user.dir
	var/turf/start = get_turf(user)
	var/list/burning = list()
	for(var/turf/open/fire_turf in range(9, start))
		if((get_dir(start, fire_turf) & blow_dir) && (locate(/obj/effect/hotspot) in fire_turf))
			burning += fire_turf
	if(!length(burning))
		to_chat(user, span_warning("There's no fire that way to fan."))
		return
	COOLDOWN_START(src, gust_cooldown, 15 SECONDS)
	user.say("FIRESTORM!!", forced = "plantain fan")
	user.visible_message(span_boldwarning("[user] fans the flames with the Plantain Fan, and they roar into a firestorm!"))
	playsound(user, 'sound/effects/magic/fireball.ogg', 80, TRUE, frequency = 0.6)
	user.do_attack_animation(get_step(user, blow_dir))
	for(var/turf/open/fire_turf as anything in burning)
		var/turf/open/next = fire_turf
		for(var/i in 1 to 4)
			next = get_step(next, blow_dir)
			if(!isopenturf(next))
				break
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(plantain_firestorm_at), next), i * 0.2 SECONDS)

/proc/plantain_firestorm_at(turf/open/where)
	if(!isopenturf(where))
		return
	new /obj/effect/hotspot(where)
	where.hotspot_expose(1000, 100, 1)
	for(var/mob/living/victim in where)
		victim.adjust_fire_stacks(3)
		victim.ignite_mob()

/obj/item/cultivation_artifact/plantain_fan/proc/gust(mob/living/user, atom/towards)
	if(!COOLDOWN_FINISHED(src, gust_cooldown))
		user.balloon_alert(user, "the fan is resting!")
		return
	COOLDOWN_START(src, gust_cooldown, 15 SECONDS)
	var/blow_dir = get_dir(user, towards) || user.dir
	user.say("HURRICANE!!", forced = "plantain fan")
	user.visible_message(span_boldwarning("[user] swings the Plantain Fan and a howling gale bursts forth!"))
	playsound(user, 'sound/effects/space_wind.ogg', 90, TRUE)
	user.do_attack_animation(get_step(user, blow_dir))
	var/turf/start = get_turf(user)
	for(var/turf/gust_turf in range(9, start))
		if(gust_turf == start || !(get_dir(start, gust_turf) & blow_dir) || (get_dir(start, gust_turf) & REVERSE_DIR(blow_dir)))
			continue
		blow(user, gust_turf, blow_dir)

/// Everything on one turf goes flying
/obj/item/cultivation_artifact/plantain_fan/proc/blow(mob/living/user, turf/gust_turf, blow_dir)
	if(prob(40))
		new /obj/effect/temp_visual/small_smoke/halfsecond(gust_turf)
	for(var/obj/effect/hotspot/flame in gust_turf)
		qdel(flame)
	for(var/obj/structure/window/window in gust_turf)
		window.take_damage(50, BRUTE, MELEE)
	for(var/atom/movable/blown in gust_turf)
		if(blown.anchored || blown == user)
			continue
		if(isliving(blown))
			var/mob/living/victim = blown
			victim.extinguish_mob()
			victim.remove_status_effect(/datum/status_effect/molten_step)
			victim.apply_status_effect(/datum/status_effect/fan_quenched)
			legendary_hit(user, victim, 5, 2 SECONDS, name, src)
		// Positional: some throw_at overrides elsewhere lack the force keyword
		blown.throw_at(get_edge_target_turf(blown, blow_dir), 10, 3, user, TRUE, FALSE, null, MOVE_FORCE_OVERPOWERING)

/// Caught in the Plantain Fan's gale: fire techniques gutter out for a while
/datum/status_effect/fan_quenched
	id = "fan_quenched"
	alert_type = null
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = STATUS_EFFECT_NO_TICK

/datum/status_effect/fan_quenched/on_apply()
	to_chat(owner, span_warning("The gale tears the fire right out of your qi!"))
	return TRUE

// ===================== Bagua Mirror =====================

/obj/item/cultivation_artifact/bagua_mirror
	name = "Bagua Mirror"
	desc = "A bronze octagonal mirror ringed with the eight trigrams. Held up, it flashes with a light evil can't stand, and it turns aside shots."
	icon_state = "bagua_mirror"
	w_class = WEIGHT_CLASS_SMALL
	block_chance = 50
	legend = "Hung over doorways to turn away evil spirits. In a cultivator's hand it does a great deal more."
	power_text = "Use it in hand: the Eight Trigrams Seal. Every cultivator who sees the light (qi or body) has their cultivation sealed for twenty seconds: \
		no techniques, no body arts, no Iron Shirt or Golden Body. The undead and the wicked burn. Held, it turns shots aside and throws qi attacks \
		(sword qi, thorn swords) straight back at whoever loosed them."
	COOLDOWN_DECLARE(flash_cooldown)

/obj/item/cultivation_artifact/bagua_mirror/attack_self(mob/user)
	if(!COOLDOWN_FINISHED(src, flash_cooldown))
		user.balloon_alert(user, "the mirror is dim!")
		return
	COOLDOWN_START(src, flash_cooldown, 45 SECONDS)
	user.say("EIGHT TRIGRAMS SEAL!!", forced = "bagua mirror")
	user.visible_message(span_boldwarning("[user] holds up the Bagua Mirror and it blazes with the light of the eight trigrams!"))
	playsound(user, 'sound/items/weapons/flash.ogg', 70, TRUE)
	cultivation_temple_sound(user, 70)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(user))
	for(var/mob/living/victim in view(6, user))
		if(victim == user)
			continue
		var/undead = (victim.mob_biotypes & MOB_UNDEAD) || IS_BLOODSUCKER(victim) || IS_CULTIST(victim) || IS_HERETIC(victim)
		if(undead)
			victim.Paralyze(3 SECONDS)
			victim.apply_damage(20, BURN, forced = TRUE)
			to_chat(victim, span_userdanger("The mirror's light sears your evil qi!"))
		if(IS_CULTIVATOR(victim) || IS_BODY_CULTIVATOR(victim))
			victim.apply_status_effect(/datum/status_effect/bagua_sealed)
			victim.Knockdown(1 SECONDS)
		else
			victim.flash_act(1, TRUE)

/obj/item/cultivation_artifact/bagua_mirror/equipped(mob/user, slot, initial)
	. = ..()
	if(slot & ITEM_SLOT_HANDS)
		RegisterSignal(user, COMSIG_ATOM_PRE_BULLET_ACT, PROC_REF(reflect_qi), override = TRUE)
	else
		UnregisterSignal(user, COMSIG_ATOM_PRE_BULLET_ACT)

/obj/item/cultivation_artifact/bagua_mirror/dropped(mob/user, silent)
	. = ..()
	UnregisterSignal(user, COMSIG_ATOM_PRE_BULLET_ACT)

/// Qi attacks are thrown straight back the way they came
/obj/item/cultivation_artifact/bagua_mirror/proc/reflect_qi(mob/living/holder, obj/projectile/incoming, def_zone)
	SIGNAL_HANDLER
	if(!istype(incoming, /obj/projectile/cultivation_sword_qi) && !istype(incoming, /obj/projectile/cultivation_thorn))
		return NONE
	if(!prob(block_chance))
		return NONE
	holder.visible_message(span_danger("[holder]'s Bagua Mirror flashes and throws [incoming] back where it came from!"))
	playsound(holder, 'sound/items/weapons/parry.ogg', 50, TRUE)
	new /obj/effect/temp_visual/cultivation_spark(get_turf(holder), "#f0d080")
	if(incoming.firer && incoming.firer != holder)
		incoming.set_angle(get_angle(holder, incoming.firer))
	else
		incoming.set_angle(rand(0, 360))
	incoming.firer = holder
	return COMPONENT_BULLET_PIERCED

/obj/item/cultivation_artifact/bagua_mirror/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(attack_type != PROJECTILE_ATTACK)
		return FALSE
	if(prob(final_block_chance))
		owner.visible_message(span_danger("[owner]'s Bagua Mirror turns [attack_text] aside!"))
		playsound(owner, 'sound/items/weapons/parry.ogg', 50, TRUE)
		return TRUE
	return FALSE

/// Sealed by the eight trigrams: no techniques of any kind
/datum/status_effect/bagua_sealed
	id = "bagua_sealed"
	alert_type = null
	duration = 20 SECONDS
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/bagua_sealed/on_apply()
	owner.remove_status_effect(/datum/status_effect/body_iron_shirt)
	owner.remove_status_effect(/datum/status_effect/body_vajra)
	owner.remove_status_effect(/datum/status_effect/body_blood_boil)
	owner.add_filter("bagua_sealed", 2, list("type" = "outline", "color" = "#f0d080", "size" = 1))
	to_chat(owner, span_userdanger("The eight trigrams lock around your meridians and sinews! Your cultivation is sealed!"))
	return TRUE

/datum/status_effect/bagua_sealed/on_remove()
	owner.remove_filter("bagua_sealed")
	to_chat(owner, span_notice("The seal of the eight trigrams fades."))

// ===================== Qiankun Pouch =====================

/obj/item/cultivation_artifact/qiankun_pouch
	name = "Qiankun Pouch"
	desc = "A small embroidered pouch that holds a whole world inside. It fits far more than it should, even huge things."
	icon_state = "qiankun_pouch"
	w_class = WEIGHT_CLASS_SMALL
	legend = "Qian and Kun, heaven and earth. The inside of this pouch is larger than the outside, which is the point."
	power_text = "Use it in hand to Swallow Heaven and Earth: every loose item within five tiles flies into the pouch. \
		Click a distant spot to Release Heaven and Earth: everything inside is hurled out at it. \
		Use it on a willing person beside you to hide them inside the pouch's world for up to thirty seconds (alt-click to let them out)."
	/// Someone hiding in the world inside
	var/obj/effect/abstract/qiankun_world/hideout
	COOLDOWN_DECLARE(swallow_cooldown)
	COOLDOWN_DECLARE(release_cooldown)

/obj/item/cultivation_artifact/qiankun_pouch/Initialize(mapload)
	. = ..()
	create_storage(max_slots = 50, max_specific_storage = WEIGHT_CLASS_GIGANTIC, max_total_storage = 200)

/obj/item/cultivation_artifact/qiankun_pouch/Destroy()
	QDEL_NULL(hideout)
	return ..()

/obj/item/cultivation_artifact/qiankun_pouch/examine(mob/user)
	. = ..()
	if(hideout?.guest)
		. += span_notice("Someone is hiding in the world inside. Alt-click to let them out.")

/// Release Heaven and Earth: everything inside comes flying out at the target
/obj/item/cultivation_artifact/qiankun_pouch/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	var/list/stored = list()
	for(var/obj/item/thing in atom_storage?.real_location)
		stored += thing
	if(!length(stored))
		user.balloon_alert(user, "the pouch is empty!")
		return ITEM_INTERACT_BLOCKING
	if(!COOLDOWN_FINISHED(src, release_cooldown))
		user.balloon_alert(user, "the pouch is still settling!")
		return ITEM_INTERACT_BLOCKING
	COOLDOWN_START(src, release_cooldown, 20 SECONDS)
	var/turf/target = get_turf(interacting_with)
	user.say("RELEASE HEAVEN AND EARTH!", forced = "qiankun pouch")
	user.visible_message(span_boldwarning("[user] upends the Qiankun Pouch and a torrent of objects comes roaring out!"))
	playsound(user, 'sound/effects/magic/summonitems_generic.ogg', 60, TRUE, frequency = 0.7)
	cultivation_distortion_wave(user, 3, 0.4 SECONDS, 180)
	var/delay = 0
	for(var/obj/item/thing as anything in stored)
		addtimer(CALLBACK(src, PROC_REF(hurl), thing, user, target), delay)
		delay += 0.1 SECONDS
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/qiankun_pouch/proc/hurl(obj/item/thing, mob/living/user, turf/target)
	if(QDELETED(thing) || QDELETED(user) || thing.loc != atom_storage?.real_location)
		return
	thing.forceMove(get_turf(user))
	thing.throw_at(target, 10, 4, user, spin = TRUE)

/// Hide a willing person inside the pouch's own little world
/obj/item/cultivation_artifact/qiankun_pouch/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ishuman(interacting_with) || interacting_with == user)
		return NONE
	if(hideout)
		to_chat(user, span_warning("Someone is already hiding inside."))
		return ITEM_INTERACT_BLOCKING
	INVOKE_ASYNC(src, PROC_REF(offer_hiding), user, interacting_with)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/qiankun_pouch/proc/offer_hiding(mob/living/user, mob/living/carbon/human/guest)
	if(tgui_alert(guest, "[user] holds open the Qiankun Pouch. Step inside its world to hide for up to thirty seconds?", "Qiankun Pouch", list("Step inside", "No"), 15 SECONDS) != "Step inside")
		return
	if(QDELETED(src) || QDELETED(guest) || hideout || !user.Adjacent(guest) || guest.buckled || guest.pulledby)
		return
	guest.visible_message(span_warning("[guest] shrinks to a speck and vanishes into the Qiankun Pouch!"), span_notice("You step into a quiet little world of mountains and clouds."))
	playsound(src, 'sound/effects/magic/blink.ogg', 50, TRUE)
	cultivation_afterimage(guest, 0.5 SECONDS)
	hideout = new(null, src)
	guest.forceMove(hideout)
	hideout.guest = guest
	addtimer(CALLBACK(src, PROC_REF(let_out)), 30 SECONDS)
	guest.log_message("hid inside the Qiankun Pouch held by [key_name(user)]", LOG_GAME)

/obj/item/cultivation_artifact/qiankun_pouch/proc/let_out()
	QDEL_NULL(hideout)

/obj/item/cultivation_artifact/qiankun_pouch/click_alt(mob/user)
	if(!hideout)
		return NONE
	let_out()
	return CLICK_ACTION_SUCCESS

/// The little world inside the pouch. Its guest steps back out next to the pouch when it ends.
/obj/effect/abstract/qiankun_world
	name = "the world inside the Qiankun Pouch"
	var/obj/item/cultivation_artifact/qiankun_pouch/pouch
	var/mob/living/guest

/obj/effect/abstract/qiankun_world/Initialize(mapload, obj/item/cultivation_artifact/qiankun_pouch/pouch)
	. = ..()
	src.pouch = pouch

/obj/effect/abstract/qiankun_world/Destroy()
	if(!QDELETED(guest) && guest.loc == src)
		var/turf/exit = get_turf(pouch) || get_turf(guest)
		if(exit)
			guest.forceMove(exit)
			guest.visible_message(span_notice("[guest] tumbles out of the Qiankun Pouch, full size again."))
			new /obj/effect/temp_visual/small_smoke/halfsecond(exit)
	if(pouch?.hideout == src)
		pouch.hideout = null
	pouch = null
	guest = null
	return ..()

/obj/effect/abstract/qiankun_world/container_resist_act(mob/living/user)
	to_chat(user, span_notice("You walk to the edge of the little world and step out."))
	qdel(src)

/obj/effect/abstract/qiankun_world/relaymove(mob/living/user, direction)
	return

/obj/item/cultivation_artifact/qiankun_pouch/attack_self(mob/user)
	if(!COOLDOWN_FINISHED(src, swallow_cooldown))
		user.balloon_alert(user, "the pouch is full of wind!")
		return
	COOLDOWN_START(src, swallow_cooldown, 20 SECONDS)
	user.say("SWALLOW HEAVEN AND EARTH!", forced = "qiankun pouch")
	user.visible_message(span_boldwarning("[user] opens the Qiankun Pouch and everything around [user.p_them()] is dragged inside!"))
	playsound(user, 'sound/effects/magic/summonitems_generic.ogg', 60, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/sense(get_turf(user))
	var/swallowed = 0
	for(var/obj/item/loose in range(5, user))
		if(loose == src || loose.anchored || !isturf(loose.loc) || (loose.item_flags & ABSTRACT))
			continue
		if(!atom_storage?.attempt_insert(loose, user, messages = FALSE))
			continue
		swallowed++
	to_chat(user, span_notice("[swallowed ? "[swallowed] thing\s vanish" : "Nothing vanishes"] into the pouch."))

// ===================== Spawning =====================

/obj/effect/spawner/random/legendary_artifact
	name = "random legendary artifact"
	icon = 'surfshack13/icons/cultivation/cultivation_artifacts.dmi'
	icon_state = "heaven_reliant"
	// The paired treasures come together: Ganjiang and Moye side by side, the sword and the saber in two different places
	loot = list(
		/obj/effect/spawner/legendary_pair/twin_swords = 1,
		/obj/effect/spawner/legendary_pair/sword_and_saber = 1,
		/obj/item/cultivation_artifact/ruyi_jingu_bang = 1,
		/obj/item/cultivation_artifact/purple_gold_gourd = 1,
		/obj/item/cultivation_artifact/plantain_fan = 1,
		/obj/item/cultivation_artifact/bagua_mirror = 1,
		/obj/item/cultivation_artifact/qiankun_pouch = 1,
		/obj/item/cultivation_artifact/xuanyuan_sword = 1,
		/obj/item/cultivation_artifact/green_dragon_blade = 1,
		/obj/item/cultivation_artifact/seven_star_sword = 1,
		/obj/item/cultivation_artifact/linglong_pagoda = 1,
		/obj/item/cultivation_artifact/universe_ring = 1,
		/obj/item/clothing/shoes/wind_fire_wheels = 1,
	)

/obj/effect/spawner/legendary_pair
	name = "legendary pair"
	icon = 'surfshack13/icons/cultivation/cultivation_artifacts.dmi'
	icon_state = "ganjiang"

/// Ganjiang and Moye, found together
/obj/effect/spawner/legendary_pair/twin_swords/Initialize(mapload)
	. = ..()
	new /obj/item/cultivation_artifact/twin_sword/ganjiang(loc)
	new /obj/item/cultivation_artifact/twin_sword/moye(loc)
	return INITIALIZE_HINT_QDEL

/// The Heaven Reliant Sword here, the Dragon Slaying Saber somewhere else in maintenance
/obj/effect/spawner/legendary_pair/sword_and_saber
	icon_state = "heaven_reliant"

/obj/effect/spawner/legendary_pair/sword_and_saber/Initialize(mapload)
	. = ..()
	new /obj/item/cultivation_artifact/heaven_reliant(loc)
	var/turf/saber_spot = get_turf(src)
	var/list/spots = GLOB.generic_maintenance_landmarks.Copy()
	while(length(spots))
		var/turf/candidate = get_turf(pick_n_take(spots))
		if(candidate && candidate.z == saber_spot?.z && get_dist(candidate, saber_spot) >= 15)
			saber_spot = candidate
			break
	new /obj/item/cultivation_artifact/dragon_saber(saber_spot)
	return INITIALIZE_HINT_QDEL

/// Every cultivator feels roughly where unclaimed legendary artifacts are lying
/proc/legendary_artifact_omen()
	var/list/sensers = heavenly_treasure_sensers()
	if(!length(sensers))
		return
	var/list/areas = list()
	for(var/obj/item/cultivation_artifact/artifact as anything in GLOB.legendary_artifacts)
		if(isturf(artifact.loc))
			areas |= get_area_name(artifact)
	if(!length(areas))
		return
	for(var/mob/living/senser as anything in sensers)
		to_chat(senser, span_boldnotice("<i>A treasure's light rises from somewhere around [english_list(areas)]. Something legendary lies unclaimed.</i>"))
