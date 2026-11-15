class_name BoardView
extends GridContainer

signal cell_pressed(idx: int)
signal tile_drop_requested(idx: int, definition: TileDefinition, offer_index: int)

const BOARD_CELL_SCENE: PackedScene = preload("res://scenes/board_cell.tscn")
const EMPTY_CELL_ICON: Texture2D = preload("res://textures/empty_board_cell.png")
const OCCUPIED_CELL_ICON: Texture2D = preload("res://textures/board_cell.png")

var board_state: BoardState
var cell_buttons: Array[BoardCell] = []
var accepts_tile_drops: bool = false
var available_energy: int = 0


func _ready() -> void:
	get_parent().rotation_degrees = randf_range(-1.0, 1.0)

	var tween = create_tween()

	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(get_parent(), "rotation_degrees", 0.5, 5.0)
	tween.tween_property(get_parent(), "rotation_degrees", -0.5, 5.0)


func _on_cell_pressed(idx: int) -> void:
	cell_pressed.emit(idx)


func setup(p_board_state: BoardState) -> void:
	board_state = p_board_state

	for idx in range(16):
		var b_cell: BoardCell = BOARD_CELL_SCENE.instantiate()

		b_cell.cell_idx = idx
		b_cell.board_view = self
		b_cell.pressed.connect(_on_cell_pressed.bind(idx))
		add_child(b_cell)
		cell_buttons.append(b_cell)

	refresh()


func refresh() -> void:
	for idx in range(16):
		var tile: TileState = board_state.cells[idx]
		var b_cell: BoardCell = cell_buttons[idx]

		b_cell.cell_icon.texture = EMPTY_CELL_ICON if tile == null else OCCUPIED_CELL_ICON
		b_cell.cell_icon.modulate = Color.WHITE

		if tile == null:
			b_cell.tooltip_text = ""
			b_cell.tile_icon.texture = null
			b_cell.hp_label.text = ""
			b_cell.turns_until_destroyed_label.text = ""
		else:
			if tile.is_alive():
				b_cell.tooltip_text = "%s\n\nHealth: %d/%d\n\n%s" % [
					tile.definition.display_name,
					tile.hp,
					tile.max_hp,
					tile.definition.description
				]
			else:
				b_cell.tooltip_text = "%s - DEAD\n\n%d turns left until destroying\n\n%s" % [
					tile.definition.display_name,
					tile.turns_until_destroyed,
					tile.definition.description
				]
				b_cell.cell_icon.modulate = Color.WHITE.darkened(0.5)

			b_cell.tile_icon.texture = tile.definition.icon
			b_cell.hp_label.text = str(tile.hp)
			b_cell.turns_until_destroyed_label.text = str(tile.turns_until_destroyed) if tile.is_dead() else ""


func can_accept_drop(idx: int, data: Variant) -> bool:
	if (
			not accepts_tile_drops
			or board_state == null
			or idx < 0
			or idx >= board_state.cells.size()
			or board_state.cells[idx] != null
			or data is not Dictionary
			or data.get("kind") != "shop_tile"
	):
		return false

	var definition: TileDefinition = data.get("definition")

	if definition == null or definition.cost > available_energy:
		return false

	return int(data.get("offer_index", -1)) >= 0


func handle_drop(idx: int, data: Variant) -> void:
	if not can_accept_drop(idx, data):
		return

	var definition: TileDefinition = data.get("definition")
	var offer_index: int = int(data.get("offer_index", -1))

	tile_drop_requested.emit(idx, definition, offer_index)
