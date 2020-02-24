extends KinematicBody2D
class_name Minion

signal tile_dug

const SPEED : int = 100

var _path : PoolVector2Array
var _target : Vector2 = Vector2(-1, -1)

func _ready() -> void:
    add_to_group("minions")
    
func is_idle() -> bool:
    if _path.size() == 0 and _target == Vector2(-1, -1):
        return true
    else:
        return false
        
func set_path_and_target(path : PoolVector2Array, target : Vector2) -> void:
    _path = path
    _target = target

func _process(delta: float) -> void:
    var walk_distance = SPEED * delta
    
    var last_position = self.position
    while _path.size():
        var distance_between_points = last_position.distance_to(_path[0])
        if walk_distance <= distance_between_points:
            self.position = last_position.linear_interpolate(_path[0], walk_distance/distance_between_points)
            return
        walk_distance -= distance_between_points
        last_position = _path[0]
        _path.remove(0)
    self.position = last_position
    
    if _target != Vector2(-1, -1):
        emit_signal("tile_dug", _target, self)
        _target = Vector2(-1, -1)