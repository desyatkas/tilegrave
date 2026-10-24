extends RefCounted
class_name BoardState

var cells: Array[TileState] = []

func _init() -> void:
    cells.resize(16)

func advance_turn() -> void:
    for i in range(cells.size()):
        var tile: TileState = cells[i]

        if tile == null:
            continue

        tile.advance_turn()

        if tile.is_dead() and tile.turns_until_destroyed == 0:
            cells[i] = null

func pos_to_idx(x: int, y: int) -> int:
    return y * 4 + x

func idx_to_pos(idx: int) -> Array[int]:
    return [idx % 4, idx / 4]

func get_tile(x: int, y: int) -> TileState:
    return cells[pos_to_idx(x, y)]

func set_tile(x: int, y: int, tile: TileState) -> void:
    cells[pos_to_idx(x, y)] = tile

func get_empty_indices() -> Array[int]:
    var empty_indices: Array[int] = []

    for idx in range(cells.size()):
        if cells[idx] == null:
            empty_indices.append(idx)

    return empty_indices

func get_alive_indices() -> Array[int]:
    var alive_indices: Array[int] = []

    for idx in range(cells.size()):
        if cells[idx] != null and cells[idx].is_alive():
            alive_indices.append(idx)

    return alive_indices
