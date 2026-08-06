#define SYNCHRONIZED_TV_DEFAULT_RANGE 7
#define SYNCHRONIZED_TV_DRIFT_CORRECTION_INTERVAL 15

/// Returns a validated eleven-character YouTube video ID from an ID or common YouTube URL.
/proc/surfshack_extract_youtube_id(raw_input)
	if(!istext(raw_input))
		return null

	var/input_text = trim(raw_input)
	if(surfshack_is_youtube_id(input_text))
		return input_text

	var/lower_input = LOWER_TEXT(input_text)
	var/id_start
	var/path_start
	var/list/short_url_prefixes = list(
		"https://youtu.be/",
		"http://youtu.be/",
		"youtu.be/",
	)
	var/list/youtube_host_prefixes = list(
		"https://www.youtube.com/",
		"http://www.youtube.com/",
		"https://youtube.com/",
		"http://youtube.com/",
		"https://m.youtube.com/",
		"http://m.youtube.com/",
		"www.youtube.com/",
		"youtube.com/",
		"m.youtube.com/",
	)

	for(var/prefix in short_url_prefixes)
		if(findtext(lower_input, prefix) == 1)
			id_start = length(prefix) + 1
			break

	if(!id_start)
		for(var/prefix in youtube_host_prefixes)
			if(findtext(lower_input, prefix) == 1)
				path_start = length(prefix) + 1
				break

		if(!path_start)
			return null

		var/youtube_path = copytext(lower_input, path_start)
		if(findtext(youtube_path, "embed/") == 1)
			id_start = path_start + length("embed/")
		else if(findtext(youtube_path, "shorts/") == 1)
			id_start = path_start + length("shorts/")
		else if(findtext(youtube_path, "watch") == 1)
			var/video_parameter = findtext(lower_input, "?v=", path_start)
			if(!video_parameter)
				video_parameter = findtext(lower_input, "&v=", path_start)
			if(!video_parameter)
				return null
			id_start = video_parameter + length("?v=")
		else
			return null

	var/id_end = length(input_text) + 1
	for(var/delimiter in list("&", "?", "#", "/"))
		var/delimiter_position = findtext(input_text, delimiter, id_start)
		if(delimiter_position && delimiter_position < id_end)
			id_end = delimiter_position

	var/video_id = copytext(input_text, id_start, id_end)
	return surfshack_is_youtube_id(video_id) ? video_id : null

/// YouTube IDs are exactly eleven URL-safe base64-like characters.
/proc/surfshack_is_youtube_id(candidate)
	if(!istext(candidate) || length(candidate) != 11)
		return FALSE

	var/static/valid_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
	for(var/index in 1 to length(candidate))
		if(!findtext(valid_characters, copytext(candidate, index, index + 1)))
			return FALSE
	return TRUE

/**
 * Stage-one synchronized video prototype.
 *
 * The machine owns the authoritative YouTube ID and playback epoch. Nearby viewers
 * open a fixed TGUI watch surface; their browsers seek to the server-derived time.
 * Queueing, crew submissions, vote skipping, map placement, and a map-anchored HTML
 * surface are intentionally left for later stages.
 */
/obj/machinery/computer/synchronized_tv
	name = "synchronized television prototype"
	desc = "An experimental entertainment console that keeps nearby viewers on the same video timeline."
	icon_screen = "library"
	use_power = NO_POWER_USE
	/// Maximum tile distance at which the watch UI remains open.
	var/viewing_range = SYNCHRONIZED_TV_DEFAULT_RANGE
	/// Current validated YouTube video ID.
	var/video_id
	/// Human-readable fallback title for the prototype.
	var/video_title
	/// world.time at which the current playback epoch started.
	var/playback_started_at
	/// Starting position in seconds for the current playback epoch.
	var/playback_offset_seconds = 0
	/// Incremented whenever clients must reconstruct the embedded player.
	var/playback_revision = 0

/obj/machinery/computer/synchronized_tv/ui_state(mob/user)
	return GLOB.always_state

/obj/machinery/computer/synchronized_tv/ui_status(mob/user, datum/ui_state/state)
	if(!user?.client || user.z != z || get_dist(user, src) > viewing_range)
		return UI_CLOSE
	if(machine_stat & (BROKEN | NOPOWER))
		return UI_CLOSE
	return UI_INTERACTIVE

/obj/machinery/computer/synchronized_tv/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SynchronizedTelevision", name)
		ui.open()

/obj/machinery/computer/synchronized_tv/ui_data(mob/user)
	var/list/data = list()
	var/distance = get_dist(user, src)

	data["video_id"] = video_id
	data["video_title"] = video_title
	data["expected_position"] = current_playback_position()
	data["playback_revision"] = playback_revision
	data["volume"] = volume_for_distance(distance)
	data["distance"] = distance
	data["viewing_range"] = viewing_range
	data["can_control"] = can_control(user)
	data["drift_interval"] = SYNCHRONIZED_TV_DRIFT_CORRECTION_INTERVAL
	return data

/obj/machinery/computer/synchronized_tv/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user
	switch(action)
		if("load_video")
			if(!can_control(user))
				to_chat(user, span_warning("Only administrators may control this prototype."))
				return TRUE

			var/raw_input = tgui_input_text(user, "Enter a YouTube video URL or eleven-character video ID.", "Load synchronized video", null, 512)
			if(isnull(raw_input))
				return TRUE

			var/new_video_id = surfshack_extract_youtube_id(raw_input)
			if(!new_video_id)
				to_chat(user, span_warning("That is not a supported YouTube video URL or ID."))
				return TRUE

			video_id = new_video_id
			video_title = "YouTube video [new_video_id]"
			playback_started_at = world.time
			playback_offset_seconds = 0
			playback_revision++
			log_admin("[key_name(user)] loaded YouTube video [new_video_id] into [src] at [AREACOORD(src)].")
			message_admins("[key_name_admin(user)] loaded YouTube video [new_video_id] into [src] at [AREACOORD(src)].")
			SStgui.update_uis(src)
			return TRUE

		if("stop_video")
			if(!can_control(user))
				to_chat(user, span_warning("Only administrators may control this prototype."))
				return TRUE

			var/old_video_id = video_id
			video_id = null
			video_title = null
			playback_started_at = 0
			playback_offset_seconds = 0
			playback_revision++
			log_admin("[key_name(user)] stopped YouTube video [old_video_id || "(none)"] on [src] at [AREACOORD(src)].")
			message_admins("[key_name_admin(user)] stopped the synchronized television [src] at [AREACOORD(src)].")
			SStgui.update_uis(src)
			return TRUE

/obj/machinery/computer/synchronized_tv/proc/can_control(mob/user)
	return !!user?.client?.holder

/obj/machinery/computer/synchronized_tv/proc/current_playback_position()
	if(!video_id || !playback_started_at)
		return 0
	return playback_offset_seconds + max(0, (world.time - playback_started_at) / 10)

/obj/machinery/computer/synchronized_tv/proc/volume_for_distance(distance)
	if(distance <= 2)
		return 100
	if(distance >= viewing_range)
		return 15
	return round(100 - ((distance - 2) * 85 / max(1, viewing_range - 2)))

#undef SYNCHRONIZED_TV_DEFAULT_RANGE
#undef SYNCHRONIZED_TV_DRIFT_CORRECTION_INTERVAL
