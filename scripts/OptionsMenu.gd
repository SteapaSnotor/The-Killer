extends Control

"""
	Controll the buttons of the option menu screen.
"""

onready var btns = [$Start,$Options,$Credits,$Exit]
var selected_btn = 0
var _selected_normal = null

#initialize
func _ready():
	btns[selected_btn].get_child(0).show()
	_selected_normal = btns[selected_btn].texture_normal
	btns[selected_btn].texture_normal = btns[selected_btn].texture_hover
	
	for btn in btns:
		btn.connect('mouse_entered',self,'_on_hover',[btn])

#when the button is hovered with the mouse
func _on_hover(btn):
	if btns.find(btn) == selected_btn: return
	btns[selected_btn].get_child(0).hide()
	btns[selected_btn].texture_normal = _selected_normal
	
	selected_btn = btns.find(btn)
	btns[selected_btn].get_child(0).show()
	_selected_normal = btns[selected_btn].texture_normal
	btns[selected_btn].texture_normal = btns[selected_btn].texture_hover

func _input(event):
	if not self.is_visible(): return
	
	var changed = false
	var new_btn = selected_btn
	
	if Input.is_action_just_pressed("Down"):
		btns[selected_btn].get_child(0).hide()
		btns[selected_btn].texture_normal = _selected_normal
		new_btn += 1
		changed = true
	elif Input.is_action_just_pressed("Up"):
		btns[selected_btn].get_child(0).hide()
		btns[selected_btn].texture_normal = _selected_normal
		new_btn -= 1
		changed = true
	elif Input.is_action_just_pressed("Enter"):
		if btns[selected_btn] == $Start: on_start()
		elif btns[selected_btn] == $Options: on_options()
		elif btns[selected_btn] == $Credits: on_credits()
		elif btns[selected_btn] == $Exit: exit()
		else: return
	else:
		return
	
	if changed:
		if new_btn == btns.size(): new_btn = 0
		elif new_btn == -1: new_btn = btns.size()-1
		
		selected_btn = new_btn
		btns[selected_btn].get_child(0).show()
		_selected_normal = btns[selected_btn].texture_normal
		btns[selected_btn].texture_normal = btns[selected_btn].texture_hover
	

#start button pressed event
func on_start():
	self.hide()
	
	var level_selection = preload("res://scenes/LevelsSelection.tscn").instance()
	get_parent().add_child(level_selection)
	level_selection.connect('closed',self,'show')

#credits button pressed event
func on_credits():
	self.hide()
	
	var credits = preload("res://scenes/Credits.tscn").instance()
	get_parent().add_child(credits)
	credits.connect('closed',self,'show')

func on_options():
	self.hide()
	
	var settings = preload("res://scenes/SettingsMenu.tscn").instance()
	get_parent().add_child(settings)
	settings.connect('closed',self,'show')

func exit():
	get_tree().change_scene("res://scenes/MainMenu.tscn")
	pass # Replace with function body.

