@tool
extends Node
##Class for Handling Dialouge in the Plugin

## WARM = friendly, expressive, curious and patient. [br]
## GENTLE = friendly, expressive, neutral curious and patient. [br]
## COLD = unfriendly, not expressive, neutraly curious and not patient. [br]
## HOSTILE = unfriendly, expressive, not curious, and not patient. [br]
## DISTANT = neutraly friendly, neutral expressiveness, neutral curiousity and neutral patience. [br]
## EAGER = friendly, expressive, curious and not patient. [br]
## DETACHED = unfriendly,neutral expressiveness, neutral curiousity and neutral patience. [br]
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
	RELATIONSHIP,
	MOOD,
	FRIENDLINESS,
	CURIOSITY,
	PATIENCE,
	EXPRESSIVENESS,
	WITNESSED_EVENT_DIRECT,
	WITNESSED_EVENT_INDIRECT,
	CUSTOM
	}

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
		vibe = Vibe.WARM
	elif _vibe_band(f, "high") and _vibe_band(e, "high") and _vibe_band(p, "high") and _vibe_band(c, "neutral"):
		vibe = Vibe.GENTLE
	elif _vibe_band(f, "low") and _vibe_band(e, "low") and _vibe_band(p, "low") and _vibe_band(c, "low"):
		vibe = Vibe.COLD
	elif _vibe_band(f, "low") and _vibe_band(e, "high") and _vibe_band(p, "low") and _vibe_band(c, "low"):
		vibe = Vibe.HOSTILE
	elif _vibe_band(f, "neutral") and _vibe_band(e, "neutral") and _vibe_band(p, "neutral") and _vibe_band(c, "neutral"):
		vibe = Vibe.DISTANT
	elif _vibe_band(f, "high") and _vibe_band(e, "high") and _vibe_band(p, "low") and _vibe_band(c, "high"):
		vibe = Vibe.EAGER
	elif _vibe_band(f, "neutral") and _vibe_band(e, "low") and _vibe_band(p, "low") and _vibe_band(c, "low"):
		vibe = Vibe.TERSE
	elif _vibe_band(f, "low") and _vibe_band(e, "neutral") and _vibe_band(p, "neutral") and _vibe_band(c, "neutral"):
		vibe = Vibe.DETACHED
	else:
		push_warning("No match found, using default of Distant")
		vibe = Vibe.DISTANT
	return vibe

func _query_event(event_id: String, npc: Resource, vibe: int , context: int, section: String) -> Array:
	var event = NpcManager.get_event(event_id)
	var parser = Parser.new()
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
	
	return [pool,sel_char]

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
			variable = ["curiousity"]
			execution_variable = [npc.curiousity]
		DialogueConditionType.PATIENCE: 
			variable = ["patience"]
			execution_variable = [npc.patience]
		DialogueConditionType.EXPRESSIVENESS: 
			variable = ["expressiveness"]
			execution_variable = [npc.expressiveness]
		DialogueConditionType.MOOD: 
			variable = ["mood"]
			execution_variable = [npc.mood]
		DialogueConditionType.RELATIONSHIP: 
			#relationships structure and mechanices arent definite yet
			pass
		DialogueConditionType.WITNESSED_EVENT_DIRECT: 
			variable = ["direct_events"]
			execution_variable = [npc.direct_events]
		DialogueConditionType.WITNESSED_EVENT_INDIRECT: 
			variable = ["indirect_events"]
			execution_variable = [npc.indirect_events]
		DialogueConditionType.CUSTOM: 
			_check_str_condition(condition, npc)
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
	var npc = request.npc 
	var pool_type = request.pool_type
	var event_id = request.event_id
	var char_id = request.char_id
	var context = request.context
	var section = request.section
	var pos_responses = []
	var pool
	var data
	var chosen_line
	var current_npc = _apply_mood(npc)
	var vibe =  _vibe_map(current_npc)
	match pool_type:
		PoolType.EVENT:
			data = _query_event(event_id, current_npc,vibe,context,section)
			pool = data[0]
			
			var chosen_index = randi() % pool.size()
			var pool_dict = pool[chosen_index]
			chosen_line = pool_dict.line
			var type = data[1]
			chosen_line = _dialogue_event_format(type, chosen_line)
			for response in pool_dict.responses:
				var condition = response.condition
				var condition_type = response.condition_type
				var result
				if condition_type != "None" or condition != "None":
					result = _condition_check(condition,npc,condition_type)
					if result:
						pos_responses.append(response)
				else:
					pos_responses.append(response)
		PoolType.NPC:
			pass
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")
	
	if chosen_line.contains("{player0}"): 
		var player_name = NpcManager.player_data.player_name
		chosen_line = chosen_line.replace("{player0}",player_name)
	return [chosen_line,pos_responses]
