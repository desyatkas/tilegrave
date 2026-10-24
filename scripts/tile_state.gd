extends RefCounted
class_name TileState

var definition: TileDefinition
var hp: int

var turns_until_destroyed: int = -1

func _init(p_definition: TileDefinition) -> void:
    definition = p_definition
    hp = definition.max_hp

func take_damage(amount: int) -> void:
    if amount <= 0 or is_dead():
        return

    hp = maxi(0, hp - amount)

    if is_dead():
        turns_until_destroyed = 4

func advance_turn() -> void:
    if is_alive():
        return

    if turns_until_destroyed > 0:
        turns_until_destroyed -= 1

func is_alive() -> bool:
    return hp > 0

func is_dead() -> bool:
    return hp <= 0
