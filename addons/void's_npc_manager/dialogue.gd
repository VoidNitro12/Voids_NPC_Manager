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
# Note. Just for reference, in the code the enum descriptor is not used in dialogue.gd
# It is however, used in NpcEngine.generate_dialogue_character_template and
# NpcEngine.generate_dialogue_event_template
enum descriptor {WARM, GENTLE, COLD, HOSTILE, DISTANT, EAGER, DETACHED, TERSE}

var _dialogue_pool_event = {}

var _dialogue_pool_character = {}

# formats a given line by swapping key strings with their information counterparts.
# all dialouge event templates should have keys such as {npc1}. corresponding to the event type
# where {npc1} is a valid field in the provided event_type that will also contain a string if filled. 
func _dialogue_event_format(event_type: String, line: String) -> String:
	var event= NpcEngine._custom_event_types[event_type]
	for key in event:
		var formated_key = "{%s}" %key
		if line.contains(formated_key):
			line = line.replace(formated_key,event[key])
	return line

# formats a given line by swapping key strings with their information counterparts.
# all dialouge char templates should have  key [code]{rel_type}[/code] explicitly, so that the manager can swap it out
# for the actual relationship type
func _dialogue_char_format(sel_char_type: String, line: String) -> String:
	var formated_char = "{rel_type}" 
	if line.contains(formated_char):
		line = line.replace(formated_char,sel_char_type)
	return line

func apply_mood(npc: Resource) -> Resource:
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

func query_event(event_id: String, npc: Resource, vibe) -> Array:
	var data = NpcEngine.get_event(event_id)
	var event = data[0]
	var pool
	if npc.npc_id in event.direct_witness:
		pool = _dialogue_pool_event[event.type]["direct"][vibe]
	elif npc.npc_id in event.indirect_witness:
		pool = _dialogue_pool_event[event.type]["indirect"][vibe]
	else:
		pool = _dialogue_pool_event["UNAWARE"][vibe]
	return [pool,event.type]
	
func query_char(target_id: String, npc: Resource, vibe) -> Array:
	var data = NpcEngine.get_npc(target_id)
	var target = data[0]
	var pool
	var sel_char 
	if npc.relationships.has(target_id):
		sel_char = npc.relationships[target_id].type
		pool = _dialogue_pool_character[sel_char][vibe]
	else:
		pool = _dialogue_pool_character["UNAWARE"][vibe]
	return [pool,sel_char]

## Core dialouge mechanic. passing this will initiate one round of conversation with an npc.
## Meaning if more than one exchange is needed this should be called in an appropriate loop.
## takes the npc resource and an event/npc id. an event id if the converation is abount an event, also 
## [code]event_based[/code] should be set to [code]true[/code]. and an npc id if the converation is abount another npc, also 
## [code]char_based[/code] should be set to [code]true[/code]
func talk_to_npc(npc: Resource, id: String, event_based: bool = false, char_based: bool = false):
	var pool
	var data
	var current_npc = apply_mood(npc)
	var vibe =  _vibe_map(current_npc)
	if event_based:
		data = query_event(id, current_npc,vibe)
		pool = data[0]
	if char_based:
		data = query_char(id, current_npc,vibe)
		pool = data[0]
	var choice_index = randi() % pool.size()
	var choice = pool[choice_index]
	if event_based:
		var type = data[1]
		choice = _dialogue_event_format(type, choice)
	elif char_based:
		var sel_char_type = data[1]
		if sel_char_type != null:
			choice = _dialogue_char_format(sel_char_type, choice)
	return choice
