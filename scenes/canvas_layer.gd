extends CanvasLayer

@export var first_audio: AudioStream
@export var loop_audio: AudioStream
@export var bpm: float = 184.0
var beat_timer: Timer
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
var playing_loop: = false
var shake_dir: = 1
func _ready():
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	audio_player.connect("finished", Callable(self, "_on_audio_finished"))
	beat_timer = Timer.new()
	beat_timer.wait_time = 60.0 / bpm
	beat_timer.one_shot = false
	beat_timer.autostart = false
	add_child(beat_timer)
	beat_timer.connect("timeout", Callable(self, "_on_beat"))

func _process(_delta):
	if Global.noteBooks == 7 and audio_player.stream == null:
		audio_player.stream = first_audio
		audio_player.play()

func _on_audio_finished():
	if not playing_loop:
		audio_player.stream = loop_audio
		audio_player.play()
		playing_loop = true
		beat_timer.start()
	else:
		audio_player.play()

func _on_beat():
	var pulse_scale = Vector2(1.15, 1.15)
	var original_scale = Vector2.ONE
	var angle = 6.0 * shake_dir
	shake_dir *= -1

	for child in get_children():
		if child is Control:

			var tween: = get_tree().create_tween()
			child.scale = pulse_scale
			child.rotation_degrees = angle

			tween.tween_property(child, "scale", original_scale, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(child, "rotation_degrees", 0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
