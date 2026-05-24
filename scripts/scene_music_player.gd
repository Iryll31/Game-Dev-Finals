extends AudioStreamPlayer

@export var restart_if_stopped := true
@export var target_volume_db := -12.0


func _ready() -> void:
	volume_db = target_volume_db
	if stream != null:
		stream.set("loop", true)
	play()


func _process(_delta: float) -> void:
	if restart_if_stopped and stream != null and not playing:
		play()
