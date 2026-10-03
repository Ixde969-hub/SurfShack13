/**
 * # Heavenly Treasures
 *
 * Every fifteen to twenty minutes a spirit herb blooms somewhere in maintenance, and every cultivator on the station
 * feels roughly where. Whoever reaches it first and picks it gets a treasure: eaten, it fills a qi cultivator's foundation,
 * forges a body cultivator's limbs, or simply heals a mortal. It can be carried, traded or stolen, and if nobody claims it
 * the bloom fades after a few minutes.
 */

/// Is the treasure cycle running
GLOBAL_VAR_INIT(heavenly_treasure_started, FALSE)

/// Start the cycle at roundstart
/proc/heavenly_treasure_start()
	if(GLOB.heavenly_treasure_started)
		return
	GLOB.heavenly_treasure_started = TRUE
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heavenly_treasure_cycle)), rand(12 MINUTES, 18 MINUTES))

/proc/heavenly_treasure_cycle()
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heavenly_treasure_cycle)), rand(15 MINUTES, 20 MINUTES))
	var/list/sensers = heavenly_treasure_sensers()
	if(!length(sensers))
		return
	var/list/spots = GLOB.generic_maintenance_landmarks.Copy()
	while(length(spots))
		var/turf/spot = get_turf(pick_n_take(spots))
		if(!isopenturf(spot) || spot.is_blocked_turf(exclude_mobs = TRUE) || (locate(/obj/structure/spirit_herb) in spot))
			continue
		var/obj/structure/spirit_herb/herb = new(spot)
		herb.announce(sensers)
		return

/// Everyone who can feel a treasure bloom: qi and body cultivators who are alive
/proc/heavenly_treasure_sensers()
	. = list()
	for(var/datum/antagonist/antag as anything in GLOB.antagonists)
		if(!istype(antag, /datum/antagonist/cultivator) && !istype(antag, /datum/antagonist/body_cultivator))
			continue
		var/mob/living/body = antag.owner?.current
		if(isliving(body) && body.stat != DEAD)
			. |= body

/obj/structure/spirit_herb
	name = "spirit herb"
	desc = "A small plant with pale jade leaves and a single glowing blossom. The air around it shimmers with qi."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "spirit_herb_plant"
	anchored = TRUE
	density = FALSE
	max_integrity = 30
	light_system = OVERLAY_LIGHT
	light_range = 2
	light_power = 1
	light_color = "#c8ffd8"
	/// Someone is already picking it
	var/picking = FALSE

/obj/structure/spirit_herb/Initialize(mapload)
	. = ..()
	cultivation_particles(src, /particles/cultivation/petals, 6 MINUTES)
	QDEL_IN(src, 6 MINUTES)

/obj/structure/spirit_herb/Destroy()
	if(isturf(loc))
		new /obj/effect/temp_visual/circle_wave/cultivation/wood(loc)
	return ..()

/// Every cultivator feels the bloom and roughly where it is
/obj/structure/spirit_herb/proc/announce(list/sensers)
	var/area/where = get_area(src)
	for(var/mob/living/senser as anything in sensers)
		to_chat(senser, span_boldnotice("<i>A fragrance of pure qi brushes your senses. A heavenly treasure is blooming somewhere around [where?.name || "the station"]! The first to pluck it claims it.</i>"))
		senser.playsound_local(get_turf(senser), 'sound/runtime/instruments/synthesis_samples/chromatic/fluid_celeste/C6.ogg', 40, FALSE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(src))
	cultivation_wind_chimes(src, 40)

/obj/structure/spirit_herb/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(. || picking)
		return
	INVOKE_ASYNC(src, PROC_REF(pick_herb), user)
	return TRUE

/obj/structure/spirit_herb/proc/pick_herb(mob/living/user)
	picking = TRUE
	user.visible_message(span_notice("[user] kneels and begins to carefully dig up [src]."), span_notice("You carefully loosen the roots..."))
	var/picked = do_after(user, 4 SECONDS, src)
	picking = FALSE
	if(!picked || QDELETED(src))
		return
	var/obj/item/spirit_herb/treasure = new(drop_location())
	user.put_in_hands(treasure)
	user.visible_message(span_boldnotice("[user] plucks the glowing spirit herb!"))
	cultivation_guqin_phrase(user, list(1, 2, 3, 5, 6))
	for(var/mob/living/senser as anything in heavenly_treasure_sensers())
		if(senser != user)
			to_chat(senser, span_notice("<i>The fragrance of the heavenly treasure fades. Someone has claimed it.</i>"))
	qdel(src)

/obj/item/spirit_herb
	name = "spirit herb"
	desc = "A glowing herb steeped in heavenly qi. Eat it to claim its power: it fills a cultivator's foundation, forges a body cultivator's limbs, and heals anyone."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "spirit_herb"
	w_class = WEIGHT_CLASS_TINY
	light_system = OVERLAY_LIGHT
	light_range = 1.5
	light_power = 0.8
	light_color = "#c8ffd8"

/obj/item/spirit_herb/attack_self(mob/living/user)
	user.visible_message(span_notice("[user] eats [src]."), span_notice("You eat [src]. It tastes like morning dew and lightning."))
	playsound(user, 'sound/items/eatfood.ogg', 40, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/wood(get_turf(user))
	cultivation_particles(user, /particles/cultivation/petals, 2 SECONDS)
	user.heal_overall_damage(brute = 25, burn = 25)
	cultivation_heal_internal_injury(user, 3)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	if(cultivator)
		var/next = cultivator.next_threshold()
		cultivator.progress = next ? min(cultivator.progress + 40, next) : cultivator.progress + 40
		cultivator.adjust_qi(cultivator.max_qi())
		cultivator.update_hud()
		to_chat(user, span_boldnotice("Heavenly qi floods your foundation!"))
	else if(body_datum)
		body_datum.gain_tempering(80, null)
		to_chat(user, span_boldnotice("Heavenly qi sinks into your bones as tempering!"))
	else
		to_chat(user, span_nicegreen("You feel wonderful."))
	qdel(src)
