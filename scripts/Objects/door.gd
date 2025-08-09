@tool
extends Area3D
class_name Door

@onready var barrier = $Door / CollisionShape3D
@onready var navigationLink = get_node_or_null("NavigationLink")
@export var audioDoorOpen = preload("res://audio/SFX/Doors/door_open.wav")
@export var audioDoorClose = preload("res://audio/SFX/Doors/door_close.wav")

@export var backSideDarker = false

var silentOpens = 0
var openTime = 0.0
var lockTime = 0.0
@onready var myAudio = $Door / Sound
var doorOpen = false
var doorLocked = false
@onready var doorTexture = $DoorTexture
@export var setDoorFrame = 112:
	set(value):
		setDoorFrame = value
		if has_node("DoorTexture"):
			get_node("DoorTexture").frame = value
			if has_node("DoorTexture/Duplicate"):
				get_node("DoorTexture/Duplicate").frame = value

@onready var defaultDoorFrame = setDoorFrame

var interactingBodies = []
@onready var doorCollider = $Door

@export var lockForTutorial = false

@export var doorNavLinkScale = 1.0

@export var doubleDoor = false

@export var exitDoor = false

func _ready():
	if !Engine.is_editor_hint():
		Global.note_books_updated.connect(note_book_check)
		$DoorTexture / Duplicate.modulate = Color.WHITE if !backSideDarker else Color(0.5, 0.5, 0.5)
		if is_instance_valid(navigationLink):
			navigationLink.enabled = !lockForTutorial



	setDoorFrame = setDoorFrame


func _physics_process(delta):
	if !Engine.is_editor_hint():
		if lockTime > 0:
			lockTime = move_toward(lockTime, 0.0, delta)
		elif doorLocked:
			doorLocked = false
		elif doubleDoor && $DoorTexture / Lock.visible:
			$DoorTexture / Lock.hide()
			$DoorTexture / Duplicate / Lock.hide()
			navigationLink.enabled = true
			barrier.disabled = true


		openTime = move_toward(openTime, 0.0, delta)

		if !interactingBodies.is_empty():
			openTime = 2.0

		if openTime <= 0.0 && doorOpen:
			if !doubleDoor:
				barrier.disabled = false
			doorOpen = false
			doorTexture.frame = defaultDoorFrame
			if silentOpens <= 0:
				myAudio.stream = audioDoorClose
				myAudio.play()
	else:
		$DoorTexture / Duplicate.modulate = Color.WHITE if !backSideDarker else Color(0.5, 0.5, 0.5)






func interact(_object):
	if doubleDoor: return
	if !doorLocked:
		if silentOpens <= 0 && is_instance_valid(Global.baldi) && !doorOpen && openTime <= 0.0:
			Global.baldi.hear(global_position, 1)
		open_door()
		if silentOpens > 0 && !doorOpen && openTime <= 0.0:
			silentOpens -= 1


func open_door():
	if lockTime > 0: return
	if silentOpens <= 0 && !doorOpen:
		myAudio.stream = audioDoorOpen
		myAudio.play()
	barrier.call_deferred("set_disabled", true)
	doorOpen = true
	doorTexture.frame = defaultDoorFrame + 1
	openTime = 3.0


func _on_character_check_body_entered(body):
	if !interactingBodies.has(body):
		interactingBodies.append(body)

	if lockForTutorial && Global.noteBooks < 2:
		if body is Player && has_node("BaldiGuide") && !exitDoor:
			if !get_node("BaldiGuide").is_playing():
				get_node("BaldiGuide").play()
	else:

		if ( !doorLocked || !doubleDoor) && !exitDoor:
			open_door()
		if body is Player && is_instance_valid(Global.baldi):
			if exitDoor:

				if Global.secret:
					get_tree().call_deferred("change_scene_to_file", "res://scenes/secret.tscn")
				else:
					get_tree().call_deferred("change_scene_to_file", "res://scenes/results.tscn")
			else:
				Global.baldi.hear(global_position, 1)

func _on_character_check_body_exited(body):
	if interactingBodies.has(body):
		interactingBodies.erase(body)


func _on_door_texture_frame_changed():
	if doorTexture != null:
		$DoorTexture / Duplicate.frame = doorTexture.frame


func _on_door_texture_texture_changed():
	if doorTexture != null:
		$DoorTexture / Duplicate.texture = doorTexture.texture


func _on_door_texture_visibility_changed():
	if doorTexture != null:
		$DoorTexture / Duplicate.visible = doorTexture.visible

func note_book_check():

	if Global.noteBooks >= 2 && lockForTutorial:

		barrier.disabled = true
		if is_instance_valid(navigationLink):
			navigationLink.enabled = true

func lock_double_door() -> bool:
	if !doubleDoor or lockTime > 0: return false
	$DoorTexture / Lock.show()
	$DoorTexture / Duplicate / Lock.show()
	lockTime = 15.0
	navigationLink.enabled = false
	openTime = 0.0
	doorOpen = true
	barrier.disabled = false
	doorLocked = true
	return true

func no_squee() -> bool:
	if doubleDoor: return false
	silentOpens = 4
	return true

func use_key() -> bool:
	if doubleDoor || !doorLocked: return false
	doorLocked = false
	return true
