class_name GameState
extends RefCounted

var player_bs: BoardState
var enemy_bs: BoardState
var player_energy: int = 8
var enemy_energy: int = 8


func _init() -> void:
	player_bs = BoardState.new()
	enemy_bs = BoardState.new()


func _resolve_sword(bs: BoardState, idx: int) -> void:
	var opponent_bs: BoardState = enemy_bs if bs == player_bs else player_bs
	var target: TileState = opponent_bs.cells[idx]

	if target == null:
		return

	var attacker: TileState = bs.cells[idx]
	target.take_damage(attacker.definition.ability_power)


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
		player_energy += energy_gain
	elif board == enemy_bs:
		enemy_energy += energy_gain


func resolve_abilities(bs: BoardState) -> void:
	if bs != player_bs and bs != enemy_bs:
		return

	for idx in bs.get_alive_indices():
		var tile: TileState = bs.cells[idx]

		match tile.definition.ability_id:
			&"sword":
				_resolve_sword(bs, idx)
