extends Button
class_name ShopOffer

var definition: TileDefinition
var offer_index: int
var affordable: bool

func _get_drag_data(_at_position: Vector2) -> Variant:
    if not affordable:
        return null

    var preview: Label = Label.new()
    preview.text = definition.display_name

    set_drag_preview(preview)

    return {
        "kind": "shop_tile",
        "definition": definition,
        "offer_index": offer_index
    }

func setup(p_definition: TileDefinition, p_offer_index: int, available_energy: int) -> void:
    definition = p_definition
    offer_index = p_offer_index

    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL

    text = "%s\nHP: %d | Cost: %d" % [
        definition.display_name,
        definition.max_hp,
        definition.cost
    ]

    tooltip_text = definition.description

    update_affordability(available_energy)

func update_affordability(available_energy: int) -> void:
    affordable = definition.cost <= available_energy
    disabled = not affordable
