extends Node2D

onready var world_map := $Navigation2D/WorldMap
onready var fog_map := $FogMap
onready var navigator := $Navigation2D
onready var inventory_bar := $CanvasLayer/InventoryBar

var inventory : Inventory
var buildings : Buildings

enum { MODE_DIG, MODE_BUILD }
enum { BUILDING_WAREHOUSE, BUILDING_QUARTER }

var _mode : int = -1
var _building_type : int = -1

var _dig_queue := []

func _ready() -> void:
    inventory = Inventory.new()
    inventory.add('Stone', 10)
    inventory.add('Iron', 2)
    
    inventory_bar.set_inventory(inventory)
    
    buildings = Buildings.new()
    buildings.set_world(self)
    buildings.create_warehouse(Vector2(18, 11))
    
    set_mode(MODE_DIG)
        
    # If the world is prepopulated    
    for m in get_tree().get_nodes_in_group("minions"):
        m._world = self
        m.connect("tile_dug", self, "_on_tile_dug")

func path_length(path : PoolVector2Array) -> float:
    """
        Calculates the total length of a path, i.e. a series of coordinates.
    """
    var dist := 0.0
    if path.size() > 0:
        var last_p = path[0]
        path.remove(0)
        for p in path:
            dist += (last_p - p).length()
            last_p = p
    return dist    

func tile_can_be_dug(tile : Vector2) -> bool:
    """
        Determines if a tile can be dug or not.
        
        Anything that is not built, nor already dug, can be dug.
    """
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

func find_adjecent_corridor(pos : Vector2, width : int, height : int) -> PoolVector2Array:
    """
        Produces a list of corridors adjecent to a square with the top left corner at pos,
        being width blocks wide and height blocks high.
    """
    var res : PoolVector2Array
    for x in range(width):
        if world_map.tile_set.tile_get_name(world_map.get_cellv(pos + Vector2(x, -1))) == "corridor":
            res.append(pos + Vector2(x, -1))
        if world_map.tile_set.tile_get_name(world_map.get_cellv(pos + Vector2(x, height))) == "corridor":
            res.append(pos + Vector2(x, height))
    for y in range(height):
        if world_map.tile_set.tile_get_name(world_map.get_cellv(pos + Vector2(-1, y))) == "corridor":
            res.append(pos + Vector2(-1, y))
        if world_map.tile_set.tile_get_name(world_map.get_cellv(pos + Vector2(width, y))) == "corridor":
            res.append(pos + Vector2(width, y))
    return res
    
func can_build(pos : Vector2, width : int, height : int) -> bool:
    """
        Determines if an area can be built.
        
        Ensures that the area consists of corridor, and that there are adjecent corridors.
    """
    # Area consists of empty corridors
    var area_free := true
    for y in range(height):
        for x in range(width):
            if world_map.tile_set.tile_get_name(world_map.get_cellv(pos + Vector2(x,y))) != "corridor":
                area_free = false
                
    # Area can be accessed, i.e. there are adjecent corridors
    var accessible : bool = (find_adjecent_corridor(pos, width, height).size() > 0)
    
    # TODO should ensure that one can not enclose minions between buildings
    
    return (area_free and accessible)

func _map_changed(tile : Vector2, width: int, height : int) -> void:
    """
        The map has changed from tile and inside width/height.
        
        This causes all walks to be recalculated.
        All walks with destinations inside the changed areas are errors.
    """
    for m in get_tree().get_nodes_in_group("minions"):
        m.map_changed(tile, width, height)
    
func _on_tile_dug(tile : Vector2, digger) -> void:
    """
        Gets called when a tile has been dug.
        
        Updates the inventory, map and fog map.
    """
    if not tile_can_be_dug(tile):
        print("ERROR: cannot dig at " + str(tile))
        return
    
    # Ensure that the dig was planned
    if tile in _dig_queue:
        _dig_queue.remove(_dig_queue.find(tile))
    else:
        print("ERROR: dig tile not in dig queue")

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
    _map_changed(tile, 1, 1)
    
    # Random decision if a monster appears or not
    if tile == Vector2(22, 11):
        # TODO not very random
        _spawn_goblin(tile)

func _spawn_goblin(tile : Vector2) -> void:
    """
        Spawns a goblin at the given tile
    """
    var gl := load("res://actors/Goblin.tscn")
    var g : Goblin = gl.instance()
    g.position = world_map_to_world(tile) + Vector2(8,8)
    self.add_child(g)

# --- world interface ---

func world_set_tiles(tiles : Dictionary) -> void:
    for k in tiles.keys():
        world_map.set_cellv(k, world_map.tile_set.find_tile_by_name(tiles[k]))

func world_map_to_world(map : Vector2) -> Vector2:
    return world_map.map_to_world(map)
    
func world_add_actor(actor : Node) -> void:
    actor._world = self
    world_map.add_child(actor)
    # TODO this is only applicable to a minion actor, unless all actors share an interface
    actor.connect("tile_dug", self, "_on_tile_dug")

func world_get_tree() -> Object:
    return get_tree()

# --- digging ---

func dig_activate():
    pass
    
func dig_deactivate():
    pass

func dig_process(event : InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.is_pressed():
            var tile_pos = world_map.world_to_map(event.global_position)

            # Check if the tile can be dug
            if not tile_can_be_dug(tile_pos):
                return
                
            # Check if the tile is already planned to be dug
            if tile_pos in _dig_queue:
                return
                
            # TODO remove tiles from the _dig_queue if the minion assigned dies
            
            # Find idle minion closest to event.position
            var found = null
            var found_dist : float = 0
            for m in get_tree().get_nodes_in_group("minions"):
                if m.is_idle():
                    if not found:
                        var path = navigator.get_simple_path(m.position, event.position)
                        if path.size() > 0:
                            found_dist = path_length(path)
                            found = m
                    else:
                        var path = navigator.get_simple_path(m.position, event.position)
                        if path.size() > 0:
                            var dist := path_length(path)                                    
                            if found_dist > dist:
                                found_dist = dist
                                found = m

            # If minion, set path
            if found:
                found.walk_to_and_dig(event.position, tile_pos)
                _dig_queue.append(tile_pos)

# --- building ---

func build_activate():
    $BuildingMarker.visible = true
    inventory_bar.set_inventory_need({'Stone': 4})

func build_deactivate():
    $BuildingMarker.visible = false
    inventory_bar.set_inventory_need({})

func build_process(event : InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.is_pressed():
            var tile_pos = world_map.world_to_map(event.global_position)

            if can_build(tile_pos, 2, 2):
                # Take the material, update the map
                if inventory.take({'Stone': 4}):
                    # Move any minions out of the way
                    for m in get_tree().get_nodes_in_group("minions"):
                        var tl : Vector2 = world_map.map_to_world(tile_pos)
                        if m.position.x >= tl.x and m.position.x <= tl.x+32 and m.position.y >= tl.y and m.position.y <= tl.y+32 and m.is_idle():
                            var options := find_adjecent_corridor(tile_pos, 2, 2)
                            m.walk_to(world_map.map_to_world(options[0])+Vector2(8,8))
                
                    # Update the map
                    match _building_type:
                        BUILDING_QUARTER:
                            buildings.create_quarter(tile_pos)
                        BUILDING_WAREHOUSE:
                            # TODO the warehouse is not supposed to be buildable
                            buildings.create_warehouse(tile_pos)    
 
                   # Update the marker status
                    _build_update_marker_state(tile_pos, 2, 2)

                    # Update all affected tasks
                    _map_changed(tile_pos, 2, 2)
    elif event is InputEventMouseMotion:
        var tile_pos = world_map.world_to_map(event.global_position)
        $BuildingMarker.position = world_map.map_to_world(tile_pos + Vector2(1,1))
        _build_update_marker_state(tile_pos, 2, 2)

func _build_update_marker_state(tile : Vector2, width : int, height : int) -> void:
    if can_build(tile, 2, 2) and inventory.can_take({'Stone': 4}):
        $BuildingMarker.texture = load("res://assets/buildings/can-2x2.png")
    else:
        $BuildingMarker.texture = load("res://assets/buildings/cannot-2x2.png")   

# --- mode ---

func set_building_type(next_building : int) -> void:
    # TODO do something here, e.g. size of foot print
    _building_type = next_building

func set_mode(next_mode : int) -> void:
    match _mode:
        MODE_DIG:
            dig_deactivate()
        MODE_BUILD:
            build_deactivate()
    
    $CanvasLayer/ToolsContainer/DigButton.pressed = false
    $CanvasLayer/ToolsContainer/BuildQuarterButton.pressed = false
    $CanvasLayer/ToolsContainer/BuildWarehouseButton.pressed = false
    _mode = next_mode
    match next_mode:
        MODE_DIG:
            $CanvasLayer/ToolsContainer/DigButton.pressed = true
        MODE_BUILD:
            match _building_type:
                BUILDING_WAREHOUSE:
                    $CanvasLayer/ToolsContainer/BuildWarehouseButton.pressed = true
                BUILDING_QUARTER:
                    $CanvasLayer/ToolsContainer/BuildQuarterButton.pressed = true
        _:
            print("Invalid mode set - going to dig")
            $CanvasLayer/ToolsContainer/DigButton.pressed = true
            _mode = MODE_DIG
            
    match _mode:
        MODE_DIG:
            dig_activate()
        MODE_BUILD:
            build_activate()

# --- UI events ---

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == BUTTON_RIGHT:
            set_mode(MODE_DIG)
            return
    elif event is InputEventKey:
        if event.is_action_pressed("tool_dig"):
            set_mode(MODE_DIG)
            return
        elif event.is_action_pressed("tool_build_quarter"):
            set_building_type(BUILDING_QUARTER)
            set_mode(MODE_BUILD)
        elif event.is_action_pressed("tool_build_warehouse"):
            set_building_type(BUILDING_WAREHOUSE)
            set_mode(MODE_BUILD)
            return
    
    match _mode:
        MODE_DIG:
            dig_process(event)
        MODE_BUILD:
            build_process(event)

func _on_DigButton_pressed() -> void:
    set_mode(MODE_DIG)
    set_mode(MODE_DIG)

func _on_BuildQuarterButton_pressed() -> void:
    set_building_type(BUILDING_QUARTER)
    set_mode(MODE_BUILD)

func _on_BuildWarehouseButton_pressed() -> void:
    set_building_type(BUILDING_WAREHOUSE)
    set_mode(MODE_BUILD)
