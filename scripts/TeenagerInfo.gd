extends Control

"""
	This UI element will show some of the teenager information.
"""

var base = null
var selected_teenager = null
var _is_mouse_over = false
var _mouse_click_pos = Vector2(-666,-666)

onready var _panel_default_position = $Panel.rect_global_position

#initialize
func init(base):
	self.base = base
	
	#connect teenagers selection signal
	for teenager_btn in base.get_teenagers_buttons():
		teenager_btn.connect("pressed",self,"show_panel",[teenager_btn.get_parent()])
	
#update teenager information
func _process(delta):
	if selected_teenager == null:
		set_process(false)
		return
		
	#update teenagers info
	$Panel/Gender.text = str(selected_teenager.get_gender())
	$Panel/Fear.text = "FEAR: " + str(int(selected_teenager.get_fear()))
	$Panel/Curiosity.text = "CURIOSITY: " + str(int(selected_teenager.get_curiosity()))
	$Panel/Traps.text = "TRAPS: " + str(selected_teenager.traps.size())
	$Panel/TrapsID.text = "TRAP ID: " + str(selected_teenager.current_trap)
	
	#drag the panel
	if _is_mouse_over and _mouse_click_pos != Vector2(-666,-666):
		var new_pos = Vector2(get_global_mouse_position().x-$Panel.get_rect().size.x/2,
		get_global_mouse_position().y-$Panel.get_rect().size.y/2)
		$Panel.rect_global_position = new_pos
	
	#drawing function
	update()

#select/release the panel
func _input(event):
	if Input.is_action_just_pressed("ok_input") and _mouse_click_pos == Vector2(-666,-666):
		_mouse_click_pos = get_global_mouse_position()
	if Input.is_action_just_released("ok_input"):
		_mouse_click_pos = Vector2(-666,-666)

#show the panel with the information for one teenager
func show_panel(teenager):
	if base.game.get_current_mode() == base.game.MODE.HUNTING:
		return
	
	$Panel.show()
	selected_teenager = teenager
	set_process(true)

#hide the panel
func hide_panel():
	$Panel.hide()
	$Panel.rect_global_position = _panel_default_position
	selected_teenager = null
	update()

func _draw():
	if selected_teenager != null:
		#draw a line from the panel to the teenager position
		var camera_node = base.get_parent().get_player_controller().camera
		var camera = camera_node.global_position
		var teenager_pos = selected_teenager.get_position() - camera
		#no idea why the player position has a wrong offset
		#I will fix it here.
		teenager_pos.y+=90
		teenager_pos.x-=20
		
		##TODO: correct the offset created by zooming the camera##
		
		draw_line(teenager_pos,$Panel.rect_global_position,Color.red)
	
func mouse_entered():
	_is_mouse_over = true

func mouse_exited():
	_is_mouse_over = false
	_mouse_click_pos = Vector2(-666,-666)
