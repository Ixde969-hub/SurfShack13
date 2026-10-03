/**
 * Ordinary wuxia weapons anyone can make: no qi needed, one trick each.
 * Meteor hammer, rope dart, butterfly swords, iron fan and bamboo staff come from the crafting menu;
 * sect jian are issued by a Sect Master at their plaque, one per member.
 */

// ===================== Meteor hammer =====================

/obj/item/wuxia_weapon
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'

/obj/item/wuxia_weapon/meteor_hammer
	name = "meteor hammer"
	desc = "Two iron weights on a long rope, swung in whirling arcs. It reaches two tiles, and a good hit can drag the target towards you."
	icon_state = "meteor_hammer"
	inhand_icon_state = "chain"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 12
	throwforce = 8
	reach = 2
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb_continuous = list("whips", "smashes", "lashes")
	attack_verb_simple = list("whip", "smash", "lash")
	hitsound = 'sound/items/weapons/chainhit.ogg'

/obj/item/wuxia_weapon/meteor_hammer/afterattack(atom/target, mob/user, click_parameters)
	. = ..()
	if(!isliving(target) || get_dist(user, target) < 2 || !prob(35))
		return
	var/mob/living/victim = target
	if(HAS_TRAIT(victim, TRAIT_PUSHIMMUNE) || victim.move_resist >= MOVE_FORCE_OVERPOWERING)
		return
	var/turf/closer = get_step(victim, get_dir(victim, user))
	if(closer && !closer.is_blocked_turf(exclude_mobs = TRUE))
		victim.visible_message(span_warning("The rope of [user]'s meteor hammer wraps around [victim] and yanks [victim.p_them()] closer!"))
		victim.forceMove(closer)
		playsound(victim, 'sound/items/weapons/chainhit.ogg', 40, TRUE)

/datum/crafting_recipe/meteor_hammer
	name = "Meteor Hammer"
	result = /obj/item/wuxia_weapon/meteor_hammer
	reqs = list(/obj/item/stack/sheet/iron = 4, /obj/item/stack/sheet/cloth = 2)
	tool_behaviors = list(TOOL_WELDER)
	time = 6 SECONDS
	category = CAT_WEAPON_MELEE

// ===================== Rope dart =====================

/obj/item/wuxia_weapon/rope_dart
	name = "rope dart"
	desc = "A steel dart on a long cord. Click someone up to four tiles away to shoot it out and snap it back; it can tear what they're holding out of their hand."
	icon_state = "rope_dart"
	inhand_icon_state = "stinger"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 8
	throwforce = 8
	sharpness = SHARP_POINTY
	w_class = WEIGHT_CLASS_SMALL
	attack_verb_continuous = list("stabs", "jabs")
	attack_verb_simple = list("stab", "jab")
	hitsound = 'sound/items/weapons/pierce.ogg'
	COOLDOWN_DECLARE(dart_cooldown)

/obj/item/wuxia_weapon/rope_dart/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with) || get_dist(user, interacting_with) > 4)
		return NONE
	if(!COOLDOWN_FINISHED(src, dart_cooldown))
		user.balloon_alert(user, "still coiling the cord!")
		return ITEM_INTERACT_BLOCKING
	if(!can_see(user, interacting_with, 4))
		return ITEM_INTERACT_BLOCKING
	COOLDOWN_START(src, dart_cooldown, 3 SECONDS)
	var/mob/living/victim = interacting_with
	user.Beam(victim, icon_state = "chain", time = 0.3 SECONDS)
	playsound(user, 'sound/items/weapons/fwoosh.ogg', 40, TRUE, frequency = 1.4)
	victim.apply_damage(8, BRUTE, sharpness = SHARP_POINTY)
	victim.visible_message(span_danger("[user]'s rope dart darts out and stings [victim]!"), span_userdanger("A rope dart stings you!"))
	var/obj/item/held = victim.get_active_held_item()
	if(held && prob(40) && !HAS_TRAIT(held, TRAIT_NODROP))
		victim.dropItemToGround(held)
		victim.visible_message(span_warning("The cord snaps back and tears [held] out of [victim]'s hand!"))
	log_combat(user, victim, "hit with a rope dart")
	return ITEM_INTERACT_SUCCESS

/datum/crafting_recipe/rope_dart
	name = "Rope Dart"
	result = /obj/item/wuxia_weapon/rope_dart
	reqs = list(/obj/item/stack/rods = 2, /obj/item/stack/sheet/cloth = 2)
	tool_behaviors = list(TOOL_WIRECUTTER)
	time = 4 SECONDS
	category = CAT_WEAPON_MELEE

// ===================== Butterfly swords =====================

/obj/item/wuxia_weapon/butterfly_sword
	name = "butterfly sword"
	desc = "A short, broad single-edged blade with a hand guard, made to be used in pairs. With one in each hand you strike faster and parry far better."
	icon_state = "butterfly_sword"
	inhand_icon_state = "shortsword"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 11
	throwforce = 8
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_NORMAL
	block_chance = 10
	attack_verb_continuous = list("slashes", "chops", "cuts")
	attack_verb_simple = list("slash", "chop", "cut")
	hitsound = 'sound/items/weapons/bladeslice.ogg'

/obj/item/wuxia_weapon/butterfly_sword/proc/paired(mob/living/user)
	for(var/obj/item/wuxia_weapon/butterfly_sword/other in user?.held_items)
		if(other != src)
			return TRUE
	return FALSE

/obj/item/wuxia_weapon/butterfly_sword/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(paired(owner))
		final_block_chance += 25
	return ..()

/obj/item/wuxia_weapon/butterfly_sword/afterattack(atom/target, mob/user, click_parameters)
	. = ..()
	if(isliving(user) && paired(user))
		user.changeNext_move(CLICK_CD_MELEE * 0.6)

/datum/crafting_recipe/butterfly_swords
	name = "Butterfly Swords (pair)"
	result = /obj/item/wuxia_weapon/butterfly_sword
	result_amount = 2
	reqs = list(/obj/item/stack/sheet/iron = 4, /obj/item/stack/sheet/cloth = 1)
	tool_behaviors = list(TOOL_WELDER)
	time = 6 SECONDS
	category = CAT_WEAPON_MELEE

// ===================== Iron fan =====================

/obj/item/wuxia_weapon/iron_fan
	name = "iron fan"
	desc = "A folding fan with iron ribs and a razor edge. Held, it bats thrown things out of the air; thrown, it cuts."
	icon_state = "iron_fan"
	inhand_icon_state = null
	force = 9
	throwforce = 14
	throw_speed = 3
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_SMALL
	attack_verb_continuous = list("slices", "fans", "slaps")
	attack_verb_simple = list("slice", "fan", "slap")
	hitsound = 'sound/items/weapons/bladeslice.ogg'

/obj/item/wuxia_weapon/iron_fan/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(attack_type == THROWN_PROJECTILE_ATTACK)
		final_block_chance += 50
	return ..()

/datum/crafting_recipe/iron_fan
	name = "Iron Fan"
	result = /obj/item/wuxia_weapon/iron_fan
	reqs = list(/obj/item/stack/rods = 3, /obj/item/paper = 2)
	tool_behaviors = list(TOOL_WELDER)
	time = 4 SECONDS
	category = CAT_WEAPON_MELEE

// ===================== Bamboo staff =====================

/obj/item/wuxia_weapon/bamboo_staff
	name = "bamboo staff"
	desc = "A long staff of dried bamboo. Wielded in both hands, a heavy swing can knock someone off their feet, but bamboo splits after enough of them."
	icon_state = "bamboo_staff"
	inhand_icon_state = "bambostaff0"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	force = 6
	throwforce = 6
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	attack_verb_continuous = list("whacks", "sweeps", "thwacks")
	attack_verb_simple = list("whack", "sweep", "thwack")
	hitsound = 'sound/items/weapons/genhit2.ogg'
	/// Heavy swings left before it splits
	var/swings_left = 6

/obj/item/wuxia_weapon/bamboo_staff/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded = 6, force_wielded = 12, icon_wielded = "bamboo_staff")

/obj/item/wuxia_weapon/bamboo_staff/afterattack(atom/target, mob/user, click_parameters)
	. = ..()
	if(!isliving(target) || !HAS_TRAIT(src, TRAIT_WIELDED) || !prob(30))
		return
	var/mob/living/victim = target
	victim.visible_message(span_danger("[user] sweeps [victim]'s legs out with [src]!"))
	victim.Knockdown(1.5 SECONDS)
	playsound(victim, 'sound/effects/hit_kick.ogg', 40, TRUE)
	swings_left--
	if(swings_left > 0)
		return
	user.visible_message(span_warning("[src] splits down its length and falls apart!"))
	playsound(src, 'sound/effects/wounds/crack1.ogg', 50, TRUE, frequency = 1.4)
	new /obj/item/stack/sheet/mineral/bamboo(drop_location(), 2)
	qdel(src)

/datum/crafting_recipe/bamboo_staff
	name = "Bamboo Staff"
	result = /obj/item/wuxia_weapon/bamboo_staff
	reqs = list(/obj/item/stack/sheet/mineral/bamboo = 4)
	time = 3 SECONDS
	category = CAT_WEAPON_MELEE

// ===================== Sect jian =====================

/// Plaque option: a Sect Master issues one sword per member
/datum/jianghu_sect
	/// Sect colour, for issued swords
	var/sect_color
	/// Swords issued so far
	var/jian_issued = 0

/datum/jianghu_sect/proc/get_color()
	if(!sect_color)
		sect_color = pick("#c0392b", "#2e86c1", "#28b463", "#d4ac0d", "#8e44ad", "#e67e22", "#17a589", "#cb4335")
	return sect_color

/obj/item/wuxia_weapon/sect_jian
	name = "sect jian"
	desc = "A straight double-edged sword with a tassel in a sect's colours."
	icon_state = "sect_jian"
	inhand_icon_state = "sabre"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 12
	throwforce = 10
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_NORMAL
	block_chance = 15
	attack_verb_continuous = list("slashes", "thrusts", "cuts")
	attack_verb_simple = list("slash", "thrust", "cut")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	/// The sect it was issued by
	var/datum/jianghu_sect/sect

/obj/item/wuxia_weapon/sect_jian/proc/set_sect(datum/jianghu_sect/new_sect)
	sect = new_sect
	name = "jian of the [sect.name]"
	desc = "A straight double-edged sword with a tassel in the colours of the [sect.name]. It feels right in a member's hand, and wrong in anyone else's."
	add_filter("sect_jian", 2, list("type" = "outline", "color" = sect.get_color(), "size" = 1, "alpha" = 160))

/obj/item/wuxia_weapon/sect_jian/Destroy()
	sect = null
	return ..()

/// In a member's hand it strikes truer and parries better
/obj/item/wuxia_weapon/sect_jian/afterattack(atom/target, mob/user, click_parameters)
	. = ..()
	if(!isliving(target) || !sect || jianghu_sect_of(user.mind) != sect)
		return
	var/mob/living/victim = target
	victim.apply_damage(5, BRUTE, sharpness = SHARP_EDGED)
	victim.apply_damage(8, STAMINA)

/obj/item/wuxia_weapon/sect_jian/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(sect && jianghu_sect_of(owner.mind) == sect)
		final_block_chance += 15
	return ..()

/obj/structure/sect_plaque/proc/issue_jian(mob/living/user)
	if(sect.jian_issued >= length(sect.members))
		to_chat(user, span_warning("Every member of the [sect.name] already has a sword. Recruit more disciples first."))
		return
	sect.jian_issued++
	var/obj/item/wuxia_weapon/sect_jian/jian = new(drop_location())
	jian.set_sect(sect)
	user.put_in_hands(jian)
	user.visible_message(span_notice("[user] takes a sword from the rack beneath the plaque of the [sect.name]."))
	playsound(src, 'sound/items/unsheath.ogg', 40, TRUE)
