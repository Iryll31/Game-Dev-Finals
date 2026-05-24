extends AnimatedSprite2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
#physics
@export var speed: int = 600
@export var moveDist: int = 100
@export var rotationSpeed: int = 0

#for sprites
@onready var startX: float = position.x
@onready var targetX: float = position.x + moveDist

func move_to(current, to, step):
	var new = current
	
	if new < to:
		new += step
		
		if new > to:
			new = to
	
	#moving backwards or negative
	else:
		new -= step
		
		if new < to:
			new = to
			
	return new
	
func _process(delta):
	rotation_degrees += rotationSpeed * delta
	
func _physics_process(delta):
	
	#move to the targetX position
	position.x = move_to(position.x, targetX, speed * delta)
	
	#if we're at our target, move in other direction
	if position.x == targetX:
		if targetX == startX:
			targetX = position.x + moveDist
		else:
			targetX = startX
