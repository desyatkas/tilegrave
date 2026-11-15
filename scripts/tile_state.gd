class_name TileState
extends RefCounted

const HEALTH_PARTICLES_SCENE: PackedScene = preload("res://scenes/health_particles.tscn")

enum VisualEvent {
	NONE = 0,
	DIED = 1,
	REVIVED = 2,
	CLONE_SOURCE = 4,
	CLONE_TARGET = 8,
}

var definition: TileDefinition
var bc: BoardCell
var max_hp: int
var hp: int
var turns_until_destroyed: int = -1
var just_died: bool = false
var pending_visual_events: int = VisualEvent.NONE


func _init(p_definition: TileDefinition) -> void:
	definition = p_definition
	max_hp = definition.max_hp
	hp = max_hp


func heal(amount: int) -> void:
	if amount <= 0:
		return

	var was_dead: bool = is_dead()
	var previous_hp: int = hp

	hp = mini(max_hp, hp + amount)

	var healed_amount: int = hp - previous_hp

	if healed_amount <= 0:
		return

	if was_dead and is_alive():
		turns_until_destroyed = -1
		just_died = false
		queue_visual_event(VisualEvent.REVIVED)

	_spawn_health_particles(true, healed_amount)


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead():
		return

	var previous_hp: int = hp

	hp = maxi(0, hp - amount)

	var damage_taken: int = previous_hp - hp

	if damage_taken <= 0:
		return

	if is_dead():
		turns_until_destroyed = 4
		just_died = true
		queue_visual_event(VisualEvent.DIED)

	_spawn_health_particles(false, damage_taken)


func _spawn_health_particles(is_healing: bool, amount: int) -> void:
	if not is_instance_valid(bc) or amount <= 0:
		return

	var particles: HealthParticles = HEALTH_PARTICLES_SCENE.instantiate()

	bc.add_child(particles)

	if is_healing:
		particles.start_plus(amount)
	else:
		particles.start_minus(amount)


func queue_visual_event(event: int) -> void:
	pending_visual_events = pending_visual_events | event


func consume_visual_events() -> int:
	var events: int = pending_visual_events

	pending_visual_events = VisualEvent.NONE

	return events


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
