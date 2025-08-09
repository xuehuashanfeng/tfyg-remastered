extends CharacterBody3D
class_name BossPlayer

var gameOver = false
var jumpRope = false
var sweeping = false
var hugging = false
var boots = false
var bootTime = 0.0

var trigger_gameover : bool = false

var slowSpeed = 4.0
var walkSpeed = 5.0
var runSpeed = 10.0
var playerSpeed = 0.0

const GRAVITY = 10.0
var initVelocity = 5.0
var jumpVelocity = 0.0
var jumpHeight = 0.0

@onready var stamina = maxStamina
var staminaRate = 10.0
var maxStamina = 100.0

@onready var guilt = initGuilt
var initGuilt = 0.0
var guiltType = ""
var hud_exploded = false
@onready var castCollider = $Camera3D / Collider
@onready var lastCameraPosition = $Camera3D.global_position
@onready var cameraOffset = $Camera3D.position
@onready var camera3D = $Camera3D

var cameraTween: Tween
var cameraVTween: Tween

var detentionTimer = 0.0

var failSafe = 0.0

var BlackBackground = preload("res://graphics/black_background_environment.tres")

var BSoda = preload("res://entities/dropped_items/BSODA.tscn")

@export_enum("Off", "On", "Funny") var debugMode = 0
@export var real_game = true

@onready var frozenPosition = global_position



var turnRate = 0.0

const ALARM_CLOCK = preload("res://entities/objects/alarm_clock.tscn")

func _ready():
	Global.boss_player = self
	Global.lock_mouse()

	if !real_game:

		for i in $PlayerHud.get_children():
			i.hide()

		$PlayerHud / Reticle.show()
	$PlayerHud.show()

	if debugMode:
		walkSpeed *= 5


func _process(delta):
	camera3D.rotation.y = 0.0 if !Input.is_action_pressed("gm_behind") || jumpRope else deg_to_rad(180.0)


	rotate_y(deg_to_rad(turnRate * delta * Global.sensativity * 8.0))
	turnRate = - Input.get_axis("gm_turn_left", "gm_turn_right")
	if !Global.analog:
		turnRate = round(turnRate)


	var headReaction: = $PlayerHud / BaldiHeadController / HeadReaction

	if !headReaction.is_playing():
		headReaction.position.y = move_toward(headReaction.position.y, 64.0, delta * 60.0 * 8.0)
	else:
		headReaction.position.y = -64.0

func _physics_process(delta):
	player_move(delta)
	stamina_check(delta)
	guilt_check(delta)

	if failSafe > 0.0:
		failSafe = move_toward(failSafe, 0.0, delta)
	else:
		hugging = false
		sweeping = false


	bootTime = move_toward(bootTime, 0.0, delta)
	boots = bootTime > 0



	$PlayerHud / Pointer.visible = false
	if castCollider.is_colliding():
		var hit = castCollider.get_collider()
		if hit is Door:

			$PlayerHud / Pointer.visible = !hit.doubleDoor && hit.visible
		else:
			$PlayerHud / Pointer.visible = hit.has_method("interact") && hit.visible

func player_move(delta):
	var direction = Input.get_vector("gm_left", "gm_right", "gm_back", "gm_forward")
	direction = Vector3(direction.x, 0.0, - direction.y)
	if stamina > 0:
		if Input.is_action_pressed("gm_run"):
			playerSpeed = runSpeed
			if velocity.length() > 0.1 && !hugging && !sweeping:
				reset_guilt("running", 0.1)
		else:
			playerSpeed = walkSpeed
	else:
		playerSpeed = walkSpeed

	var moveDirection = direction * playerSpeed

	if jumpRope:
		moveDirection = Vector3.ZERO
	if jumpRope || jumpHeight > 0:

		jumpVelocity -= GRAVITY * delta
		jumpHeight = max(0, jumpHeight + (jumpVelocity * delta))

		if cameraVTween:
			cameraVTween.kill()

		cameraVTween = create_tween()
		cameraVTween.tween_property(camera3D, "v_offset", jumpHeight, delta)

	if !velocity.is_equal_approx(Vector3.ZERO):
		var collider = move_and_collide(velocity * delta, true)
		if collider:
			move_and_collide(velocity.slide(velocity.slide(collider.get_normal()).normalized()) * delta)
			velocity = velocity.slide(collider.get_normal())

		velocity.y = 0
		move_and_slide()
		camera3D.global_translate( - get_real_velocity() * delta)
	velocity = moveDirection.rotated(basis.y, rotation.y)

	if cameraTween:
		cameraTween.kill()
	cameraTween = create_tween()
	cameraTween.tween_property(camera3D, "position", cameraOffset, delta)


	if jumpRope && global_position.distance_to(frozenPosition) >= 1.0:
		jumpRope = false

func stamina_check(delta):
	if velocity.length() > 0.1:
		if Input.is_action_pressed("gm_run") && stamina > 0.0:
			stamina -= staminaRate * delta
		if stamina <= 0.0 && stamina > -5.0:
			stamina = -5.0
	elif stamina < maxStamina:
		stamina += staminaRate * delta

func _input(event):
	var sensativity = Global.sensativity / 100.0
	if event is InputEventMouseMotion:
		if !Global.analog:
			turnRate = sign( - event.relative.x)
		else:
			rotate_y(deg_to_rad( - event.relative.x * sensativity))

	if jumpRope:
		if event.is_action_pressed("gm_jump") && jumpHeight <= 0.0:
			jumpVelocity = initVelocity
	elif event.is_action_pressed("gm_click") && castCollider.is_colliding():

		var hit = castCollider.get_collider()
		if hit.has_method("interact"):
			hit.interact(self)


	if event.is_action_pressed("gm_pause"):
		get_tree().paused = true
		Global.unlock_mouse()
		await get_tree().process_frame
		Options.show()
		await Options.closed
		get_tree().paused = false
		Global.lock_mouse()

func reset_guilt(type, amount):
	if amount >= guilt:
		guilt = amount
		guiltType = type

func guilt_check(delta):
	if guilt > 0:
		guilt = move_toward(guilt, 0.0, delta)
	detentionTimer = move_toward(detentionTimer, 0.0, delta)

func game_over():
	if debugMode == 2:
		Global.baldi.move_and_collide( - camera3D.global_basis.z * 100.0)
	if debugMode > 0: return
	camera3D.process_mode = Node.PROCESS_MODE_ALWAYS
	if is_instance_valid(Global.baldi):
		camera3D.global_position = Global.baldi.global_position + Global.baldi.global_position.direction_to(Vector3(global_position.x, Global.baldi.global_position.y, global_position.z)) * 2.0 + Vector3(0, 1, 0)
		camera3D.look_at(Global.baldi.global_position + Vector3(0, 1, 0), up_direction)
	$Caught.play()

	$PlayerHud.visible = false
	Global.background.environment = BlackBackground

	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	camera3D.far = 200.0
	tween.tween_property(camera3D, "far", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR)

	get_tree().paused = true
	await tween.finished
	get_tree().paused = false
	Global.reset_values()
	get_tree().change_scene_to_file("res://scenes/gameover.tscn")


	if not hud_exploded and Global.noteBooks == 7:
		explode_player_hud()


	if trigger_gameover and randi() %5 == 0:
		game_over()
		return



func bali_react(react_frame = "Notice"):
	$PlayerHud / BaldiHeadController / HeadReaction.play(react_frame)

func explode_player_hud():
	hud_exploded = true


	var hud_tween = create_tween()
	hud_tween.tween_property($PlayerHud, "scale", Vector3(1.5, 1.5, 1.5), 0.2)
	hud_tween.tween_property($PlayerHud, "scale", Vector3(3.0, 3.0, 3.0), 0.3)
	hud_tween.tween_property($PlayerHud, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.5)

	$PlayerHud.hide()


	var cam_tween = create_tween()
	cam_tween.tween_property(camera3D, "position:x", camera3D.position.x + randf_range(-50, 50), 0.8)
	cam_tween.tween_property(camera3D, "position:y", camera3D.position.y + randf_range(-30, 30), 0.8)
	cam_tween.tween_property(camera3D, "position", camera3D.global_position, 0.2)
