class_name GameState
extends RefCounted

const HEART_TILE: TileDefinition = preload("res://resources/heart_tile.tres")

var player_bs: BoardState
var enemy_bs: BoardState
var max_player_energy: int = 16
var max_enemy_energy: int = 16
var player_energy: int = 8
var enemy_energy: int = 8


func _init() -> void:
	player_bs = BoardState.new()
	enemy_bs = BoardState.new()

	player_bs.set_tile(randi_range(0, 3), randi_range(0, 3), TileState.new(HEART_TILE))
	enemy_bs.set_tile(randi_range(0, 3), randi_range(0, 3), TileState.new(HEART_TILE))


func _resolve_sword(bs: BoardState, idx: int) -> void:
	var opponent_bs: BoardState = enemy_bs if bs == player_bs else player_bs
	var target: TileState = opponent_bs.cells[idx]

	if target == null:
		return

	target.take_damage(1)


func _resolve_medkit(bs: BoardState) -> void:
	var pool: Array[TileState] = []

	for idx in bs.get_alive_indices():
		if (
				bs.cells[idx].hp < bs.cells[idx].max_hp
				and bs.cells[idx].definition.id != &"medkit"
		):
			pool.append(bs.cells[idx])

	if pool.is_empty():
		return

	var target: TileState = pool.pick_random()

	target.heal(1)


func _resolve_shield(bs: BoardState, idx: int) -> void:
	var pos: Array[int] = bs.idx_to_pos(idx)
	var x: int = pos[0]
	var y: int = pos[1]
	var neighbors: Array[Vector2i] = [
		Vector2i(x, y - 1),
		Vector2i(x - 1, y),
		Vector2i(x, y + 1),
		Vector2i(x + 1, y),
	]

	for neighbor_pos in neighbors:
		if (
				neighbor_pos.x < 0
				or neighbor_pos.x >= 4
				or neighbor_pos.y < 0
				or neighbor_pos.y >= 4
		):
			continue

		var neighbor: TileState = bs.get_tile(
			neighbor_pos.x,
			neighbor_pos.y
		)

		if neighbor == null or not neighbor.is_alive():
			continue

		neighbor.hp = mini(neighbor.max_hp, maxi(neighbor.hp, 2))


func purchase_tile(board: BoardState, x: int, y: int, definition: TileDefinition) -> bool:
	if (
			(board != player_bs and board != enemy_bs)
			or (x < 0 or x >= 4 or y < 0 or y >= 4)
			or definition == null
			or board.get_tile(x, y) != null
	):
		return false

	var is_player: bool = board == player_bs
	var energy: int = player_energy if is_player else enemy_energy

	if energy < definition.cost:
		return false

	board.set_tile(x, y, TileState.new(definition))

	if is_player:
		player_energy -= definition.cost
	else:
		enemy_energy -= definition.cost

	return true


func regenerate_energy(board: BoardState) -> void:
	var energy_gain: int = board.get_alive_indices().size()

	if board == player_bs:
		player_energy = mini(player_energy + energy_gain, max_player_energy)
	elif board == enemy_bs:
		enemy_energy = mini(enemy_energy + energy_gain, max_enemy_energy)


func resolve_abilities(bs: BoardState) -> void:
	if bs != player_bs and bs != enemy_bs:
		return

	for idx in bs.get_alive_indices():
		var tile: TileState = bs.cells[idx]

		match tile.definition.id:
			&"sword":
				_resolve_sword(bs, idx)
			&"medkit":
				_resolve_medkit(bs)
			&"shield":
				_resolve_shield(bs, idx)
