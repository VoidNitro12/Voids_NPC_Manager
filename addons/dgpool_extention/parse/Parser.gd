@tool
class_name Parser

const POOL_MARKER = "@"
const TYPE_MARKER = "~"
const VIBE_MARKER = "/"
const MODE_MARKER = "*"
const SECTION_MARKER = "section"
const NPC_LINE_MARKER = "-"
const RESPONSE_MARKER = ">"
const SEPARATOR = "^"
const COMMENT_MARKER = "#"

var hierarchy = {
	TYPE_MARKER : [VIBE_MARKER,MODE_MARKER,SECTION_MARKER,NPC_LINE_MARKER,RESPONSE_MARKER],
	VIBE_MARKER : [MODE_MARKER,SECTION_MARKER,NPC_LINE_MARKER,RESPONSE_MARKER],
	MODE_MARKER : [SECTION_MARKER,NPC_LINE_MARKER,RESPONSE_MARKER],
	SECTION_MARKER : [NPC_LINE_MARKER,RESPONSE_MARKER],
	NPC_LINE_MARKER : [RESPONSE_MARKER],
	RESPONSE_MARKER: [],
	}
	
var regex = RegEx.new()
var response_format = "\"([^\"]+)\"\\s*(\\{[^\\}]+\\})"
var locator = {}
var script_type 
var current_type: String = ""
var current_vibe: String = ""
var current_mode: String = ""
var current_section: String = ""
var current_locator_pointer: String = ""
var _on_npc_line: bool = false
var _line_num: int = 0
var _current_level
var _to_skip: Array = []
var _valid: bool = false
var current_choice: Dictionary =  {"line": "", "responses": []}
var section_data: Array

func validate_dialogue_file(file_path: String) -> Array:
	regex.compile(response_format)
	_valid = false
	_line_num = 0
	current_type = ""
	current_vibe = ""
	current_mode = ""
	current_section = ""
	var stack_check = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Could not open file: %s" % file_path)
		stack_check.append(false)
	var lines = file.get_as_text().split("\n")
	file.close()
	
	for line in lines:
		_line_num += 1
		var bare_line = line.strip_edges()
		if bare_line.begins_with("COMMENT_MARKER") or bare_line.is_empty():
			continue
		bare_line = inline_comments_check(bare_line)
		
		if bare_line.begins_with(POOL_MARKER):
			_valid = _check_pool_type(bare_line)
			stack_check.append(_valid)
		elif bare_line.begins_with(TYPE_MARKER):
			_to_skip = []
			_valid = _check_event_type(bare_line)
			stack_check.append(_valid)
		elif bare_line.begins_with(VIBE_MARKER):
			if VIBE_MARKER in _to_skip:
				continue
			else:
				_to_skip = []
				_valid = _check_vibe(bare_line)
				stack_check.append(_valid)
		elif bare_line.begins_with(MODE_MARKER):
			if MODE_MARKER in _to_skip:
				continue
			else:
				_to_skip = []
				_valid = _check_mode(bare_line)
				stack_check.append(_valid)
		elif bare_line.begins_with(SECTION_MARKER):
			if SECTION_MARKER in _to_skip:
				continue
			else:
				_to_skip = []
				_valid = _check_section(bare_line)
				stack_check.append(_valid)
		elif bare_line.begins_with(NPC_LINE_MARKER):
			if NPC_LINE_MARKER in _to_skip:
				continue
			else:
				_to_skip = []
				_valid = _check_npc_line(bare_line)
				stack_check.append(_valid)
		elif bare_line.begins_with(RESPONSE_MARKER):
			if RESPONSE_MARKER in _to_skip:
				continue
			else:
				_to_skip = []
				_valid = _check_responses(bare_line)
				stack_check.append(_valid)
		else:
			push_error("Unrecognized line beginning on line %d"%_line_num)
			_move_till_next_top()
			stack_check.append(false)
		if current_choice["line"] != "" or current_choice["responses"].size() > 0:
			section_data.append(current_choice)
	assert(stack_check.has(false) == false, "Unable to parse pool script due to errors")
	return [locator,script_type]

#func get_indent(line: String) -> int:
	#var count = 0
	#for c in line:
		#if c == " " or c == "\t":
			#count += 1
		#else:
			#break
	#return count

func _check_pool_type(line: String):
	var name = line.trim_prefix(POOL_MARKER)
	match name:
		"EVENT":
			script_type = NpcDialogue.PoolType.EVENT
			locator= {}
		"NPC":
			script_type = NpcDialogue.PoolType.NPC
			locator= {}
		_:
			push_error("Invalid Pool Type, should be EVENT or NPC")
			return false
	return true

func _check_event_type(line: String):
	current_type = ""
	current_vibe = ""
	current_mode = ""
	current_section = ""
	_on_npc_line = false
	_current_level = TYPE_MARKER
	var name = line.trim_prefix(TYPE_MARKER).strip_edges()
	match script_type:
		NpcDialogue.PoolType.EVENT:
			if name not in NpcManager._event_types:
				push_error("Invalid Pool type on line %d. see NpcManager.get_event_types() " %_line_num)
				_move_till_next_top()
				return false
			else:
				_current_level = VIBE_MARKER
				current_type = name
				return true
		NpcDialogue.PoolType.NPC:
			if name not in NpcManager._relationship_types:
				push_error("Invalid Relationship Type on line %d. see NpcManager.get_event_types() " %_line_num)
				_move_till_next_top()
				return false
			else:
				_current_level = VIBE_MARKER
				current_type = name
				return true
		_:
			push_error("Invalid Pool Type, should be EVENT or NPC")
	
		
func _check_vibe(line: String):
	current_vibe = ""
	if current_type == "":
		push_error("No _valid Pool type to place Descriptor under on line %d"%_line_num)
		_move_till_next_top()
		return false
		
	var name = line.trim_prefix(VIBE_MARKER).strip_edges()
	if name not in NpcDialogue.Vibe.keys():
		push_error("In_valid Emotional Descriptor on line %d" %_line_num)
		_move_till_next_top()
	else:
		_current_level = MODE_MARKER
		current_vibe = name
		return true

		

func _check_mode(line: String):
	current_mode = ""
	if current_vibe == "":
		push_error("No valid Emotional Descriptor to place Context under on line %d"%_line_num)
		_move_till_next_top()
		return false
	var name = line.trim_prefix(MODE_MARKER).strip_edges()
	if name not in NpcDialogue.PoolContext.keys():
		push_error("Invalid Pool Context on line %d" %_line_num)
		_move_till_next_top()
	else:
		_current_level = SECTION_MARKER
		current_mode = name
		return true

func _check_section(line: String):
	current_section = ""
	if current_mode == "":
		push_error("No valid Emotional Descriptor  to place Context under on line %d"%_line_num)
		_move_till_next_top()
		return false
	var name = line.trim_prefix(SECTION_MARKER).strip_edges()
	current_section = name
	_current_level = NPC_LINE_MARKER
	var locator_name = current_type + SEPARATOR + current_vibe + SEPARATOR + current_mode + SEPARATOR + name
	current_locator_pointer = locator_name
	locator[current_locator_pointer] = []
	section_data = locator[current_locator_pointer]
	current_choice = {"line": "", "responses": []}
	return true

func _check_npc_line(line: String):
	_on_npc_line = false
	if current_section == null:
		push_error("No valid Section to place Context under on line %d"%_line_num)
		_move_till_next_top()
		return false
	var text = line.trim_prefix(NPC_LINE_MARKER).strip_edges()
	if not text.begins_with("\"") and not text.ends_with("\""):
		push_error("NPC line must be contained in qoutes with no other statements, line %d"%_line_num)
		_move_till_next_top()
		return false
	else:
		_current_level = RESPONSE_MARKER
		_on_npc_line = true
		if current_choice["line"] != "" or current_choice["responses"].size() > 0:
			section_data.append(current_choice)
		current_choice = {"line": "", "responses": []}
		text = text.trim_prefix("\"")
		text = text.trim_suffix("\"")
		current_choice["line"] = text
		return true

func _check_responses(line: String):
	if _on_npc_line:
		var check_text = line.trim_prefix(RESPONSE_MARKER).strip_edges()
		var check = validate_response_format(check_text)
		if check:
			return true
		else:
			_move_till_next_top()
	else:
		push_error("No NPC Line to put Pos Responses under, line %d"%_line_num)
		_move_till_next_top()
	return false

func validate_response_format(line: String) -> bool:
	var response = {}
	var text
	var meta_raw
	var found = regex.search(line)
	if found == null:
		return false
	text = found.get_string(1)
	meta_raw = found.get_string(2)
	response["condition"] = "None"
	response["condition_type"] = "None"
	response["effect"] = "None"
	response["tag"] = "None"
	response["text"] = "None"
	
	var meta = JSON.parse_string(meta_raw)
	if meta == null:
		push_error("Invalid Meta Data Formating on Line %d"%_line_num)
		return false
	response["text"] = text
	if meta.has("condition"):
		response["condition"] = meta.condition
	if meta.has("condition_type"):
		response["condition_type"] = meta.condition_type
	if meta.has("effect"):
		response["effect"] = meta.effect
	if meta.has("tag"):
		response["tag"] = meta.tag
	
	current_choice["responses"].append(response)
	return true

func _move_till_next_top():
	var current = _current_level
	_to_skip = hierarchy[current]

func inline_comments_check(line: String) -> String:
	var quotes_stack = 0
	for i in range(line.length()):
		if line[i] == '"':
			quotes_stack += 1 
		if quotes_stack == 2:
			quotes_stack = 0
		if line[i] == COMMENT_MARKER and quotes_stack == 0:
			line = line.substr(0,i)
	if quotes_stack != 0:
		push_error("Uneven number of qouatations in line %d"%_line_num)
	return line
