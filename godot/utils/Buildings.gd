extends Node
class_name Buildings

"""
    Class representing all buildings in the world
"""

var _world
var _buildings := []

func _init() -> void:
    pass

func set_world(world) -> void:
    """
        Must be called first, sets a reference to the world tile map
    """
    self._world = world

func create_warehouse(pos : Vector2) -> void:
    # TODO assumes it is ok to build
    # TODO assumes that minions have been moved out of the way
    # TODO assumes map changed is emitted by caller
    self._world.world_set_tiles({ pos + Vector2(0,0) : "building-warehouse-1", 
                                  pos + Vector2(1,0) : "building-warehouse-2", 
                                  pos + Vector2(0,1) : "building-warehouse-3", 
                                  pos + Vector2(1,1) : "building-warehouse-4" })
    var warehouse := BuildingWarehouse.new(pos, self._world)
    _buildings.append(warehouse)
    
func create_quarter(pos : Vector2) -> void:
    # TODO assumes it is ok to build
    # TODO assumes that minions have been moved out of the way
    # TODO assumes map changed is emitted by caller
    # TODO should have quarter graphics
    self._world.world_set_tiles({ pos + Vector2(0,0) : "building-quarter-1", 
                                  pos + Vector2(1,0) : "building-quarter-2", 
                                  pos + Vector2(0,1) : "building-quarter-3", 
                                  pos + Vector2(1,1) : "building-quarter-4" })
    var quarter := BuildingQuarter.new(pos, self._world)
    _buildings.append(quarter)
                
class BuildingWarehouse:
    """
        Class representing a warehouse
        
        Spawns up to 4 minions, one second apart on start-up.
    """
    
    var _pos : Vector2
    var _world
    
    var _minion_preload
    
    func _init(pos : Vector2, world) -> void:
        self._pos = pos
        self._world = world
        
        self._minion_preload = load("res://actors/Minion.tscn")
        
        yield(self._world.world_get_tree().create_timer(1.0), "timeout")
        _spawn_minion(Vector2(0,0))
        yield(self._world.world_get_tree().create_timer(1.0), "timeout")
        _spawn_minion(Vector2(1,0))
        yield(self._world.world_get_tree().create_timer(1.0), "timeout")
        _spawn_minion(Vector2(0,1))
        yield(self._world.world_get_tree().create_timer(1.0), "timeout")
        _spawn_minion(Vector2(1,1))
            
    func _spawn_minion(offset: Vector2) -> void:
        var m : Minion = _minion_preload.instance()
        m.position = self._world.world_map_to_world(self._pos+offset) + Vector2(8,8)
        m.connect("death", self, "_on_minion_death")
        self._world.world_add_actor(m)

class BuildingQuarter:
    """
        Class representing a quarter
        
        Spawns up to 3 minions, one every 20 s.
    """
    
    var _pos : Vector2
    var _world
    var _minions := []
    
    onready var _minion_preload
    
    func _init(pos : Vector2, world) -> void:
        self._pos = pos
        self._world = world
        
        self._minion_preload = load("res://actors/Minion.tscn")
        
        # TODO would be nice to have a progress bar inseatd of a hidden timer
        yield(self._world.world_get_tree().create_timer(20.0), "timeout")
        _spawn_minion()
        
    func _on_minion_death(m) -> void:
        assert m in _minions
        _minions.remove(m)
        
        # TODO how do we avoid minions spawning frm ohere and _spawn_minion?
        if _minions.size() < 3:
            yield(self._world.world_get_tree().create_timer(20.0), "timeout")
            _spawn_minion()        
    
    func _spawn_minion() -> void:
        var m : Minion = _minion_preload.instance()
        m.position = self._world.world_map_to_world(self._pos) + Vector2(8,8)
        m.connect("death", self, "_on_minion_death")
        _minions.append(m)
        self._world.world_add_actor(m)
        
        # TODO how do we avoid minions spawning frm ohere and _on_minion_death?
        if _minions.size() < 3:
            yield(self._world.world_get_tree().create_timer(20.0), "timeout")
            _spawn_minion()