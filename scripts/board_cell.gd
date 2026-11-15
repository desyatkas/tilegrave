class_name BoardCell
extends Button

@export var cell_icon: TextureRect
@export var tile_icon: TextureRect
@export var hp_label: RichTextLabel
@export var turns_until_destroyed_label: RichTextLabel

var cell_idx: int = -1
var board_view: BoardView
var tween: Tween


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
		Vector2.ONE * 1.1,
		0.2
	)
	tween.parallel().tween_property(
		self,
		"rotation_degrees",
		5,
		0.2
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
		0.2
	)
	tween.parallel().tween_property(
		self,
		"rotation_degrees",
		0,
		0.2
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
		Vector2.ONE * 1.1,
		0.2
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
		0.2
	)

	await tween.finished

	z_index = 0
