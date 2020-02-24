extends Node2D

onready var world_map := $Navigation2D/WorldMap
onready var fog_map := $FogMap
onready var navigator := $Navigation2D

var inventory : Inventory

var path := Array()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    inventory = Inventory.new()
    inventory.connect("amount_changed", self, "_on_inventory_amount_changed")
    inventory.force_update()
    inventory.add('Stone', 10)
    inventory.add('Iron', 2)
    
    for m in get_tree().get_nodes_in_group("minions"):
        m.connect("tile_dug", self, "_on_tile_dug")

func tile_can_be_dug(tile : Vector2) -> bool:
    # Is it already dug or built?
    if world_map.tile_set.tile_get_name(world_map.get_cellv(tile)) == "corridor" or \
       world_map.tile_set.tile_get_name(world_map.get_cellv(tile)).begins_with("building-"):
        return false
    
    # Is it accessible via a corridor
    var found = false
    for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
        if world_map.get_cellv(tile + d) == world_map.tile_set.find_tile_by_name("corridor"):
            found = true
    return found

func _on_tile_dug(tile : Vector2, digger : Minion) -> void:
    if not tile_can_be_dug(tile):
        print("ERROR: cannot dig at " + str(tile))
        return
    
    # Ensure that is can be dug by the digger
    if digger:
        var digger_tile : Vector2 = world_map.world_to_map(digger.position)
        var delta := digger_tile - tile
        var dist = delta.x * delta.x + delta.y * delta.y
        if dist > 1:
            print("ERROR: digger at " + str(digger.position) + " (" + str(digger_tile) + ") cannot dig at " + str(tile))
            return
    
    # Update world and inventory
    match world_map.tile_set.tile_get_name(world_map.get_cellv(tile)):
        'coal':
            inventory.add('Coal', 1)
        'emerald':
            inventory.add('Emerald', 1)
        'gold':
            inventory.add('Gold', 1)
        'iron':
            inventory.add('Iron', 1)
        'lapis':
            inventory.add('Lapis', 1)
        'redstone':
            inventory.add('Redstone', 1)
        'stone':
            inventory.add('Stone', 1)
    world_map.set_cellv(tile, world_map.tile_set.find_tile_by_name("corridor"))
    # Update fog
    var edge_id : int = fog_map.tile_set.find_tile_by_name("edge")
    fog_map.set_cellv(tile, TileMap.INVALID_CELL)
    for x in range(-1, 2):
        for y in range(-1, 2):
            if fog_map.get_cellv(tile + Vector2(x, y)) != TileMap.INVALID_CELL:
                fog_map.set_cellv(tile + Vector2(x, y), edge_id)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.is_pressed():
            var tile_pos = world_map.world_to_map(event.global_position)
            if event.button_index == BUTTON_LEFT:
                # Check if the tile can be dug
                if not tile_can_be_dug(tile_pos):
                    return
                
                # Find idle minion closest to event.position
                var found : Minion = null
                var found_dist : float = 0
                for m in get_tree().get_nodes_in_group("minions"):
                    if m.is_idle():
                        if not found:
                            var path = navigator.get_simple_path(m.position, event.position)
                            assert path.size() > 0
                            var dist := 0.0
                            var last_p = path[0]
                            path.remove(0)
                            for p in path:
                                dist += (last_p - p).length()
                                last_p = p
                                
                            found_dist = dist
                            found = m
                        else:
                            var path = navigator.get_simple_path(m.position, event.position)
                            assert path.size() > 0
                            var dist := 0.0
                            var last_p = path[0]
                            path.remove(0)
                            for p in path:
                                dist += (last_p - p).length()
                                last_p = p
                                
                            if found_dist > dist:
                                found_dist = dist
                                found = m

                # If minion, set path
                if found:
                    found.set_path_and_target(navigator.get_simple_path(found.position, event.position), tile_pos)
            else:
                $Navigation2D/WorldMap/BuildingMarker.visible = true
        else:
            var tile_pos = world_map.world_to_map(event.global_position)
            $Navigation2D/WorldMap/BuildingMarker.visible = false
            var can_build := true
            for y in range(2):
                for x in range(2):
                    if world_map.tile_set.tile_get_name(world_map.get_cellv(tile_pos + Vector2(x,y))) != "corridor":
                        can_build = false
            if can_build:
                world_map.set_cellv(tile_pos + Vector2(0,0), world_map.tile_set.find_tile_by_name("building-warehouse-1"))
                world_map.set_cellv(tile_pos + Vector2(1,0), world_map.tile_set.find_tile_by_name("building-warehouse-2"))
                world_map.set_cellv(tile_pos + Vector2(0,1), world_map.tile_set.find_tile_by_name("building-warehouse-3"))
                world_map.set_cellv(tile_pos + Vector2(1,1), world_map.tile_set.find_tile_by_name("building-warehouse-4"))
    elif event is InputEventMouseMotion:
        var tile_pos = world_map.world_to_map(event.global_position)
        $Navigation2D/WorldMap/BuildingMarker.position = world_map.map_to_world(tile_pos + Vector2(1,1))
        var can_build := true
        for y in range(2):
            for x in range(2):
                if world_map.tile_set.tile_get_name(world_map.get_cellv(tile_pos + Vector2(x,y))) != "corridor":
                    can_build = false
        if can_build:
            $Navigation2D/WorldMap/BuildingMarker.texture = load("res://assets/buildings/can-2x2.png")
        else:
            $Navigation2D/WorldMap/BuildingMarker.texture = load("res://assets/buildings/cannot-2x2.png")
        

var _hud_map := Dictionary()
func _on_inventory_amount_changed(name : String, amount : int) -> void:
    if _hud_map.size() == 0:
        _hud_map['Coal'] = $CanvasLayer/Control/HBoxContainer/Label
        _hud_map['Emerald'] = $CanvasLayer/Control/HBoxContainer/Label2
        _hud_map['Gold'] = $CanvasLayer/Control/HBoxContainer/Label3
        _hud_map['Iron'] = $CanvasLayer/Control/HBoxContainer/Label4
        _hud_map['Lapis'] = $CanvasLayer/Control/HBoxContainer/Label5
        _hud_map['Redstone'] = $CanvasLayer/Control/HBoxContainer/Label6
        _hud_map['Stone'] = $CanvasLayer/Control/HBoxContainer/Label7
    _hud_map[name].text = str(amount)

class Inventory:
    var _amounts := Array()
    var _names := ['Coal', 'Emerald', 'Gold', 'Iron', 'Lapis', 'Redstone', 'Stone']
    
    signal amount_changed
    
    func _init() -> void:
        for i in range(len(self._names)):
            self._amounts.append(0)
            
    func force_update() -> void:
        for name in self._names:
            emit_signal("amount_changed", name, self._amounts[_names.find(name)])
    
    func add(name : String, amount : int = 1) -> void:
        assert name in self._names
        
        self._amounts[_names.find(name)] += amount
        emit_signal("amount_changed", name, self._amounts[_names.find(name)])