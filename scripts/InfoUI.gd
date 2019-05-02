extends Control

"""
	This UI element will show several informations about the current game.
	Things like score, death progress and time.
"""

var base = null
var points = 0
var activated_teens = []
var teens = []

#world nodes
onready var _score = $InfoPanel/Score
onready var fc_slots = $FCSlots.get_children()

#constructor
func init(base):
	self.base = base
	self.teens = get_tree().get_nodes_in_group("AI")
	
func _process(delta):
	if base == null:
		return
		
	#search for teens that aren't on routine
	for teen in teens:
		if teen.is_routine_paused and activated_teens.find(teen) == -1:
			activated_teens.append(teen)
		elif not teen.is_routine_paused and activated_teens.find(teen) != -1:
			activated_teens.erase(teen)
		else: continue
		
	if activated_teens != []:
		fill_fc_slots()
	else: clear_fc_slots()
	
	#fill the score label
	_score.text = str(score.get_score(base.game.get_level()))

#TODO: slot animations
#fill the fear/curiosity slots of teenagers that aren't on routine.
func fill_fc_slots():
	var teen_id = 0
	for teen in activated_teens:
		if teen_id > fc_slots.size()-1:
			#no more slots
			break
		
		#TODO: fill teen's slot portrait
		var fear_bar = fc_slots[teen_id].get_node('FearProgress')
		var curiosity_bar = fc_slots[teen_id].get_node('CuriosityProgress')
		
		fear_bar.set_value(teen.get_fear())
		curiosity_bar.set_value(teen.get_curiosity())
		fc_slots[teen_id].show()
		
		
		teen_id += 1
	
	#clean not used slots
	var slot_id = 0
	for slot in fc_slots:
		if slot_id > teen_id-1:
			slot.hide()
		slot_id += 1
		
	
func clear_fc_slots():
	for slot in fc_slots:
		slot.hide()







