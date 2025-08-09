extends CharacterBody3D
class_name Player

var gameOver = false
var jumpRope = false
var sweeping = false
var hugging = false
var boots = false
var bootTime = 0.0

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

var itemSelected = 0
var items = []

var itemNames = [
	"棍母",
	"shit",
	"mother fuck", 
	"666", 
	"cum发射", 
	"银行偷的钱", 
	"我命由我不由天，昼夜看片似神仙。", 
	"爱栏目 看咯唱K", 
	"可乐", 
	"我操这剪刀是假的。", 
	"逼格 哦了\' 波哦碳酸", 
]
@onready var slots = $PlayerHud / ItemSlots / ItemSlots

var turnRate = 0.0

const ALARM_CLOCK = preload("res://entities/objects/alarm_clock.tscn")

func _ready():
	Global.player = self
	Global.lock_mouse()
	items.resize(slots.get_child_count())
	items.fill(Global.ITEMS.NONE)
	update_items()
	Global.note_books_updated.connect(update_note_book_counter)


	if !real_game:

		for i in $PlayerHud.get_children():
			i.hide()

		$PlayerHud / Reticle.show()
	$PlayerHud.show()

	if debugMode:
		walkSpeed *= 5


func _process(delta):
	camera3D.rotation.y = 0.0 if !Input.is_action_pressed("gm_behind") || jumpRope else deg_to_rad(180.0)
	$PlayerHud / Detention.visible = detentionTimer > 0
	$PlayerHud / Detention / Label.text = "恭喜你！你今天导了 \n" + str(int(ceil(detentionTimer))) + " 次管。"
	$"../CanvasLayer/ProgressBar".value = (stamina / maxStamina) * 100
	$PlayerHud / Warning.visible = stamina < 0.0
	update_note_book_counter()


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

	if event.is_action_pressed("gm_next_item"):
		set_selected_item(itemSelected + 1)
	elif event.is_action_pressed("gm_prev_item"):
		set_selected_item(itemSelected - 1)

	if event.is_action_pressed("gm_use"):
		use_item()


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

func update_note_book_counter():
	if Global.endless:
		$"../CanvasLayer/Label".text = str(Global.noteBooks) + " Notebooks"
	else:
		$"../CanvasLayer/Label".text = str(Global.noteBooks) + "/7 Notebooks"


	if not hud_exploded and Global.noteBooks == 7:
		explode_player_hud()

func set_selected_item(newItemSelect):
	slots.get_child(itemSelected).color = Color.WHITE
	itemSelected = wrapi(newItemSelect, 0, slots.get_child_count())
	slots.get_child(itemSelected).color = Color.RED
	update_items()

func use_item():
	var trigger_gameover = false
	match (items[itemSelected]):
		Global.ITEMS.ZESTI:
			stamina = maxStamina * 2.0
			items[itemSelected] = Global.ITEMS.NONE
			trigger_gameover = true

		Global.ITEMS.BSODA:
			var mySoda = BSoda.instantiate()
			get_parent().add_child(mySoda)
			reset_guilt("drink", 1.0)
			mySoda.global_position = global_position
			items[itemSelected] = Global.ITEMS.NONE
			trigger_gameover = true

		Global.ITEMS.LOCK:
			var hit = castCollider.get_collider()
			if hit and hit.has_method("lock_double_door"):
				if hit.lock_double_door():
					items[itemSelected] = Global.ITEMS.NONE
					trigger_gameover = true

		Global.ITEMS.KEY:
			var hit = castCollider.get_collider()
			if hit and hit.has_method("use_key"):
				if hit.use_key():
					items[itemSelected] = Global.ITEMS.NONE
					trigger_gameover = true

		Global.ITEMS.QUARTER:
			var hit = castCollider.get_collider()
			if hit and hit.has_method("use_quarter"):
				items[itemSelected] = Global.ITEMS.NONE
				hit.use_quarter(self)
				trigger_gameover = true

		Global.ITEMS.NO_SQUEE:
			var hit = castCollider.get_collider()
			if hit and hit.has_method("no_squee"):
				hit.no_squee()
				$NoSquee.play()
				items[itemSelected] = Global.ITEMS.NONE
				trigger_gameover = true

		Global.ITEMS.TAPE:
			var hit = castCollider.get_collider()
			if hit and hit.has_method("use_tape"):
				hit.use_tape(self)
				items[itemSelected] = Global.ITEMS.NONE
				trigger_gameover = true

		Global.ITEMS.BOOTS:
			items[itemSelected] = Global.ITEMS.NONE
			trigger_gameover = true
			hugging = false
			bootTime = 15.0
			$PlayerHud / Boots.show()
			var tween = get_tree().create_tween()
			$PlayerHud / Boots.position.y = -128.0
			tween.tween_property($PlayerHud / Boots, "position:y", get_viewport().size.y, 1.0)
			await tween.finished
			$PlayerHud / Boots.hide()

		Global.ITEMS.ALARM:
			var clock = ALARM_CLOCK.instantiate()
			add_sibling(clock)
			clock.global_position = global_position
			items[itemSelected] = Global.ITEMS.NONE
			trigger_gameover = true

		Global.ITEMS.SCISSORS:
			var hit = castCollider.get_collider()
			if hit:
				var original_mask = castCollider.collision_mask
				castCollider.collision_mask = 0
				castCollider.set_collision_mask_value(4, true)
				castCollider.force_raycast_update()
				if hit.has_method("scissors"):
					hit.scissors()
				items[itemSelected] = Global.ITEMS.NONE
				trigger_gameover = true
				castCollider.collision_mask = original_mask

		_:
			pass

	if trigger_gameover and randi() %5 == 0:
		game_over()
		return

	update_items()

func add_item(itemID):
	var currentGetItem = 0
	while items[min(currentGetItem, items.size() - 1)] != Global.ITEMS.NONE && currentGetItem < items.size():
		currentGetItem += 1
	if currentGetItem >= items.size():
		currentGetItem = itemSelected
	items[currentGetItem] = itemID
	update_items()

func lose_item(item):
	items[item] = 0
	update_items()


func update_items():
	for i in items.size():
		slots.get_child(i).get_child(0).texture = Global.itemTextures[items[i]]
	$PlayerHud / ItemText.text = itemNames[items[itemSelected]]

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
