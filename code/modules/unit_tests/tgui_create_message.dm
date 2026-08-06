/// Test that `TGUI_CREATE_MESSAGE` is correctly implemented
/datum/unit_test/tgui_create_message

/datum/unit_test/tgui_create_message/Run()
	var/type = "something/here"
	var/list/payload = list(
		"name" = "Terry McTider",
		"heads_caved" = 100,
		"accomplishments" = list(
			"nothing",
			"literally nothing",
			list(
				"something" = "just kidding",
			),
		),
	)

	var/message = TGUI_CREATE_MESSAGE(type, payload)

	// Ensure consistent output to compare by performing a round-trip.
	var/output = json_encode(json_decode(url_decode(message)))

	var/expected = json_encode(list(
		"type" = type,
		"payload" = payload,
	))

	TEST_ASSERT_EQUAL(expected, output, "TGUI_CREATE_MESSAGE didn't round trip properly")

/// Test synchronized television YouTube URL normalization and host validation.
/datum/unit_test/synchronized_tv_youtube_id/Run()
	TEST_ASSERT(surfshack_extract_youtube_id("dQw4w9WgXcQ") == "dQw4w9WgXcQ", "A raw YouTube ID should be accepted.")
	TEST_ASSERT(surfshack_extract_youtube_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ") == "dQw4w9WgXcQ", "A standard watch URL should be accepted.")
	TEST_ASSERT(surfshack_extract_youtube_id("https://youtu.be/dQw4w9WgXcQ?t=10") == "dQw4w9WgXcQ", "A short URL should be accepted and query parameters stripped.")
	TEST_ASSERT(surfshack_extract_youtube_id("https://www.youtube.com/shorts/dQw4w9WgXcQ") == "dQw4w9WgXcQ", "A Shorts URL should be accepted.")
	TEST_ASSERT(!surfshack_extract_youtube_id("https://example.com/watch?v=dQw4w9WgXcQ"), "Non-YouTube hosts must be rejected.")
	TEST_ASSERT(!surfshack_extract_youtube_id("https://example.com/youtu.be/dQw4w9WgXcQ"), "YouTube-looking paths on unrelated hosts must be rejected.")
	TEST_ASSERT(!surfshack_extract_youtube_id("not-a-video"), "Malformed IDs must be rejected.")
