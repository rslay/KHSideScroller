extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

const FRICTION = 0.2
const SPEED = 100
const MAXSPEED = 100

const UP = Vector2(0, -1)
const GRAVITY = 5
const JUMPHEIGHT = -175

var anim = "idle"
var motion = Vector2()

var levitatedToTop = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _physics_process(delta):
	
	motion.y += GRAVITY
	
	if is_on_floor():
		motion.y -= GRAVITY
		if Input.is_action_pressed("ui_right") && Input.is_action_pressed("ui_left"):
			pass
		elif Input.is_action_pressed("ui_right"):
			motion.x = min(motion.x + SPEED, MAXSPEED)
			$AnimatedSprite.flip_h = true
			$AnimatedSprite.play("walk")
		elif Input.is_action_pressed("ui_left"):
			motion.x = max(motion.x - SPEED, -MAXSPEED)
			$AnimatedSprite.flip_h = false
			$AnimatedSprite.play("walk")
		else:
			$AnimatedSprite.play("idle")
			motion.x = lerp(motion.x, 0, 0.2)
		if Input.is_action_just_pressed("ui_select"):
			motion.y = JUMPHEIGHT
	else:
		if Input.is_action_pressed("ui_right") && Input.is_action_pressed("ui_left"):
			pass
		elif Input.is_action_pressed("ui_right"):
			motion.x = min(motion.x + SPEED, MAXSPEED)
		elif Input.is_action_pressed("ui_left"):
			motion.x = max(motion.x - SPEED, -MAXSPEED)
		$AnimatedSprite.play("jump")
		
	
	if Input.is_action_pressed("ui_right") && Input.is_action_pressed("ui_left"):
		$AnimatedSprite.play("levitate")
		motion.x = 0
		if levitatedToTop:
			if motion.y > 200:
				motion.y += 30
			else:
				levitatedToTop = false
		else:
			if motion.y < 200:
				motion.y -= 30
			else:
				levitatedToTop = true
	
	# Animate and move
	print(motion)
	print(levitatedToTop)
	move_and_slide(motion, UP)