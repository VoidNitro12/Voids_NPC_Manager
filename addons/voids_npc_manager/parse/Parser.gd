@tool
class_name Parser

var line_regex = RegEx.new()
var meta_data_regex = RegEx.new()
var intent_regex = RegEx.new()
var _lexer = Lexer.new()
var _validator = Validator.new()
var locator: Dictionary = {}
var script_type: int
var current_locator_pointer: String = ""
var current_line: String = ""
var current_intent: int
var current_responses: Array = []

class NPC_line:
	var line
	var intent
	var responses
	func _init(line: String,intent: int,responses: Array):
		self.line = line
		self.intent = intent
		self.responses = responses

class Response:
	var text
	var condition
	var condition_type
	var effect
	var intent
	var tag
	func _init(text: String, condition: String, condition_type: String, effect: String, intent: int, tag: String):
		self.text = text
		self.condition = condition
		self.condition_type = condition_type
		self.effect = effect
		self.intent = intent
		self.tag = tag

func parse_tokens(tokens: Array) -> Array:
	locator = {}
	script_type 
	current_locator_pointer= ""
	current_line= ""
	current_intent = -1
	current_responses= []
	line_regex.compile(_validator.line_format)
	meta_data_regex.compile(_validator.meta_data_format)
	intent_regex.compile(_validator.intent_format)
	var section_data: Array = []
	var current_type: String = ""
	var current_vibe: String = ""
	var current_mode: String = ""
	var current_section: String = ""
	
	for token in tokens:
		match token.marker:
			Lexer.POOL_MARKER:
				match token.value:
					"EVENT":
						script_type = NpcDialogue.PoolType.EVENT
					"NPC":
						script_type = NpcDialogue.PoolType.NPC
			Lexer.TYPE_MARKER:
				_store_line()
				section_data = []
				current_type= ""
				current_vibe = ""
				current_mode= ""
				current_section= ""
				current_type = token.value
			Lexer.VIBE_MARKER:
				_store_line()
				current_vibe = token.value
			Lexer.MODE_MARKER:
				_store_line()
				current_mode = token.value
			Lexer.SECTION_MARKER:
				_store_line()
				current_section = token.value
				current_section = current_section.strip_edges()
				var parts = [current_type,current_vibe,current_mode,current_section]
				var SEPARATOR = _lexer.SEPARATOR
				current_locator_pointer = SEPARATOR.join(parts)
				locator[current_locator_pointer] = []
			Lexer.NPC_LINE_MARKER:
				_store_line()
				var data = _parse_npc_line(token)
				current_line = data[0]
				current_intent = data[1]
			Lexer.RESPONSE_MARKER:
				var response = _parse_response(token)
				current_responses.append(response)
		if token == tokens[-1]:
			_store_line()
	return [locator,script_type]

func _store_line():
	if current_line != "":
		var npc_line = NPC_line.new(current_line,current_intent,current_responses)
		locator[current_locator_pointer].append(npc_line)
		current_line = ""
		current_intent = -1
		current_responses = []

func _parse_npc_line(token: Lexer.Token) -> Array:
	var line = token.value
	var found = line_regex.search(line)
	var text = found.get_string(1)
	var meta_raw = found.get_string(2)
	var meta_found = intent_regex.search(meta_raw)
	var intent = ""
	if meta_found != null:
		intent =  meta_found.get_string(1)
	match intent:
		"":
			intent = NpcDialogue.intent_commands.keep_topic
		"keep_topic":
			intent = NpcDialogue.intent_commands.keep_topic
	return [text,intent]

# all meta data fields default to "None" if empty or invalid (not in qoutes)
func _parse_response(token: Lexer.Token) -> Response:
	var line = token.value
	var found = line_regex.search(line)
	var text = found.get_string(1)
	var condition = "None"
	var condition_type = "None"
	var effect = "None"
	var tag = "None"
	var intent = NpcDialogue.intent_commands.keep_topic
	var meta_raw = found.get_string(2)
	var meta_found = meta_data_regex.search_all(meta_raw)
	for meta in meta_found:
		match meta.get_string(1):
			"condition":
				condition = meta.get_string(2)
			"condition_type":
				condition_type = meta.get_string(2)
			"effect":
				effect = meta.get_string(2)
			"tag":
				tag = meta.get_string(2)
			"intent":
				var value = meta.get_string(2)
				match value:
					"":
						intent = NpcDialogue.intent_commands.keep_topic
					"keep_topic":
						intent = NpcDialogue.intent_commands.keep_topic
	var response = Response.new(text,condition,condition_type,effect,intent,tag)
	return response
