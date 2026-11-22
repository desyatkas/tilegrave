class_name Main
extends Control

const HEART_TILE: TileDefinition = preload("res://resources/heart_tile.tres")
const SWORD_TILE: TileDefinition = preload("res://resources/sword_tile.tres")
const MEDKIT_TILE: TileDefinition = preload("res://resources/medkit_tile.tres")
const SHIELD_TILE: TileDefinition = preload("res://resources/shield_tile.tres")
const H_MIRROR_TILE: TileDefinition = preload("res://resources/horizontal_mirror_tile.tres")
const V_MIRROR_TILE: TileDefinition = preload("res://resources/vertical_mirror_tile.tres")
const BOMB_TILE: TileDefinition = preload("res://resources/bomb_tile.tres")
const NECROMANCER_TILE: TileDefinition = preload("res://resources/necromancer_tile.tres")
const GENERATOR_TILE: TileDefinition = preload("res://resources/generator_tile.tres")

@export var player_bv: BoardView
@export var enemy_bv: BoardView
@export var shop_view: ShopView
@export var player_hp_icon: TextureRect
@export var player_hp_label: RichTextLabel
@export var player_energy_icon: TextureRect
@export var player_energy_label: RichTextLabel
@export var enemy_hp_icon: TextureRect
@export var enemy_hp_label: RichTextLabel
@export var enemy_energy_icon: TextureRect
@export var enemy_energy_label: RichTextLabel
@export var end_turn_button: Button
@export var main_menu_panel: Panel
@export var logo: TextureRect
@export var version_label: RichTextLabel
@export var results_panel: Panel
@export var results_title: RichTextLabel
@export var defeat_sfx: AudioStreamPlayer
@export var draw_sfx: AudioStreamPlayer
@export var victory_sfx: AudioStreamPlayer
@export var click_sfx: AudioStreamPlayer


var game: GameState
var turns: int = 0
var game_over: bool = false
var enemy_has_taken_turn: bool = false


func _ready() -> void:
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	game = GameState.new()
	game.energy_changed.connect(_on_energy_changed)
	player_bv.setup(game.player_bs)
	player_bv.is_player = true
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
		BOMB_TILE,
		NECROMANCER_TILE,
		GENERATOR_TILE,
	]

	shop_view.setup(tile_pool, game.player_energy)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	update_ui()

	for thing in [
			player_hp_icon,
			player_hp_label,
			player_energy_icon,
			player_energy_label,
			enemy_hp_icon,
			enemy_hp_label,
			enemy_energy_icon,
			enemy_energy_label,
			end_turn_button,
			main_menu_panel,
			logo,
			results_panel,
			results_title
	]:
		thing.rotation_degrees = randf_range(-1.0, 1.0)

		var tween = create_tween()

		tween.set_loops()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(thing, "rotation_degrees", 1.0, 5.0)
		tween.tween_property(thing, "rotation_degrees", -1.0, 5.0)


func _on_energy_changed(bs: BoardState) -> void:
	var tween = create_tween()

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		player_energy_icon if bs == player_bv.board_state else enemy_energy_icon,
		"scale",
		Vector2(1.5, 1.5),
		0.1
	)
	tween.parallel().tween_property(
		player_energy_icon if bs == player_bv.board_state else enemy_energy_icon,
		"rotation_degrees",
		5,
		0.1
	)
	tween.chain().tween_property(
		player_energy_icon if bs == player_bv.board_state else enemy_energy_icon,
		"scale",
		Vector2.ONE,
		0.1
	)
	tween.parallel().tween_property(
		player_energy_icon if bs == player_bv.board_state else enemy_energy_icon,
		"rotation_degrees",
		0,
		0.1
	)


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

	click_sfx.play()
	end_turn_button.disabled = true
	player_bv.accepts_tile_drops = false
	turns += 1

	await resolve_abilities_animated(player_bv, game.player_bs)

	game.player_bs.advance_turn()
	game.regenerate_energy(game.player_bs)
	player_bv.refresh()
	update_ui()

	await run_enemy_turn()

	enemy_has_taken_turn = true
	player_bv.refresh()
	enemy_bv.refresh()

	if check_game_over():
		update_ui()

		return

	shop_view.refresh_offers(game.player_energy)
	end_turn_button.disabled = false
	player_bv.accepts_tile_drops = true
	update_ui()


func resolve_abilities_animated(board_view: BoardView, bs: BoardState) -> void:
	var ability_indices: Array[int] = bs.get_alive_indices()

	for idx in ability_indices:
		var tile: TileState = bs.cells[idx]

		if tile == null or not tile.is_alive() or not game.has_ability(tile):
			continue

		var cell: BoardCell = board_view.cell_buttons[idx]

		await cell.animate_ability_start()

		if bs.cells[idx] == tile and tile.is_alive():
			game.resolve_ability(bs, idx)
			player_bv.refresh()
			enemy_bv.refresh()
			update_ui()

			await get_tree().create_timer(0.25).timeout

		await cell.animate_ability_end()


func run_enemy_turn() -> void:
	var empty_indices: Array[int] = game.enemy_bs.get_empty_indices()
	var tile_idx: int = -1
	var definition: TileDefinition = HEART_TILE

	if (
			tile_idx == -1
			and game.enemy_energy >= SHIELD_TILE.cost
			and not empty_indices.is_empty()
	):
		tile_idx = find_best_shield_idx(empty_indices)

		if tile_idx != -1:
			definition = SHIELD_TILE

	if (
			tile_idx == -1
			and not empty_indices.is_empty()
	):
		if game.enemy_energy >= H_MIRROR_TILE.cost:
			var h_idx: int = find_best_mirror_idx(
				empty_indices,
				&"h_mirror"
			)

			if h_idx != -1:
				tile_idx = h_idx
				definition = H_MIRROR_TILE

		if (
			tile_idx == -1
			and game.enemy_energy >= V_MIRROR_TILE.cost
		):
			var v_idx: int = find_best_mirror_idx(
				empty_indices,
				&"v_mirror"
			)

			if v_idx != -1:
				tile_idx = v_idx
				definition = V_MIRROR_TILE

	if (
			tile_idx == -1
			and game.enemy_energy >= BOMB_TILE.cost
			and not empty_indices.is_empty()
	):
		tile_idx = find_best_bomb_idx(empty_indices)

		if tile_idx != -1:
			definition = BOMB_TILE

	if (
			tile_idx == -1
			and game.enemy_energy >= SWORD_TILE.cost
			and not empty_indices.is_empty()
	):
		tile_idx = find_sword_target_idx(empty_indices)

		if tile_idx != -1:
			definition = SWORD_TILE

	if (
			tile_idx == -1
			and game.enemy_energy >= NECROMANCER_TILE.cost
			and has_revivable_dead_enemy_tile()
			and not empty_indices.is_empty()
	):
		tile_idx = empty_indices.pick_random()
		definition = NECROMANCER_TILE

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

	enemy_bv.refresh()
	update_ui()

	await resolve_abilities_animated(enemy_bv, game.enemy_bs)

	game.enemy_bs.advance_turn()
	game.regenerate_energy(game.enemy_bs)
	enemy_bv.refresh()
	update_ui()


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


func find_best_shield_idx(empty_indices: Array[int]) -> int:
	var best_idx: int = -1
	var best_score: int = 0

	for idx in empty_indices:
		var pos: Array[int] = game.enemy_bs.idx_to_pos(idx)
		var x: int = pos[0]
		var y: int = pos[1]
		var neighbors: Array[Vector2i] = [
			Vector2i(x, y - 1),
			Vector2i(x - 1, y),
			Vector2i(x, y + 1),
			Vector2i(x + 1, y),
		]
		var score: int = 0

		for neighbor_pos in neighbors:
			if (
					neighbor_pos.x < 0
					or neighbor_pos.x >= 4
					or neighbor_pos.y < 0
					or neighbor_pos.y >= 4
			):
				continue

			var neighbor: TileState = game.enemy_bs.get_tile(neighbor_pos.x, neighbor_pos.y)

			if (
					neighbor == null
					or neighbor.is_dead()
					or neighbor.definition.id == &"shield"
			):
				continue

			var protected_hp: int = mini(neighbor.max_hp, maxi(neighbor.hp, 2))

			score += protected_hp - neighbor.hp

		if score > best_score:
			best_score = score
			best_idx = idx

	return best_idx


func find_best_mirror_idx(empty_indices: Array[int], mirror_id: StringName) -> int:
	var best_idx: int = -1
	var best_score: int = 0

	for idx in empty_indices:
		var pos: Array[int] = game.enemy_bs.idx_to_pos(idx)
		var x: int = pos[0]
		var y: int = pos[1]
		var source: Vector2i
		var target: Vector2i

		match mirror_id:
			&"h_mirror":
				source = Vector2i(x - 1, y)
				target = Vector2i(x + 1, y)
			&"v_mirror":
				source = Vector2i(x, y - 1)
				target = Vector2i(x, y + 1)
			_:
				return -1

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
			continue

		var source_tile: TileState = game.enemy_bs.get_tile(
			source.x,
			source.y
		)
		var target_tile: TileState = game.enemy_bs.get_tile(
			target.x,
			target.y
		)

		if source_tile == null or target_tile != null:
			continue

		var score: int = get_mirror_tile_score(source_tile)

		if score > best_score:
			best_score = score
			best_idx = idx

	return best_idx


func get_mirror_tile_score(tile: TileState) -> int:
	match tile.definition.id:
		&"sword":
			return 5
		&"shield":
			return 4
		&"medkit":
			return 3
		&"heart":
			return 2
		_:
			return 0


func find_best_bomb_idx(empty_indices: Array[int]) -> int:
	var best_idx: int = -1
	var best_score: int = 1

	for idx in empty_indices:
		var pos: Array[int] = game.player_bs.idx_to_pos(idx)
		var x: int = pos[0]
		var y: int = pos[1]
		var neighbors: Array[Vector2i] = [
			Vector2i(x, y - 1),
			Vector2i(x - 1, y),
			Vector2i(x, y + 1),
			Vector2i(x + 1, y),
		]
		var score: int = 0
		var target: TileState = game.player_bs.get_tile(x, y)

		if target != null and target.is_alive():
			score += 1

		for neighbor_pos in neighbors:
			if (
					neighbor_pos.x < 0
					or neighbor_pos.x >= 4
					or neighbor_pos.y < 0
					or neighbor_pos.y >= 4
			):
				continue

			var neighbor: TileState = game.player_bs.get_tile(
				neighbor_pos.x,
				neighbor_pos.y
			)

			if neighbor != null and neighbor.is_alive():
				score += 1

		if score > best_score:
			best_score = score
			best_idx = idx

	return best_idx


func has_damaged_enemy_tile() -> bool:
	for idx in game.enemy_bs.get_alive_indices():
		var tile: TileState = game.enemy_bs.cells[idx]

		if tile.hp < tile.max_hp and tile.definition.id != &"medkit":
			return true

	return false


func has_revivable_dead_enemy_tile() -> bool:
	for idx in game.enemy_bs.get_dead_indices():
		var tile: TileState = game.enemy_bs.cells[idx]

		if tile.definition.id != &"necromancer":
			return true

	return false


func check_game_over() -> bool:
	var player_alive: bool = not game.player_bs.get_alive_indices().is_empty()
	var enemy_alive: bool = not game.enemy_bs.get_alive_indices().is_empty()

	if not player_alive:
		finish_game(0.0)

		return true

	if not player_alive and enemy_has_taken_turn and not enemy_alive:
		finish_game(0.5)

		return true

	if enemy_has_taken_turn and not enemy_alive:
		finish_game(1.0)

		return true

	return false


func finish_game(result: float) -> void:
	game_over = true
	end_turn_button.disabled = true
	shop_view.visible = false
	player_bv.accepts_tile_drops = false

	match result:
		0.0:
			defeat_sfx.play()
			results_title.text = "Defeat!"
		0.5:
			draw_sfx.play()
			results_title.text = "Draw!"
		1.0:
			victory_sfx.play()
			results_title.text = "Victory!"

	var tween = create_tween()

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		results_panel,
		"global_position:y",
		320.0,
		1.0
	)


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

	player_hp_label.text = "%d/%d" % [player_hp, player_max_hp]
	player_energy_label.text = "%d/%d" % [game.player_energy, game.player_max_energy]
	enemy_hp_label.text = "%d/%d" % [enemy_hp, enemy_max_hp]
	enemy_energy_label.text = "%d/%d" % [game.enemy_energy, game.enemy_max_energy]
	player_bv.available_energy = game.player_energy
	shop_view.update_energy(game.player_energy)


func _on_play_button_pressed() -> void:
	click_sfx.play()

	var tween = create_tween()

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		main_menu_panel,
		"global_position:y",
		-main_menu_panel.size.y - 32.0,
		1.0
	)

	await get_tree().create_timer(0.666).timeout

	player_bv.get_parent().visible = true
	enemy_bv.get_parent().visible = true
	shop_view.get_parent().visible = true

	await get_tree().create_timer(0.111).timeout

	player_hp_icon.visible = true
	player_hp_label.visible = true
	player_energy_icon.visible = true
	player_energy_label.visible = true
	enemy_hp_icon.visible = true
	enemy_hp_label.visible = true
	enemy_energy_icon.visible = true
	enemy_energy_label.visible = true
	end_turn_button.visible = true


func _on_quit_button_pressed() -> void:
	click_sfx.play()

	await click_sfx.finished

	get_tree().quit()


func _on_back_to_main_menu_button_pressed() -> void:
	click_sfx.play()

	await click_sfx.finished

	get_tree().reload_current_scene()
