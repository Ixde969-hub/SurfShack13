/datum/uplink_item/dangerous/execution_sword
	name = "Execution Sword"
	desc = "This modified energy sword has been specially designed to cleanly remove the head of a human\
			 in one well aimed swipe. It contains a hacked transmitter that will broadcast the\
			 details of your gruesome execution on the station announcement channel so everyone will know the\
			 name of the filthy pig you are about to slaughter. You may dedicate your executions to whomever you\
			 please by using the device in hand but you may only do so once. Be warned that you must remain still\
			 for a long time to execute a target so be sure to have them restrained and if you should be interrupted\
			 then news of your failure will be broadcast to the station."
	item = /obj/item/melee/execution_sword/antag
	cost = 1
	surplus = 30
	purchasable_from = ~UPLINK_INFILTRATORS

/obj/item/chainsaw/energy
	name = "energy chainsaw"
	desc = "An incredibly deadly modified chainsaw using plasma-based energy cutters in place of an ordinary chain. Heavy, loud, and exceptionally destructive."
	force_on = 60
	armour_penetration = 15
	block_chance = 50

/datum/uplink_item/dangerous/energy_chainsaw
	name = "Energy Chainsaw"
	desc = "An incredibly deadly modified chainsaw with plasma-based energy cutters. It tears through matter with extreme efficiency, but remains heavy, large, and monstrously loud."
	item = /obj/item/chainsaw/energy
	cost = 14
	purchasable_from = UPLINK_TRAITORS

#include "energy_chainsaw_assets.dm"
