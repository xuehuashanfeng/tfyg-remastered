extends Node3D

func _ready():
    Global.note_books_updated.connect(new_dialogue)

func new_dialogue():
    $BaldiGreeting.stream = load("res://audio/Characters/Baldi/BaldiTutor/BAL_GetPrize_Mobile.wav")
    $BaldiGreeting.play()
    for i in get_tree().get_nodes_in_group("reward"):
        if i.has_method("activate"):
            i.activate()
    translate(basis.x * 3)
