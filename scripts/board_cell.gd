class_name BoardCell
extends Button

@export var cell_icon: TextureRect
@export var tile_icon: TextureRect
@export var hp_label: RichTextLabel
@export var turns_until_destroyed_label: RichTextLabel

var cell_idx: int = -1
var board_view: BoardView
var tween: Tween
var effect_tween: Tween
var displayed_tile: TileState
var displayed_is_alive: bool = true


func _ready() -> void:
	turns_until_destroyed_label.rotation_degrees = randf_range(-1.0, 1.0)

	var loop_tween = create_tween()

	loop_tween.set_loops()
	loop_tween.set_trans(Tween.TRANS_SINE)
	loop_tween.set_ease(Tween.EASE_IN_OUT)
	loop_tween.tween_property(
			turns_until_destroyed_label,
			"rotation_degrees",
			1.0,
			0.1
	)
	loop_tween.tween_property(
			turns_until_destroyed_label,
			"rotation_degrees",
			-1.0,
			0.1
	)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if board_view == null:
		return false
	else:
		return board_view.can_accept_drop(cell_idx, data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if board_view != null:
		board_view.handle_drop(cell_idx, data)


func _on_mouse_entered() -> void:
	if not board_view.board_state.cells[cell_idx]:
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


func animate_ability_start() -> void:
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

	await tween.finished


func animate_ability_end() -> void:
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

	await tween.finished

	z_index = 0

func animate_death() -> void:
	if effect_tween and effect_tween.is_running():
		effect_tween.kill()

	tile_icon.scale = Vector2.ONE
	tile_icon.rotation_degrees = 0.0
	tile_icon.modulate = Color.WHITE
	effect_tween = create_tween()
	effect_tween.set_trans(Tween.TRANS_BACK)
	effect_tween.set_ease(Tween.EASE_OUT)
	effect_tween.tween_property(
		tile_icon,
		"scale",
		Vector2(1.1, 1.1),
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"rotation_degrees",
		10.0,
		0.1
	)
	effect_tween.chain().tween_property(
		tile_icon,
		"scale",
		Vector2(0.75, 0.75),
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"rotation_degrees",
		-5.0,
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"modulate",
		Color.RED,
		0.1
	)
	effect_tween.chain().tween_property(
		tile_icon,
		"scale",
		Vector2.ONE,
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"rotation_degrees",
		0.0,
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"modulate",
		Color.WHITE.darkened(0.5),
		0.1
	)


func animate_revival() -> void:
	if effect_tween and effect_tween.is_running():
		effect_tween.kill()

	tile_icon.scale = Vector2.ONE
	tile_icon.rotation_degrees = 0.0
	tile_icon.scale = Vector2(0.75, 0.75)
	tile_icon.modulate = Color.GREEN
	effect_tween = create_tween()
	effect_tween.set_trans(Tween.TRANS_BACK)
	effect_tween.set_ease(Tween.EASE_OUT)
	effect_tween.tween_property(
		tile_icon,
		"scale",
		Vector2(1.1, 1.1),
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"modulate",
		Color.WHITE,
		0.1
	)
	effect_tween.chain().tween_property(
		tile_icon,
		"scale",
		Vector2.ONE,
		0.1
	)


func animate_clone_source(is_alive: bool) -> void:
	if effect_tween and effect_tween.is_running():
		effect_tween.kill()

	tile_icon.scale = Vector2.ONE
	tile_icon.rotation_degrees = 0.0
	tile_icon.modulate = Color.WHITE

	var final_modulate: Color = Color.WHITE if is_alive else Color.WHITE.darkened(0.5)

	effect_tween = create_tween()
	effect_tween.set_trans(Tween.TRANS_BACK)
	effect_tween.set_ease(Tween.EASE_OUT)
	effect_tween.tween_property(
		tile_icon,
		"scale",
		Vector2(1.1, 1.1),
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"modulate",
		Color.BLUE,
		0.1
	)
	effect_tween.chain().tween_property(
		tile_icon,
		"scale",
		Vector2.ONE,
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"modulate",
		final_modulate,
		0.1
	)


func animate_clone_target(is_alive: bool) -> void:
	if effect_tween and effect_tween.is_running():
		effect_tween.kill()

	tile_icon.scale = Vector2.ZERO
	tile_icon.rotation_degrees = 180.0
	tile_icon.modulate = Color(Color.BLUE, 0.0)

	var final_modulate: Color = Color.WHITE if is_alive else Color.WHITE.darkened(0.5)

	effect_tween = create_tween()
	effect_tween.set_trans(Tween.TRANS_BACK)
	effect_tween.set_ease(Tween.EASE_OUT)
	effect_tween.tween_property(
		tile_icon,
		"scale",
		Vector2(1.1, 1.1),
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"rotation_degrees",
		0.0,
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"modulate",
		Color.BLUE,
		0.1
	)
	effect_tween.chain().tween_property(
		tile_icon,
		"modulate",
		final_modulate,
		0.1
	)
	effect_tween.parallel().tween_property(
		tile_icon,
		"scale",
		Vector2.ONE,
		0.1
	)
