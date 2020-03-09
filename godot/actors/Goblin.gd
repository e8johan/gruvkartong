extends KinematicBody2D
class_name Goblin

var _world setget _set_world

func _ready() -> void:
    add_to_group("monsters")

func _set_world(world) -> void:
    _world = world
    
# TODO do something here