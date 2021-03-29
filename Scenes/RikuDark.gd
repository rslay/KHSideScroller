extends KinematicBody2D


const SHADOWPOS = 35 # needs to be adjusted

const FRICTION = 0.05
const SPEED = 200
const MAXSPEED = 230
const DEPTH_WALK_SPEED = 2
const AIRBORNE_MAXSPEED = 280
const FLIGHT_MAXSPEED = 350

const LANDINGLAG = 22

const EDGEOFFSET = 15

const UP = Vector2(0, -1)
const GRAVITYDEF = 10
var GRAVITY = GRAVITYDEF

const JUMPHEIGHT = -300
const JUMPDELAY = 7

const LEVITATEDELAY = 1

const ATTACK1DELAY = 40
const ATTACK1_MOTION = 100
const ATTACK1_MOTION_TIME = [8, 12]

const FLIGHTDELAY = 21

const SFX_1 = "res://SFX/cloud1.wav"
const SFX_2 = "res://SFX/cloud2.wav"



var flying = false
var flightc = 0

var floorPos = 0

# prevents player from starting levitation accidentally, once its greater than LEVITATEDELAY cloud will float
var levitateBuffer = 0

# How far "up" and "down" the player can go
const OFFSETLIMITS = Vector2(-30, 30)
# How far "up" and "down" the player is
var depthOffset = 0

var health = 150
var maxhealth = 175

# This is for the shadow - its the depthOffset before the player goes airborne
var prevDepthOffset = depthOffset

# When the player faces left or right, his sprite needs to be centered via an offsent
const DIRECTIONOFFSET = -1
var facingDirectionOffset = DIRECTIONOFFSET

var midair = false
var landingc = 0 # 0 means not landing

var attacking = false
var attackc = 0 # 0 means not attacking

var jumping = false
var jumpc = 0 # 0 means not attacking

var anim = "idle"
var motion = Vector2()

var levitatedToTop = -1

var voiceSFX

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
#	voiceSFX = AudioStreamPlayer.new()
#	self.add_child(voiceSFX)
#	voiceSFX.volume_db = -10
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func playSFX1():
	voiceSFX.stream = load(SFX_1)
#	voiceSFX.play()

func playSFX2():
	voiceSFX.stream = load(SFX_2)
#	voiceSFX.play()

func turnLeft():
	$AnimatedSprite.flip_h = false
	anim = "walk"
	facingDirectionOffset = -DIRECTIONOFFSET

func turnRight():
	$AnimatedSprite.flip_h = true
	anim = "walk"
	facingDirectionOffset = DIRECTIONOFFSET

func airtime():
	if flying:
		if transform.origin.y > 125:
			if motion.y > 0:
				motion.y = 0
			else:
				motion.y -= 5
		elif transform.origin.y < 125:
			if motion.y < 0:
				motion.y = 0
			else:
				motion.y += 5
		else:
			motion.y = 0
		
		
		GRAVITY = 0
		if flightc < FLIGHTDELAY and flightc >= 0:
			anim = "flystart"
			flightc += 1
		elif flightc < 0:
			anim = "flyend"
		else:
			anim = "flying"
	else:
		GRAVITY = GRAVITYDEF
		if motion.y > 0:
			anim = "falling"
		else:
			anim = "jumped"
		#if floorPos == 0:
		#	floorPos = get_transform().origin.y
		#	motion.x += 10
			
	# Linear extrapolation, imitates friction.
	motion.x = lerp(motion.x, 0, FRICTION)

func land():
	midair = false
	#floorPos = 0
	motion.x = 0
	if landingc <= LANDINGLAG:
		landingc += 1
		anim = "landing"
	else:
		landingc = 0

func jump():
#	midair = false
	motion.x = 0
	if jumpc <= JUMPDELAY:
		jumpc += 1
#		anim = "jumping"
	else:
		jumpc = 0
		jumping = false
		midair = true
		motion.y = JUMPHEIGHT
		airtime()

func attack1():
	attacking = false
	if attackc <= ATTACK1DELAY:
		attackc += 1
		anim = "attack1"
		if attackc in range(ATTACK1_MOTION_TIME[0], ATTACK1_MOTION_TIME[1]):
			if $AnimatedSprite.flip_h:
				motion.x += ATTACK1_MOTION
			else:
				motion.x -= ATTACK1_MOTION
#			randomize()
#			if randf() > 0.5:
#				playSFX2()
#			else:
#				playSFX1()
		else:
			motion.x = 0
	else:
		attackc = 0
		anim = "idle"


func _physics_process(delta):
	
	motion.y += GRAVITY
	
	if is_on_floor():
		flying = false
		if midair || landingc != 0: # landing
			land()
		elif jumping || jumpc != 0: # about to jump
			jump()
		elif attacking || attackc != 0:
			attack1()
		else: 
			motion.y -= GRAVITY
			if Input.is_action_pressed("ui_right") && Input.is_action_pressed("ui_left"):
				anim = "idle"
			elif Input.is_action_pressed("ui_right"):
				motion.x = min(motion.x + SPEED, MAXSPEED)
				turnRight()
			elif Input.is_action_pressed("ui_left"):
				motion.x = max(motion.x - SPEED, -MAXSPEED)
				turnLeft()
			else:
				motion.x = 0

			if Input.is_action_pressed("ui_up") && Input.is_action_pressed("ui_down"):
				pass
			elif Input.is_action_pressed("ui_up"):
				depthOffset = max(depthOffset - DEPTH_WALK_SPEED, OFFSETLIMITS.x)
				anim = "walk"
			elif Input.is_action_pressed("ui_down"):
				depthOffset = min(depthOffset + DEPTH_WALK_SPEED, OFFSETLIMITS.y)
				anim = "walk"

			# Player is not moving in any direction
			if !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_up") and !Input.is_action_pressed("ui_down"):
				anim = "idle"
				motion.x = 0
				
			if Input.is_action_just_pressed("ui_select"): # Spacebar
				if not midair:
					# Build-up before jumping, use "about to jump" animation
					anim = 'jumping'
					jumping = true
				elif midair:
					pass # double jump
				
			if Input.is_action_just_pressed("attack1"): # Z button
				attacking = true

	else:
#		if !midair:
#			prevDepthOffset = depthOffset
#			midair = true
#			print("not on floor and midair!?")

		if Input.is_action_pressed("ui_right") and Input.is_action_pressed("ui_left"):
			pass
		elif Input.is_action_pressed("ui_right"):
			if flying:
				pass
#				turnRight()
#				motion.x = min(motion.x + SPEED, FLIGHT_MAXSPEED)
			else:
				motion.x = min(motion.x + SPEED, AIRBORNE_MAXSPEED)
		elif Input.is_action_pressed("ui_left"):
			if flying:
				pass
#				turnLeft()
#				motion.x = min(motion.x + SPEED, -FLIGHT_MAXSPEED)
			else:
				motion.x = max(motion.x - SPEED, -AIRBORNE_MAXSPEED)

		if Input.is_action_pressed("ui_up") && Input.is_action_pressed("ui_down"):
			pass
		elif Input.is_action_pressed("ui_up"):
			if flying:
				pass
#				if depthOffset - 2 > OFFSETLIMITS.x:
#					depthOffset -= 2
#					$Shadow.set_offset(Vector2(0, $Shadow.offset.y - 2))
			else:
				if depthOffset - 1 > OFFSETLIMITS.x:
					depthOffset -= 1
					$Shadow.set_offset(Vector2(0, $Shadow.offset.y - 1))
					anim = "walk"
		elif Input.is_action_pressed("ui_down"):
			if flying:
				pass
#				if depthOffset - 2 < OFFSETLIMITS.y:
#					depthOffset += 2
#					$Shadow.set_offset(Vector2(0, $Shadow.offset.y + 2))
			else:
				if depthOffset - 1 < OFFSETLIMITS.y:
					depthOffset += 1
					$Shadow.set_offset(Vector2(0, $Shadow.offset.y + 1))
					anim = "walk"
		
		if Input.is_action_just_pressed("ui_select"):
			pass
			# Should be flipping/double jumping midair
#			flightc = 0
#			if flying:
#				flying = false
#				flightc = -1
#			else:
#				flying = true
		airtime()
	
	# Animate and move
	$AnimatedSprite.set_offset(Vector2(facingDirectionOffset, depthOffset))
	
	if midair:
#		$Shadow.set_offset(Vector2(0, $Shadow.offset.y - motion.y * 0.0168))
		$Shadow.set_offset(Vector2(0, $Shadow.offset.y - motion.y))
		
		#$Shadow.set_offset(Vector2(0, floorPos - get_transform().origin.y + depthOffset + SHADOWPOS))
	else:
		$Shadow.set_offset(Vector2(0, depthOffset + SHADOWPOS))
	
#	print("Motion:")
#	print(motion)
	#print("Levitated to top:")
	#print(levitatedToTop)
	print("Animation:")
	print($AnimatedSprite.animation)
	#print("Landing:")
#	print(get_transform().origin.y)
	#print("$Shadow.offset.y - ", $Shadow.offset.y - get_transform().origin.y, ", Floorpos - ", floorPos)
	
	$AnimatedSprite.play(anim)
	move_and_slide(motion, UP)
	if get_transform().origin.x > get_viewport().size.x - EDGEOFFSET:
		transform.origin.x = get_viewport().size.x - EDGEOFFSET
	elif get_transform().origin.x < EDGEOFFSET:
		transform.origin.x = EDGEOFFSET
	
	
