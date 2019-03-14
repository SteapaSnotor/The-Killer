extends "res://scripts/FSM.gd"

"""
	The Finite state machine for each AI (teenager).
"""

#certain states deactivate routines
var _on_routine = false

#this will be true when the player placed traps in  a chain reaction
#without chaing reactions, teenagers that are not in panic mode, will just 
#go back to their routines.
var is_chain_reaction = false

#replaces is_chain_reaction. When true that means that this teenager can't
#go back to his routines. Must be activated when he's escaping or in panic
var is_routine_over = false

#initialize state machine
func _ready():
	var states = {
		$Idle:$Idle.name,
		$Moving:$Moving.name,
		$Waiting: $Waiting.name,
		$Lured: $Lured.name,
		$Panic: $Panic.name,
		$Escaping: $Escaping.name,
		$Dead:$Dead.name,
		$OnVice:$OnVice.name,
		$Startled:$Startled.name
	}
	
	for state in states:
		if not state.is_connected("finished",self,"finish_state"):
			state.connect("finished",self,"finish_state")
	
	current_state = $Idle
	state_timer = $StateTimer
	#timeout signal
	state_timer.connect("timeout",self,"timeout")
	
	teenager = get_parent()
	init()

func get_current_state():
	return current_state.name

#execute a state from the player's routine
func execute_routine(state,position,time):
	state_position = position
	state_time = time
	_on_routine = true
	change(get_node(state))
	
	#state information

#if is following a routine, tell the player base AI that this step is over
#otherwise, just follow to the next
func finish_state():
	if _on_routine == true and is_routine_over == false:
		_on_routine = false
		teenager.next_routine()
	else:
		#external events will prevent this teenager from executing
		#routine states.
		pass
		

#forces the AI to start a new routine
func force_new_routine():
	pass

#force a new state change. Generally used by traps or the player.
func force_state(state):
	#check if this state is compatible
	#TODO: before changing the state, check if it's possible.
	#some states  cannot be connected to the state the ai is trying to change.
	if state == 'Panic' and current_state.name == 'Panic':
		return
	if state == 'Panic' and current_state.name == 'Escaping':
		return
	if state == 'OnVice' and current_state.name == 'Panic' or  (current_state.name == 'Escaping' and state == 'OnVice'):
		return
	
	
	_on_routine = false
	current_state.exit()
	change(get_node(state))
	
	#TODO: check if the AI isn't already in the current state

#detect transitions between states
func state_transitions():
	pass






