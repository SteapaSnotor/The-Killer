#tool
extends Node2D
"""
	Control several aspects of the gameplay.
	Things like game over events, points distribution, world information etc...
"""

#the game has been loaded
signal loaded
signal game_over
signal game_over_music
signal game_won
signal game_won_music
signal changed_points
signal speed_changed

enum MODE {
	PLANNING,
	HUNTING,
	PAUSED,
	GAMEOVER,
	WON
}

#the speed the timer will update the time (in seconds).
const default_speed = 1
const fast_speed = 0.2
const ultra_speed = 0.1
const debug_speed = 0.04

#fixed costs in the game
const body_recovery_cost = 30

#the maximum value the tiredness modifier can hold
const max_tiredness = 6

#the amount of time the player needs to rest to lose 1 tiredness point
const resting_time = 7

var current_mode = MODE.PLANNING setget set_current_mode, get_current_mode
var last_mode = MODE.PLANNING

#the time in-game stored in minutes. 
export var time = 0 setget set_time, get_time
#points to spend on this level buying traps
export var points = 0 setget set_points, get_points
#enable/disable the debug mode
export var debug_mode = false
#the interval between killing the player should stay if he wants 
#a score of 100% on the 'killing score'.
export var perfect_killing_interval = 10

#Default: 1 minute in-game = 1 second.
var timer_speed = default_speed
var ai_timer_speed = default_speed
var previous_time_speed = default_speed

#traps on this level
var traps_data = {}

#used to keep track of teenagers speed when changing the game speed.
var teens_speed = {}

#the initial number of teens in game
var teen_num = 0 setget , get_teenagers_num
#number of teenagers that already died
var teen_dead_num = 0 setget set_teen_dead_num

#if theres light in the buildings on the game.
var has_light = true

#it will increase each time the player spawns, and decreases as he's out
#of the hunting mode.
var player_tiredness = 0

#user interface
onready var ui = $GameUI
#types of traps
onready var trap_enum = preload("res://scripts/Traps.gd").TYPES
#color for the day/night cycle
onready var canvas_m = get_node("Lights'Shadows/CanvasModulate")
#audio system, it plays music and sound effects.
onready var audio_system = $Audio
#2d lights
onready var lights = $Lights

#INITIALIZE
func _ready():
	#A* pathfinding
	star.init($Tiles/Path,Vector2(25,25),false)
	randomize()
	#loads traps information for this level
	load_trap_info()
	#start timer
	init_timer()
	#initialze the ai
	init_teenagers()
	#initialize score
	init_score()
	#initialize medals
	if not medals.checked_medals: medals.check_medals($NewGroundsAPI)
	teen_num = get_teenagers().size()
	connect("game_won",self,"set_current_mode",[MODE.WON])
	emit_signal("loaded")
	

#day/night cycle
func _process(delta):
	daynightcycle()
	update_ambience()
	check_medals()
	
	if debug_mode:
		#helps when listening to music while programming
		settings.background_db = -100
		settings.music_db = -100
		settings.sound_db = -100
	
#return all the teenagers in the game
func get_teenagers():
	return get_tree().get_nodes_in_group("AI")

#the number of teenagers when the gamed did start
func get_teenagers_num():
	return teen_num

#return all teens that still alive
func get_teenagers_alive():
	var teens = []
	for teen in get_teenagers():
		if teen.state_machine.get_current_state() != 'Dead':
			teens.append(teen)
	
	return teens

#return all teenagers that have a given trait
func get_teenagers_by_trait(trait):
	var teenagers = get_teenagers()
	if teenagers == []: return teenagers
	var teenagers_by_trait = []
	
	var traits_enum = teenagers[0].TRAITS
	
	for teen in teenagers:
		if teen.traits.keys().find(trait) != -1:
			teenagers_by_trait.append(teen)
	
	return teenagers_by_trait

#get the player if the game is on the hunting mode
func get_player():
	if get_tree().get_nodes_in_group("Player").size() != 0:
		return $AI.get_node("PlayerHunter")
	else:
		return null

#return the current player controller
func get_player_controller():
	return get_node("PlayerController")
	
#get the closest tile from 'pos' in a given 'tileset'.
#if the closest tile is higher than limit, then it will return pos.
func get_closest_tile(tilemap,pos,limit=100):
	var map_tiles = tilemap.get_used_cells()
	var world_tiles = []
	var distance = [] 
	var closest = pos
	
	#convert all tiles map positions their positions in the real world
	for tile in map_tiles:
		world_tiles.append(tilemap.map_to_world(tile))
		
	#get the distance from 'pos' for each tile
	for tile in world_tiles:
		distance.append(tile.distance_to(pos))
	distance.sort()
	
	#if the distance is less than the limit, return the closest tile
	if distance.front() < limit:
		for tile in world_tiles:
			if tile.distance_to(pos) == distance.front():
				closest = tile
				break
	
	return closest
	
#like get_closest_tile but only search for tiles of a given id
func get_closest_tile_by_id(tilemap,pos,id,limit=100):
	var map_tiles = tilemap.get_used_cells_by_id(id)
	var world_tiles = []
	var distance = [] 
	var closest = pos
	
	#convert all tiles map positions their positions in the real world
	for tile in map_tiles:
		world_tiles.append(tilemap.map_to_world(tile))
		
	#get the distance from 'pos' for each tile
	for tile in world_tiles:
		distance.append(tile.distance_to(pos))
	distance.sort()
	
	#if the distance is less than the limit, return the closest tile
	if distance.front() < limit:
		for tile in world_tiles:
			if tile.distance_to(pos) == distance.front():
				closest = tile
				break
	
	return closest


#return the tilemap of containing floor tiles. It's used by traps.
func get_floor_tile():
	return $Tiles/Path
	#return $Tiles/Floor

#return walls of buildings in the map
func get_wall_tile():
	#TODO: this will also return some floor tiles, change this later...
	return $Tiles/Buildings

#return the closest point on the map where the ai can get nasty
func get_love_point(teen_pos):
	var points = common.convert_to_world($Tiles/LovePoints.get_used_cells(),$Tiles/LovePoints)
	points = common.order_by_distance(points,teen_pos)
	return points.front()

#returns a bathroom object that is empty
func get_free_bathroom():
	var objects = get_tree().get_nodes_in_group('Object')
	var bathrooms = []
	
	for object in objects:
		if object.type == object.TYPE.BATHROOM and object.current_teen == []:
			return object
		elif object.type == object.TYPE.BATHROOM:
			bathrooms.append(object)
	
	#no free bathrooms? returns one anyway
	return bathrooms[0]
	

#return all the objects in the game
func get_world_objects():
	return get_tree().get_nodes_in_group('Object')

#returns the tilemap for the pathfinding algorithm
func get_pathfinding_tile():
	return $Tiles/Path

#return the tile that is responsible for checking if things 
#are inside/outside a building.
func get_indoor_detection():
	return $Tiles/IndoorDetection

#return the tilemap with the points where the AI can barricade himself.
func get_barricading_points():
	return $Tiles/BarricadingPoints

#return all doors in game
func get_doors():
	var objects = get_tree().get_nodes_in_group('Object')
	var doors = []
	
	for door in objects:
		if door.type == door.TYPE.DOOR:
			doors.append(door)
	
	return doors

#returns the tilemap that shows the location where player can spawn
func get_spawn_points():
	return $Tiles/SpawnPoints

#change the current game mode
func set_current_mode(value):
	if current_mode != MODE.GAMEOVER:
		current_mode = value
	
	match current_mode:
		MODE.HUNTING:
			disable_spawn_points()
			ui.info_ui.normal_btn()
			ui.lock()
			if player_tiredness < max_tiredness:
				set_player_tiredness(player_tiredness + 2)
		MODE.PLANNING:
			ui.unlock()
			ui.info_ui.normal_btn()
		MODE.GAMEOVER:
			ui.lock()
			disable_spawn_points()
			emit_signal("game_over")
			var player = get_player()
			if player != null:player.queue_free()
			get_player_controller().lock()
			var cam_pos = get_escaped_teens()[0].global_position
			cam_pos.x -= 320
			cam_pos.y -= 100
			get_player_controller().connect('travel_finished',get_player_controller(),'zoom_camera',[Vector2(-0.2,-0.2)])
			get_player_controller().travel_camera_to(cam_pos,500)
		MODE.WON:
			ui.lock()
			disable_spawn_points()
			var player = get_player()
			if player != null:player.queue_free()
		_:
			#the game is paused...
			pass
	
func get_current_mode():
	return current_mode

#the closest escape point from a teenager
func get_escaping_point(teen_pos):
	var points = common.convert_to_world($Tiles/ExitPoints.get_used_cells(),$Tiles/ExitPoints)
	points = common.order_by_distance(points,teen_pos)
	return points.front()

#return the closest escape object from a teen. Escape objects are things
#like cars, boats etc...
func get_escape_object(teen_pos):
	var objects = get_tree().get_nodes_in_group('Object')
	var escape_objects = {}
	
	for object in objects:
		match object.type:
			object.TYPE.CAR:
				escape_objects[object.global_position] = object
			_:
				continue
	
	objects = common.order_by_distance(escape_objects.keys(),teen_pos)
	return escape_objects[objects.front()]

#get traps that are placed on the map
func get_placed_traps():
	var traps = get_tree().get_nodes_in_group("Misc")
	traps = traps + get_tree().get_nodes_in_group("Vice")
	#traps = traps + get_tree().get_nodes_in_group("Lure")
	
	return traps

#will return an array containing teens on escaped state
func get_escaped_teens():
	var teenagers = []
	for teen in get_teenagers():
		if teen.state_machine.get_current_state() == 'Escaped':
			teenagers.append(teen)
			
	return teenagers

#return true when is night or false when is daylight
func is_night():
	if time/60 > 6 and time/60 < 19:
		return false
	else:
		return true

#update the number of teens that died and check for winning conditions
func set_teen_dead_num(value):
	teen_dead_num = value
	
	#all teens are dead, the player won.
	if teen_dead_num == teen_num:
		emit_signal("game_won")

func set_player_tiredness(value,_signal = false):
	if value != -1: player_tiredness = value
	
	if not _signal:
		if not has_node('RestingTimer'):
			#create a timer that will decrease the player tiredness
			var resting_timer = preload("res://scenes/CustomTimer.tscn").instance()
			add_child(resting_timer)
			resting_timer.name = 'RestingTimer'
			resting_timer.stop()
			resting_timer.connect('timeout',self,'set_player_tiredness',[-1,true])
			resting_timer.wait_time = resting_time
			resting_timer.start()
	else:
		if player_tiredness != 0:
			if get_current_mode() == MODE.PLANNING:
				player_tiredness -= 1
		else:
			get_node('RestingTimer').stop()
			get_node('RestingTimer').queue_free()

#show all the spawn points and return an array containing their position
func enable_spawn_points():
	var spawn = $Tiles/SpawnPoints
	
	spawn.show()
	
	var positions = []
	
	for tile in spawn.get_used_cells():
		positions.append(spawn.map_to_world(tile))
		
	return positions

func disable_spawn_points():
	$Tiles/SpawnPoints.hide()

#get current level path
func get_level():
	return self.filename

#return the traps (for this level) of a given type
func get_traps(type):
	return traps_data[type]

#starts the in-game timer
func init_timer():
	$GameTimer.set_wait_time(timer_speed) #1 minute per second
	$GameTimer.connect("timeout",self,"set_time",[1])
	$GameTimer.start()

#will initialize the AI in game
func init_teenagers():
	for teen in get_teenagers():
		#signals
		teen.connect("recover_teen",self,"transform_teen",[teen])

#initialized the game score
func init_score():
	score.set_killing_score(get_level(),0)
	score.set_score(get_level(),0)

#transform the teen into a misc trap
func transform_teen(teen):
	#the number of death traps this teen will generate (randomly). MAX:3
	var parts = int(rand_range(1,4))
	var parts_textures = [teen.death_trap1,teen.death_trap2,
	teen.death_trap3]
	var text_id = 0
	
	for trap in parts:
		#transform the teen in a death trap and add it to the misc category
		#this dictionary goes to the new trap
		var death_data = {'Anim1':parts_textures[text_id]}
		
		#assign new data
		traps_data[trap_enum.MISC]['ID'].append(traps_data[trap_enum.MISC]['ID'].size())
		traps_data[trap_enum.MISC]['Icon'].append(teen.death_icon.get_path().get_file())
		traps_data[trap_enum.MISC]['Fear'].append(100)
		traps_data[trap_enum.MISC]['Curiosity'].append(0)
		traps_data[trap_enum.MISC]['Price'].append(0)
		traps_data[trap_enum.MISC]['OneShot'].append(false)
		traps_data[trap_enum.MISC]['Requirements'].append(["NULL"])
		traps_data[trap_enum.MISC]['OnSpot'].append(false)
		traps_data[trap_enum.MISC]['Walkable'].append(false)
		traps_data[trap_enum.MISC]['Name'].append("Remains")
		traps_data[trap_enum.MISC]['Desc'].append("The remains of this poor bastard.")
		traps_data[trap_enum.MISC]['Sound'].append("NULL")
		traps_data[trap_enum.MISC]['DeathTrap'].append(death_data)
		traps_data[trap_enum.MISC]['Placement'].append(get_floor_tile())
		
		text_id += 1
		
	#ui animation
	ui.play_death_trap_anim(teen.get_dead_teen_texture(),teen.get_global_transform_with_canvas())
	teen.call_deferred('free')

#this will remove the last death trap added to the game from the player's
#avaialble traps. 
func remove_death_trap(data):
	var id = 0
	for value in traps_data[trap_enum.MISC]['DeathTrap']:
		if value == data:
			break
		else: id += 1 
		
	for value in traps_data[trap_enum.MISC]:
		traps_data[trap_enum.MISC][value].remove(id)
	
	#reassign ids
	for value in range(traps_data[trap_enum.MISC]['ID'].size()):
		if traps_data[trap_enum.MISC]['ID'][value] > id:
			traps_data[trap_enum.MISC]['ID'][value] -= 1
	
	#for value in traps_data[trap_enum.MISC]:
	#	traps_data[trap_enum.MISC][value].pop_back()
	#	pass

#loads data from all traps available in this level
func load_trap_info():
	var traps = {} #traps.json 
	var traps_in_level = {} #traps_by_level.json
	
	#dictionary structury
	traps_data = {
	trap_enum.BUMP:{"ID":[],"Icon":[],"Fear":[],"Curiosity":[],"Price":[],"Requirements":[],"OneShot":[],"OnSpot":[],"Walkable":[],"Name":[],"Desc":[],"Placement":[],"Sound":[]},
	trap_enum.LURE:{"ID":[],"Icon":[],"Fear":[],"Curiosity":[],"Price":[],"Requirements":[],"OneShot":[],"OnSpot":[],"Walkable":[],"Name":[],"Desc":[],"Placement":[],"Sound":[]},
	trap_enum.MISC:{"ID":[],"Icon":[],"Fear":[],"Curiosity":[],"Price":[],"Requirements":[],"OneShot":[],"OnSpot":[],"Walkable":[],"Name":[],"Desc":[],"DeathTrap":[],"Placement":[],"Sound":[]},
	trap_enum.VICE:{"ID":[],"Icon":[],"Fear":[],"Curiosity":[],"Price":[],"Requirements":[],"OneShot":[],"OnSpot":[],"Walkable":[],"Name":[],"Desc":[],"Placement":[],"Sound":[]
	}
	}
	#all traps
	var file = File.new()
	file.open("res://resources/json/traps.json",File.READ)
	traps = file.get_as_text()
	file.close()
	traps = parse_json(traps)
	
	#traps in this level
	file.open("res://resources/json/traps_by_level.json",File.READ)
	traps_in_level = file.get_as_text()
	file.close()
	traps_in_level = parse_json(traps_in_level)
	
	#assign the traps for this level to the dictionary
	for type in traps_in_level['Traps'][get_level()]:
		if traps_in_level['Traps'][get_level()][type].size()>= 1:
			for trap in traps_in_level['Traps'][get_level()][type]:
				
				#trap data
				var _type = type 
				var id = int(trap)
				var icon = traps['Traps'][type]['Icon'][id]
				var fear = int(traps['Traps'][type]['Fear'][id])
				var curiosity = int(traps['Traps'][type]['Curiosity'][id])
				var price = int(traps['Traps'][type]['Price'][id])
				var requirements = traps['Traps'][type]['Requirements'][id]
				var oneshot = common.string_to_boolean(traps['Traps'][type]['OneShot'][id])
				var onspot = common.string_to_boolean(traps['Traps'][type]['OnSpot'][id])
				var walkable = common.string_to_boolean(traps['Traps'][type]['Walkable'][id])
				var _name = str(traps['Traps'][type]['Name'][id])
				var description = str(traps['Traps'][type]['Desc'][id])
				var placement = str(traps['Traps'][type]['Placement'][id])
				var sound = str(traps['Traps'][type]['Sound'][id])
				
				#change the trap type to an enum
				match type:
					"BUMP":
							_type = trap_enum.BUMP
					"LURE":
							_type = trap_enum.LURE
					"MISC":
							_type = trap_enum.MISC
					"VICE":
							_type = trap_enum.VICE
					_:
							_type = trap_enum.NULL
							
				
				#assign where this trap should be placed
				match placement:
					"WORLD":
						placement = get_floor_tile()
					"WALLS":
						placement = get_wall_tile()
				
				if id > traps_data[_type]['ID'].size():
					#the trap mus be inserted at the same positions of its
					#id. If that can't be done, fill the array with trash
					#until theres room to be inserted.
					for trash in range(id - traps_data[_type]['ID'].size()):
						traps_data[_type]['ID'].append(-666)
						traps_data[_type]['Icon'].append(icon)
						traps_data[_type]['Fear'].append(fear)
						traps_data[_type]['Curiosity'].append(curiosity)
						traps_data[_type]['Price'].append(price)
						traps_data[_type]['OneShot'].append(oneshot)
						traps_data[_type]['Requirements'].append(requirements)
						traps_data[_type]['OnSpot'].append(onspot)
						traps_data[_type]['Walkable'].append(walkable)
						traps_data[_type]['Name'].append(_name)
						traps_data[_type]['Desc'].append(description)
						traps_data[_type]['Placement'].append(placement)
						traps_data[_type]['Sound'].append(sound)
						
						if _type == trap_enum.MISC:
							traps_data[_type]['DeathTrap'].append(null)
				
				
				#assign data
				traps_data[_type]['ID'].insert(id,id)
				traps_data[_type]['Icon'].insert(id,icon)
				traps_data[_type]['Fear'].insert(id,fear)
				traps_data[_type]['Curiosity'].insert(id,curiosity)
				traps_data[_type]['Price'].insert(id,price)
				traps_data[_type]['OneShot'].insert(id,oneshot)
				traps_data[_type]['Requirements'].insert(id,requirements)
				traps_data[_type]['OnSpot'].insert(id,onspot)
				traps_data[_type]['Walkable'].insert(id,walkable)
				traps_data[_type]['Name'].insert(id,_name)
				traps_data[_type]['Desc'].insert(id,description)
				traps_data[_type]['Placement'].insert(id,placement)
				traps_data[_type]['Sound'].insert(id,sound)
				
				#misc traps have a special property
				if _type == trap_enum.MISC:
					traps_data[_type]['DeathTrap'].insert(id,null)
				
				
#change the current timer speed in seconds
func update_time_speed(value):
	$GameTimer.stop()
	$GameTimer.set_wait_time(value)
	previous_time_speed = timer_speed
	timer_speed = value
	$GameTimer.start()
	update_game_speed()
	emit_signal("speed_changed")
	

#update the speed of several things in-game. Timers, K-bodies etc...
func update_game_speed():
	var teenagers = get_tree().get_nodes_in_group("AI")
	##Teenagers speed##
	for teen in teenagers:
		var base_spd = teen.base_speed
		var new_speed = base_spd
		var anim_speed = 1
		#increase/decrease the speed of the teen according to the timer's
		#speed.
		match timer_speed:
			default_speed:
				anim_speed = 1
				ai_timer_speed = 1
				
				match previous_time_speed:
					fast_speed:
						new_speed = new_speed * -1
					ultra_speed:
						new_speed = ((new_speed * 3.5) - base_spd) * -1
					_:
						#the game was paused, do nothing
						new_speed = 0
						pass
				
				#if teens_speed.keys().find(teen) != -1:
				#	new_speed = teens_speed[teen]
				#	teens_speed.erase(teen)
				#else:continue
			fast_speed:
				anim_speed = 2
				ai_timer_speed = 6
				teen.teenager_anims.set_speed_scale(2)
				
				match previous_time_speed:
					ultra_speed:
						new_speed = ((new_speed * 2) - new_speed * 3.5)
					default_speed:
						new_speed = (new_speed * 2) - base_spd
					_:
						#the game was paused, do nothing
						new_speed = 0
				
				#if teens_speed.keys().find(teen) == -1:
				#	common.merge_dict(teens_speed,{teen:teen.speed})
				#	new_speed *= 2
				#else:
				#	new_speed = teens_speed[teen]
				#	new_speed *= 2
			ultra_speed:
				anim_speed = 3
				ai_timer_speed = 12
				teen.teenager_anims.set_speed_scale(3)
				
				match previous_time_speed:
					fast_speed:
						new_speed = (new_speed * 3.5 - (new_speed * 2))
					default_speed:
						new_speed = (new_speed * 3.5) - base_spd
					_:
						#the game was paused, do nothing
						new_speed = 0
					
				#if teens_speed.keys().find(teen) == -1:
				#	common.merge_dict(teens_speed,{teen:teen.speed})
				#	new_speed *= 3.5
				#else:
				#	new_speed = teens_speed[teen]
				#	new_speed *= 3.5
				"""
			debug_speed:
				previous_time_speed = debug_speed
				anim_speed = 4
				ai_timer_speed = 4
				teen.teenager_anims.set_speed_scale(4)
				if teens_speed.keys().find(teen) == -1:
					common.merge_dict(teens_speed,{teen:teen.speed})
					new_speed *= 5
				else:
					new_speed = teens_speed[teen]
					new_speed *= 5
				"""
		
		#kinematic body speed
		teen.speed += new_speed
		#animations speed
		teen.teenager_anims.set_speed_scale(anim_speed)

#decrease the killing score
func update_killing_score():
	if get_level() == '':
		return
	var scr = score.get_killing_score(get_level())
	if scr > 0:
		score.set_killing_score(get_level(),scr-1)

func set_time(value):
	time += value
	
	if time / 60 == 24 or time >= 1440:
		#one day has passed, restart the clock
		time = 0
	
	if ((time / 60) >= 20 or (time / 60) <= 6) and has_light:
		update_lights(true)
	else:
		update_lights(false)
	update_killing_score()

#turn lights on/off
func update_lights(value):
	if lights == null: return
	
	if value:
		self.lights.show()
	else: self.lights.hide()
	
func get_time():
	return time

func set_points(value):
	points = value
	emit_signal("changed_points")

func get_points():
	return points

func pause_game():
	last_mode = get_current_mode()
	previous_time_speed = -1
	set_current_mode(MODE.PAUSED)
	get_tree().paused = true
	
func resume_game():
	set_current_mode(last_mode)
	get_tree().paused = false

func daynightcycle():
	if canvas_m == null:
		return
	
	var ra = [0.661133,-0.450579,-0.102644,0.003019,-0.017206,-0.010087]
	var rb = [-0.228901,-0.139233,0.029436,0.047411,0.007989]
	var ga = [0.626849,-0.437814,-0.050352,-0.009737,-0.028222,0.002317]
	var gb = [-0.279056,-0.106992,0.066646,0.032230,-0.001321]
	var ba = [0.725802,-0.268970,-0.035903,-0.006988,-0.021679,-0.002546]
	var bb = [-0.175541,-0.079950,0.034039,0.021785,-0.000069]
	var w = [0.258071,0.264981,0.258893]
	
	var r = 0
	var g = 0
	var b = 0
	
	var hour = float(time)/ float(60)
	if time/60 >= 23 or time/60 < 6:
		return

	for i in range(6):
		r += ra[i]*cos(i*hour*w[0])
		g += ga[i]*cos(i*hour*w[1])
		b += ba[i]*cos(i*hour*w[2])
	for i in range(1,6):
		r += rb[i-1]*sin(i*hour*w[0])
		g += gb[i-1]*sin(i*hour*w[1])
		b += bb[i-1]*sin(i*hour*w[2])
	r = min(r,1)
	g = min(g,1)
	b = min(b,1)
	canvas_m.color = Color(r,g,b,1)
	canvas_m.show()

#returns true if any teenager is in panic, escaping or any state that 
#allows the hunter to be spawned
func check_teenagers():
	var teenagers = get_tree().get_nodes_in_group("AI")
	
	for teen in teenagers:
		var state = teen.state_machine.get_current_state()
		
		match state:
			'Panic':
				return true
			'Escaping':
				return true
			'Shock':
				return true
			'Fighting':
				return true
			'Screaming':
				return true
			'Barricading':
				return true
				
	return false

#unlock medals
func check_medals():
	if get_level() == 'res://scenes/prototype2.tscn' and not medals.medals_data[58135]:
		if get_current_mode() == MODE.WON:
			medals.unlock(58135,$NewGroundsAPI)
			ui.achievement.play_achievement(58135)
	
	if not medals.medals_data[58134]:
		for teen in get_teenagers():
			if teen.state_machine.get_current_state() == 'Dead':
				medals.unlock(58134,$NewGroundsAPI)
				ui.achievement.play_achievement(58134)
				
	if get_level() == 'res://scenes/Level1.tscn' and not medals.medals_data[58136]:
		if get_current_mode() == MODE.WON:
			medals.unlock(58136,$NewGroundsAPI)
			ui.achievement.play_achievement(58136)
	

#update the sounds/musics of the level.
func update_ambience():
	var night = false
	var day = false
	
	if time/60 > 6 and time/60 < 19:
		day = true
		night = false
	else:
		day = false
		night = true
	
	if get_current_mode() == MODE.GAMEOVER:
		if audio_system.is_playing_list():
			audio_system.stop_play_list()
		
		if not audio_system.is_track_playing('GameOver'):
			#game over music, after the teen is gone
			for escaped in get_escaped_teens():
				var modulate = escaped.get_modulate()
				if modulate.a < 0.3:
					audio_system.play_music('GameOver')
					emit_signal("game_over_music")
		
		
		if audio_system.is_track_playing('Psycho'):
			audio_system.stop_track('Psycho')
		
		audio_system.stop_track('DaylightBackground')
		audio_system.stop_track('NightTimeBackground')
		
		
		return
	if get_current_mode() == MODE.WON:
		if audio_system.is_playing_list():
			audio_system.stop_play_list()
		
		if not audio_system.is_track_playing('Credits'):
			var can_play = true
			#game over music, after the teen is gone
			if get_teenagers().size() == 0:
				audio_system.play_music('Credits')
				emit_signal("game_won_music")
				return
			else:
				for teen in get_teenagers():
					if  teen.dead_anims.get_frame() == teen.dead_anims.frames.get_frame_count(teen.dead_anims.animation)-1:
						continue
					else: can_play = false
			if can_play: 
				audio_system.play_music('Credits')
				emit_signal("game_won_music")
						
		if audio_system.is_track_playing('Psycho'):
			audio_system.stop_track('Psycho')
		
		audio_system.stop_track('DaylightBackground')
		audio_system.stop_track('NightTimeBackground')
		return
	
	if check_teenagers():
		if audio_system.is_playing_list():
			audio_system.stop_play_list()
			
		if not audio_system.is_track_playing('Psycho'):
			audio_system.play_music('Psycho',false,true)
		
		audio_system.stop_track('DaylightBackground')
		audio_system.stop_track('NightTimeBackground')
		return
	else:
		if audio_system.is_track_playing('Psycho'):
			audio_system.stop_track('Psycho')
		
	if day and !check_teenagers():
		if !audio_system.is_track_playing('DaylightBackground'):
			audio_system.play_background('DaylightBackground')
	elif night and !check_teenagers():
		if !audio_system.is_track_playing('NightTimeBackground'):
			audio_system.play_background('NightTimeBackground')
			
	
	#create playlist
	if not audio_system.is_playing_list():
		audio_system.start_play_list(['Tension','Tension2','MoreTension',
		'Scary'],true)
	



