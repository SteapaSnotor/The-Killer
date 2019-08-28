extends Control

"""
	Miscellaneous elements of the user interface
"""

signal new_misc

onready var object_panel = $ObjectPanel

var base = null
var current_object = null

#constructor
func init(base):
	self.base = base
	self.base.connect("element_toggle",self,"_on_new_misc")
	
	#link all world objects to the object panel
	var objects = get_tree().get_nodes_in_group("Object")
	for obj in objects:
		#only if they are pickable
		if obj.is_clickable:
			obj.get_node("Button").connect("pressed",self,"show_object_panel",[obj])
			

#hunt button pressed state
func hunt():
	#check if the game can change to the hunting mode before spawning
	#the hunter.
	if base.game.get_current_mode() == base.game.MODE.GAMEOVER:
		return
		 
	var hunter = preload("res://scenes/PlayerHunter.tscn").instance()
	hunter.init(base.game,base)
	base.game.get_node("AI").add_child(hunter)
	
	base.emit_signal('element_changed_focus')

#super zoom btn
func zoom():
	var controller = base.game.get_player_controller()
	controller.set_super_zoom(!controller.super_zoom)

#the object panel shows iformation about a object the player selected
func show_object_panel(obj):
	#don't select objects when the player is hunting
	if get_tree().get_nodes_in_group("Player").size() > 0:
		return
		
	#also don't select objects when the player is putting traps on the world
	if base.get_selected_traps().size() > 0:
		return
	
	#this will close panels or other elements
	base.emit_signal('element_toggle')
	base.emit_signal('element_changed_focus')
	
	$ObjectPanel/Object/Name.text = obj.obj_name
	$ObjectPanel/Object/Desc.text = obj.obj_desc
	
	if obj.is_activable:
		$ObjectPanel/Object/UseButton.show()
	else:
		$ObjectPanel/Object/UseButton.hide()
	
	if not $ObjectPanel.is_visible():
		object_panel.show()
		$ObjectPanel/Object/Close.connect('pressed',self,'hide_object_panel')
		
	current_object = obj

func hide_object_panel():
	$ObjectPanel/Object/Close.disconnect('pressed',self,'hide_object_panel')
	object_panel.hide()
	current_object = null
	
func activate_object():
	#TODO: sound effect
	#TODO: use money
	if current_object != null: current_object.activate()

func _on_new_misc():
	emit_signal("new_misc")