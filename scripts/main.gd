class_name Main
extends Control

const HEART_TILE: TileDefinition = preload("res://resources/heart_tile.tres")
const SWORD_TILE: TileDefinition = preload("res://resources/sword_tile.tres")
const MEDKIT_TILE: TileDefinition = preload("res://resources/medkit_tile.tres")
const SHIELD_TILE: TileDefinition = preload("res://resources/shield_tile.tres")
const H_MIRROR_TILE: TileDefinition = preload("res://resources/horizontal_mirror_tile.tres")
const V_MIRROR_TILE: TileDefinition = preload("res://resources/vertical_mirror_tile.tres")

@export var player_bv: BoardView
@export var enemy_bv: BoardView
@export var shop_view: ShopView
@export var player_hp_label: RichTextLabel
@export var player_energy_label: RichTextLabel
@export var enemy_hp_label: RichTextLabel
@export var enemy_energy_label: RichTextLabel
@export var turns_label: RichTextLabel
@export var end_turn_button: Button
@export var result_label: RichTextLabel

var game: GameState
var turns: int = 0
var game_over: bool = false
var enemy_has_taken_turn: bool = false


func _ready() -> void:
	game = GameState.new()
	player_bv.setup(game.player_bs)
	player_bv.accepts_tile_drops = true
	player_bv.tile_drop_requested.connect(_on_player_tile_drop_requested)
	enemy_bv.setup(game.enemy_bs)

	var tile_pool: Array[TileDefinition] = [
		HEART_TILE,
		SWORD_TILE,
		MEDKIT_TILE,
		SHIELD_TILE,
		H_MIRROR_TILE,
		V_MIRROR_TILE,
	]

	shop_view.setup(tile_pool, game.player_energy)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	update_ui()


func _on_player_tile_drop_requested(idx: int, definition: TileDefinition, offer_index: int) -> void:
	var pos: Array[int] = game.player_bs.idx_to_pos(idx)

	if (
			game_over
			or not game.purchase_tile(
					game.player_bs,
					pos[0],
					pos[1],
					definition
			)
	):
		return

	shop_view.consume_offer(offer_index)
	player_bv.refresh()
	update_ui()


func _on_player_cell_pressed(idx: int) -> void:
	var pos: Array[int] = game.player_bs.idx_to_pos(idx)

	if game.purchase_tile(game.player_bs, pos[0], pos[1], HEART_TILE):
		player_bv.refresh()
		enemy_bv.refresh()
		update_ui()


func _on_end_turn_pressed() -> void:
	if game_over:
		return

	turns += 1

	game.resolve_abilities(game.player_bs)
	game.player_bs.advance_turn()
	game.regenerate_energy(game.player_bs)
	run_enemy_turn()
	enemy_has_taken_turn = true
	player_bv.refresh()
	enemy_bv.refresh()

	if check_game_over():
		update_ui()

		return

	shop_view.refresh_offers(game.player_energy)
	update_ui()


func run_enemy_turn() -> void:
	var empty_indices: Array[int] = game.enemy_bs.get_empty_indices()
	var tile_idx: int = -1
	var definition: TileDefinition = HEART_TILE

	if game.enemy_energy >= SWORD_TILE.cost:
		tile_idx = find_sword_target_idx(empty_indices)

		if tile_idx != -1:
			definition = SWORD_TILE

	if (
			tile_idx == -1
			and game.enemy_energy >= MEDKIT_TILE.cost
			and has_damaged_enemy_tile()
			and not empty_indices.is_empty()
	):
		tile_idx = empty_indices.pick_random()
		definition = MEDKIT_TILE

	if (
			tile_idx == -1
			and game.enemy_energy >= HEART_TILE.cost
			and not empty_indices.is_empty()
	):
		tile_idx = empty_indices.pick_random()
		definition = HEART_TILE

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

		if target.definition.id == &"sword":
			return idx

	for idx in empty_indices:
		var target: TileState = game.player_bs.cells[idx]

		if target != null and target.is_alive():
			return idx

	return -1


func has_damaged_enemy_tile() -> bool:
	for idx in game.enemy_bs.get_alive_indices():
		var tile: TileState = game.enemy_bs.cells[idx]

		if tile.hp < tile.max_hp and tile.definition.id != &"medkit":
			return true

	return false


func check_game_over() -> bool:
	var player_alive: bool = not game.player_bs.get_alive_indices().is_empty()
	var enemy_alive: bool = not game.enemy_bs.get_alive_indices().is_empty()

	if not player_alive and enemy_has_taken_turn and not enemy_alive:
		finish_game("DRAW!")

		return true

	if not player_alive:
		finish_game("DEFEAT!")

		return true

	if enemy_has_taken_turn and not enemy_alive:
		finish_game("VICTORY!")

		return true

	return false


func finish_game(result: String) -> void:
	game_over = true
	result_label.text = result
	result_label.visible = true
	end_turn_button.disabled = true
	shop_view.visible = false
	player_bv.accepts_tile_drops = false


func update_ui() -> void:
	var player_hp: int = 0
	var player_max_hp: int = 0
	var enemy_hp: int = 0
	var enemy_max_hp: int = 0

	for idx in player_bv.board_state.get_occupied_indices():
		player_hp += player_bv.board_state.cells[idx].hp
		player_max_hp += player_bv.board_state.cells[idx].max_hp

	for idx in enemy_bv.board_state.get_occupied_indices():
		enemy_hp += enemy_bv.board_state.cells[idx].hp
		enemy_max_hp += enemy_bv.board_state.cells[idx].max_hp

	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	player_energy_label.text = "Energy: %d/%d" % [game.player_energy, game.player_max_energy]
	enemy_hp_label.text = "HP: %d/%d" % [enemy_hp, enemy_max_hp]
	enemy_energy_label.text = "Energy: %d/%d" % [game.enemy_energy, game.enemy_max_energy]
	player_bv.available_energy = game.player_energy
	turns_label.text = "Turns: %d" % turns
	shop_view.update_energy(game.player_energy)
