extends Area3D

enum ZONE_TYPE{FACULTY, PRINCIPAL}
@export var zone: ZONE_TYPE = ZONE_TYPE.FACULTY

func _on_body_entered(body):
    match (zone):
        ZONE_TYPE.PRINCIPAL:
            if body is Player:
                if body.guiltType == "escape":
                    body.guilt = 0.0
            elif body is Principal:
                if !body.angry:
                    body.inOffice = true
        ZONE_TYPE.FACULTY:
            if body is Player:
                body.reset_guilt("faculty", 1.0)

                var layer_memory = collision_layer
                var mask_memory = collision_mask
                collision_layer = 0
                collision_mask = 0

                await get_tree().physics_frame
                collision_layer = layer_memory
                collision_mask = mask_memory



func _on_body_exited(body):
    match (zone):
        ZONE_TYPE.PRINCIPAL:
            if body is Player:
                body.reset_guilt("escape", body.detentionTimer)
            elif body is Principal:
                body.inOffice = false
