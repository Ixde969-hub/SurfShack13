/obj/machinery/vending/snack
	name = "\improper Getmore Chocolate Corp"
	desc = "A snack machine courtesy of the Getmore Chocolate Corporation, based out of Mars."
	product_slogans = "Try our new nougat bar!;Twice the calories for half the price!"
	product_ads = "The healthiest!;Award-winning chocolate bars!;Mmm! So good!;Oh my god it's so juicy!;Have a snack.;Snacks are good for you!;Have some more Getmore!;Best quality snacks straight from mars.;We love chocolate!;Try our new jerky!"
	icon_state = "snack"
	panel_type = "panel2"
	light_mask = "snack-light-mask"
	products = list(
		/obj/item/food/spacetwinkie = 6,
		/obj/item/food/cheesiehonkers = 6,
		/obj/item/food/cheesiehonkers/honk_poppers = 3,
		/obj/item/food/candy = 6,
		/obj/item/food/chips = 6,
		/obj/item/food/chips/morale = 3,
		/obj/item/food/chips/shrimp = 6,
		/obj/item/food/sosjerky = 6,
		/obj/item/food/cornchips/random = 6,
		/obj/item/food/sosjerky = 6,
		/obj/item/food/no_raisin = 6,
		/obj/item/food/peanuts = 6,
		/obj/item/food/peanuts/random = 3,
		/obj/item/food/cnds = 6,
		/obj/item/food/cnds/flavor_roulette = 3,
		/obj/item/food/cnds/random = 3,
		/obj/item/food/semki = 6,
		/obj/item/reagent_containers/cup/glass/dry_ramen = 3,
		/obj/item/storage/box/gum = 3,
		/obj/item/food/energybar = 6,
		/obj/item/food/hot_shots = 6,
		/obj/item/food/sticko = 6,
		/obj/item/food/sticko/random = 3,
		/obj/item/food/shok_roks = 6,
		/obj/item/food/shok_roks/random = 3,
	)
	contraband = list(
		/obj/item/food/syndicake = 6,
		/obj/item/food/peanuts/ban_appeal = 3,
		/obj/item/food/candy/bronx = 1,
	)
	premium = list(
		/obj/item/food/spacers_sidekick = 3,
		/obj/item/food/pistachios = 3,
		/obj/item/food/swirl_lollipop = 3,
	)
	refill_canister = /obj/item/vending_refill/snack
	req_access = list(ACCESS_KITCHEN)
	default_price = PAYCHECK_CREW * 0.6
	extra_price = PAYCHECK_CREW
	payment_department = ACCOUNT_SRV

/obj/item/vending_refill/snack
	machine_name = "Getmore Chocolate Corp"

/obj/machinery/vending/snack/blue
	icon_state = "snackblue"

/obj/machinery/vending/snack/orange
	icon_state = "snackorange"

/obj/machinery/vending/snack/green
	icon_state = "snackgreen"

/obj/machinery/vending/snack/teal
	icon_state = "snackteal"

// Surf Shack snack pack: novelty vending snacks using existing food sprites.
/obj/item/food/cheesiehonkers/honk_poppers
	name = "\improper Honk Poppers"
	desc = "Cheesy little snacks engineered to deliver a medically unnecessary amount of honk per crunch."

/obj/item/food/cheesiehonkers/honk_poppers/make_edible()
	. = ..()
	AddComponent(/datum/component/edible, on_consume = CALLBACK(src, PROC_REF(on_consume)))

/obj/item/food/cheesiehonkers/honk_poppers/proc/on_consume(mob/living/eater)
	playsound(eater, 'sound/items/bikehorn.ogg', 35, TRUE)
	to_chat(eater, span_notice("The snack honks triumphantly as you crunch it."))

/obj/item/food/cnds/flavor_roulette
	name = "\improper C&Ds Flavor Roulette"
	desc = "Every bag is one mystery flavor. Corporate assures you all outcomes are technically food."

/obj/item/food/cnds/flavor_roulette/Initialize(mapload)
	. = ..()
	switch(rand(1, 5))
		if(1)
			name = "banana C&Ds Flavor Roulette"
			desc = "You won banana. Probably."
			tastes = list("banana" = 3, "chocolate candy" = 1)
		if(2)
			name = "coffee C&Ds Flavor Roulette"
			desc = "Breakfast and dessert have reached an uneasy compromise."
			tastes = list("coffee" = 3, "chocolate candy" = 1)
		if(3)
			name = "mint C&Ds Flavor Roulette"
			desc = "Cold-tasting candy without any of the actual cold."
			tastes = list("mint" = 3, "chocolate candy" = 1)
		if(4)
			name = "pickle C&Ds Flavor Roulette"
			desc = "Somebody signed off on this."
			tastes = list("pickle" = 3, "chocolate candy" = 1)
		if(5)
			name = "printer toner C&Ds Flavor Roulette"
			desc = "The flavor department insists this is an abstract interpretation."
			tastes = list("warm plastic" = 2, "chocolate candy" = 1)

/obj/item/food/chips/morale
	name = "\improper Employee Morale Chips"
	desc = "Each crunch contains one legally non-binding piece of encouragement."

/obj/item/food/chips/morale/make_edible()
	. = ..()
	AddComponent(/datum/component/edible, on_consume = CALLBACK(src, PROC_REF(on_consume)))

/obj/item/food/chips/morale/proc/on_consume(mob/living/eater)
	var/encouragement = pick(
		"Corporate believes you are statistically above average today.",
		"That crunch was executed with exceptional professionalism.",
		"You are doing at least one thing correctly right now.",
		"Your continued existence has been noted and provisionally approved.",
		"Keep going. The vending machine is rooting for you.",
	)
	to_chat(eater, span_notice("The bag rustles encouragingly: \"[encouragement]\""))
