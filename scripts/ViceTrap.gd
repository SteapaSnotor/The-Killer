extends "res://scripts/Traps.gd"

"""
	Vice traps. This traps are placed in the world will change the teenager's
	modifiers.
"""

var id = 0

var effects = {
	0:[funcref(self,"decrease_speed")],
	1:[funcref(self,"decrease_speed")]
	
}
var is_placed = false
var is_used = false
var body_on_radius = null

#world nodes
onready var texture = $Texture
onready var radius = $Texture/DetectionRadius

func _ready():
	#TODO: change the textures acording to its ID
	#on radius signal
	radius.connect("body_entered",self,"_on_radius")
	radius.connect("body_exited",self,"_out_radius")

#move the trap around the map
func _process(delta):
	if base == null or is_placed:
		if is_placed and body_on_radius != null and !is_used:
			#this trap is on the teenager radius. If he's both are in the
			#same location (indoor or outdoor) emit the signal
			if body_on_radius.get_parent().is_indoor == is_indoor:
				_on_radius(body_on_radius)
				body_on_radius = null
			else:
				print("waiting")
		return
	
	var closest = base.get_closest_tile(tiles,get_global_mouse_position(),20)
	if closest == get_global_mouse_position():
		#the player can't place the trap here
		set_is_invalid_tile(true)
	else: set_is_invalid_tile(false)
	
	texture.global_position =  Vector2(closest.x+25/2,closest.y+25/2)

func _input(event):
	if Input.is_action_just_pressed("ok_input"):
		if not is_invalid_tile and not is_placed:
			is_placed = true
			#set_process(false)
			ui.disconnect("new_trap",self,"exit")
			#on radius signal
			#radius.connect("body_entered",self,"_on_radius")
			
	elif Input.is_action_just_pressed("cancel_input"):
		#remove the trap if it's not placed yet when the player hits cancel
		if not is_placed:
			queue_free()

#when something entered this trap radius. Check if it's the player then do 
#its effects
#TODO: raycast to see if the player can really see the trap
func _on_radius(body):
	if body.name == "KinematicTeenager" and is_placed:
		#check if the teenager can see the trap
		if body.get_parent().is_indoor != is_indoor:
			#he can't see the trap now, but lets wait if he can see it later
			body_on_radius = body
			return
		is_used = true
		body.get_parent().set_trap(self)
		activate_vice(body.get_parent())
	elif body.name == "KinematicTeenager" and !is_placed:
		#this trap has not been placed yet, but let's wait if it does later on
		body_on_radius = body
		#for effect in effects[id]:
			#apply each effect of this trap
			#TODO: those effects should be applied inside the OnVice State
			#effect.call_func(body.get_parent())

func _out_radius(body):
	if body_on_radius == body:
		body_on_radius = null









