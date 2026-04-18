@tool
extends Node

## WARM = friendly, expressive, curious and patient. [br]
## GENTLE = friendly, expressive, neutral curious and patient. [br]
## COLD = unfriendly, not expressive, neutraly curious and not patient. [br]
## HOSTILE = unfriendly, expressive, not curious, and not patient. [br]
## DISTANT = neutraly friendly, neutral expressiveness, neutral curiousity and neutral patience. [br]
## EAGER = friendly, expressive, curious and not patient. [br]
## DETACHED = unfriendly,neutral expressiveness, neutral curiousity and neutral patience. [br]
## TERSE = neutraly friendly, not expressive, not curious and not patient. [br]
enum descriptor {WARM, GENTLE, COLD, HOSTILE, DISTANT, EAGER, DETACHED, TERSE}
# Note. Just for reference, in the code the enum descriptor is not used in dialogue.gd
# It is however, used in NpcManager.generate_dialogue_character_template and
# NpcManager.generate_dialogue_event_template

enum DialogueSubject { EVENT = 0, NPC = 1, GENERIC = -1 }

enum PoolContext { REACTIVE = 0, PROACTIVE = 1, ONGOING = 2 }

var _dialogue_pool_event = {}

var _dialogue_pool_character = {}

# formats a given line by swapping key strings with their information counterparts.
# all dialouge event templates should have keys such as {npc1}. corresponding to the event type
# where {npc1} is a valid field in the provided event_type that will also contain a string if filled. 
func _dialogue_event_format(event: Resource, line: String) -> String:
	var all_fields = {
		"name": event.event_name,
		"where": event.where,
		"time": event.time,
		"date": event.date,
		"day": event.day,
		}
	all_fields.merge(event.custom)
	for key in all_fields:
		var formated_key = "{%s}" %key
		if line.contains(formated_key):
			line = line.replace(formated_key,all_fields[key])
	return line


func _check_str_condition(text: String, npc: Resource ):
	var conditions = NpcManager.dialogue_conditions
	if conditions.has(text):
		return conditions[text].call(npc)

# formats a given line by swapping key strings with their information counterparts.
# all dialouge char templates should have  key [code]{rel_type}[/code] explicitly, so that the manager can swap it out
# for the actual relationship type
func _dialogue_char_format(sel_char_type: String, line: String) -> String:
	var formated_char = "{rel_type}" 
	if line.contains(formated_char):
		line = line.replace(formated_char,sel_char_type)
	return line

func _apply_mood(npc: Resource) -> Resource:
	var traits = ["friendliness", "expressiveness", "patience", "curiosity"]
	for value in traits:
		var base = npc[value]
		var min_val = base - npc.personality_range
		var max_val = base + npc.personality_range
		npc[value] = clampf(base + npc.mood, min_val, max_val)
	return npc

func _vibe_band(value: float, range: String) -> bool:
	var range_float = []
	if range == "high" : 
		range_float = [0.6,1.0]
	elif range == "neutral": 
		range_float = [0.4,0.6]
	elif range == "low": 
		range_float = [0.0,0.4]
	var result = false
	var low = range_float[0]
	var high = range_float[1]
	if value < high and value > low:
		result = true
	return result

func _vibe_map(npc: Resource):
	var vibe
	var f = npc.friendliness
	var e = npc.expressiveness
	var p = npc.patience
	var c = npc.curiosity
	if _vibe_band(f, "high") and _vibe_band(e, "high")  and _vibe_band(p, "high") and _vibe_band(c, "high"):
		vibe = "WARM"
	elif _vibe_band(f, "high") and _vibe_band(e, "high") and _vibe_band(p, "high") and _vibe_band(c, "neutral"):
		vibe = "GENTLE"
	elif _vibe_band(f, "low") and _vibe_band(e, "low") and _vibe_band(p, "low") and _vibe_band(c, "low"):
		vibe = "COLD"
	elif _vibe_band(f, "low") and _vibe_band(e, "high") and _vibe_band(p, "low") and _vibe_band(c, "low"):
		vibe = "HOSTILE"
	elif _vibe_band(f, "neutral") and _vibe_band(e, "neutral") and _vibe_band(p, "neutral") and _vibe_band(c, "neutral"):
		vibe = "DISTANT"
	elif _vibe_band(f, "high") and _vibe_band(e, "high") and _vibe_band(p, "low") and _vibe_band(c, "high"):
		vibe = "EAGER"
	elif _vibe_band(f, "neutral") and _vibe_band(e, "low") and _vibe_band(p, "low") and _vibe_band(c, "low"):
		vibe = "TERSE"
	elif _vibe_band(f, "low") and _vibe_band(e, "neutral") and _vibe_band(p, "neutral") and _vibe_band(c, "neutral"):
		vibe = "DETACHED"
	else:
		push_warning("No match found, using default of Distant")
		vibe = "DISTANT"
	return vibe

func _query_event(event_id: String, npc: Resource, vibe, pool_style: int, chat_tag: int = -1) -> Array:
	var event = NpcManager.get_event(event_id)
	var pool
	var convo_mode
	var chat_mode_error = "Ensure chat_tag is passed and pool_style = 2 to use Chat mode"
	match pool_style:
		0:
			convo_mode = "Reactive"
		1:
			convo_mode = "Proactive"
		2:
			convo_mode = "Chat"
		_:
			push_error("Invalid pool_style")
	if npc.npc_id in event.direct_witness:
		if chat_tag == -1 and convo_mode != "Chat":
			pool = _dialogue_pool_event[event.type]["direct"][vibe][convo_mode]["greetings"]
		elif chat_tag != -1 and convo_mode == "Chat":
			pool = _dialogue_pool_event[event.type]["direct"][vibe][convo_mode][chat_tag]
		else:
			push_error(chat_mode_error)
	elif npc.npc_id in event.indirect_witness:
		if chat_tag == -1 and convo_mode != "Chat":
			pool = _dialogue_pool_event[event.type]["indirect"][vibe][convo_mode]["greetings"]
		elif chat_tag != -1 and convo_mode == "Chat":
			pool = _dialogue_pool_event[event.type]["indirect"][vibe][convo_mode][chat_tag]
		else:
			push_error(chat_mode_error)
	else:
		#pool = _dialogue_pool_event["UNAWARE"][vibe][convo_mode]["greetings"]
		if chat_tag == -1 and convo_mode != "Chat":
			pool = _dialogue_pool_event["UNAWARE"][vibe][convo_mode]["greetings"]
		elif chat_tag != -1 and convo_mode == "Chat":
			pool = _dialogue_pool_event["UNAWARE"][vibe][convo_mode][chat_tag]
		else:
			push_error(chat_mode_error)
	return [pool,event]

func _query_char(target_id: String, npc: Resource, vibe, reactive) -> Array:
	#Currently Outdated while building
	var target = NpcManager.get_npc(target_id)
	var pool
	var sel_char 
	var active_type
	if reactive:
		active_type = "Reactive"
	else:
		active_type = "Proactive"
	if npc.relationships.has(target_id):
		sel_char = npc.relationships[target_id].type
		pool = _dialogue_pool_character[sel_char][vibe][active_type]
	else:
		pool = _dialogue_pool_character["UNAWARE"][vibe][active_type]
	return [pool,sel_char]

## Core dialouge mechanic. passing this will initiate one round of conversation with an npc.
## Meaning if more than one exchange is needed this should be called in an appropriate chaining system.[br]
## Takes a Dialogue Request object.[br]
## [codeblock]
## var request = DialogueRequest.new()
##	request.npc = npc # A valid NPC resource
##	request.chat_tag = -1 # Default if begining of chat else chose a valid tag
##	request.char_id = "" # Default if not talking about any npc
##	request.event_id = "0" # Default if not talking about any event
##	request.context = NpcDialogue.PoolContext.REACTIVE
##	request.subject_type = NpcDialogue.DialogueSubject.GENERIC
## talk_to_npc(request)
## [/codeblock]
## [code]chat_tag[/code] is the grouping for which the last response falls under, see [method NpcManager.chat_tag_fields]. [br]
## Returns a An Array containing a String of dialouge selected from a dialogue pool about characters and events, As well as an array of
## potential responses that exist.[br]
## see [method NpcManager.generate_dialogue_character_template] and [method NpcManager.generate_dialogue_event_template] 
## to go about making these pools. [br]
func talk_to_npc(request: Resource) -> Array:
	var npc = request.npc 
	var subject_type = request.subject_type
	var event_id = request.event_id
	var char_id = request.char_id
	var context = request.context
	var chat_tag = request.chat_tag
	var pos_responses
	var pool
	var data
	var chosen_line
	var current_npc = _apply_mood(npc)
	var vibe =  _vibe_map(current_npc)
	if subject_type == 0:
		data = _query_event(event_id, current_npc,vibe,context,chat_tag)
		pool = data[0]
		
		var chosen_index = randi() % pool.size()
		var pool_dict = pool[chosen_index]
		chosen_line = pool_dict.line
		var type = data[1]
		chosen_line = _dialogue_event_format(type, chosen_line)
		pos_responses = pool_dict.responses
		
	if chosen_line.contains("{player0}"): 
		var player_name = NpcManager.player_data.player_name
		chosen_line = chosen_line.replace("{player0}",player_name)
	return [chosen_line,pos_responses]
