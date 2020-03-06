extends KinematicBody2D
class_name Minion

signal tile_dug
signal death

const SPEED : int = 100

var _tasks : Tasks
var _world setget _set_world

# TODO no way to die at the moment... life is good

func _init() -> void:
    _tasks = Tasks.new()
    _tasks.minion = self
    add_child(_tasks)
    add_to_group("minions")
    
func _set_world(w) -> void:
    _tasks.world = w
    _world = w
    
func _on_tile_dug(target : Vector2, minion) -> void:
    emit_signal("tile_dug", target, minion)
    
func is_idle() -> bool:
    return _tasks.is_idle()
        
func walk_to_and_dig(walk_to : Vector2, dig_tile : Vector2) -> void:
    _tasks.add_walk(walk_to)
    _tasks.add_dig(dig_tile)

func walk_straight_to(walk_to : Vector2) -> void:
    _tasks.add_straight_walk(walk_to)

func walk_to(walk_to : Vector2) -> void:
    _tasks.add_walk(walk_to)
    
func map_changed(tile : Vector2, width : int, height : int) -> void:
    _tasks.map_changed(tile, width, height)