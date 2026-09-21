/obj/machinery/vending/games
	name = "\improper Good Clean Fun"
	desc = "Vends things that the Captain and Head of Personnel are probably not going to appreciate you fiddling with instead of your job..."
	product_ads = "Escape to a fantasy world!;Fuel your gambling addiction!;Ruin your friendships!;Roll for initiative!;Elves and dwarves!;Paranoid computers!;Totally not satanic!;Fun times forever!"
	icon_state = "games"
	panel_type = "panel4"
	product_categories = list(
		list(
			"name" = "Cards",
			"icon" = "diamond",
			"products" = list(
				/obj/item/toy/cards/deck = 5,
				/obj/item/toy/cards/deck/blank = 3,
				/obj/item/toy/cards/deck/blank/black = 3,
				/obj/item/toy/cards/deck/cas = 3,
				/obj/item/toy/cards/deck/cas/black = 3,
				/obj/item/toy/cards/deck/kotahi = 3,
				/obj/item/toy/cards/deck/tarot = 3,
				/obj/item/toy/cards/deck/wizoff = 3,
			),
		),
		list(
			"name" = "Toys",
			"icon" = "hat-wizard",
			"products" = list(
				/obj/item/toy/captainsaid = 1,
				/obj/item/toy/intento = 3,
				/obj/item/toy/beach_ball/rally = 2,
				/obj/item/toy/redbutton/vibe_checker = 2,
				/obj/item/toy/redbutton/rps_referee = 2,
				/obj/item/storage/box/tail_pin = 1,
			),
		),
		list(
			"name" = "Art",
			"icon" = "palette",
			"products" = list(
				/obj/item/storage/crayons = 2,
				/obj/item/chisel = 3,
				/obj/item/paint_palette = 3,
				/obj/item/canvas/nineteen_nineteen = 5,
				/obj/item/canvas/twentythree_nineteen = 5,
				/obj/item/canvas/twentythree_twentythree = 5,
				/obj/item/canvas/twentyfour_twentyfour = 5,
				/obj/item/canvas/thirtysix_twentyfour = 3,
				/obj/item/canvas/fortyfive_twentyseven = 3,
				/obj/item/wallframe/painting/large = 5,
				/obj/item/stack/pipe_cleaner_coil/random = 10,
			),
		),
		list(
			"name" = "Fishing",
			"icon" = "fish",
			"products" = list(
				/obj/item/storage/toolbox/fishing = 2,
				/obj/item/storage/box/fishing_hooks = 2,
				/obj/item/storage/box/fishing_lines = 2,
				/obj/item/storage/box/fishing_lures = 2,
				/obj/item/book/manual/fish_catalog = 5,
				/obj/item/reagent_containers/cup/fish_feed = 4,
				/obj/item/fish_analyzer = 2,
				/obj/item/fishing_rod/telescopic = 1,
				/obj/item/fish_tank = 1,
			),
		),
		list(
			"name" = "Skillchips",
			"icon" = "floppy-disk",
			"products" = list(
				/obj/item/skillchip/appraiser = 2,
				/obj/item/skillchip/basketweaving = 2,
				/obj/item/skillchip/bonsai = 2,
				/obj/item/skillchip/intj = 2,
				/obj/item/skillchip/light_remover = 2,
				/obj/item/skillchip/master_angler = 2,
				/obj/item/skillchip/sabrage = 2,
				/obj/item/skillchip/useless_adapter = 5,
				/obj/item/skillchip/wine_taster = 2,
				/obj/item/skillchip/big_pointer = 2,
			),
		),
		list(
			"name" = "Other",
			"icon" = "star",
			"products" = list(
				/obj/item/camera = 3,
				/obj/item/camera_film = 5,
				/obj/item/cardpack/resin = 20, //Both card packs have had their count raised to 20 from 10 until card persistence is implemented.
				/obj/item/cardpack/series_one = 20,
				/obj/item/dyespray = 3,
				/obj/item/hourglass = 2,
				/obj/item/instrument/piano_synth/headphones = 4,
				/obj/item/razor = 3,
				/obj/item/storage/card_binder = 10,
				/obj/item/storage/dice = 10,
			),
		),
	)
	contraband = list(
		/obj/item/dice/fudge = 9,
		/obj/item/clothing/shoes/wheelys/skishoes = 4,
		/obj/item/instrument/musicalmoth = 1,
		/obj/item/gun/ballistic/revolver/russian = 1, //the most dangerous game
		/obj/item/skillchip/acrobatics = 1,
	)
	premium = list(
		/obj/item/disk/holodisk = 5,
		/obj/item/rcl = 2,
		/obj/item/airlock_painter = 1,
		/obj/item/clothing/shoes/wheelys/rollerskates= 3,
		/obj/item/melee/skateboard/pro = 3,
		/obj/item/melee/skateboard/hoverboard = 1,
	)
	refill_canister = /obj/item/vending_refill/games
	default_price = PAYCHECK_CREW
	extra_price = PAYCHECK_COMMAND * 1.25
	payment_department = ACCOUNT_SRV
	light_mask = "games-light-mask"

/obj/item/vending_refill/games
	machine_name = "\improper Good Clean Fun"
	icon_state = "refill_games"

// Surf Shack fun pack: three harmless toys using existing art and systems.
/obj/item/toy/beach_ball/rally
	name = "rally beach ball"
	desc = "A beach ball with a tiny rally counter. Keep it bouncing between people without letting it touch anything boring."
	var/rally_hits = 0

/obj/item/toy/beach_ball/rally/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(isliving(hit_atom))
		rally_hits++
		if(rally_hits >= 3)
			visible_message(span_notice("[src]'s rally counter flashes [rally_hits]!"))
		return
	if(rally_hits)
		visible_message(span_notice("[src]'s [rally_hits]-hit rally comes to an end."))
		rally_hits = 0

/obj/item/toy/redbutton/vibe_checker
	name = "vibe checker"
	desc = "A needlessly authoritative button that assigns a completely scientific vibe score."

/obj/item/toy/redbutton/vibe_checker/attack_self(mob/user)
	if(cooldown > world.time)
		to_chat(user, span_warning("The vibe checker is still recalibrating."))
		return
	cooldown = world.time + 20
	var/vibe_score = rand(0, 100)
	var/vibe_readout
	if(vibe_score <= 20)
		vibe_readout = "critically questionable"
	else if(vibe_score <= 40)
		vibe_readout = "a little suspicious"
	else if(vibe_score <= 60)
		vibe_readout = "perfectly average"
	else if(vibe_score <= 80)
		vibe_readout = "immaculate"
	else
		vibe_readout = "astronomical"
	user.visible_message(
		span_notice("[user] checks their vibe. [src] reports [vibe_score]/100: [vibe_readout]!"),
		span_notice("You check your vibe. [src] reports [vibe_score]/100: [vibe_readout]!"),
	)

/obj/item/toy/redbutton/rps_referee
	name = "rock-paper-scissors referee"
	desc = "A pocket referee for the oldest conflict-resolution protocol known to spacers."

/obj/item/toy/redbutton/rps_referee/attack_self(mob/user)
	if(cooldown > world.time)
		to_chat(user, span_warning("The referee demands a rematch pause."))
		return
	var/player_choice = tgui_input_list(user, "Choose your move.", "Rock, Paper, Scissors", list("Rock", "Paper", "Scissors"))
	if(isnull(player_choice))
		return
	cooldown = world.time + 10
	var/referee_choice = pick("Rock", "Paper", "Scissors")
	var/result
	if(player_choice == referee_choice)
		result = "It's a tie"
	else if(
		(player_choice == "Rock" && referee_choice == "Scissors") ||
		(player_choice == "Paper" && referee_choice == "Rock") ||
		(player_choice == "Scissors" && referee_choice == "Paper")
	)
		result = "[user] wins"
	else
		result = "[src] wins"
	user.visible_message(
		span_notice("[user] plays [player_choice]. [src] plays [referee_choice]. [result]!"),
		span_notice("You play [player_choice]. [src] plays [referee_choice]. [result]!"),
	)
