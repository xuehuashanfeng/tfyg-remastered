@tool
extends Area3D

var respawnTime = 0.0

@export_range(0, 6) var noteBookIndex = 0:
    get:
        return noteBookIndex
    set(value):
        noteBookIndex = value
        if get_node_or_null("NoteBook") != null:
            get_node("NoteBook").frame = value

func interact(object):
    if !visible:
        return
    var math = Global.MathGame.instantiate()
    get_parent().add_child(math)
    get_tree().paused = true
    visible = false

    if object is Player:
        object.stamina = object.maxStamina

    if Global.endless:
        respawnTime = 120.0

func _process(_delta):
    $NoteBook.position.y = sin(Engine.get_frames_drawn() * 0.017453292) / 2.0 + 1.0

func _physics_process(delta):

    if respawnTime > 0.0:
        respawnTime -= delta

        if respawnTime <= 0.0:
            visible = true
            $Respawn.play()
