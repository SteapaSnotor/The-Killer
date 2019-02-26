extends Control

"""
	This UI element will show some of the teenager information.
"""

var base = null
var selected_teenager = null
#TODO: make this panel movable
#TODO: a line going from the panel to the selected teenager

#initialize
func init(base):
	self.base = base
	
	#connect teenagers selection signal
	for teenager_btn in base.get_teenagers_buttons():
		teenager_btn.connect("pressed",self,"show_panel",[teenager_btn.get_parent().get_parent()])
	
#update teenager information
func _process(delta):
	if selected_teenager == null:
		set_process(false)
		return
		
	#update teenagers info
	$Panel/Gender.text = str(selected_teenager.get_gender())
	$Panel/Fear.text = "FEAR: " + str(selected_teenager.get_fear())
	$Panel/Curiosity.text = "CURIOSITY: " + str(selected_teenager.get_curiosity())
	
	#drawing function
	update()
	
#show the panel with the information for one teenager
func show_panel(teenager):
	$Panel.show()
	selected_teenager = teenager
	set_process(true)

#hide the panel
func hide_panel():
	$Panel.hide()
	selected_teenager = null
	update()

func _draw():
	if selected_teenager != null:
		#draw a line from the panel to the teenager position
		var camera = base.get_parent().get_player_controller().camera.global_position
		var teenager_pos = selected_teenager.get_position() - camera
		#no idea why the player position has a wrong offset
		#I will fix it here.
		teenager_pos.y+=90
		teenager_pos.x-=20
		
		draw_line(teenager_pos,$Panel.rect_global_position,Color.red)
	






