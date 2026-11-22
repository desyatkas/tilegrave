class_name ShopView
extends GridContainer

const SHOP_OFFER_SCENE = preload("res://scenes/shop_offer.tscn")

@export var purchase_sfx: AudioStreamPlayer

var tile_pool: Array[TileDefinition]
var offers: Array[ShopOffer]


func _ready() -> void:
	get_parent().rotation_degrees = randf_range(-1.0, 1.0)

	var tween = create_tween()

	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(get_parent(), "rotation_degrees", 0.5, 5.0)
	tween.tween_property(get_parent(), "rotation_degrees", -0.5, 5.0)


func setup(p_tile_pool: Array[TileDefinition], available_energy: int) -> void:
	tile_pool = p_tile_pool

	for idx in range(4):
		var offer: ShopOffer = SHOP_OFFER_SCENE.instantiate()

		offer.setup(tile_pool.pick_random(), idx, available_energy)
		add_child(offer)
		offers.append(offer)

	ensure_affordable_offer(available_energy)


func update_energy(available_energy: int) -> void:
	for offer in offers:
		offer.update_affordability(available_energy)


func refill_offer(idx: int, available_energy: int) -> void:
	if idx < 0 or idx >= offers.size():
		return

	offers[idx].setup(tile_pool.pick_random(), idx, available_energy)
	ensure_affordable_offer(available_energy)
	update_energy(available_energy)


func ensure_affordable_offer(available_energy: int) -> void:
	for offer in offers:
		if offer.definition.cost <= available_energy:
			return

	var affordable_tiles: Array[TileDefinition]

	for definition in tile_pool:
		if definition.cost <= available_energy:
			affordable_tiles.append(definition)

	if not affordable_tiles.is_empty():
		offers[0].setup(affordable_tiles.pick_random(), 0, available_energy)


func consume_offer(idx: int) -> void:
	if idx < 0 or idx >= offers.size():
		return

	purchase_sfx.play()
	offers[idx].mark_sold_out()


func refresh_offers(available_energy: int) -> void:
	for idx in range(offers.size()):
		offers[idx].setup(tile_pool.pick_random(), idx, available_energy)

	ensure_affordable_offer(available_energy)
	update_energy(available_energy)
