@tool
extends "res://entities/objects/item.gd"

func _ready():
    if !Engine.is_editor_hint():
        global_position = Global.get_wander_point("wander", 1, 15) + Vector3(0, 4, 0)
