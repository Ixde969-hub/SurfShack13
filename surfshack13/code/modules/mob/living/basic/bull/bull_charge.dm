/// Charge never hit anything and ran out of steam
#define BULL_CHARGE_MISSED 0
/// Charge ended by goring a mob
#define BULL_CHARGE_HIT_MOB 1
/// Charge ended by slamming into something it couldn't break
#define BULL_CHARGE_HIT_OBSTACLE 2
/// Charge was interrupted (death, stun, deletion)
#define BULL_CHARGE_ABORTED 3

/**
 * Bull rush
 *
 * Paws the ground for a windup, locks onto where the target was standing, then barrels in a straight line
 * through that spot until it hits something or runs out of steam.
 * - Mobs get gored, wounded and thrown.
 * - Normal walls get smashed through (up to max_walls per charge, the last one only cracks to a girder half the time).
 * - Reinforced/hard walls and anything else it can't break stun the bull instead.
 * - Windows, grilles, tables and the like are just ploughed through.
 * - If nothing gets hit the cooldown is short so the AI simply lines up again.
 */
/datum/action/cooldown/mob_cooldown/bull_charge
	name = "Bull Rush"
	desc = "Paw the ground, then charge in a straight line through wherever your target was standing."
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	cooldown_time = 4 SECONDS
	melee_cooldown_time = 0
	shared_cooldown = NONE
	/// How long we paw the ground before dashing
	var/windup_time = 1.2 SECONDS
	/// How long before the dash we stop tracking the target and commit to a spot
	var/aim_lock_time = 0.4 SECONDS
	/// Deciseconds per tile while dashing
	var/charge_speed = 0.8
	/// Max tiles travelled in one dash
	var/charge_range = 14
	/// Cooldown used when we didn't hit anything, so we line up again quickly
	var/miss_cooldown = 1.5 SECONDS
	/// Normal walls we can go through per charge
	var/max_walls = 2
	/// Brute damage dealt to gored mobs
	var/gore_damage = 25
	/// Brute damage dealt to mobs we trample over while they're lying down
	var/trample_damage = 10
	/// How far gored mobs get thrown
	var/throw_range = 6
	/// How long gored mobs stay down
	var/gore_knockdown = 2 SECONDS
	/// Damage dealt to fragile structures (windows, grilles, tables...) we plough through
	var/fragile_damage = 400
	/// Damage dealt to other dense objects we slam into (airlocks, machines...)
	var/obstacle_damage = 120
	/// How long we're stunned after hitting something we can't break
	var/recoil_stun = 1 SECONDS
	/// Brute damage we take when slamming into something we can't break
	var/recoil_damage = 5

	/// Are we currently winding up or dashing
	var/charging = FALSE
	/// Are we currently performing a move from our own loop (anything else gets blocked)
	var/actively_moving = FALSE
	/// Who we're winding up at
	var/datum/weakref/target_ref
	/// The turf we committed to charging through
	var/turf/aim_turf
	/// Our dash move loop
	var/datum/move_loop/charge_loop
	/// Direction we're dashing in, used for throwing
	var/charge_dir
	/// Walls broken this charge
	var/walls_smashed = 0
	/// Mobs we already trampled this charge
	var/list/trampled
	/// Timers for windup stages, so we can cancel them
	var/list/windup_timers

	/// Things we just smash through without slowing down
	var/static/list/fragile_types = typecacheof(list(
		/obj/structure/window,
		/obj/structure/grille,
		/obj/structure/table,
		/obj/structure/railing,
		/obj/structure/girder,
		/obj/structure/barricade,
		/obj/structure/door_assembly,
		/obj/structure/windoor_assembly,
		/obj/machinery/door/window,
	))

/datum/action/cooldown/mob_cooldown/bull_charge/Destroy()
	abort_charge()
	return ..()

/datum/action/cooldown/mob_cooldown/bull_charge/Remove(mob/removed_from)
	abort_charge()
	return ..()

/datum/action/cooldown/mob_cooldown/bull_charge/IsAvailable(feedback = FALSE)
	if(charging)
		return FALSE
	return ..()

/datum/action/cooldown/mob_cooldown/bull_charge/Activate(atom/target)
	if(charging || !isliving(owner))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || target_turf.z != owner.z || target_turf == get_turf(owner))
		return FALSE

	var/mob/living/bull = owner
	charging = TRUE
	walls_smashed = 0
	trampled = list()
	target_ref = WEAKREF(target)
	aim_turf = target_turf
	// Hold the cooldown (and melee) until the charge is over
	StartCooldown(100 SECONDS, 100 SECONDS)

	RegisterSignal(bull, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(on_pre_move))
	RegisterSignal(bull, COMSIG_LIVING_DEATH, PROC_REF(abort_charge))

	bull.face_atom(target)
	bull.visible_message(span_danger("[bull] paws at the ground and lowers [bull.p_their()] horns!"))
	playsound(bull, 'sound/mobs/non-humanoids/cow/cow.ogg', 80, TRUE, frequency = 0.7)
	bull.Shake(2, 1, windup_time)
	var/obj/effect/temp_visual/decoy/flash = new(bull.loc, bull)
	animate(flash, alpha = 0, color = COLOR_RED, transform = matrix() * 1.5, time = windup_time)

	windup_timers = list(
		addtimer(CALLBACK(src, PROC_REF(lock_aim)), max(windup_time - aim_lock_time, 0), TIMER_STOPPABLE),
		addtimer(CALLBACK(src, PROC_REF(begin_dash)), windup_time, TIMER_STOPPABLE),
	)
	return TRUE

/// Stop tracking the target and commit to where they are now
/datum/action/cooldown/mob_cooldown/bull_charge/proc/lock_aim()
	if(!charging)
		return
	var/atom/target = target_ref?.resolve()
	if(target && get_turf(target) && target.z == owner.z && get_turf(target) != get_turf(owner))
		aim_turf = get_turf(target)
	owner.face_atom(aim_turf)
	new /obj/effect/temp_visual/telegraphing/bull_charge(aim_turf)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/begin_dash()
	windup_timers = null
	if(!charging)
		return
	var/mob/living/bull = owner
	if(bull.stat != CONSCIOUS || HAS_TRAIT(bull, TRAIT_INCAPACITATED) || HAS_TRAIT(bull, TRAIT_IMMOBILIZED) || bull.buckled)
		end_charge(BULL_CHARGE_ABORTED)
		return

	charge_dir = get_dir(bull, aim_turf)
	bull.setDir(charge_dir)
	playsound(bull, 'sound/effects/meteorimpact.ogg', 60, TRUE)

	// Not homing, so it keeps going in a straight line past the aim turf until the timeout
	charge_loop = GLOB.move_manager.move_towards(bull, aim_turf, charge_speed, FALSE, (charge_range + max_walls) * charge_speed, priority = MOVEMENT_ABOVE_SPACE_PRIORITY)
	if(!charge_loop)
		end_charge(BULL_CHARGE_ABORTED)
		return
	RegisterSignal(charge_loop, COMSIG_MOVELOOP_PREPROCESS_CHECK, PROC_REF(pre_loop_move))
	RegisterSignal(charge_loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(post_loop_move))
	RegisterSignal(charge_loop, COMSIG_QDELETING, PROC_REF(on_loop_end))
	RegisterSignal(bull, COMSIG_MOVABLE_BUMP, PROC_REF(on_bump))
	RegisterSignal(bull, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/action/cooldown/mob_cooldown/bull_charge/proc/pre_loop_move(datum/source)
	SIGNAL_HANDLER
	actively_moving = TRUE

/datum/action/cooldown/mob_cooldown/bull_charge/proc/post_loop_move(datum/source)
	SIGNAL_HANDLER
	actively_moving = FALSE

/// No wandering off during the windup or veering mid-dash
/datum/action/cooldown/mob_cooldown/bull_charge/proc/on_pre_move(atom/source, atom/new_loc)
	SIGNAL_HANDLER
	if(!actively_moving)
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/// Loop timed out, we went the whole way without hitting anything worth stopping for
/datum/action/cooldown/mob_cooldown/bull_charge/proc/on_loop_end(datum/source)
	SIGNAL_HANDLER
	charge_loop = null
	if(charging)
		end_charge(BULL_CHARGE_MISSED)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/on_moved(atom/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	new /obj/effect/temp_visual/decoy/fading(old_loc, source)
	// Anyone lying in our path gets run over
	for(var/mob/living/victim in get_turf(source))
		if(victim == source || (victim in trampled) || victim.body_position != LYING_DOWN)
			continue
		trampled += victim
		victim.visible_message(span_danger("[source] tramples [victim]!"), span_userdanger("[source] tramples right over you!"))
		victim.apply_damage(trample_damage, BRUTE, wound_bonus = CANT_WOUND)
		playsound(victim, 'sound/effects/hit_kick.ogg', 50, TRUE)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/on_bump(atom/movable/source, atom/bumped)
	SIGNAL_HANDLER
	if(!charging || bumped == source)
		return
	INVOKE_ASYNC(src, PROC_REF(handle_impact), bumped)
	// No swapping places with or pushing what we just rammed
	return COMPONENT_INTERCEPT_BUMPED

/datum/action/cooldown/mob_cooldown/bull_charge/proc/handle_impact(atom/bumped)
	if(!charging)
		return
	var/mob/living/bull = owner
	shake_camera(bull, 2, 2)

	if(isliving(bumped))
		gore(bumped)
		return

	if(iswallturf(bumped))
		var/turf/closed/wall/wall = bumped
		if(wall.hardness < 30 || walls_smashed >= max_walls) // reinforced, plastitanium etc
			recoil(wall)
			return
		walls_smashed++
		playsound(wall, 'sound/effects/meteorimpact.ogg', 100, TRUE)
		if(walls_smashed < max_walls || prob(50))
			bull.visible_message(span_danger("[bull] smashes straight through [wall]!"))
			wall.dismantle_wall(devastated = TRUE)
			if(walls_smashed >= max_walls)
				end_charge(BULL_CHARGE_HIT_OBSTACLE) // out of momentum
			return
		bull.visible_message(span_danger("[bull] slams into [wall], caving it in!"))
		wall.dismantle_wall(devastated = FALSE) // leaves a girder
		recoil(null, recoil_stun * 0.5)
		return

	if(ismineralturf(bumped))
		var/turf/closed/mineral/rock = bumped
		if(walls_smashed >= max_walls)
			recoil(rock)
			return
		walls_smashed++
		bull.visible_message(span_danger("[bull] bursts through [rock]!"))
		rock.gets_drilled(bull)
		return

	if(isturf(bumped)) // indestructible walls and friends
		recoil(bumped)
		return

	if(!isobj(bumped))
		return
	var/obj/thing = bumped
	if(is_type_in_typecache(thing, fragile_types))
		thing.take_damage(fragile_damage, BRUTE, MELEE, TRUE, get_dir(thing, bull))
		if(QDELETED(thing) || !thing.density)
			bull.visible_message(span_danger("[bull] crashes right through [thing]!"))
			return
		recoil(thing)
		return
	if(!thing.anchored)
		bull.visible_message(span_danger("[bull] sends [thing] flying!"))
		thing.throw_at(get_ranged_target_turf(thing, charge_dir, throw_range), throw_range, 3, bull)
		return
	thing.take_damage(obstacle_damage, BRUTE, MELEE, TRUE, get_dir(thing, bull))
	if(QDELETED(thing) || !thing.density)
		bull.visible_message(span_danger("[bull] smashes through [thing]!"))
		return
	recoil(thing)

/// Gore a mob, wound them and send them flying
/datum/action/cooldown/mob_cooldown/bull_charge/proc/gore(mob/living/victim)
	var/mob/living/bull = owner
	end_charge(BULL_CHARGE_HIT_MOB)
	if(victim.check_block(bull, gore_damage, "the charging [bull.name]", attack_type = LEAP_ATTACK))
		victim.Knockdown(gore_knockdown * 0.5)
		recoil(null)
		return

	victim.visible_message(
		span_danger("[bull] gores [victim] and sends [victim.p_them()] flying!"),
		span_userdanger("[bull] gores you and sends you flying!"),
	)
	playsound(victim, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	shake_camera(victim, 4, 3)

	var/zone = pick(BODY_ZONE_CHEST, BODY_ZONE_CHEST, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	victim.apply_damage(gore_damage, BRUTE, zone, wound_bonus = 10, bare_wound_bonus = 15, sharpness = SHARP_POINTY)
	if(iscarbon(victim))
		var/mob/living/carbon/carbon_victim = victim
		var/obj/item/bodypart/limb = carbon_victim.get_bodypart(zone) || carbon_victim.get_bodypart(BODY_ZONE_CHEST)
		if(limb)
			carbon_victim.cause_wound_of_type_and_severity(pick(WOUND_BLUNT, WOUND_PIERCE), limb, WOUND_SEVERITY_MODERATE, WOUND_SEVERITY_SEVERE, WOUND_PICK_LOWEST_SEVERITY, bull)

	victim.Knockdown(gore_knockdown)
	victim.throw_at(get_ranged_target_turf(victim, charge_dir, throw_range), throw_range, 3, bull, gentle = FALSE)

/// We hit something we can't get through, ouch
/datum/action/cooldown/mob_cooldown/bull_charge/proc/recoil(atom/obstacle, stun = recoil_stun)
	var/mob/living/bull = owner
	if(charging)
		end_charge(BULL_CHARGE_HIT_OBSTACLE)
	if(obstacle)
		bull.visible_message(span_danger("[bull] slams headfirst into [obstacle] and staggers!"))
		playsound(obstacle, 'sound/effects/bang.ogg', 80, TRUE)
		if(iswallturf(obstacle))
			var/turf/closed/wall/wall = obstacle
			wall.add_dent(WALL_DENT_HIT)
	bull.apply_damage(recoil_damage, BRUTE)
	bull.Stun(stun, ignore_canstun = TRUE)
	bull.do_jitter_animation(20)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/abort_charge(datum/source)
	SIGNAL_HANDLER
	if(charging)
		end_charge(BULL_CHARGE_ABORTED)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/end_charge(result)
	if(!charging)
		return
	charging = FALSE
	actively_moving = FALSE
	for(var/timer in windup_timers)
		deltimer(timer)
	windup_timers = null
	target_ref = null
	aim_turf = null
	trampled = null
	if(owner)
		UnregisterSignal(owner, list(COMSIG_MOVABLE_PRE_MOVE, COMSIG_MOVABLE_BUMP, COMSIG_MOVABLE_MOVED, COMSIG_LIVING_DEATH))
	if(charge_loop)
		UnregisterSignal(charge_loop, list(COMSIG_MOVELOOP_PREPROCESS_CHECK, COMSIG_MOVELOOP_POSTPROCESS, COMSIG_QDELETING))
		qdel(charge_loop)
		charge_loop = null
	if(QDELETED(owner))
		return
	if(result == BULL_CHARGE_ABORTED)
		StartCooldown(miss_cooldown, 0)
	else if(result == BULL_CHARGE_MISSED)
		owner.visible_message(span_notice("[owner] skids to a halt and snorts, looking around."))
		StartCooldown(miss_cooldown, 0)
	else
		StartCooldown(cooldown_time, 0)
	SEND_SIGNAL(owner, COMSIG_FINISHED_CHARGE)

/obj/effect/temp_visual/telegraphing/bull_charge
	icon = 'icons/mob/telegraphing/telegraph.dmi'
	icon_state = "target_circle"
	color = COLOR_RED
	duration = 0.6 SECONDS

#undef BULL_CHARGE_MISSED
#undef BULL_CHARGE_HIT_MOB
#undef BULL_CHARGE_HIT_OBSTACLE
#undef BULL_CHARGE_ABORTED
