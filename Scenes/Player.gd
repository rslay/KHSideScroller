extends KinematicBody2D


const SHADOWPOS = 35

const FRICTION = 0.05
const SPEED = 120
const MAXSPEED = 120
const AIRBORNE_MAXSPEED = 170
const FLIGHT_MAXSPEED = 350

const LANDINGLAG = 20

const EDGEOFFSET = 15

const UP = Vector2(0, -1)
const GRAVITYDEF = 10
var GRAVITY = GRAVITYDEF
const JUMPHEIGHT = -250

const LEVITATEDELAY = 20
const ATTACK1DELAY = 45
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
var landing = 0 # 0 means not landing

var attacking = false
var attackc = 0 # 0 means not attacking

var anim = "idle"
var motion = Vector2()

var levitatedToTop = -1

var voiceSFX

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	voiceSFX = AudioStreamPlayer.new()
	self.add_child(voiceSFX)
	voiceSFX.volume_db = -10
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func playSFX1():
	voiceSFX.stream = load(SFX_1)
	voiceSFX.play()

func playSFX2():
	voiceSFX.stream = load(SFX_2)
	voiceSFX.play()

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
			anim = "jumping"
		#if floorPos == 0:
		#	floorPos = get_transform().origin.y
			#motion.x += 10
			
		# Linear extrapolation, imitates friction.
	motion.x = lerp(motion.x, 0, FRICTION)

func land():
	midair = false
	#floorPos = 0
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
		if attackc == ATTACK1DELAY/4:
			randomize()
			if randf() > 0.5:
				playSFX2()
			else:
				playSFX1()
	else:
		attackc = 0


func _physics_process(delta):
	
	motion.y += GRAVITY
	
	if is_on_floor():
		flying = false
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
			else:
				motion.x = 0

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
			if flying:
				turnRight()
				motion.x = min(motion.x + SPEED, FLIGHT_MAXSPEED)
			else:
				motion.x = min(motion.x + SPEED, AIRBORNE_MAXSPEED)
		elif Input.is_action_pressed("ui_left"):
			if flying:
				turnLeft()
				motion.x = min(motion.x + SPEED, -FLIGHT_MAXSPEED)
			else:
				motion.x = max(motion.x - SPEED, -AIRBORNE_MAXSPEED)

		if Input.is_action_pressed("ui_up") && Input.is_action_pressed("ui_down"):
			pass
		elif Input.is_action_pressed("ui_up"):
			if flying:
				if depthOffset - 2 > OFFSETLIMITS.x:
					depthOffset -= 2
					$Shadow.set_offset(Vector2(0, $Shadow.offset.y - 2))
			else:
				if depthOffset - 1 > OFFSETLIMITS.x:
					depthOffset -= 1
					$Shadow.set_offset(Vector2(0, $Shadow.offset.y - 1))
					anim = "walk"
		elif Input.is_action_pressed("ui_down"):
			if flying:
				if depthOffset - 2 < OFFSETLIMITS.y:
					depthOffset += 2
					$Shadow.set_offset(Vector2(0, $Shadow.offset.y + 2))
			else:
				if depthOffset - 1 < OFFSETLIMITS.y:
					depthOffset += 1
					$Shadow.set_offset(Vector2(0, $Shadow.offset.y + 1))
					anim = "walk"
		
		if Input.is_action_just_pressed("ui_select"):
			flightc = 0
			if flying:
				flying = false
				flightc = -1
			else:
				flying = true
				
		
		
		airtime()


	if Input.is_action_pressed("ui_right") and Input.is_action_pressed("ui_left") and not flying:
		motion.x = 0
		if levitateBuffer == LEVITATEDELAY:
			#midair = true
			if levitatedToTop:
				#anim = "levitatedown"
				if motion.y < GRAVITY*20:
					motion.y += GRAVITY*1.5
				else:
					levitatedToTop = false
			elif !levitatedToTop:
				#anim = "levitateup"
				if motion.y > GRAVITY*-20:
					motion.y -= GRAVITY*1.5
				else:
					levitatedToTop = true
		else:
			if levitateBuffer > 10:
				if is_on_floor():
					anim = "idle"
				else:
					anim = "falling"
			levitateBuffer += 1
	else:
		levitateBuffer = 0
	
	# Animate and move
	$AnimatedSprite.set_offset(Vector2(facingDirectionOffset, depthOffset))
	
	if midair:
		$Shadow.set_offset(Vector2(0, $Shadow.offset.y - motion.y*0.0168))
		
		#$Shadow.set_offset(Vector2(0, floorPos - get_transform().origin.y + depthOffset + SHADOWPOS))
	else:
		$Shadow.set_offset(Vector2(0, depthOffset + SHADOWPOS))
	
	print("Motion:")
	print(motion)
	#print("Levitated to top:")
	#print(levitatedToTop)
	#print("Animation:")
	#print($AnimatedSprite.animation)
	#print("Landing:")
	print(get_transform().origin.y)
	#print("$Shadow.offset.y - ", $Shadow.offset.y - get_transform().origin.y, ", Floorpos - ", floorPos)
	
	$AnimatedSprite.play(anim)
	move_and_slide(motion, UP)
	if get_transform().origin.x > get_viewport().size.x - EDGEOFFSET:
		transform.origin.x = get_viewport().size.x - EDGEOFFSET
	elif get_transform().origin.x < EDGEOFFSET:
		transform.origin.x = EDGEOFFSET
	
	