extends Character
class_name Baldi

@export var active = false

var baseTime = 3.0
var timeToMove = 0.0

var baldiWait = 0.1

var baldiSpeedScale = 0.65

var moveFrames = 0.5

var currentPriority = 0

var antiHearing = false
var antiHearingTime = 0.0
var vibrationDistance = 50.0

var baldiAnger = 0.0
var baldiTempAnger = 0.0
var angerRate = 0.01
var angerRateRatio = 0.00025
var angerFrequency = 1.0
var timeToAnger = 0.0

var wanderTarget = Vector3.ZERO
var previous = Vector3.ZERO

var coolDown = 0.0

var rumble = false

@onready var sfxSlap = $Slap
@onready var playerChecker = $PlayerChecker

func _ready():
	super ()
	Global.baldi = self
	wander()
	set_physics_process(active)
	visible = active

func activate():
	active = true
	show()
	set_physics_process(active)
	playerChecker.target_position = Global.player.global_position - global_position
	playerChecker.force_raycast_update()


func _process(_delta):
	$Baldi.speed_scale = max(1.0, speed / 60.0)

func _physics_process(delta):

	if timeToMove > 0.0:
		timeToMove -= delta
	else:
		move()

	coolDown = max(0, coolDown - delta)

	baldiTempAnger = move_toward(baldiTempAnger, 0.0, 0.02 * delta)



	if antiHearingTime > 0:
		antiHearingTime -= delta
	else:
		antiHearing = false


	if Global.endless:
		if timeToAnger > 0:
			timeToAnger -= delta
		else:
			timeToAnger = angerFrequency
			get_angry(angerRate)
			angerRate += angerRateRatio


	if moveFrames > 0:
		speed = 75.0
		moveFrames -= delta * 60.0
	else:
		speed = 0.0



	if Global.player:
		playerChecker.target_position = Global.player.global_position - global_position

		if !playerChecker.is_colliding():
			set_target_node(Global.player)

	super (delta)


func wander():
	navAgent.target_position = Global.get_wander_point()
	coolDown = 1.0
	currentPriority = 0

func set_target_node(object):
	navAgent.target_position = object.global_position
	coolDown = 1.0
	currentPriority = 0


func move():
	if global_position.is_equal_approx(previous) && coolDown <= 0:
		wander()
	moveFrames = 10.0
	timeToMove = baldiWait - baldiTempAnger
	previous = global_position
	sfxSlap.play()
	$Baldi.stop()
	$Baldi.play("slap")

	if Global.rumble:
		var distance = global_position.distance_to(Global.player.global_position)
		if distance <= vibrationDistance:
			Input.start_joy_vibration(0, 0.5, 1.0 - (distance / vibrationDistance), 0.15)

func get_angry(setAnger):
	baldiAnger = max(0.5, baldiAnger + setAnger)
	baldiWait = -3.0 * baldiAnger / (baldiAnger + 2.0 / baldiSpeedScale) + 3.0

func get_temp_anger(tempSet):
	baldiTempAnger += tempSet

func hear(soundLocation = Vector3.ZERO, priority = 0, playReaction = true):
	if !antiHearing:
		if priority >= currentPriority:
			var oldTarget = navAgent.target_position
			navAgent.target_position = soundLocation
			if navAgent.get_final_position().slide(Vector3.UP).distance_to(navAgent.target_position.slide(Vector3.UP)) > 1.0:
				navAgent.target_position = oldTarget

				if active && playReaction:
					Global.player.bali_react("Confused")
			else:
				currentPriority = priority

				if active && playReaction:
					Global.player.bali_react("Notice")

		elif active:
			Global.player.bali_react("Confused")

func activate_anti_hearing(time):
	wander()
	antiHearing = true
	antiHearingTime = time

func _on_player_collider_body_entered(body):
	if playerChecker.is_colliding(): return
	if body is Player && visible:
		if body.has_method("game_over"):
			body.game_over()
