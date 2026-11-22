class_name HealthParticles
extends GPUParticles2D

const PLUS: Texture2D = preload("res://textures/plus.png")
const MINUS: Texture2D = preload("res://textures/minus.png")

@export var plus_sfx: AudioStreamPlayer
@export var minus_sfx: AudioStreamPlayer

func _on_finished() -> void:
	queue_free()


func start_plus(p_amount: int) -> void:
	plus_sfx.play()
	amount = p_amount
	texture = PLUS
	emitting = true


func start_minus(p_amount: int) -> void:
	minus_sfx.play()
	amount = p_amount
	texture = MINUS
	emitting = true
