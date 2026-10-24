extends GridContainer
class_name BoardView

signal cell_pressed(idx: int)
signal tile_drop_requested(idx: int, definition: TileDefinition, offer_index: int)

var board_state: BoardState
var cell_buttons: Array[Button]

var accepts_tile_drops: bool = false
var available_energy: int = 0

func setup(p_board_state: BoardState) -> void:
    board_state = p_board_state

    for idx in range(16):
        var button: BoardCell = BoardCell.new()
        button.cell_idx = idx
        button.board_view = self
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.size_flags_vertical = Control.SIZE_EXPAND_FILL
        button.pressed.connect(_on_cell_pressed.bind(idx))

        add_child(button)
        cell_buttons.append(button)

    refresh()

func refresh() -> void:
    for idx in range(16):
        var tile: TileState = board_state.cells[idx]

        if tile == null:
            cell_buttons[idx].text = ""
        elif tile.is_dead():
            cell_buttons[idx].text = "%s\nDEAD (%d)" % [
                tile.definition.display_name,
                tile.turns_until_destroyed
            ]
        else:
            cell_buttons[idx].text = "%s\nHP: %d" % [
                tile.definition.display_name,
                tile.hp
            ]

func can_accept_drop(idx: int, data: Variant) -> bool:
    if not accepts_tile_drops or board_state == null or idx < 0 or idx >= board_state.cells.size() or board_state.cells[idx] != null or data is not Dictionary or data.get("kind") != "shop_tile":
        return false

    var definition: TileDefinition = data.get("definition") as TileDefinition

    if definition == null or definition.cost > available_energy:
        return false

    return int(data.get("offer_index", -1)) >= 0

func handle_drop(idx: int, data: Variant) -> void:
    if not can_accept_drop(idx, data):
        return

    var definition: TileDefinition = data.get("definition") as TileDefinition
    var offer_index: int = int(data.get("offer_index", -1))

    tile_drop_requested.emit(idx, definition, offer_index)

func _on_cell_pressed(idx: int) -> void:
    cell_pressed.emit(idx)
