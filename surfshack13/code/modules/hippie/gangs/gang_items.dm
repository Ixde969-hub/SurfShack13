// Gangtool shop entries. Only Hippie's "Gang War" items are ported; the Gangmageddon and
// vigilante-only entries (gateways, mounted guns, rocket launchers, mechs) are left out.

/datum/gang_item
	/// Shown in the shop
	var/name
	/// What gets spawned
	var/item_path
	/// Influence cost
	var/cost = 0
	/// Extra message on purchase
	var/spawn_msg
	/// Shop section
	var/category
	/// Unique key within its category
	var/id

/datum/gang_item/proc/purchase(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool, check_canbuy = TRUE)
	if(check_canbuy && !can_buy(user, gang, gangtool))
		return FALSE
	var/real_cost = get_cost(user, gang, gangtool)
	if(!spawn_item(user, gang, gangtool))
		return FALSE
	gang.adjust_influence(-real_cost)
	to_chat(user, span_notice("You bought \the [name]."))
	log_game("[key_name(user)] bought [name] for the [gang.name] gang with [real_cost] influence.")
	return TRUE

/// Spawns the item in the user's hands. Returns TRUE on success.
/datum/gang_item/proc/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	if(!item_path)
		return FALSE
	var/obj/item/bought = new item_path(user.drop_location())
	user.put_in_hands(bought)
	if(spawn_msg)
		to_chat(user, spawn_msg)
	return TRUE

/datum/gang_item/proc/can_buy(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return gang && gang.influence >= get_cost(user, gang, gangtool) && can_see(user, gang, gangtool)

/datum/gang_item/proc/can_see(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return TRUE

/datum/gang_item/proc/get_cost(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return cost

/datum/gang_item/proc/get_cost_display(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return "([get_cost(user, gang, gangtool)] Influence)"

/datum/gang_item/proc/get_name_display(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return name

/datum/gang_item/proc/get_extra_info(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return

// ---- Clothing ----

/datum/gang_item/clothing
	category = "Purchase Gang Clothes (Only the jumpsuit and suit give you added influence):"

/datum/gang_item/clothing/under
	name = "Gang Uniform"
	id = "under"
	cost = 1

/datum/gang_item/clothing/under/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	if(!length(gang.inner_outfits))
		return FALSE
	var/outfit_type = pick(gang.inner_outfits)
	user.put_in_hands(new outfit_type(user.drop_location()))
	to_chat(user, span_notice("This is your gang's official uniform, wearing it will increase your influence."))
	return TRUE

/datum/gang_item/clothing/suit
	name = "Gang Armored Outerwear"
	id = "suit"
	cost = 1

/datum/gang_item/clothing/suit/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	if(!length(gang.outer_outfits))
		return FALSE
	var/outfit_type = pick(gang.outer_outfits)
	var/obj/item/clothing/outerwear = new outfit_type(user.drop_location())
	outerwear.set_armor(/datum/armor/gang_outerwear)
	outerwear.desc += " Tailored for the [gang.name] Gang to offer the wearer moderate protection against ballistics and physical trauma."
	user.put_in_hands(outerwear)
	to_chat(user, span_notice("This is your gang's official outerwear, wearing it will increase your influence."))
	return TRUE

/datum/armor/gang_outerwear
	melee = 20
	bullet = 35
	laser = 10
	energy = 10
	bomb = 30
	fire = 30
	acid = 30

/datum/gang_item/clothing/hat
	name = "Pimp Hat"
	id = "hat"
	cost = 16
	item_path = /obj/item/clothing/head/collectable/petehat/gang

/obj/item/clothing/head/collectable/petehat/gang
	name = "pimpin' hat"
	desc = "The undisputed king of style."

/datum/gang_item/clothing/mask
	name = "Golden Death Mask"
	id = "mask"
	cost = 18
	item_path = /obj/item/clothing/mask/gskull

/obj/item/clothing/mask/gskull
	name = "golden death mask"
	desc = "Strike terror, and envy, into the hearts of your enemies."
	icon_state = "gskull"

/datum/gang_item/clothing/shoes
	name = "Bling Boots"
	id = "boots"
	cost = 22
	item_path = /obj/item/clothing/shoes/gang

/obj/item/clothing/shoes/gang
	name = "blinged-out boots"
	desc = "Stand aside peasants."
	icon_state = "bling"

/datum/gang_item/clothing/neck
	name = "Gold Necklace"
	id = "necklace"
	cost = 9
	item_path = /obj/item/clothing/neck/necklace/dope

/datum/gang_item/clothing/hands
	name = "Decorative Brass Knuckles"
	id = "hand"
	cost = 11
	item_path = /obj/item/clothing/gloves/gang

/obj/item/clothing/gloves/gang
	name = "braggadocio's brass knuckles"
	desc = "Purely decorative, don't find out the hard way."
	icon_state = "knuckles"
	w_class = WEIGHT_CLASS_NORMAL

/datum/gang_item/clothing/belt
	name = "Badass Belt"
	id = "belt"
	cost = 13
	item_path = /obj/item/storage/belt/military/gang

/obj/item/storage/belt/military/gang
	name = "badass belt"
	desc = "The belt buckle simply reads 'BAMF'."
	icon_state = "gangbelt"
	worn_icon_state = "gang"
	inhand_icon_state = null

// ---- Weapons ----

/datum/gang_item/weapon
	category = "Purchase Weapons:"

/datum/gang_item/weapon/shuriken
	name = "Shuriken"
	id = "shuriken"
	cost = 3
	item_path = /obj/item/throwing_star

/datum/gang_item/weapon/switchblade
	name = "Switchblade"
	id = "switchblade"
	cost = 5
	item_path = /obj/item/switchblade

/datum/gang_item/weapon/surplus
	name = "Surplus Rifle"
	id = "surplus"
	cost = 8
	item_path = /obj/item/gun/ballistic/automatic/surplus

/datum/gang_item/weapon/surplus_ammo
	name = "Surplus Rifle Ammo"
	id = "surplus_ammo"
	cost = 5
	item_path = /obj/item/ammo_box/magazine/m10mm/rifle

// Hippie sold an improvised sawn-off shotgun, which Surf no longer has.
/datum/gang_item/weapon/shotgun
	name = "Double-Barreled Shotgun"
	id = "sawn"
	cost = 6
	item_path = /obj/item/gun/ballistic/shotgun/doublebarrel

/datum/gang_item/weapon/buckshot
	name = "Box of Buckshot"
	id = "buckshot"
	cost = 5
	item_path = /obj/item/storage/box/lethalshot

// Hippie's 10mm pistol is Surf's 9mm Makarov now.
/datum/gang_item/weapon/pistol
	name = "Makarov Pistol"
	id = "pistol"
	cost = 30
	item_path = /obj/item/gun/ballistic/automatic/pistol

/datum/gang_item/weapon/pistol_ammo
	name = "Makarov Ammo"
	id = "pistol_ammo"
	cost = 10
	item_path = /obj/item/ammo_box/magazine/m9mm

/datum/gang_item/weapon/uzi
	name = "Uzi SMG"
	id = "uzi"
	cost = 60
	item_path = /obj/item/gun/ballistic/automatic/mini_uzi

/datum/gang_item/weapon/uzi_ammo
	name = "Uzi Ammo"
	id = "uzi_ammo"
	cost = 40
	item_path = /obj/item/ammo_box/magazine/uzim9mm

/datum/gang_item/weapon/glock
	name = "Glock 17"
	id = "g17"
	cost = 30
	item_path = /obj/item/gun/ballistic/automatic/pistol/g17

/datum/gang_item/weapon/glock_ammo
	name = "G17 Ammo"
	id = "g17_ammo"
	cost = 10
	item_path = /obj/item/ammo_box/magazine/g17

// ---- Equipment ----

/datum/gang_item/equipment
	category = "Purchase Equipment:"

/datum/gang_item/equipment/medpatch
	name = "Healing Patch"
	id = "heal"
	cost = 4
	item_path = /obj/item/reagent_containers/pill/patch/gang

/obj/item/reagent_containers/pill/patch/gang
	name = "unlabeled medical patch"
	desc = "Very popular among the type of people who can't go to a real hospital."
	icon_state = "bandaid_brute"
	list_reagents = list(/datum/reagent/medicine/c2/libital = 20, /datum/reagent/medicine/c2/aiuri = 10, /datum/reagent/drug/methamphetamine = 5)

/datum/gang_item/equipment/spraycan
	name = "Territory Spraycan"
	id = "spraycan"
	cost = 5

/datum/gang_item/equipment/spraycan/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	user.put_in_hands(new /obj/item/toy/crayon/spraycan/gang(user.drop_location(), gang))
	return TRUE

/datum/gang_item/equipment/sharpener
	name = "Sharpener"
	id = "whetstone"
	cost = 3
	item_path = /obj/item/sharpener

/datum/gang_item/equipment/emp
	name = "EMP Grenade"
	id = "EMP"
	cost = 5
	item_path = /obj/item/grenade/empgrenade

/datum/gang_item/equipment/c4
	name = "C4 Explosive"
	id = "c4"
	cost = 7
	item_path = /obj/item/grenade/c4

/datum/gang_item/equipment/frag
	name = "Fragmentation Grenade"
	id = "frag nade"
	cost = 18
	item_path = /obj/item/grenade/frag

/datum/gang_item/equipment/stimpack
	name = "Black Market Stimulants"
	id = "stimpack"
	cost = 12
	item_path = /obj/item/reagent_containers/hypospray/medipen/stimulants

/datum/gang_item/equipment/implant_breaker
	name = "Implant Breaker"
	id = "implant_breaker"
	cost = 10
	spawn_msg = span_notice("The <b>implant breaker</b> is a single-use device that destroys all implants within the target before trying to recruit them to your gang. Also works on enemy gangsters.")

/datum/gang_item/equipment/implant_breaker/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	user.put_in_hands(new /obj/item/implanter/gang(user.drop_location(), gang))
	to_chat(user, spawn_msg)
	return TRUE

/datum/gang_item/equipment/wetwork_boots
	name = "Wetwork Boots"
	id = "wetwork"
	cost = 20
	item_path = /obj/item/clothing/shoes/combat/gang

/obj/item/clothing/shoes/combat/gang
	name = "wetwork boots"
	desc = "A gang's best hitmen are prepared for anything."
	clothing_traits = list(TRAIT_NO_SLIP_WATER)

/datum/gang_item/equipment/bulletproof_armor
	name = "Bulletproof Armor"
	id = "BPA"
	cost = 20
	item_path = /obj/item/clothing/suit/armor/bulletproof

/datum/gang_item/equipment/bulletproof_helmet
	name = "Bulletproof Helmet"
	id = "BPH"
	cost = 10
	item_path = /obj/item/clothing/head/helmet/alt

/datum/gang_item/equipment/pen
	name = "Recruitment Pen"
	id = "pen"
	cost = 10
	item_path = /obj/item/pen/gang
	spawn_msg = span_notice("More <b>recruitment pens</b> will allow you to recruit gangsters faster. Only gang leaders can recruit with pens.")

/datum/gang_item/equipment/pen/can_see(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return user.mind?.has_antag_datum(/datum/antagonist/gang/boss) && ..()

/datum/gang_item/equipment/pen/purchase(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool, check_canbuy = TRUE)
	. = ..()
	if(.)
		gangtool.free_pen = FALSE

/datum/gang_item/equipment/pen/get_cost(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return gangtool?.free_pen ? 0 : ..()

/datum/gang_item/equipment/pen/get_cost_display(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return gangtool?.free_pen ? "(GET ONE FREE)" : ..()

/datum/gang_item/equipment/gangtool
	name = "Spare Gangtool"
	id = "gangtool"
	cost = 10

/datum/gang_item/equipment/gangtool/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	var/tool_type = /obj/item/gangtool/spare
	if(length(gang.leaders) < gang.max_leaders)
		tool_type = /obj/item/gangtool/spare/lieutenant
		to_chat(user, span_notice("<b>Gangtools</b> allow you to promote a gangster to be your Lieutenant, enabling them to recruit and purchase items like you. Simply have them register the gangtool. You may promote up to [gang.max_leaders - length(gang.leaders)] more Lieutenants."))
	user.put_in_hands(new tool_type(user.drop_location()))
	return TRUE

/datum/gang_item/equipment/gangtool/get_name_display(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	if(gang && length(gang.leaders) < gang.max_leaders)
		return "Promote a Gangster"
	return "Spare Gangtool"

/datum/gang_item/equipment/dominator
	name = "Station Dominator"
	id = "dominator"
	cost = 30
	item_path = /obj/machinery/dominator
	spawn_msg = span_notice("The <b>dominator</b> will secure your gang's dominance over the station. Turn it on when you are ready to defend it.")

/datum/gang_item/equipment/dominator/can_see(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return user.mind?.has_antag_datum(/datum/antagonist/gang/boss) && ..()

/datum/gang_item/equipment/dominator/can_buy(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return gang?.dom_attempts && ..()

/datum/gang_item/equipment/dominator/get_name_display(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return gang?.dom_attempts ? "<b>[..()]</b>" : ..()

/datum/gang_item/equipment/dominator/get_cost_display(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return gang?.dom_attempts ? ..() : "(Out of stock)"

/datum/gang_item/equipment/dominator/get_extra_info(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	if(gang)
		return "This device requires a 5x5 area clear of walls to work. (Estimated Takeover Time: [round(gang.determine_domination_time() / 60, 0.1)] minutes)"

/datum/gang_item/equipment/dominator/purchase(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool, check_canbuy = TRUE)
	var/area/user_area = get_area(user)
	if(!(user_area.type in (gang.territories | gang.new_territories)))
		to_chat(user, span_warning("The <b>dominator</b> can be spawned only on territory controlled by your gang!"))
		return FALSE
	for(var/obj/thing in get_turf(user))
		if(thing.density)
			to_chat(user, span_warning("There's not enough room here!"))
			return FALSE
	var/open_turfs = 0
	for(var/turf/nearby in view(3, user))
		if(!isclosedturf(nearby))
			open_turfs++
	if(open_turfs < GANG_DOM_REQUIRED_TURFS)
		if(tgui_alert(user, "Are you sure you wish to place the dominator here? There needs to be [GANG_DOM_REQUIRED_TURFS - open_turfs] more open tiles!", "Confirm", list("Ready", "Later")) != "Ready")
			return FALSE
	return ..()

/datum/gang_item/equipment/dominator/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	new item_path(get_turf(user))
	to_chat(user, spawn_msg)
	return TRUE
