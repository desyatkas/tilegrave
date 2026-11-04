class_name GameState
extends RefCounted

const HEART_TILE: TileDefinition = preload("res://resources/heart_tile.tres")

var player_bs: BoardState
var enemy_bs: BoardState
var player_energy: int = 8
var player_max_energy: int = 16
var enemy_energy: int = 8
var enemy_max_energy: int = 16


func _init() -> void:
	player_bs = BoardState.new()
	enemy_bs = BoardState.new()
	player_bs.set_tile(
			randi_range(0, 3),
			randi_range(0, 3),
			TileState.new(HEART_TILE)
	)
	enemy_bs.set_tile(
			randi_range(0, 3),
			randi_range(0, 3),
			TileState.new(HEART_TILE)
	)


func _resolve_sword(bs: BoardState, idx: int) -> void:
	var opponent_bs: BoardState = enemy_bs if bs == player_bs else player_bs
	var target: TileState = opponent_bs.cells[idx]

	if target == null:
		return

	target.take_damage(1)


func _resolve_medkit(bs: BoardState, idx: int) -> void:
	var pool: Array[TileState] = []

	for i in bs.get_alive_indices():
		if (
				bs.cells[i].hp < bs.cells[i].max_hp
				and bs.cells[i].definition.id != &"medkit"
		):
			pool.append(bs.cells[i])

	if pool.is_empty():
		return

	var target: TileState = pool.pick_random()

	target.heal(1)
	bs.cells[idx].take_damage(1)


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

		if (
				neighbor == null
				or neighbor.definition.id == &"shield"
				or not neighbor.is_alive()
		):
			continue

		neighbor.hp = mini(neighbor.max_hp, maxi(neighbor.hp, 2))


func _resolve_mirror(bs: BoardState, idx: int) -> void:
	var pos: Array[int] = bs.idx_to_pos(idx)
	var x: int = pos[0]
	var y: int = pos[1]
	var source: Vector2i
	var target: Vector2i

	match bs.get_tile(x, y).definition.id:
		&"h_mirror":
			source = Vector2i(x - 1, y)
			target = Vector2i(x + 1, y)
		&"v_mirror":
			source = Vector2i(x, y - 1)
			target = Vector2i(x, y + 1)
		_:
			return

	if (
			source.x < 0
			or source.x >= 4
			or source.y < 0
			or source.y >= 4
			or target.x < 0
			or target.x >= 4
			or target.y < 0
			or target.y >= 4
	):
		return

	var source_tile: TileState = bs.get_tile(source.x, source.y)

	if source_tile == null:
		return

	if bs.get_tile(target.x, target.y) != null:
		return

	var target_tile: TileState = TileState.new(source_tile.definition) if source_tile else null

	target_tile.hp = source_tile.hp
	target_tile.turns_until_destroyed = source_tile.turns_until_destroyed
	bs.set_tile(target.x, target.y, target_tile)


func _resolve_bomb(bs: BoardState, idx: int) -> void:
	var opponent_bs: BoardState = enemy_bs if bs == player_bs else player_bs
	var pos: Array[int] = opponent_bs.idx_to_pos(idx)
	var x: int = pos[0]
	var y: int = pos[1]
	var neighbors: Array[Vector2i] = [
		Vector2i(x, y - 1),
		Vector2i(x - 1, y),
		Vector2i(x, y + 1),
		Vector2i(x + 1, y),
	]
	var target: TileState = opponent_bs.cells[idx]

	if target != null:
		target.take_damage(1)

	for neighbor_pos in neighbors:
		if (
				neighbor_pos.x < 0
				or neighbor_pos.x >= 4
				or neighbor_pos.y < 0
				or neighbor_pos.y >= 4
		):
			continue

		var neighbor: TileState = opponent_bs.get_tile(
			neighbor_pos.x,
			neighbor_pos.y
		)

		if (
				neighbor == null
				or neighbor.is_dead()
		):
			continue

		neighbor.take_damage(1)

	bs.cells[idx].take_damage(bs.cells[idx].hp)


func _resolve_necromancer(bs: BoardState, idx: int) -> void:
	var did_heal: bool = false

	for i in bs.get_dead_indices():
		if bs.cells[i].definition.id != &"necromancer":
			bs.cells[i].heal(1)
			did_heal = true

	if did_heal:
		bs.cells[idx].take_damage(1)


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
		player_energy = mini(player_energy + energy_gain, player_max_energy)
	elif board == enemy_bs:
		enemy_energy = mini(enemy_energy + energy_gain, enemy_max_energy)


func resolve_abilities(bs: BoardState) -> void:
	if bs != player_bs and bs != enemy_bs:
		return

	for idx in bs.get_alive_indices():
		var tile: TileState = bs.cells[idx]

		match tile.definition.id:
			&"sword":
				_resolve_sword(bs, idx)
			&"medkit":
				_resolve_medkit(bs, idx)
			&"shield":
				_resolve_shield(bs, idx)
			&"h_mirror", &"v_mirror":
				_resolve_mirror(bs, idx)
			&"bomb":
				_resolve_bomb(bs, idx)
			&"necromancer":
				_resolve_necromancer(bs, idx)
