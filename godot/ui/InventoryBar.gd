extends HBoxContainer

var _hud_map := Dictionary()
var _inventory_need := Dictionary()
var _inventory : Inventory = null

func _ready() -> void:
    _hud_map['Coal'] = $Label
    _hud_map['Emerald'] = $Label2
    _hud_map['Gold'] = $Label3
    _hud_map['Iron'] = $Label4
    _hud_map['Lapis'] = $Label5
    _hud_map['Redstone'] = $Label6
    _hud_map['Stone'] = $Label7

func set_inventory(inventory : Inventory) -> void:
    if _inventory:
        _inventory.disconnect("amount_changed", self, "_on_inventory_amount_changed")

    _inventory = inventory

    _inventory.connect("amount_changed", self, "_on_inventory_amount_changed")
    _inventory.force_update()

func set_inventory_need(needs : Dictionary) -> void:
    _inventory_need = needs
    _inventory_update_colour()

func _on_inventory_amount_changed(name : String, amount : int) -> void:
    """
        Updated the HUD upon inventory amount changes
    """
    _hud_map[name].text = str(amount)
    _inventory_update_colour()
    
func _inventory_update_colour() -> void:
    if not _inventory:
        return
    
    for k in _hud_map.keys():
        var show_red := false
        if k in _inventory_need:
            if _inventory_need[k] > _inventory.amount(k):
                show_red = true
        if show_red:
            _hud_map[k].set("custom_colors/font_color", Color(1.0, 0.0, 0.0))
        else:
            _hud_map[k].set("custom_colors/font_color", Color(1.0, 1.0, 1.0))
