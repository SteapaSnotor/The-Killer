extends Node

"""
	Teenager escaped state
	
	This is a point-of-no-return state.
"""

signal finished
signal entered

#constructor
func init(base,state_position,state_time):
	emit_signal("entered")
	
func update(delta):
	pass
	
#destructor
func exit():
	emit_signal("finished")