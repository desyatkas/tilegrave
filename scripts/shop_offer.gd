class_name ShopOffer
extends Button

const EMPTY_CELL_ICON: Texture2D = preload("res://textures/empty_board_cell.png")
const OCCUPIED_CELL_ICON: Texture2D = preload("res://textures/board_cell.png")

@export var board_cell_icon: TextureRect
@export var offer_icon: TextureRect
@export var cost_label: RichTextLabel

var definition: TileDefinition
var offer_index: int
var affordable: bool


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not affordable:
		return null

	set_drag_preview(self.duplicate())

	return {
		"kind": "shop_tile",
		"definition": definition,
		"offer_index": offer_index
	}


func setup(p_definition: TileDefinition, p_offer_index: int, available_energy: int) -> void:
	definition = p_definition
	offer_index = p_offer_index
	offer_icon.texture = definition.icon
	cost_label.text = str(definition.cost)
	tooltip_text = "%s\n\nCost: %d\nHealth: %d\n\n%s" % [
		definition.display_name,
		definition.cost,
		definition.max_hp,
		definition.description
	]
	update_affordability(available_energy)


func update_affordability(available_energy: int) -> void:
	if definition == null:
		affordable = false
		disabled = true

		return

	affordable = definition.cost <= available_energy
	disabled = not affordable

	board_cell_icon.texture = OCCUPIED_CELL_ICON if affordable else EMPTY_CELL_ICON


func mark_sold_out() -> void:
	definition = null
	affordable = false
	disabled = true
	tooltip_text = ""
	board_cell_icon.texture = EMPTY_CELL_ICON
	offer_icon.texture = null
	cost_label.text = ""
