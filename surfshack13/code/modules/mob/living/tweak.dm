/datum/emote/living/tweak
	key = "tweak"
	key_third_person = "tweaks"
	message = "starts tweaking"

// muscle twitching is incredibly energy intensive, IRL the body does it in an attempt to increase circulation and flush harmful chemicals out the body, or to warm up the body
/datum/emote/living/tweak/run_emote(mob/user, params, type_override, intentional)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(!C.adjustStaminaLoss(60))
			return
	user.AddComponent(/datum/component/tweak, time=8 SECONDS)
	return ..()

GLOBAL_VAR_INIT(hyper_adrenaline_next_round, FALSE)
GLOBAL_VAR_INIT(hyper_adrenaline_active, FALSE)
GLOBAL_DATUM_INIT(hyper_adrenaline_controller, /datum/hyper_adrenaline_controller, new)

/proc/hyper_adrenaline_is_active()
	return GLOB.hyper_adrenaline_active

/datum/hyper_adrenaline_controller
	var/round_effects_applied = FALSE

/datum/hyper_adrenaline_controller/New()
	. = ..()
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(on_round_start))

/datum/hyper_adrenaline_controller/proc/on_round_start(datum/source, round_start_time)
	SIGNAL_HANDLER

	if(round_effects_applied)
		return
	round_effects_applied = TRUE

	GLOB.hyper_adrenaline_active = GLOB.hyper_adrenaline_next_round
	if(!GLOB.hyper_adrenaline_active)
		return

	CONFIG_SET(number/damage_multiplier, CONFIG_GET(number/damage_multiplier) * HYPER_ADRENALINE_DAMAGE_MULTIPLIER)

	to_chat(world, span_notice("<b>Hyper Adrenaline is active for this round.</b>"), confidential = TRUE)
	message_admins(span_adminnotice("Hyper Adrenaline was enabled at round start."))

ADMIN_VERB(toggle_hyper_adrenaline, R_SERVER, "Toggle Hyper Adrenaline", "Enable or disable Hyper Adrenaline for the upcoming round.", ADMIN_CATEGORY_SERVER)
	if(SSticker.current_state > GAME_STATE_PREGAME)
		to_chat(user, span_warning("Hyper Adrenaline is locked for the current round and can only be selected before round start."))
		return

	GLOB.hyper_adrenaline_next_round = !GLOB.hyper_adrenaline_next_round
	var/state_text = GLOB.hyper_adrenaline_next_round ? "enabled" : "disabled"

	log_admin("[key_name(user)] [state_text] Hyper Adrenaline for the upcoming round.")
	message_admins(span_adminnotice("[key_name_admin(user)] has [state_text] Hyper Adrenaline for the upcoming round."))
	to_chat(world, span_notice("<b>Hyper Adrenaline has been [state_text] for the upcoming round.</b>"), confidential = TRUE)
	SSblackbox.record_feedback("nested tally", "admin_toggle", 1, list("Toggle Hyper Adrenaline", GLOB.hyper_adrenaline_next_round ? "Enabled" : "Disabled"))

#define SHARED_SURF_FEED_CONFIG_PATH "data/shared_surf_feed_url.txt"
#define SHARED_SURF_FEED_WINDOW "shared_surf_feed"

/// Returns the operator-provided session-bootstrap or provider URL.
/// The data directory is gitignored so account session material is never committed.
/proc/get_shared_surf_feed_url()
	if(!fexists(SHARED_SURF_FEED_CONFIG_PATH))
		return null

	var/feed_url = trim(file2text(SHARED_SURF_FEED_CONFIG_PATH))
	if(!length(feed_url) || findtext(lowertext(feed_url), "https://") != 1)
		return null

	return feed_url

/client/verb/open_shared_surf_feed()
	set name = "Open Shared Surf Feed"
	set category = "OOC"
	set desc = "Open the experimental shared TikTok or Instagram account feed."

	var/feed_url = get_shared_surf_feed_url()
	if(!feed_url)
		to_chat(src, span_warning("The shared Surf feed is unavailable or has not been configured."))
		return

	// json_encode provides a safely quoted JavaScript string without logging or displaying the URL.
	var/redirect_html = "<!doctype html><html><head><meta charset='utf-8'><title>Shared Surf Feed</title></head><body><p>Opening shared feed...</p><script>window.location.replace([json_encode(feed_url)]);</script></body></html>"
	src << browse(redirect_html, "window=[SHARED_SURF_FEED_WINDOW];size=480x800;can_close=1;can_resize=1;titlebar=1")

/client/verb/close_shared_surf_feed()
	set name = "Close Shared Surf Feed"
	set category = "OOC"
	set desc = "Close the experimental shared feed window."

	src << browse(null, "window=[SHARED_SURF_FEED_WINDOW]")

#undef SHARED_SURF_FEED_CONFIG_PATH
#undef SHARED_SURF_FEED_WINDOW
