/**
 * The secret hidden inside the Heaven Reliant Sword and the Dragon Slaying Saber.
 * Shatter the two against each other and two manuals fall out: the Nine Yin Manual and the Wumu Yishu.
 * Each teaches one reader a technique nobody else on the station can learn, usable by anyone, cultivator or not.
 */
/obj/item/book/granter/legendary_inheritance
	name = "legendary manual"
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "manual"
	pages_to_mastery = 3
	reading_time = 3 SECONDS
	uses = 1
	/// The technique it teaches
	var/datum/action/granted_action

/obj/item/book/granter/legendary_inheritance/can_learn(mob/living/user)
	if(!user.mind)
		return FALSE
	if(locate(granted_action) in user.actions)
		to_chat(user, span_warning("You already know everything this book holds."))
		return FALSE
	return TRUE

/obj/item/book/granter/legendary_inheritance/on_reading_finished(mob/living/user)
	var/datum/action/technique = new granted_action(user.mind)
	technique.Grant(user)
	cultivation_guqin_phrase(user, list(1, 3, 5, 6, 5))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(user))
	user.log_message("learned [technique.name] from [src]", LOG_GAME)

/obj/item/book/granter/legendary_inheritance/recoil(mob/living/user)
	to_chat(user, span_warning("The pages crumble as you open them. Whatever it held has already passed to someone else."))

// ===================== Nine Yin Manual =====================

/obj/item/book/granter/legendary_inheritance/nine_yin
	name = "Nine Yin Manual"
	desc = "A silk-bound manual that fell out of the shattered Heaven Reliant Sword. Its pages are cold to the touch."
	icon_state = "manual_nine_yin"
	granted_action = /datum/action/cooldown/nine_yin_claw
	remarks = list(
		"The Way of Heaven takes from what is excessive to give to what is lacking...",
		"Five fingers, nine yin, white bone...",
		"Soft overcomes hard. Cold overcomes heat. The fingers overcome the skull...",
	)

/obj/item/book/granter/legendary_inheritance/nine_yin/on_reading_finished(mob/living/user)
	. = ..()
	to_chat(user, span_boldnotice("You have learned the Nine Yin White Bone Claw! Use it on someone beside you: it ignores armour, tears their meridians, and leaves them reeling."))

/datum/action/cooldown/nine_yin_claw
	name = "Nine Yin White Bone Claw"
	desc = "A five-fingered claw from the Nine Yin Manual. Rakes someone beside you for heavy damage that ignores armour, tears their meridians (internal injury) \
		and leaves them staggered and dazed."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "nine_yin_claw"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED|AB_CHECK_HANDS_BLOCKED
	click_to_activate = TRUE
	unset_after_click = TRUE
	cooldown_time = 20 SECONDS

/datum/action/cooldown/nine_yin_claw/Activate(atom/target)
	var/mob/living/user = owner
	if(!isliving(target) || target == user || !user.Adjacent(target))
		user.balloon_alert(user, "too far!")
		return FALSE
	var/mob/living/victim = target
	StartCooldown()
	user.do_attack_animation(victim, ATTACK_EFFECT_CLAW)
	user.say("Nine Yin White Bone Claw!", forced = "nine yin manual")
	victim.visible_message(span_danger("[user]'s fingers turn bone-white and rake through [victim]!"), span_userdanger("Icy fingers tear straight through you!"))
	playsound(victim, 'sound/items/weapons/slash.ogg', 60, TRUE, frequency = 0.8)
	new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), "#e8f4ff")
	cultivation_distortion_wave(victim, 2, 0.3 SECONDS, 160)
	victim.apply_damage(25, BRUTE, user.zone_selected, wound_bonus = 15, sharpness = SHARP_EDGED)
	cultivation_add_internal_injury(victim)
	victim.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
	victim.adjust_dizzy_up_to(6 SECONDS, 10 SECONDS)
	log_combat(user, victim, "struck with the Nine Yin White Bone Claw")
	return TRUE

// ===================== Wumu Yishu =====================

/obj/item/book/granter/legendary_inheritance/wumu_yishu
	name = "Wumu Yishu"
	desc = "General Yue Fei's lost book of war, which fell out of the shattered Dragon Slaying Saber. Every page is a battle plan."
	icon_state = "manual_wumu"
	granted_action = /datum/action/cooldown/wumu_command
	remarks = list(
		"An army that knows its general fears nothing...",
		"Shake a mountain, easy. Shake the Yue Family Army, impossible...",
		"Repay the nation with utmost loyalty...",
	)

/obj/item/book/granter/legendary_inheritance/wumu_yishu/on_reading_finished(mob/living/user)
	. = ..()
	to_chat(user, span_boldnotice("You have learned the Command of the Wumu Yishu! Rally up to three people you can see into an unbreakable formation."))

/datum/action/cooldown/wumu_command
	name = "Command of the Wumu Yishu"
	desc = "Rally up to three people you can see, and yourself, into a battle formation for 30 seconds: they move faster, shrug off exhaustion and fear, \
		and take far less stamina damage."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "wumu_command"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 2 MINUTES

/datum/action/cooldown/wumu_command/Activate(atom/target)
	StartCooldown()
	INVOKE_ASYNC(src, PROC_REF(rally), owner)
	return TRUE

/datum/action/cooldown/wumu_command/proc/rally(mob/living/general)
	var/list/options = list()
	for(var/mob/living/carbon/human/soldier in view(7, general))
		if(soldier != general && soldier.stat == CONSCIOUS)
			options[soldier.real_name] = soldier
	var/list/chosen = list()
	if(length(options))
		chosen = tgui_input_checkboxes(general, "Rally whom? (up to three)", "Command of the Wumu Yishu", options, 0, 3)
	if(QDELETED(general) || general.stat != CONSCIOUS)
		return
	general.say("Shake a mountain, easy! Shake my army, impossible!", forced = "wumu yishu")
	cultivation_great_bell(general, 50)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(general))
	var/list/rallied = list(general)
	for(var/name in chosen)
		var/mob/living/soldier = options[name]
		if(!QDELETED(soldier) && soldier.stat == CONSCIOUS && (soldier in view(9, general)))
			rallied += soldier
	for(var/mob/living/soldier as anything in rallied)
		soldier.apply_status_effect(/datum/status_effect/wumu_formation)

/datum/status_effect/wumu_formation
	id = "wumu_formation"
	alert_type = null
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = STATUS_EFFECT_NO_TICK

/datum/status_effect/wumu_formation/on_apply()
	owner.add_traits(list(TRAIT_FEARLESS), TRAIT_STATUS_EFFECT(id))
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/wumu_formation)
	owner.adjustStaminaLoss(-40)
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(discipline))
	owner.add_filter("wumu_formation", 2, list("type" = "outline", "color" = "#e0a040", "size" = 1))
	to_chat(owner, span_boldnotice("You fall into formation. You will not break."))
	return TRUE

/datum/status_effect/wumu_formation/on_remove()
	owner.remove_traits(list(TRAIT_FEARLESS), TRAIT_STATUS_EFFECT(id))
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/wumu_formation)
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	owner.remove_filter("wumu_formation")

/datum/status_effect/wumu_formation/proc/discipline(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype == STAMINA)
		damage_mods += 0.5

/datum/movespeed_modifier/status_effect/wumu_formation
	multiplicative_slowdown = -0.25
