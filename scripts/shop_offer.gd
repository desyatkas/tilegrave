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
var tween: Tween


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not affordable:
		return null

	set_drag_preview(self.duplicate())

	return {
		"kind": "shop_tile",
		"definition": definition,
		"offer_index": offer_index
	}


func _on_mouse_entered() -> void:
	if not definition or not affordable:
		return

	if tween and tween.is_running():
		tween.kill()

	z_index = 1
	tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self,
		"scale",
		Vector2(1.1, 1.1),
		0.1
	)
	tween.parallel().tween_property(
		self,
		"rotation_degrees",
		5,
		0.1
	)

	await tween.finished


func _on_mouse_exited() -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.1
	)
	tween.parallel().tween_property(
		self,
		"rotation_degrees",
		0,
		0.1
	)

	await tween.finished

	z_index = 0


func setup(p_definition: TileDefinition, p_offer_index: int, available_energy: int) -> void:
	scale = Vector2.ZERO
	rotation_degrees = 180.0
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

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.5
	)
	tween.parallel().tween_property(
		self,
		"rotation_degrees",
		0.0,
		0.5
	)


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
