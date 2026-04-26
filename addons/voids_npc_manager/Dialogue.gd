@tool
extends Node
##Class for Handling Dialogue in the Plugin

## WARM = friendly, expressive, curious and patient. [br]
## GENTLE = friendly, expressive, neutral curious and patient. [br]
## COLD = unfriendly, not expressive, neutraly curious and not patient. [br]
## HOSTILE = unfriendly, expressive, not curious, and not patient. [br]
## DISTANT = neutraly friendly, neutral expressiveness, neutral curiosity and neutral patience. [br]
## EAGER = friendly, expressive, curious and not patient. [br]
## DETACHED = unfriendly,neutral expressiveness, neutral curiosity and neutral patience. [br]
## TERSE = neutraly friendly, not expressive, not curious and not patient. [br]
enum Vibe {WARM, GENTLE, COLD, HOSTILE, DISTANT, EAGER, DETACHED, TERSE}
# Note. its Just for reference, in the keys the enum descriptor is not used in dialogue.gd

## For the Type of pool the manager should pool from, [br]
## EVENT = Event pool. [br]
## NPC = NPC pool. [br]
## GENERIC = Generic pool when not specifically talking about an Event or NPC, Is an event of type [code]default_convo[/code] and id [code]"0"[/code]
enum PoolType { EVENT, NPC, GENERIC}

## Context for conversations,[br]
## REACTIVE = The NPC being spoken to did not initiate the conversation.[br]
## PROACTIVE = The NPC being spoken to initiated the conversation.[br]
## ONGOING = The conversation has began and is being followed up.[br]
enum PoolContext { REACTIVE, PROACTIVE, ONGOING}

## Default set Condition Types for evaluating conditions in dialouge. Choose CUSTOM to use custom functions
## with [method NpcManager.register_dialogue_condition]
enum DialogueConditionType {
	MOOD,
	FRIENDLINESS,
	CURIOSITY,
	PATIENCE,
	EXPRESSIVENESS,
	WITNESSED_EVENT_DIRECT,
	WITNESSED_EVENT_INDIRECT,
	CUSTOM
	}


const _RANGES = {
	"high": [60,100],
	"neutral": [40,60],
	"low": [0,40]
}

## Templates used to define Vibes explicitly
const VIBE_TEMPLATES = [
	{ "name": Vibe.WARM, "friendliness":["high"], "expressiveness":["high","neutral"], "patience":["high","neutral"], "curiosity":["high","neutral"]},
	{ "name": Vibe.GENTLE, "friendliness":["high","neutral"], "expressiveness":["high"], "patience":["high","neutral"], "curiosity":["neutral","low"]},
	{ "name": Vibe.COLD, "friendliness":["low"], "expressiveness":["low"], "patience":["low","neutral"], "curiosity":["low"]},
	{ "name": Vibe.HOSTILE, "friendliness":["low"], "expressiveness":["high"], "patience":["low"], "curiosity":["low","neutral"]},
	{ "name": Vibe.DISTANT, "friendliness":["neutral","low"], "expressiveness":["neutral","low"], "patience":["neutral"], "curiosity":["neutral"]},
	{ "name": Vibe.EAGER, "friendliness":["high","neutral"], "expressiveness":["high"], "patience":["low"], "curiosity":["high"]},
	{ "name": Vibe.TERSE, "friendliness":["neutral"], "expressiveness":["low"], "patience":["low"], "curiosity":["low","neutral"]},
	{ "name": Vibe.DETACHED, "friendliness":["low"], "expressiveness":["neutral","low"], "patience":["neutral"], "curiosity":["neutral"]}
]

var parser = DialogueCache.new()

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

func _check_str_condition(condition: String, npc: Resource ):
	var conditions = NpcManager.dialogue_conditions
	var result
	if conditions.has(condition):
		result = conditions[condition].call(npc)
	else:
		push_error("Custom condition does not exist for condition: %s"%condition)
		return null
	if result is not bool:
		push_error("Custom condition returned a value other than boolean. condition: %s"%condition)
		return null
	return result

# formats a given line by swapping key strings with their information counterparts.
# all dialouge char templates should have  key [code]{rel_type}[/code] explicitly, so that the manager can swap it out
# for the actual relationship type
func _dialogue_char_format(sel_char_type: String, line: String) -> String:
	var formated_char = "{rel_type}" 
	if line.contains(formated_char):
		line = line.replace(formated_char,sel_char_type)
	return line

func _apply_mood(npc: Resource, npc_id: String) -> Resource:
	var file_name = "NPC_%s.tres" %npc_id
	var save_path = NpcManager.npc_path + file_name
	var traits = ["friendliness", "expressiveness", "patience", "curiosity"]
	for value in traits:
		var base = npc["base_" + value]
		var min_val = base - npc.personality_range
		var max_val = base + npc.personality_range
		npc[value] = clampf(npc[value] + npc.mood, min_val, max_val)
	NpcManager._save_queue.append({"res": npc, "path": save_path})
	return npc

func _vibe_band(value: int, range: String) -> bool:
	var bounds = _RANGES[range]
	return value <= bounds[1] and value >= bounds[0]

func _vibe_map(npc: Resource):
	var traits = {
		"friendliness": npc.friendliness,
		"expressiveness": npc.expressiveness,
		"patience": npc.patience,
		"curiosity": npc.curiosity,
	}
	for template in VIBE_TEMPLATES:
		var vibe_valid = true
		for trait_name in ["friendliness","expressiveness","patience","curiosity"]:
			var trait_value = traits[trait_name]
			var allowed_ranges = template[trait_name]
			var trait_passes = false
			for range in allowed_ranges:
				if _vibe_band(trait_value, range):
					trait_passes = true
					break
			if not trait_passes:
				vibe_valid = false
				break
		if vibe_valid:
			return template["name"]
	push_warning("No match found, using default of Distant")
	return Vibe.DISTANT

func _query_event(event_id: String, npc: Resource, vibe: String, context: String, section: String) -> Array:
	var event = NpcManager.get_event(event_id)
	var pool
	var event_type = event.type
	var prefix
	if event_id in npc.direct_events:
		prefix = "direct"
		section = prefix + "_" + section
		pool = parser.pool_request(PoolType.EVENT,event_type,vibe,context,section)
	elif  event_id in npc.indirect_events:
		prefix = "indirect"
		section = prefix + "_" + section
		pool = parser.pool_request(PoolType.EVENT,event_type,vibe,context,section)
	else:
		pool = parser.pool_request(PoolType.EVENT,"UNAWARE",vibe,context,section)
	return [pool,event]

func _query_char(char_id: String, npc: Resource, vibe: String, context: String, section: String) -> Array:
	var target = NpcManager.get_npc(char_id)
	var pool
	var rel_type
	if npc.relationships.has(char_id):
		rel_type = npc.relationships[char_id].type
		pool = parser.pool_request(PoolType.NPC,rel_type,vibe,context,section)
	else:
		rel_type = "UNAWARE"
		pool = parser.pool_request(PoolType.NPC,rel_type,vibe,context,section)
	
	return [pool,rel_type]

# friendliness,curiosity,patience,expressiveness and mood do value checks only (<,>,=)
# relationship also only does value checks with npc.relationship.value
# direct_events and indirect_events do dict checks only 
func _condition_check(condition: String,npc: Resource, condition_type: String):
	var expression = Expression.new()
	var variable
	var execution_variable
	var result
	match condition_type: 
		DialogueConditionType.FRIENDLINESS: 
			variable = ["friendliness"]
			execution_variable = [npc.friendliness]
		DialogueConditionType.CURIOSITY: 
			variable = ["curiosity"]
			execution_variable = [npc.curiosity]
		DialogueConditionType.PATIENCE: 
			variable = ["patience"]
			execution_variable = [npc.patience]
		DialogueConditionType.EXPRESSIVENESS: 
			variable = ["expressiveness"]
			execution_variable = [npc.expressiveness]
		DialogueConditionType.MOOD: 
			variable = ["mood"]
			execution_variable = [npc.mood]
		DialogueConditionType.WITNESSED_EVENT_DIRECT: 
			variable = ["direct_events"]
			execution_variable = [npc.direct_events]
		DialogueConditionType.WITNESSED_EVENT_INDIRECT: 
			variable = ["indirect_events"]
			execution_variable = [npc.indirect_events]
		DialogueConditionType.CUSTOM: 
			result = _check_str_condition(condition, npc)
			if result != null:
				return result
		_: 
			push_error("Invalid Condition Type. see NpcDialogue.DialogueConditionType")
	expression.parse(condition, variable)
	result = expression.execute(execution_variable)
	return result

## Core dialouge mechanic. passing this will initiate one round of conversation with an npc.
## Meaning if more than one exchange is needed this should be called in an appropriate chaining system.[br]
## Takes a Dialogue Request object.[br]
## [codeblock]
## var request = DialogueRequest.new()
##	request.npc = npc # A valid NPC resource of the NPC being spoken to
##	request.pool_type = NpcDialogue.PoolType.GENERIC # Default if not takin about a specific NPC or Event
##	request.char_id = "" # Default if not talking about a specific Npc
##	request.event_id = "0" # Default if not talking about any event
##	request.context = NpcDialogue.PoolContext.REACTIVE
## talk_to_npc(request)
## [/codeblock]
## Returns a An Array containing a String of dialouge selected from a dialogue pool about characters and events, As well as an array of
## potential responses that exist.[br]
func talk_to_npc(request: Resource) -> Array:
	var npc_id = request.npc 
	var pool_type = request.pool_type
	var event_id = request.event_id
	var char_id = request.char_id
	var context = request.context
	if context < 0 or context >= PoolContext.size():
		push_error("Invalid Context Index")
	else:
		context = PoolContext.keys()[context]
	var section = request.section
	var pos_responses = []
	var pool
	var data
	var chosen_line
	var npc = NpcManager.get_npc(npc_id)
	var current_npc = _apply_mood(npc,npc_id)
	var vibe =  _vibe_map(current_npc)
	vibe = Vibe.keys()[vibe]
	match pool_type:
		PoolType.EVENT:
			data = _query_event(event_id, current_npc,vibe,context,section)
			pool = data[0]
			var event_resource = data[1]
			
			var chosen_index = randi() % pool.size()
			var pool_dict = pool[chosen_index]
			chosen_line = pool_dict.line
			
			chosen_line = _dialogue_event_format(event_resource, chosen_line)
			for response in pool_dict.responses:
				var condition = response.condition
				var condition_type = response.condition_type
				var result
				if condition_type != "None" and condition != "None":
					result = _condition_check(condition,npc,condition_type)
					if result:
						pos_responses.append(response)
				else:
					pos_responses.append(response)
		PoolType.NPC:
			data = _query_char(char_id,npc,vibe,context,section)
			pool = data[0]
			var npc_resource = data[1]
			
			var chosen_index = randi() % pool.size()
			var pool_dict = pool[chosen_index]
			chosen_line = pool_dict.line
			
			chosen_line = _dialogue_char_format(npc_resource, chosen_line)
			for response in pool_dict.responses:
				var condition = response.condition
				var condition_type = response.condition_type
				var result
				if condition_type != "None" and condition != "None":
					result = _condition_check(condition,npc,condition_type)
					if result:
						pos_responses.append(response)
				else:
					pos_responses.append(response)
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")
	
	if chosen_line.contains("{player0}"): 
		var player_name = NpcManager.player_data.player_name
		chosen_line = chosen_line.replace("{player0}",player_name)
	return [chosen_line,pos_responses]
