/**
 * Six more combination techniques, unlocked from Foundation by holding both elements (a Root Law and a Complementary Law).
 * They join Steam Veil, Thousand Thorn Swords, Molten Step and Mud Prison in laws.dm and elements.dm.
 */

/datum/cultivation_combo/flowing_blade
	element_one = ELEMENT_METAL
	element_two = ELEMENT_WATER
	technique = /datum/action/cooldown/spell/pointed/cultivation/flowing_blade

/datum/cultivation_combo/crimson_edge
	element_one = ELEMENT_METAL
	element_two = ELEMENT_FIRE
	technique = /datum/action/cooldown/spell/cultivation/crimson_edge

/datum/cultivation_combo/iron_mountain_array
	element_one = ELEMENT_METAL
	element_two = ELEMENT_EARTH
	technique = /datum/action/cooldown/spell/cultivation/iron_mountain_array

/datum/cultivation_combo/spring_rain
	element_one = ELEMENT_WATER
	element_two = ELEMENT_WOOD
	technique = /datum/action/cooldown/spell/pointed/cultivation/spring_rain

/datum/cultivation_combo/blossoming_flame
	element_one = ELEMENT_FIRE
	element_two = ELEMENT_WOOD
	technique = /datum/action/cooldown/spell/pointed/cultivation/blossoming_flame

/datum/cultivation_combo/rootbound_sanctuary
	element_one = ELEMENT_EARTH
	element_two = ELEMENT_WOOD
	technique = /datum/action/cooldown/spell/cultivation/rootbound_sanctuary

// ===================== Flowing Blade (metal + water) =====================

/datum/action/cooldown/spell/pointed/cultivation/flowing_blade
	name = "Flowing Blade"
	desc = "Metal and water meet: a crescent of water-edged qi that flows through everyone in its path, cutting each one and leaving them slowed."
	cast_range = 9
	cooldown_time = 12 SECONDS
	qi_cost = 25

/datum/action/cooldown/spell/pointed/cultivation/flowing_blade/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/flowing_blade/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/obj/projectile/cultivation_sword_qi/flowing/wave = new(get_turf(user))
	wave.damage = (12 + 2 * cultivation_realm_of(user)) * cultivation_qi_power(user)
	// Water dulls the edge: it cuts, but never severs
	wave.caster_realm = -2
	wave.aim_projectile(cast_on, user)
	wave.firer = user
	wave.fired_from = user
	user.do_attack_animation(get_step(user, get_dir(user, cast_on)), ATTACK_EFFECT_SLASH)
	playsound(user, 'sound/effects/splash.ogg', 50, TRUE, frequency = 1.2)
	wave.fire()

/// Passes through people instead of stopping at the first
/obj/projectile/cultivation_sword_qi/flowing
	name = "flowing blade"
	color = "#7fc8ff"
	damage = 12
	wound_bonus = 0
	bare_wound_bonus = 10
	projectile_piercing = PASSMOB
	light_color = "#7fc8ff"

/obj/projectile/cultivation_sword_qi/flowing/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/victim = target
		victim.apply_status_effect(/datum/status_effect/cultivation_slow, 3 SECONDS)
		new /obj/effect/temp_visual/circle_wave/cultivation/water(get_turf(victim))

// ===================== Crimson Edge (metal + fire) =====================

/datum/action/cooldown/spell/cultivation/crimson_edge
	name = "Crimson Edge"
	desc = "Metal and fire meet: your weapon (or your fists) glows red-hot. Your next three melee blows set whoever they hit on fire."
	cooldown_time = 20 SECONDS
	qi_cost = 20

/datum/action/cooldown/spell/cultivation/crimson_edge/cast(mob/living/cast_on)
	. = ..()
	cast_on.apply_status_effect(/datum/status_effect/crimson_edge)

/datum/status_effect/crimson_edge
	id = "crimson_edge"
	alert_type = null
	duration = 20 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = STATUS_EFFECT_NO_TICK
	var/charges = 3

/datum/status_effect/crimson_edge/refresh(effect, ...)
	charges = 3
	return ..()

/datum/status_effect/crimson_edge/on_apply()
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack))
	RegisterSignal(owner, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	owner.add_filter("crimson_edge", 2, list("type" = "outline", "color" = "#ff4a1a", "size" = 1))
	owner.visible_message(span_warning("[owner]'s hands glow red-hot!"))
	playsound(owner, 'sound/effects/fire_puff.ogg', 40, TRUE)
	return TRUE

/datum/status_effect/crimson_edge/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_UNARMED_ATTACK))
	owner.remove_filter("crimson_edge")

/datum/status_effect/crimson_edge/proc/on_item_attack(mob/living/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	sear(target)

/datum/status_effect/crimson_edge/proc/on_unarmed_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(proximity)
		sear(target)

/datum/status_effect/crimson_edge/proc/sear(atom/target)
	if(!isliving(target) || target == owner)
		return
	var/mob/living/victim = target
	victim.adjust_fire_stacks(2)
	victim.ignite_mob()
	victim.apply_damage(4, BURN)
	new /obj/effect/temp_visual/cultivation_spark(get_turf(victim), "#ff6a1f", rand(-6, 6), rand(0, 10))
	if(--charges <= 0)
		qdel(src)

// ===================== Iron Mountain Array (metal + earth) =====================

/datum/action/cooldown/spell/cultivation/iron_mountain_array
	name = "Iron Mountain Array"
	desc = "Metal and earth meet: a ring of iron spikes bursts from the floor around you for 8 seconds. Nobody can step through, and touching them hurts."
	cooldown_time = 30 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/cultivation/iron_mountain_array/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_warning("Iron spikes erupt from the floor in a ring around [cast_on]!"))
	playsound(cast_on, 'sound/effects/rock/rock_break.ogg', 60, TRUE)
	playsound(cast_on, 'sound/items/unsheath.ogg', 50, TRUE, frequency = 0.7)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(get_turf(cast_on))
	for(var/turf/open/edge in orange(1, cast_on))
		if(edge.is_blocked_turf(exclude_mobs = FALSE))
			continue
		new /obj/structure/cultivation_iron_spikes(edge)

/obj/structure/cultivation_iron_spikes
	name = "iron spikes"
	desc = "A thicket of iron spikes bristling out of the floor."
	icon = 'surfshack13/icons/cultivation/cultivation_terrain.dmi'
	icon_state = "iron_spikes"
	density = TRUE
	anchored = TRUE
	max_integrity = 80
	layer = ABOVE_OBJ_LAYER

/obj/structure/cultivation_iron_spikes/Initialize(mapload)
	. = ..()
	pixel_y = -12
	alpha = 0
	animate(src, pixel_y = 0, alpha = 255, time = 0.15 SECONDS, easing = BACK_EASING | EASE_OUT)
	QDEL_IN(src, 8 SECONDS)

/obj/structure/cultivation_iron_spikes/Bumped(atom/movable/bumped_atom)
	. = ..()
	if(!isliving(bumped_atom))
		return
	var/mob/living/poked = bumped_atom
	poked.apply_damage(5, BRUTE, pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG), sharpness = SHARP_POINTY)
	to_chat(poked, span_warning("You run into the iron spikes!"))

// ===================== Spring Rain (water + wood) =====================

/datum/action/cooldown/spell/pointed/cultivation/spring_rain
	name = "Spring Rain"
	desc = "Water and wood meet: a soft rain falls over a 5x5 area for 6 seconds, healing you and your allies inside it and putting out fires."
	cast_range = 6
	cooldown_time = 30 SECONDS
	qi_cost = 35
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/cultivation/spring_rain/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/spring_rain/cast(atom/cast_on)
	. = ..()
	new /obj/effect/cultivation_spring_rain(get_turf(cast_on), owner)
	owner.visible_message(span_notice("[owner] raises a hand and a gentle rain begins to fall."))

/obj/effect/cultivation_spring_rain
	name = "spring rain"
	icon = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/datum/weakref/caster_ref
	var/pulses_left = 6

/obj/effect/cultivation_spring_rain/Initialize(mapload, mob/living/caster)
	. = ..()
	caster_ref = WEAKREF(caster)
	cultivation_particles(src, /particles/cultivation/rain, 6 SECONDS)
	playsound(src, 'sound/effects/splash.ogg', 40, TRUE, frequency = 0.6)
	START_PROCESSING(SSobj, src)

/obj/effect/cultivation_spring_rain/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/cultivation_spring_rain/process(seconds_per_tick)
	var/mob/living/caster = caster_ref?.resolve()
	for(var/turf/open/wet in range(2, src))
		for(var/obj/effect/hotspot/flame in wet)
			qdel(flame)
		for(var/mob/living/soaked in wet)
			soaked.extinguish_mob()
			if(soaked.stat != DEAD && cultivation_is_ally(caster, soaked))
				soaked.heal_overall_damage(brute = 2, burn = 3)
				new /obj/effect/temp_visual/heal(wet, "#7fd7ff")
	if(--pulses_left <= 0)
		qdel(src)

/particles/cultivation/rain
	icon_state = "qi_mote"
	color = "#9fd4ff"
	width = 192
	height = 192
	count = 80
	spawning = 8
	lifespan = 0.8 SECONDS
	fade = 0.2 SECONDS
	position = generator(GEN_BOX, list(-80, 60), list(80, 80), NORMAL_RAND)
	velocity = list(0, -5)
	drift = list(0, 0)
	scale = list(0.4, 1.2)

// ===================== Blossoming Flame (fire + wood) =====================

/datum/action/cooldown/spell/pointed/cultivation/blossoming_flame
	name = "Blossoming Flame"
	desc = "Fire and wood meet: plant a red flower on a spot up to three tiles away. When anyone but you steps near it, it bursts into a 3x3 blossom of flame. \
		It wilts after a minute; you can have two planted at once."
	cast_range = 3
	cooldown_time = 10 SECONDS
	qi_cost = 20
	aim_assist = FALSE
	/// Our planted flowers, oldest first
	var/list/datum/weakref/flowers = list()

/datum/action/cooldown/spell/pointed/cultivation/blossoming_flame/is_valid_target(atom/cast_on)
	var/turf/spot = get_turf(cast_on)
	return isopenturf(spot) && !spot.is_blocked_turf(exclude_mobs = TRUE)

/datum/action/cooldown/spell/pointed/cultivation/blossoming_flame/cast(atom/cast_on)
	. = ..()
	for(var/datum/weakref/flower_ref as anything in flowers.Copy())
		if(!flower_ref.resolve())
			flowers -= flower_ref
	if(length(flowers) >= 2)
		var/datum/weakref/oldest = flowers[1]
		flowers -= oldest
		qdel(oldest.resolve())
	var/obj/effect/cultivation_blossom/flower = new(get_turf(cast_on), owner)
	flowers += WEAKREF(flower)
	to_chat(owner, span_notice("A small red flower pushes up out of the floor."))

/obj/effect/cultivation_blossom
	name = "red flower"
	desc = "A small, bright red flower growing improbably out of the floor. It's warm."
	icon = 'surfshack13/icons/cultivation/cultivation_terrain.dmi'
	icon_state = "blossom"
	anchored = TRUE
	layer = BELOW_OBJ_LAYER
	var/datum/weakref/planter_ref
	var/bursting = FALSE

/obj/effect/cultivation_blossom/Initialize(mapload, mob/living/planter)
	. = ..()
	planter_ref = WEAKREF(planter)
	var/static/list/connections = list(COMSIG_ATOM_ENTERED = PROC_REF(on_near))
	AddComponent(/datum/component/connect_range, src, connections, 1)
	QDEL_IN(src, 1 MINUTES)

/obj/effect/cultivation_blossom/proc/on_near(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(bursting || !isliving(arrived) || arrived == planter_ref?.resolve())
		return
	var/mob/living/visitor = arrived
	if(visitor.stat == DEAD || (visitor.movement_type & (FLYING|FLOATING)))
		return
	bursting = TRUE
	INVOKE_ASYNC(src, PROC_REF(burst))

/obj/effect/cultivation_blossom/proc/burst()
	var/turf/center = get_turf(src)
	visible_message(span_danger("The red flower bursts open into a blossom of flame!"))
	playsound(center, 'sound/effects/magic/fireball.ogg', 60, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/fire(center)
	var/mob/living/planter = planter_ref?.resolve()
	for(var/turf/open/burning in range(1, center))
		new /obj/effect/hotspot(burning)
		burning.hotspot_expose(700, 50, 1)
		for(var/mob/living/victim in burning)
			if(victim == planter)
				continue
			victim.apply_damage(12 * cultivation_qi_power(planter), BURN)
			victim.adjust_fire_stacks(2)
			victim.ignite_mob()
	qdel(src)

// ===================== Rootbound Sanctuary (earth + wood) =====================

/datum/action/cooldown/spell/cultivation/rootbound_sanctuary
	name = "Rootbound Sanctuary"
	desc = "Earth and wood meet: roots and moss spread over the 3x3 area around you for 10 seconds. You and your allies inside regenerate \
		and can't be knocked down or stunned."
	cooldown_time = 45 SECONDS
	qi_cost = 45

/datum/action/cooldown/spell/cultivation/rootbound_sanctuary/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_notice("Roots and moss spread out across the floor around [cast_on]."))
	playsound(cast_on, 'sound/effects/bush/crunchybushwhack1.ogg', 50, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/wood(get_turf(cast_on))
	var/obj/effect/cultivation_grove/grove = new(get_turf(cast_on), cast_on)
	grove.process(1)

/obj/effect/cultivation_grove
	name = "rootbound sanctuary"
	icon = 'surfshack13/icons/cultivation/cultivation_effects_96.dmi'
	icon_state = "grove"
	pixel_x = -32
	pixel_y = -32
	anchored = TRUE
	layer = BELOW_OBJ_LAYER
	plane = FLOOR_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/datum/weakref/caster_ref

/obj/effect/cultivation_grove/Initialize(mapload, mob/living/caster)
	. = ..()
	caster_ref = WEAKREF(caster)
	alpha = 0
	animate(src, alpha = 220, time = 0.5 SECONDS)
	cultivation_particles(src, /particles/cultivation/petals, 10 SECONDS)
	START_PROCESSING(SSobj, src)
	QDEL_IN(src, 10 SECONDS)

/obj/effect/cultivation_grove/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/cultivation_grove/process(seconds_per_tick)
	var/mob/living/caster = caster_ref?.resolve()
	for(var/mob/living/sheltered in range(1, src))
		if(sheltered.stat == DEAD || !cultivation_is_ally(caster, sheltered))
			continue
		sheltered.heal_overall_damage(brute = 2 * seconds_per_tick, burn = 2 * seconds_per_tick)
		sheltered.apply_status_effect(/datum/status_effect/rootbound)

/// Held up by the grove's roots
/datum/status_effect/rootbound
	id = "rootbound"
	alert_type = null
	duration = 2.5 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = STATUS_EFFECT_NO_TICK

/datum/status_effect/rootbound/on_apply()
	owner.add_traits(list(TRAIT_STUNIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.SetKnockdown(0)
	return TRUE

/datum/status_effect/rootbound/on_remove()
	owner.remove_traits(list(TRAIT_STUNIMMUNE), TRAIT_STATUS_EFFECT(id))
