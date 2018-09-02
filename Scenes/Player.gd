extends KinematicBody2D

const SHADOWPOS = 35

const FRICTION = 0.05
const SPEED = 120
const MAXSPEED = 120
const AIRBONE_MAXSPEED = 170

const LANDINGLAG = 10

const UP = Vector2(0, -1)
const GRAVITY = 10
const JUMPHEIGHT = -200

const LEVITATEDELAY = 20
const ATTACK1DELAY = 60

# prevents player from starting levitation accidentally, once its greater than LEVITATEDELAY cloud will float
var levitateBuffer = 0

# How far "up" and "down" the player can go
const OFFSETLIMITS = Vector2(-30, 30)
# How far "up" and "down" the player is
var depthOffset = 15

var health = 150
var maxhealth = 175

# This is for the shadow - its the depthOffset before the player goes airborne
var prevDepthOffset = depthOffset

# When the player faces left or right, his sprite needs to be centered via an offsent
const DIRECTIONOFFSET = 7
var facingDirectionOffset = DIRECTIONOFFSET

var midair = false
var landing = 0 # 0 means not landing

var attacking = false
var attackc = 0 # 0 means not attacking

var anim = "idle"
var motion = Vector2()

var levitatedToTop = -1

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func turnLeft():
	$AnimatedSprite.flip_h = false
	anim = "walk"
	facingDirectionOffset = -DIRECTIONOFFSET

func turnRight():
	$AnimatedSprite.flip_h = true
	anim = "walk"
	facingDirectionOffset = DIRECTIONOFFSET

func airtime():
	if motion.y > 0:
		anim = "falling"
	else:
		anim = "jumping"

	# Linear extrapolation, imitates friction.
	motion.x = lerp(motion.x, 0, FRICTION)

func land():
	midair = false
	motion.x = 0
	if landing <= LANDINGLAG:
		landing += 1
		anim = "landing"
	else:
		landing = 0

func attack1():
	attacking = false
	motion.x = 0
	if attackc <= ATTACK1DELAY:
		attackc += 1
		anim = "attack1"
	else:
		attackc = 0


func _physics_process(delta):
	
	motion.y += GRAVITY
	
	if is_on_floor():
		if midair || landing != 0:
			land()
		elif attacking || attackc != 0:
			attack1()
		else: 
			motion.y -= GRAVITY
			if Input.is_action_pressed("ui_right") && Input.is_action_pressed("ui_left"):
				pass
			elif Input.is_action_pressed("ui_right"):
				motion.x = min(motion.x + SPEED, MAXSPEED)
				turnRight()
			elif Input.is_action_pressed("ui_left"):
				motion.x = max(motion.x - SPEED, -MAXSPEED)
				turnLeft()

			if Input.is_action_pressed("ui_up") && Input.is_action_pressed("ui_down"):
				pass
			elif Input.is_action_pressed("ui_up"):
				depthOffset = max(depthOffset - 1, OFFSETLIMITS.x)
				anim = "walk"
			elif Input.is_action_pressed("ui_down"):
				depthOffset = min(depthOffset + 1, OFFSETLIMITS.y)
				anim = "walk"

			# Player is not moving in any direction
			if !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_up") and !Input.is_action_pressed("ui_down"):
				anim = "idle"
				# Linear extrapolation, imitates friction.
				#motion.x = lerp(motion.x, 0, FRICTION)
				# Lets just stop the player immediately instead
				motion.x = 0
				
			if Input.is_action_just_pressed("ui_select"):
				midair = true
				motion.y = JUMPHEIGHT
				airtime()
				
			if Input.is_action_just_pressed("attack1"):
				attacking = true

	else:
		if !midair:
			prevDepthOffset = depthOffset
			midair = true

		if Input.is_action_pressed("ui_right") && Input.is_action_pressed("ui_left"):
			pass
		elif Input.is_action_pressed("ui_right"):
			motion.x = min(motion.x + SPEED, AIRBONE_MAXSPEED)
		elif Input.is_action_pressed("ui_left"):
			motion.x = max(motion.x - SPEED, -AIRBONE_MAXSPEED)

		if Input.is_action_pressed("ui_up") && Input.is_action_pressed("ui_down"):
			pass
		elif Input.is_action_pressed("ui_up"):
			if depthOffset - 1 > OFFSETLIMITS.x:
				depthOffset -= 1
				$Shadow.set_offset(Vector2(0, $Shadow.offset.y - 1))
				anim = "walk"
		elif Input.is_action_pressed("ui_down"):
			if depthOffset - 1 < OFFSETLIMITS.y:
				depthOffset += 1
				$Shadow.set_offset(Vector2(0, $Shadow.offset.y + 1))
				anim = "walk"
		airtime()


	if Input.is_action_pressed("ui_right") && Input.is_action_pressed("ui_left"):
		motion.x = 0
		if levitateBuffer == LEVITATEDELAY:
			anim = "levitate"
			#midair = true
			if levitatedToTop:
				if motion.y < GRAVITY*20:
				 	motion.y += GRAVITY*1.5
				else:
					levitatedToTop = false
			elif !levitatedToTop:
				if motion.y > GRAVITY*-20:
					motion.y -= GRAVITY*1.5
				else:
					levitatedToTop = true
		else:
			if levitateBuffer > 3:
				anim = "idle"
			levitateBuffer += 1
	else:
		levitateBuffer = 0
	
	# Animate and move
	$AnimatedSprite.set_offset(Vector2(facingDirectionOffset, depthOffset))
	
	if midair:
		#if motion.y > 0:
		$Shadow.set_offset(Vector2(0, $Shadow.offset.y - motion.y*0.01675))
		#else:
		#$Shadow.set_offset(Vector2(0, $Shadow.offset.y - motion.y*0.0156))
	else:
		$Shadow.set_offset(Vector2(0, depthOffset + SHADOWPOS))
	
	#print("Motion:")
	#print(motion)
	#print("Levitated to top:")
	#print(levitatedToTop)
	#print("Animation:")
	#print($AnimatedSprite.animation)
	#print("Landing:")
	#print(landing)
	print("Shadow:")
	print($Shadow.offset.y-$AnimatedSprite.offset.y)
	#print("Animated:")
	#print($AnimatedSprite.offset)
	
	$AnimatedSprite.play(anim)
	move_and_slide(motion, UP)
	
	