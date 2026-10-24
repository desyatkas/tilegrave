extends Control
class_name Main

const LAZY_TILE: TileDefinition = preload("res://resources/lazy_tile.tres")
const SWORD_TILE: TileDefinition = preload("res://resources/sword_tile.tres")

@export var player_bv: BoardView
@export var enemy_bv: BoardView

@export var shop_view: ShopView

@export var player_energy_label: Label
@export var enemy_energy_label: Label

@export var end_turn_button: Button

var game: GameState

func _ready() -> void:
    game = GameState.new()

    player_bv.setup(game.player_bs)
    player_bv.accepts_tile_drops = true
    player_bv.tile_drop_requested.connect(_on_player_tile_drop_requested)

    enemy_bv.setup(game.enemy_bs)

    var tile_pool: Array[TileDefinition] = [
        LAZY_TILE,
        SWORD_TILE
    ]

    shop_view.setup(tile_pool, game.player_energy)

    end_turn_button.pressed.connect(_on_end_turn_pressed)

    update_ui()

func _on_player_tile_drop_requested(idx: int, definition: TileDefinition, offer_index: int) -> void:
    var pos: Array[int] = game.player_bs.idx_to_pos(idx)

    if not game.purchase_tile(
        game.player_bs,
        pos[0],
        pos[1],
        definition
    ):
        return

    shop_view.refill_offer(offer_index, game.player_energy)

    player_bv.refresh()

    update_ui()

func _on_player_cell_pressed(idx: int) -> void:
    var pos: Array[int] = game.player_bs.idx_to_pos(idx)

    if game.purchase_tile(game.player_bs, pos[0], pos[1], LAZY_TILE):
        player_bv.refresh()
        enemy_bv.refresh()

        update_ui()

func _on_end_turn_pressed() -> void:
    game.resolve_abilities(game.player_bs)

    game.player_bs.advance_turn()
    game.regenerate_energy(game.player_bs)

    run_enemy_turn()

    player_bv.refresh()
    enemy_bv.refresh()

    update_ui()

func run_enemy_turn() -> void:
    var empty_indices: Array[int] = game.enemy_bs.get_empty_indices()
    var tile_idx: int = -1
    var definition: TileDefinition = LAZY_TILE

    if game.enemy_energy >= SWORD_TILE.cost:
        tile_idx = find_sword_target_idx(empty_indices)

        if tile_idx != -1:
            definition = SWORD_TILE

    if tile_idx == -1 and game.enemy_energy >= LAZY_TILE.cost:
        if not empty_indices.is_empty():
            tile_idx = empty_indices.pick_random()
            definition = LAZY_TILE

    if tile_idx != -1:
        var pos: Array[int] = game.enemy_bs.idx_to_pos(tile_idx)

        game.purchase_tile(
            game.enemy_bs,
            pos[0],
            pos[1],
            definition
        )

    game.resolve_abilities(game.enemy_bs)

    game.enemy_bs.advance_turn()
    game.regenerate_energy(game.enemy_bs)

func find_sword_target_idx(empty_indices: Array[int]) -> int:
    for idx in empty_indices:
        var target: TileState = game.player_bs.cells[idx]

        if target == null or not target.is_alive():
            continue

        if target.definition.ability_id == &"sword":
            return idx

    for idx in empty_indices:
        var target: TileState = game.player_bs.cells[idx]

        if target != null and target.is_alive():
            return idx

    return -1

func update_ui() -> void:
    player_energy_label.text = "Energy: %d" % game.player_energy
    enemy_energy_label.text = "Energy: %d" % game.enemy_energy

    player_bv.available_energy = game.player_energy
    shop_view.update_energy(game.player_energy)
