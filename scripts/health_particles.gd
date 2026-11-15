class_name HealthParticles
extends GPUParticles2D

const PLUS: Texture2D = preload("res://textures/plus.png")
const MINUS: Texture2D = preload("res://textures/minus.png")


func _on_finished() -> void:
	queue_free()


func start_plus(p_amount: int) -> void:
	amount = p_amount
	texture = PLUS
	emitting = true


func start_minus(p_amount: int) -> void:
	amount = p_amount
	texture = MINUS
	emitting = true
