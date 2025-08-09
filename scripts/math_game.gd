extends CanvasLayer

const VU_COUNT = 16
const FREQ_MAX = 11050.0
const MIN_DB = 60.0

var spectrum
var getFrame = 0.0

@onready var liveBaldiReaction = $Pad / LiveBaldiReaction

@onready var mathDialogue = $MathDialogue
@onready var music = $Music
@onready var results = [$Pad / Result1, 
$Pad / Result2, 
$Pad / Result3, 
]

@onready var numberLineEdit = $Pad / Answer
@onready var LineEditRegEx = RegEx.new()
var old_text = ""

var hintText = ["ABCDEFG", 
"I HEAR EVERY DOOR YOU FUCK", ]

var audioQueue = []

@export var correctTexture = preload("res://graphics/YCTPTextures/Check.png")
@export var incorrectTexture = preload("res://graphics/YCTPTextures/X.png")

@onready var questions = $Pad / Questions
var questionOverlaps = []

@export var bal_plus = preload("res://audio/SFX/FinalMode/quiet noise loop.wav")
@export var bal_minus = preload("res://audio/SFX/FinalMode/quiet noise loop.wav")
@export var bal_times = preload("res://audio/SFX/FinalMode/quiet noise loop.wav")
@export var bal_divide = preload("res://audio/SFX/FinalMode/quiet noise loop.wav")
@export var bal_equels = preload("res://audio/SFX/FinalMode/quiet noise loop.wav")
@export var bal_howto = preload("res://audio/SFX/FinalMode/quiet noise loop.wav")
@export var bal_intro = preload("res://audio/SFX/FinalMode/quiet noise loop.wav")
@export var bal_screech = preload("res://audio/SFX/FinalMode/quiet noise loop.wav")

var bal_numbers = [
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
]

@export var praises = AudioStreamRandomizer
var problemAudio = [
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav"), 
preload("res://audio/SFX/FinalMode/quiet noise loop.wav")
]

var impossible = false

var endDelay = 0

var problem = 0
var wrongAnswers = 0
var solution = 0

func _ready():
	Global.unlock_mouse()
	LineEditRegEx.compile("^-?[0-9]*$")

	spectrum = AudioServer.get_bus_effect_instance(3, 0)
	if Global.endless:
		hintText = ["That\'s more like it...", "Keep up the good work or see me after class...", ]
	if Global.noteBooks == 0:
		queue_audio(bal_intro)
		queue_audio(bal_howto)
	new_problems()

	liveBaldiReaction.visible = !Global.spoopMode
	if !Global.spoopMode:
		music.play()

	for i: TextureButton in $Pad / Keypad.get_children():
		i.pressed.connect(parse_button.bind(i))

func _process(delta):

	var hzOffset = 1.5
	var hz = hzOffset * FREQ_MAX / VU_COUNT
	var prevHz = (hzOffset - 1.0) * FREQ_MAX / VU_COUNT

	var magnitude = spectrum.get_magnitude_for_frequency_range(hz, prevHz).length()
	var volume = (clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1))
	if !mathDialogue.playing:
		volume = 0.0

		if audioQueue.size() > 0 && !Global.spoopMode:
			mathDialogue.stream = audioQueue[0]
			mathDialogue.play()
			audioQueue.pop_front()

	getFrame = lerp(getFrame, snappedf(volume, 0.1), delta * 16.0)
	if !Global.spoopMode:
		liveBaldiReaction.frame = round(getFrame * 6.0)

	if problem > 1:
		endDelay -= 1.0 * delta
		if endDelay <= 0:
			Global.noteBooks += 1
			queue_free()
			Global.lock_mouse()
			get_tree().paused = false



func new_problems():
	numberLineEdit.clear()
	if problem <= 2:
		queue_audio(problemAudio[problem])
		if (problem <= 1 || Global.noteBooks <= 0):
			var nums = [randi_range(0, 9), randi_range(0, 9)]

			var getSign = sign(randf() - 0.5)
			var symbol = "+"
			solution = nums[0] + nums[1]
			if getSign < 0:
				symbol = "-"
				solution = nums[0] - nums[1]
			questions.text = "SOLVE MATH Q" + str(problem + 1) + ":\n\n" + str(nums[0]) + symbol + str(nums[1]) + "="
			queue_audio(bal_numbers[nums[0]])

			queue_audio(bal_plus if getSign >= 0 else bal_minus)
			queue_audio(bal_numbers[nums[1]])
		else:
			impossible = true

			queue_audio(bal_screech)

			questionOverlaps.append(questions)

			var textDuplicate = questions.duplicate()
			$Pad.add_child(textDuplicate)
			questionOverlaps.append(textDuplicate)

			textDuplicate = questions.duplicate()
			$Pad.add_child(textDuplicate)
			questionOverlaps.append(textDuplicate)

			for i in questionOverlaps.size():
				var nums = [randi_range(1, 9999), randi_range(1, 9999), randi_range(1, 9999)]
				var getSign = sign(randf() - 0.5)
				var symbol = "+"
				solution = nums[0] + nums[1]
				if getSign < 0:
					symbol = "-"
				var secondSymbol = "/"
				if getSign < 0:
					secondSymbol = "x"
				questionOverlaps[i].text = "SOLVE MATH Q" + str(problem + 1) + ":\n" + str(nums[0]) + symbol + str(nums[1]) + secondSymbol + str(nums[2]) + "="

				if i == 0:
					queue_audio(bal_plus if getSign >= 0 else bal_minus)
					queue_audio(bal_screech)
					queue_audio(bal_divide if getSign >= 0 else bal_times)
					queue_audio(bal_screech)
					queue_audio(bal_equels)


	else:

		if questionOverlaps.size() > 1:
			questionOverlaps[1].queue_free()
			questionOverlaps[2].queue_free()
		if !Global.spoopMode:
			questions.text = "WOW! YOU EXIST!"
		elif !Global.endless && wrongAnswers >= 3:
			questions.text = "BAKA."
			Global.faildBooks += 1
		else:
			questions.text = hintText[int(round(randf()))]


	problem += 1



func _on_LineEdit_text_changed(new_text):
	var caretPos = numberLineEdit.caret_column
	if LineEditRegEx.search(new_text):
		old_text = str(new_text)
	else:
		numberLineEdit.text = old_text
		numberLineEdit.caret_column = caretPos - 1

func queue_audio(audio: AudioStream = null):
	audioQueue.append(audio)


func _on_answer_text_submitted(_new_text):
	if problem <= 3:

		mathDialogue.stop()
		audioQueue.clear()
		if solution == int(numberLineEdit.text) && numberLineEdit.text != "" && !impossible:
			results[problem - 1].texture = correctTexture
			Global.secret = false

		else:
			if wrongAnswers == 0 && music.playing:
				music.stream = load("res://audio/Characters/Bully/B.wav")
				music.play()

				$Pad / BaldiAnimator.play("Anger")
			wrongAnswers += 1
			results[problem - 1].texture = incorrectTexture
			if !Global.spoopMode:
				Global.spoopMode = true
				for i in get_tree().get_nodes_in_group("pre_game"):
					if i is AudioStreamPlayer:
						i.stop()
					else:
						i.queue_free()
				for i in get_tree().get_nodes_in_group("activatable"):
					if i.has_method("activate"):
						i.activate()

			if !Global.endless:
				if problem >= 1:
					Global.baldi.get_angry(0)
				else:
					Global.baldi.get_temp_anger(0.25)

				if Global.noteBooks >= 6 && !Global.escapeMode:
					Global.escapeMode = true
					for i in get_tree().get_nodes_in_group("escape"):
						if i.has_method("escape_activate"):
							i.escape_activate()

			else:
				Global.baldi.get_angry(1.0)
		new_problems()

func parse_button(button: TextureButton):

	match (button.name):
		"OK":
			_on_answer_text_submitted(numberLineEdit.text)
		"-":
			if numberLineEdit.text.begins_with("-"):
				numberLineEdit.text = numberLineEdit.text.right(-1)
			else:
				numberLineEdit.text = numberLineEdit.text.insert(0, "-")
		"C":
			numberLineEdit.clear()
		_:
			numberLineEdit.text += button.name
