extends Node

"""
	'settings' singleton.
	Will store all player's choice settings. Things like audio volume,
	screen resolution etc...
"""

const version = '0.0.5ALPHA'

signal audio_changed

#audio system
var sound_db = 0 setget set_sound_db, get_sound_db
var music_db = -10 setget set_music_db, get_music_db
var background_db = 5 setget set_background_db, get_background_db

#when the player opened the game for the first time
var first_time = true

#this singleton must run all the time
func _ready():
	set_pause_mode(Node.PAUSE_MODE_PROCESS)

#shortcut for entering in full screen
func _input(event):
	if Input.is_action_just_pressed("FullScreen"):
		OS.set_window_fullscreen(!OS.is_window_fullscreen())

func set_sound_db(value):
	sound_db = value
	emit_signal("audio_changed")
	
func get_sound_db():
	return sound_db
	
func set_music_db(value):
	music_db = value
	emit_signal("audio_changed")
	
func get_music_db():
	return music_db
	
func set_background_db(value):
	background_db = value
	emit_signal("audio_changed")

func get_background_db():
	return background_db








