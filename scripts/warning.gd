extends CanvasLayer
@export var warnings: PackedStringArray = [
"[center]TFYG Remastered是一个含有成人内容，傻逼内容以及小蚪的游戏。如果你是活蹦乱跳的，并且你还想活蹦乱跳的话，就不要玩这个游戏！！！(听说玩了的人都变成了神经病！)\n(Press any key to continue)", 
"[center]WARNING!\nIn case you haven\'t figured it out yet, this game is intended to be a 小蚪 game. As such, it has some things that might scare players and is generally pretty spoopy. (Well, at least it\'s supposed to be...) If you downloaded this thinking it would be great edutainment for your kid or something. don\'t let them play it!... Unless, of course, they enjoy horror games.\n\nYOU HAVE BEEN WARNED\n(Press to continue)"\
\
\
\
, 
"[center]Baldi and all characters are property of mystman12. All code, assets, and music are owned by mystman12. We have nothing to do with mystman12, this is a fanmade decompile of the game. We are not responsible for anything made with said decompile, but you may not use this decompile for commercial purposes. This includes ads, ingame-purchases etc. By using this tool or playing any mods created with this tool you agree to the conditions above.\n\n(Press to continue)"\
\
, 
]
var warningID = 0
@export var tiptext = ["Better than Baldi's Basics!","我要游戏源文件，。","boss站能加我吗，？。","意义不明哈。","You re cool because you read this."]
func _ready():
	update_text()

func update_text():
	$Label.text = warnings[warningID]


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if warningID < warnings.size() - 1:
				warningID += 1
				update_text()
			else:
				get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_ok_button_pressed() -> void:
	if warningID < warnings.size() - 1:
		warningID += 1
		update_text()
	else:
			$Timer.start()

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
