#include "crynet_nanosuit.inc"
#include "crynet_fidelity.inc"

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

// The normal MOD control powers itself off at exactly zero charge. CryNet instead falls back to
// Maximum Armor and recharges after its delay, so retain a negligible reserve while active.
/obj/item/mod/control/pre_equipped/crynet/process(seconds_per_tick)
	if(active && get_charge() <= 0)
		add_charge(0.01)
	return ..()

/datum/uplink_item/dangerous/crynet_nanosuit
	name = "CryNet Nanosuit"
	desc = "A banned CryNet adaptive combat nanosuit with mutually exclusive Armor, Cloak, Speed, and Strength modes. Once worn it locks to the operator and broadcasts its activation on the station. Its systems include self-recharging power, emergency medical nanites, defrosting, night vision, threat HUDs, explosion sensing, a jetpack, and an emag-overclockable combat controller."
	item = /obj/item/mod/control/pre_equipped/crynet/faithful
	cost = 20
	surplus = 0
	purchasable_from = UPLINK_TRAITORS

#include "crynet_assets.inc"
