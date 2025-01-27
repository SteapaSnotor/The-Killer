extends Node2D

"""
	Control the tutorial in the first level
"""

signal next_step

const text_speed = 0.05

#world nodes
onready var text_box = $CanvasLayer/TextBox
onready var text_animation = $CanvasLayer/TextBox/Animation
onready var text = $CanvasLayer/TextBox/Label
onready var timer = $CanvasLayer/TutorialTimer
onready var infographics = $CanvasLayer/Infographic
onready var player_controller = get_parent().get_node('PlayerController')
onready var old_music_db = settings.music_db
onready var old_background_db = settings.background_db
onready var trail_positions = []

var current_step = 0
var current_text = 0
var _step_called = false
var _next_step_key = true
var is_tracks_paused = true
var lowered_sounds = false
var is_checking_lure = false
var is_checking_misc = false
var is_checking_hunter = false
var is_checking_startled = false
var is_checking_removed = false
var lure_trail = []
var misc_pos = null
var hunter_pos = null
var removed_name = null
var is_checking_hunter_state = false
var hunter_state = null
var is_finished = false

#shhh!
var _hidden_texts_id = 0

#the teens on game
var teens = []
var teen_state = null

#text on the textbox
var tutorial_text = {}

var steps = {
	0:{"methods":[funcref(self,'wait')],"params":[3]},
	1:{"methods":[funcref(self,'pause')],"params":[null]},
	2:{"methods":[funcref(self,'show_text')],"params":[true]},
	3:{"methods":[funcref(self,'next_text')],"params":[null]},
	4:{"methods":[funcref(self,'show_text')],"params":[true]},
	5:{"methods":[funcref(self,'next_text')],"params":[null]},
	6:{"methods":[funcref(self,'show_infographic')],"params":['Keys']},
	7:{"methods":[funcref(self,'show_text'),funcref(self,'check_keys')],"params":[false,'Keys']},
	8:{"methods":[funcref(self,'next_text')],"params":[null]},
	9:{"methods":[funcref(self,'hide_infographic')],"params":['Keys']},
	10:{"methods":[funcref(self,'show_infographic')],"params":['Keys2']},
	11:{"methods":[funcref(self,'show_text'),funcref(self,'check_camera_zoom')],"params":[false,Vector2(1,1)]},
	12:{"methods":[funcref(self,'hide_infographic')],"params":['Keys2']},
	13:{"methods":[funcref(self,'next_text')],"params":[null]},
	14:{"methods":[funcref(self,'show_text')],"params":[true]},
	15:{"methods":[funcref(self,'move_camera')],"params":[Vector2(621,100)]},
	16:{"methods":[funcref(self,'next_text')],"params":[null]},
	17:{"methods":[funcref(self,'show_text')],"params":[true]},
	18:{"methods":[funcref(self,'show_infographic')],"params":['HighLight']},
	19:{"methods":[funcref(self,'next_text')],"params":[null]},
	20:{"methods":[funcref(self,'show_text')],"params":[true]},
	21:{"methods":[funcref(self,'next_text')],"params":[null]},
	22:{"methods":[funcref(self,'show_text')],"params":[true]},
	23:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight']},
	24:{"methods":[funcref(self,'highlight_teen')],"params":['Teenager2']},
	25:{"methods":[funcref(self,'resume')],"params":[null]},
	26:{"methods":[funcref(self,'next_text')],"params":[null]},
	27:{"methods":[funcref(self,'show_text'),funcref(self,'check_teen_panel')],"params":[false,'Teenager2']},
	28:{"methods":[funcref(self,'remove_teen_highlight')],"params":['Teenager2']},
	29:{"methods":[funcref(self,'next_text')],"params":[null]},
	30:{"methods":[funcref(self,'show_text')],"params":[true]},
	31:{"methods":[funcref(self,'next_text')],"params":[null]},
	32:{"methods":[funcref(self,'show_text')],"params":[true]},
	33:{"methods":[funcref(self,'next_text')],"params":[null]},
	34:{"methods":[funcref(self,'show_text')],"params":[true]},
	35:{"methods":[funcref(self,'next_text')],"params":[null]},
	36:{"methods":[funcref(self,'show_text')],"params":[true]},
	37:{"methods":[funcref(self,'show_infographic')],"params":['HighLight3']},
	38:{"methods":[funcref(self,'move_text_box')],"params":[50]},
	39:{"methods":[funcref(self,'next_text')],"params":[null]},
	40:{"methods":[funcref(self,'show_text'),funcref(self,'check_speed')],"params":[false,0.1]},
	41:{"methods":[funcref(self,'move_text_box')],"params":[-50]},
	42:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight3']},
	43:{"methods":[funcref(self,'next_text')],"params":[null]},
	44:{"methods":[funcref(self,'show_text'),funcref(self,'check_teen_state')],"params":[false,'Fishing']},
	45:{"methods":[funcref(self,'change_game_speed')],"params":[1]},
	46:{"methods":[funcref(self,'next_text')],"params":[null]},
	47:{"methods":[funcref(self,'show_text')],"params":[true]},
	48:{"methods":[funcref(self,'show_infographic')],"params":['HighLight4']},
	49:{"methods":[funcref(self,'next_text')],"params":[null]},
	50:{"methods":[funcref(self,'show_text')],"params":[true]},
	51:{"methods":[funcref(self,'next_text')],"params":[null]},
	52:{"methods":[funcref(self,'show_text'),funcref(self,'check_ui_button')],"params":[false,'LureBtn']},
	53:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight4']},
	54:{"methods":[funcref(self,'show_infographic')],"params":['HighLight5']},
	55:{"methods":[funcref(self,'next_text')],"params":[null]},
	56:{"methods":[funcref(self,'show_text')],"params":[true]},
	57:{"methods":[funcref(self,'next_text')],"params":[null]},
	58:{"methods":[funcref(self,'show_text'),funcref(self,'check_ui_button')],"params":[false,'Slot1']},
	59:{"methods":[funcref(self,'highlight_map')],"params":[[Vector2(887, 787),Vector2(887, 737),
Vector2(912, 737),Vector2(887, 562),Vector2(887, 412),Vector2(687, 412),
Vector2(537, 412),Vector2(462, 287),Vector2(287, 362),Vector2(137, 462)]]},
	60:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight5']},
	61:{"methods":[funcref(self,'check_lure_is_placed')],"params":[[Vector2(887, 787),Vector2(887, 737),
Vector2(912, 737),Vector2(887, 562),Vector2(887, 412),Vector2(687, 412),
Vector2(537, 412),Vector2(462, 287),Vector2(287, 362),Vector2(137, 462)]]},
	62:{"methods":[funcref(self,'show_infographic')],"params":['HighLight6']},
	63:{"methods":[funcref(self,'remove_map_highlight')],"params":[null]},
	64:{"methods":[funcref(self,'move_text_box')],"params":[50]},
	65:{"methods":[funcref(self,'next_text')],"params":[null]},
	66:{"methods":[funcref(self,'show_text')],"params":[true]},
	67:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight6']},
	68:{"methods":[funcref(self,'next_text')],"params":[null]},
	69:{"methods":[funcref(self,'show_text')],"params":[true]},
	70:{"methods":[funcref(self,'show_infographic')],"params":['HighLight7']},
	71:{"methods":[funcref(self,'next_text')],"params":[null]},
	72:{"methods":[funcref(self,'show_text')],"params":[true]},
	73:{"methods":[funcref(self,'move_text_box')],"params":[-50]},
	74:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight7']},
	75:{"methods":[funcref(self,'show_infographic')],"params":['HighLight8']},
	76:{"methods":[funcref(self,'next_text')],"params":[null]},
	77:{"methods":[funcref(self,'show_text'),funcref(self,'check_ui_button')],"params":[false,'MiscBtn']},
	78:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight8']},
	79:{"methods":[funcref(self,'highlight_map')],"params":[[Vector2(112, 462)]]},
	80:{"methods":[funcref(self,'next_text')],"params":[null]},
	81:{"methods":[funcref(self,'show_text'),funcref(self,'check_misc_is_placed')],"params":[false,Vector2(112, 462)]},
	82:{"methods":[funcref(self,'remove_map_highlight')],"params":[null]},
	83:{"methods":[funcref(self,'pause')],"params":[null]},
	84:{"methods":[funcref(self,'next_text')],"params":[null]},
	85:{"methods":[funcref(self,'show_text')],"params":[true]},
	86:{"methods":[funcref(self,'show_infographic')],"params":['HighLight9']},
	87:{"methods":[funcref(self,'next_text')],"params":[null]},
	88:{"methods":[funcref(self,'show_text'),funcref(self,'check_ui_button')],"params":[false,'HuntBtn']},
	89:{"methods":[funcref(self,'move_camera')],"params":[Vector2(75,335)]},
	90:{"methods":[funcref(self,'highlight_map')],"params":[[Vector2(435, 335)]]},
	91:{"methods":[funcref(self,'next_text')],"params":[null]},
	92:{"methods":[funcref(self,'show_text'),funcref(self,'check_hunter_is_placed')],"params":[false,Vector2(435, 335)]},
	93:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight9']},
	94:{"methods":[funcref(self,'next_text')],"params":[null]},
	95:{"methods":[funcref(self,'show_text')],"params":[true]},
	96:{"methods":[funcref(self,'next_text')],"params":[null]},
	97:{"methods":[funcref(self,'show_text')],"params":[true]},
	98:{"methods":[funcref(self,'move_camera')],"params":[Vector2(730,779)]},
	99:{"methods":[funcref(self,'show_infographic')],"params":['HighLight10']},
	100:{"methods":[funcref(self,'next_text')],"params":[null]},
	101:{"methods":[funcref(self,'show_text'),funcref(self,'check_ui_button')],"params":[false,'BumpBtn']},
	102:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight10']},
	103:{"methods":[funcref(self,'resume')],"params":[null]},
	104:{"methods":[funcref(self,'highlight_map')],"params":[[Vector2(900,800)]]},
	105:{"methods":[funcref(self,'next_text')],"params":[null]},
	106:{"methods":[funcref(self,'show_text')],"params":[true]},
	107:{"methods":[funcref(self,'next_text')],"params":[null]},
	108:{"methods":[funcref(self,'show_text'),funcref(self,'check_teen_state')],"params":[false,'Lured']},
	109:{"methods":[funcref(self,'remove_map_highlight')],"params":[null]},
	110:{"methods":[funcref(self,'next_text')],"params":[null]},
	111:{"methods":[funcref(self,'show_text'),funcref(self,'check_teen_state')],"params":[false,'Panic']},
	112:{"methods":[funcref(self,'check_hunter_state')],"params":['EndingSpawn']},
	113:{"methods":[funcref(self,'pause')],"params":[null]},
	114:{"methods":[funcref(self,'next_text')],"params":[null]},
	115:{"methods":[funcref(self,'show_text'),funcref(self,'check_hunter_state')],"params":[false,'Attacking']},
	116:{"methods":[funcref(self,'resume')],"params":[null]},
	117:{"methods":[funcref(self,'check_teen_state')],"params":['Dead']},
	118:{"methods":[funcref(self,'move_text_box')],"params":[50]},
	119:{"methods":[funcref(self,'show_infographic')],"params":['HighLight12']},
	120:{"methods":[funcref(self,'next_text')],"params":[null]},
	121:{"methods":[funcref(self,'show_text')],"params":[true]},
	122:{"methods":[funcref(self,'move_text_box')],"params":[-50]},
	123:{"methods":[funcref(self,'hide_infographic')],"params":['HighLight12']},
	124:{"methods":[funcref(self,'next_text')],"params":[null]},
	125:{"methods":[funcref(self,'highlight_teen')],"params":['Teenager2']},
	126:{"methods":[funcref(self,'show_text')],"params":[true]},
	127:{"methods":[funcref(self,'next_text')],"params":[null]},
	128:{"methods":[funcref(self,'show_text')],"params":[true]},
	129:{"methods":[funcref(self,'next_text')],"params":[null]},
	130:{"methods":[funcref(self,'show_text'),funcref(self,'check_teen_is_removed')],"params":[false,'Teenager2']},
	131:{"methods":[funcref(self,'next_text')],"params":[null]},
	132:{"methods":[funcref(self,'show_text')],"params":[true]},
	133:{"methods":[funcref(self,'next_text')],"params":[null]},
	134:{"methods":[funcref(self,'show_text')],"params":[true]},
	135:{"methods":[funcref(self,'move_camera')],"params":[Vector2(681,118)]},
	136:{"methods":[funcref(self,'next_text')],"params":[null]},
	137:{"methods":[funcref(self,'show_text')],"params":[true]},
	138:{"methods":[funcref(self,'next_text')],"params":[null]},
	139:{"methods":[funcref(self,'show_text')],"params":[true]},
	140:{"methods":[funcref(self,'next_text')],"params":[null]},
	141:{"methods":[funcref(self,'show_text')],"params":[true]},
	142:{"methods":[funcref(self,'next_text')],"params":[null]},
	143:{"methods":[funcref(self,'show_text')],"params":[false]},
	#
}

#init tutotiral
func _ready():
	#load tutorial text
	var file = File.new()
	file.open("res://resources/json/tutorial_text.json",File.READ)
	var data = file.get_as_text()
	tutorial_text = parse_json(data)
	
	connect('next_step',self,'next_step')
	get_parent().connect('game_won',self,'tutorial_ended',[true])
	get_parent().connect('game_over',self,'tutorial_ended',[false])
	
	for teen in get_tree().get_nodes_in_group('AI'):
		teens.append(teen)
		

#execute the current function of the current step
func _process(delta):
	if is_finished:
		#the tutorial is over
		return
	
	if not _step_called:
		for method in range(steps[current_step]['methods'].size()):
			#the curret step wasn't called, call it now.
			if steps[current_step]['params'][method] != null:
				_step_called = true
				steps[current_step]['methods'][method].call_func(steps[current_step]['params'][method])
			else:
				_step_called = true
				steps[current_step]['methods'][method].call_func()
				
	####functions that don't use signals####
	if teen_state != null:
		check_teen_state(teen_state)
	if not lowered_sounds and text_box.is_visible():
		change_tracks_volume(false)
		lowered_sounds = true
	elif lowered_sounds and not text_box.is_visible():
		change_tracks_volume(true)
		lowered_sounds = false
	
	if is_checking_lure:
		check_lure_is_placed(lure_trail)
	elif is_checking_misc:
		check_misc_is_placed(misc_pos)
	elif is_checking_hunter:
		check_hunter_is_placed(hunter_pos)
	elif is_checking_hunter_state:
		check_hunter_state(hunter_state)
	elif is_checking_removed:
		check_teen_is_removed(removed_name)
	
	#####
	
	#on the tutorial the sounds/music still needs to play when the game
	#is paused.
	if get_parent().audio_system != null:
		if is_tracks_paused:
			resume_tracks()
			
	#prevent the player from changing the game speed too much
	if current_step >=50:
		if get_parent().timer_speed != 1:
			get_parent().ui.info_ui.normal_btn()

func _exit():
	#TODO: change pause system for tracks
	set_process(false)
	pass
	
#user input
func _input(event):
	if event.is_action_pressed("Space"):
		if text_box.is_visible() and text.get_visible_characters()>1:
			show_text(_next_step_key,true,true)

#show the current text at the text box
func show_text(next_step=true,_timer = false,foward = false):
	if not _timer:
		text_box.show()
		text.set_text(tutorial_text['Text'][str(current_text)])
		text.set_visible_characters(0)
		timer.wait_time = text_speed
		if not timer.is_connected('timeout',self,'show_text'):
			timer.connect('timeout',self,'show_text',[next_step,true])
		_next_step_key = next_step
		timer.start()
		#change_tracks_volume(-10)
	elif foward:
		#fast foward the text
		if text.get_visible_characters() != text.get_total_character_count():
			text.set_visible_characters(text.get_total_character_count()-1)
			text_animation.play('neutral')
		else:
			timer.disconnect('timeout',self,'show_text')
			text_box.hide()
			text.set_visible_characters(0)
			if next_step:
				emit_signal("next_step")
			#change_tracks_volume(10)
			
	else:
		timer.stop()
		text.set_visible_characters(text.get_visible_characters()+1)
		if text.get_visible_characters() == text.get_total_character_count():
			text_animation.play('neutral')
		else:
			if text_animation.get_animation() != 'talking':
				text_animation.play('talking')
			timer.start()

#pause game
func pause():
	#prevent the the screen to be stuck
	player_controller._scroll_left = false
	player_controller._scroll_right = false
	player_controller._scroll_up = false
	player_controller._scroll_down = false
	player_controller._scroller_timer = false
	get_tree().paused = true
	emit_signal("next_step")

#resume game
func resume():
	get_tree().paused = false
	emit_signal("next_step")

#advance the tutorial foward
func next_step():
	current_step += 1
	_step_called = false

#advance on the next text
func next_text():
	current_text += 1
	emit_signal("next_step")

func previous_text():
	current_text -= 1

#wait a given amount of time before going to the next step
func wait(time,_signal = false):
	if not _signal:
		timer.wait_time = time
		timer.connect('timeout',self,'wait',[time,true])
		timer.start()
	else:
		timer.disconnect('timeout',self,'wait')
		emit_signal("next_step")

#show animations from the tutorial
func show_infographic(spr,pos=null):
	infographics.get_node(spr).show()
	emit_signal("next_step")

func hide_infographic(spr):
	infographics.get_node(spr).hide()
	emit_signal("next_step")

#hight a given teen
func highlight_teen(teen_name):
	for teen in teens:
		if teen.name == teen_name:
			var highlight = $CanvasLayer/Infographic/HighLight2.duplicate()
			teen.add_child(highlight)
			highlight.show()
			
			#var teen_pos = teen.get_global_transform_with_canvas()
			#teen_pos = teen_pos.origin
			
			#$CanvasLayer/Infographic/HighLight2.show()
			#$CanvasLayer/Infographic/HighLight2.global_position = teen_pos
			break
	emit_signal("next_step")

func remove_teen_highlight(teen_name):
	for teen in teens:
		if teen.name == teen_name:
			teen.get_node('HighLight2').call_deferred('free')
			break
	emit_signal("next_step")

#check if all the given keys are pressed before going to the next step.
#also change their textures when pressed.
func check_keys(keys,_signal = null):
	if _signal == null:
		for key in infographics.get_node(keys).get_children():
			if key is TextureButton:
				key.connect('pressed',self,'check_keys',[keys,key])
	else:
		var btn = _signal
		btn.disconnect('pressed',self,'check_keys')
		btn.texture_normal = btn.texture_pressed
		btn.disabled = true
		
		#check if he pressed enough buttons
		var pressed_btns = 0
		for key in infographics.get_node(keys).get_children():
			if key is TextureButton:
				if key.disabled:
					pressed_btns += 1
		
		if keys == 'Keys' and pressed_btns >=4:
			#pressed enough buttons here, next step
			if text_box.is_visible():
				show_text(_next_step_key,true,true)
				text_box.hide()
				emit_signal("next_step")
				if timer.is_connected('timeout',self,'show_text'):
					timer.disconnect('timeout',self,'show_text')
			else:
				emit_signal("next_step")

#advance to the next step once the time speed is 
func check_speed(speed,_signal=false):
	var game = get_parent()
	if not _signal:
		if common.is_float_equal(speed,game.timer_speed):
			emit_signal("next_step")
			return
		
		game.connect('speed_changed',self,'check_speed',[speed,true])
	else:
		if common.is_float_equal(speed,game.timer_speed):
			emit_signal("next_step")
			game.disconnect('speed_changed',self,'check_speed')

#check if a any teenager is on a given state. If so, advance one step.
func check_teen_state(state):
	for teen in teens:
		if teen.state_machine.get_current_state() == state:
			teen_state = null
			
			#state detected, next step
			if text_box.is_visible():
				show_text(_next_step_key,true,true)
				text_box.hide()
				emit_signal("next_step")
				if timer.is_connected('timeout',self,'show_text'):
					timer.disconnect('timeout',self,'show_text')
			else:
				emit_signal("next_step")
			
			return
	
	teen_state = state
	
#if the hunter is on a given state, go to the next step
func check_hunter_state(state):
	is_checking_hunter_state = true
	hunter_state = state
	var hunter = get_tree().get_nodes_in_group('Player')
	if hunter == []:
		return
		
	hunter = hunter[0]
	
	if hunter.state_machine.get_current_state() == state:
		is_checking_hunter_state = false
		emit_signal("next_step")
	

#check if the camera's zoom level is different from 'zoom'
func check_camera_zoom(zoom,_signal = false):
	if not _signal:
		player_controller.connect("changed_zoom",self,"check_camera_zoom",[zoom,true])
	else:
		if player_controller.camera.get_zoom() != zoom:
			player_controller.disconnect("changed_zoom",self,"check_camera_zoom")
			if text_box.is_visible():
				show_text(_next_step_key,true,true)
				text_box.hide()
				emit_signal("next_step")
				if timer.is_connected('timeout',self,'show_text'):
					timer.disconnect('timeout',self,'show_text')
			else:
				emit_signal("next_step")
			
			#emit_signal("next_step")

#check if a button has been pressed, if so go to the next step
func check_ui_button(_btn,_signal = false):
	if not _signal:
		if get_tree().get_nodes_in_group('Lure').size() > 0:
			#workaround for my lazyness
			if current_step == 58:
				emit_signal("next_step")
				return 
		
		for btn in get_parent().ui.get_buttons():
			if btn.name == _btn:
				btn.connect('pressed',self,'check_ui_button',[btn,true])
				break
	else:
		_btn.disconnect('pressed',self,'check_ui_button')
		#emit_signal("next_step")

		emit_signal("next_step")

#move the camera to a given position
func move_camera(to,_signal = false):
	#reset zooms
	player_controller.camera.set_zoom(Vector2(1,1))
	if not _signal:
		player_controller.travel_camera_to(to)
		player_controller.connect("travel_finished",self,"move_camera",[to,true])
	else:
		player_controller.disconnect("travel_finished",self,"move_camera")
		emit_signal("next_step")

#go to the next step when a given teen panel is open
func check_teen_panel(teen_name,_signal = false,btn = null):
	if not _signal:
		for teen in teens:
			if teen.name == teen_name:
				var b = teen.get_node('TeenagerButton')
				b.connect('pressed',self,'check_teen_panel',[teen_name,true,b])
				
				break
	else:
		btn.disconnect('pressed',self,'check_teen_panel')
		emit_signal("next_step")
			
#move the text box along the y axis
func move_text_box(y_pos):
	text_box.global_position.y += y_pos
	emit_signal("next_step")


func pause_tracks():
	for track in get_parent().audio_system.get_tracks():
		track.set_pause_mode(PAUSE_MODE_INHERIT)
	
	is_tracks_paused = true

func resume_tracks():
	for track in get_parent().audio_system.get_tracks():
		track.set_pause_mode(PAUSE_MODE_PROCESS)
	
	is_tracks_paused = false

#lower the volume of all tracks for better atmosphere
func change_tracks_volume(increase=true):
	if increase:
		settings.set_background_db(old_background_db)
		settings.set_music_db(old_music_db)
	else:
		settings.set_background_db(-5)
		settings.set_music_db(-20)

#change the current game speed
func change_game_speed(speed):
	var game = get_parent()
	game.ui.info_ui.normal_btn()
	emit_signal("next_step")

#create highlights on the map
func highlight_map(positions):
	for pos in positions:
		var spr = Sprite.new()
		spr.texture = preload("res://sprites/tutorial/trail.png")
		spr.global_position = pos
		spr.add_to_group('_highlightTutorial')
		if current_step == 90:
			spr.set_z_index(2)
		else:
			spr.set_z_index(1)
		get_parent().add_child(spr)
	
	emit_signal("next_step")

#remove highlights from the map
func remove_map_highlight():
	for highlight in get_tree().get_nodes_in_group('_highlightTutorial'):
		highlight.call_deferred('free')
	
	emit_signal("next_step")

#check if a lure trap is placed on the given trail
func check_lure_is_placed(trail):
	lure_trail = trail
	
	for lure in get_tree().get_nodes_in_group('Lure'):
		if lure.is_placed:
			if lure.id != 0:
				#he put the wrong trap..
				lure.call_deferred('free')
				get_parent().points = 10000
				break
			#check if he put the lure in the right spot
			var is_right = true
			for point in lure.trail:
				if lure_trail.find(point) == -1:
					is_right = false
			
			if is_right:
				is_checking_lure = false
				emit_signal("next_step")
				return
			else:
				#easter egg here
				get_parent().points += 1500
				var _hidden_texts = ["You put the trap on the wrong spot. Put it exactly where I highlighted on the map.",
				"Calm down boss, I know you are an experienced director, but I'm asking you to please put the trap where I highlighted on the scenery.",
				"Listen to me dude, I highlighted the spots where you should put the lure in yellow. JUST PUT IT IN THERE.",
				"You put the trail in the wrong spot again...","Really? What's wrong with you?","Are you serious?",
				"...","Enough! Put the trap on the wrong spot again and you will receive a surprise.",
				"Here goes, now everyone on Newgrounds will know how stubborn you are haha, idiot."] 
				
				if _hidden_texts_id < _hidden_texts.size():
					text_box.hide()
					text.text = _hidden_texts[_hidden_texts_id] 
					text.set_visible_characters(0)
					timer.connect('timeout',self,'show_text',[false,true])
					timer.start()
					text_box.show()
					
					if _hidden_texts_id == _hidden_texts.size() -1:
						print('give him a special achievement')
						var api = get_parent().get_node('NewGroundsAPI')
						medals.unlock(58132,api)
						get_parent().ui.achievement.play_achievement(58132)
					
					_hidden_texts_id += 1
				lure.call_deferred('free')
				break
	
	is_checking_lure = true

#check if a misc trap is placed on the given trail
func check_misc_is_placed(pos):
	misc_pos = pos
	
	for misc in get_tree().get_nodes_in_group('Misc'):
		if misc.is_placed:
			if misc.id != 3:
				#he put the wrong trap..
				misc.call_deferred('free')
				get_parent().points = 10000
				break
			#check if he put the misc in the right spot
			if misc.current_texture.global_position == pos:
				emit_signal("next_step")
				is_checking_misc = false
				return
	
	is_checking_misc = true

#check if the hunter is set to be spawn on the right location
func check_hunter_is_placed(pos):
	is_checking_hunter = true
	hunter_pos = pos
	var hunter = get_tree().get_nodes_in_group("Player")
	
	if hunter == []:
		return
	
	hunter = hunter[0]
	
	if hunter.state_machine.get_node('Deployment').is_spawn_set:
		if hunter.global_position == pos:
			is_checking_hunter = false
			emit_signal("next_step")
			return

#check if a given teen has been removed from the game
func check_teen_is_removed(teen_name):
	is_checking_removed = true
	removed_name = teen_name
	
	var teens = get_parent().get_node('AI')
	
	if not teens.has_node(teen_name):
		is_checking_removed  = false
		emit_signal("next_step")

#when the tutorial is over
func tutorial_ended(won):
	settings.set_background_db(old_background_db)
	settings.set_music_db(old_music_db)
	pause_tracks()
	
	if won:
		current_text = 45
		show_text(false)
	else:
		current_text = 46
		show_text(false)










