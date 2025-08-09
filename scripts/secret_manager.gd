extends Node3D

func _process(delta):

	var camera = get_viewport().get_camera_3d()
	var baldi = $Filename2
	baldi.look_at(baldi.global_position + camera.global_basis.z, Vector3.UP)


func _on_recording_finished():
	get_tree().quit()


func _on_ending_body_entered(body):
	if !$Filename2 / Recording.is_playing():
		$Filename2 / Recording.play()
