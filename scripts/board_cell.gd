class_name BoardCell
extends Button

@export var cell_icon: TextureRect
@export var tile_icon: TextureRect
@export var hp_label: RichTextLabel
@export var turns_until_destroyed_label: RichTextLabel

var cell_idx: int = -1
var board_view: BoardView


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if board_view == null:
		return false
	else:
		return board_view.can_accept_drop(cell_idx, data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if board_view != null:
		board_view.handle_drop(cell_idx, data)


func animate_ability_start() -> void:
	var tween: Tween = create_tween()

	z_index = 1
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE * 1.1,
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished


func animate_ability_end() -> void:
	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	z_index = 0
