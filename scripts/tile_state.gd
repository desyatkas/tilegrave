class_name TileState
extends RefCounted

const HEALTH_PARTICLES_SCENE: PackedScene = preload("res://scenes/health_particles.tscn")

var definition: TileDefinition
var bc: BoardCell
var max_hp: int
var hp: int
var turns_until_destroyed: int = -1
var just_died: bool = false


func _init(p_definition: TileDefinition) -> void:
	definition = p_definition
	max_hp = definition.max_hp
	hp = max_hp


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)

	var particles = HEALTH_PARTICLES_SCENE.instantiate()

	bc.add_child(particles)
	particles.start_plus(amount)


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead():
		return

	hp = maxi(0, hp - amount)

	if is_dead():
		turns_until_destroyed = 4
		just_died = true

	var particles = HEALTH_PARTICLES_SCENE.instantiate()

	bc.add_child(particles)
	particles.start_minus(amount)


func advance_turn() -> void:
	if is_alive():
		return

	if just_died:
		just_died = false

		return

	if turns_until_destroyed > 0:
		turns_until_destroyed -= 1


func is_alive() -> bool:
	return hp > 0


func is_dead() -> bool:
	return hp <= 0
