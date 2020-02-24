extends Node
class_name Tasks

signal tile_dug

# Assigned minion
var minion = null setget _set_minion
# Assigned world
var world

var _queue := Array()

func _ready() -> void:
    pass # Replace with function body.
    set_process(false)
    
func _process(delta: float) -> void:
    assert _queue.size() > 0
    
    var done = _queue[0].process(delta, minion)
    if done:
        _queue.remove(0)
        if _queue.size() == 0:
            set_process(false)
            
# ---

func is_idle() -> bool:
    return (_queue.size() == 0)

func add_walk(dest : Vector2) -> void:
    var t := TaskWalk.new(dest, self)
    _queue.append(t)
    set_process(true)

func add_dig(target : Vector2) -> void:
    var t := TaskDig.new(target, self)
    _queue.append(t)
    set_process(true)
    
# ---

func map_changed(tile : Vector2, width : int, height : int) -> void:
    for t in _queue:
        t.map_changed(tile, width, height)

# ---

func _set_minion(m) -> void:
    if minion:
        minion.disconnect("tile_dug", minion, "_on_tile_dug")
    
    minion = m
    
    connect("tile_dug", minion, "_on_tile_dug")

# ---

func _on_tile_dug(target : Vector2, minion) -> void:
    emit_signal("tile_dug", target, minion)

# ---

class TaskWalk:
    var _dest : Vector2
    var _path = null
    var _world
    
    func _init(dest : Vector2, parent) -> void:
        self._dest = dest
        self._world = parent.world
        
    func process(delta : float, minion) -> bool:
        if not _path:
            _path = _world.navigator.get_simple_path(minion.position, self._dest)
        
        var walk_distance = minion.SPEED * delta
        var last_position = minion.position
        while _path.size():
            var distance_between_points = last_position.distance_to(_path[0])
            if walk_distance <= distance_between_points:
                minion.position = last_position.linear_interpolate(_path[0], walk_distance/distance_between_points)
                return false
            walk_distance -= distance_between_points
            last_position = _path[0]
            _path.remove(0)
        minion.position = last_position
        return true

    func map_changed(tile : Vector2, width : int, height : int) -> void:
        var tl : Vector2 = _world.world_map.map_to_world(tile)
        if _dest.x >= tl.x and _dest.x <= tl.x+16*width and _dest.y >= tl.y and _dest.y <= tl.y+16*height:
            assert false # Cannot move to a changed area
        else:
            _path = null # Clear all paths

class TaskDig:
    signal done
    
    var _target : Vector2
    var _done : bool = false
    
    func _init(target : Vector2, parent) -> void:
        self.connect("done", parent, "_on_tile_dug")
        self._target = target
        
    func process(delta : float, minion) -> bool:
        _done = true
        emit_signal("done", _target, minion)
        return true

    func map_changed(tile : Vector2, width : int, height : int) -> void:
        if _target.x >= tile.x and _target.x < tile.x+width and _target.y >= tile.y and _target.y < tile.y+height and not _done:
            assert false # Cannot dig a changed area
