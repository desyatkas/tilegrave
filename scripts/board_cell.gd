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
