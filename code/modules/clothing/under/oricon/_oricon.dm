/obj/item/clothing/under/oricon
	name = "master oricon uniform"
	desc = "You shouldn't be seeing this."
	armor_type = /datum/armor/station/padded
	siemens_coefficient = 0.8
	// default to false
	worn_has_rolldown = UNIFORM_HAS_NO_ROLL
	worn_has_rollsleeve = UNIFORM_HAS_NO_ROLL
	// default to no inhand; until someone gets generic inhands
	worn_render_flags = WORN_RENDER_INHAND_NO_RENDER | WORN_RENDER_SLOT_ONE_FOR_ALL
	worn_bodytypes = BODYTYPES(BODYTYPE_DEFAULT)
