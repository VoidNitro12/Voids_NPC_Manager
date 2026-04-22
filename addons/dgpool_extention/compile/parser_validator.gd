class_name ParserValidator

const EVENT_MARKER = "~"
const VIBE_MARKER = "/"
const MODE_MARKER = "*"
const SECTION_MARKER = "section"
const NPC_LINE_MARKER = "-"
const RESPONSE_MARKER = ">"

var hierarchy = {
	EVENT_MARKER : [VIBE_MARKER,MODE_MARKER,SECTION_MARKER,NPC_LINE_MARKER,RESPONSE_MARKER],
	VIBE_MARKER : [MODE_MARKER,SECTION_MARKER,NPC_LINE_MARKER,RESPONSE_MARKER],
	MODE_MARKER : [SECTION_MARKER,NPC_LINE_MARKER,RESPONSE_MARKER],
	SECTION_MARKER : [NPC_LINE_MARKER,RESPONSE_MARKER],
	NPC_LINE_MARKER : [RESPONSE_MARKER],
	RESPONSE_MARKER: [],
	}

var locator = {"EVENT": {},"VIBE": {},"MODE":{},"SECTION":{}}
var current_event = ""
var current_vibe = ""
var current_mode = ""
var current_section = ""
var _on_npc_line = false
var _line_num = 0
var _current_level
var _to_skip = []
var _valid = false

func validate_dialogue_file(file_path: String) -> Dictionary:
	_valid = false
	_line_num = 0
	current_event = ""
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
		if line.begins_with("#") or line.is_empty():
			continue
		var bare_line = line.strip_edges()
		bare_line = inline_comments_check(bare_line)
		
		if bare_line.begins_with(EVENT_MARKER):
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
	assert(stack_check.has(false) == false, "Unable to parse pool script due to errors")
	return locator

#func get_indent(line: String) -> int:
	#var count = 0
	#for c in line:
		#if c == " " or c == "\t":
			#count += 1
		#else:
			#break
	#return count

#func parse_response_metadata(line: String) -> Dictionary:
	#var text = line
	#var response = {}
	#response["condition"] = "None"
	#response["effect"] = "None"
	#response["tag"] = "None"
#
	#var open_paren = text.find("(")
	#var close_paren = text.find(")")
	#if open_paren != -1 and close_paren != -1:
		#var raw  = text.substr(0, open_paren).strip_edges()
		#raw = raw.trim_prefix("\"")
		#raw = raw.trim_suffix("\"")
		#response["text"] = raw
		#var meta = text.substr(open_paren + 1)
		#meta = meta.trim_suffix(")")
		#var parts = meta.split(",")
		#for part in parts:
			#var kv = part.split(":")
			#var key = kv[0].strip_edges()
			#var value = kv[1].strip_edges()
			#value = value.trim_prefix("\"")
			#value = value.trim_suffix("\"")
			#response[key] = value
	#return response

func _check_event_type(line: String):
	current_event = null
	current_vibe = null
	current_mode = null
	current_section = null
	_on_npc_line = false
	_current_level = EVENT_MARKER
	var event_name = line.trim_prefix(EVENT_MARKER).strip_edges()
	if event_name not in NpcManager._event_types:
		push_error("In_valid Event Type on line %d, skipping. see NpcManager.get_event_types() " %_line_num)
		_move_till_next_top()
		return false
	else:
		_current_level = VIBE_MARKER
		current_event = event_name
		locator["EVENT"][event_name] = _line_num
		return true
		
func _check_vibe(line: String):
	current_vibe = null
	if current_event != null:
		var name = line.trim_prefix(VIBE_MARKER).strip_edges()
		if name not in NpcDialogue.descriptor.keys():
			push_error("In_valid Emotional Descriptor on line %d, Skipping descriptor" %_line_num)
			_move_till_next_top()
		else:
			_current_level = MODE_MARKER
			current_vibe = name
			var locator_name = current_event + "_" + name
			locator["VIBE"][locator_name] = _line_num
			return true
	else:
		push_error("No _valid Event type to place Descriptor under on line %d, Skipping descriptor"%_line_num)
		_move_till_next_top()
	return false

func _check_mode(line: String):
	current_mode = null
	if current_vibe != null:
		var name = line.trim_prefix(MODE_MARKER).strip_edges()
		if name not in NpcDialogue.PoolContext.keys():
			push_error("In_valid Pool Context on line %d Skipping context" %_line_num)
			_move_till_next_top()
		else:
			_current_level = SECTION_MARKER
			current_mode = name
			var locator_name = current_event + "_" + current_vibe + "_" + name
			locator["MODE"][locator_name] = _line_num
			return true
	else:
		push_error("No _valid Emotional Descriptor to place Context under on line %d, Skipping"%_line_num)
		_move_till_next_top()
	return false

func _check_section(line: String):
	current_section = null
	if current_mode != null:
		var name = line.trim_prefix(SECTION_MARKER).strip_edges()
		current_section = name
		_current_level = NPC_LINE_MARKER
		var locator_name = current_event + "_" + current_vibe + "_" + current_mode + "_" + name
		locator["SECTION"][locator_name] = _line_num
		return true
	else:
		push_error("No _valid Emotional Descriptor  to place Context under on line %d, Skipping"%_line_num)
		_move_till_next_top()
		return false

func _check_npc_line(line: String):
	_on_npc_line = false
	if current_section != null:
		var text = line.trim_prefix(NPC_LINE_MARKER).strip_edges()
		if not text.begins_with("\"") and not text.ends_with("\""):
			push_error("NPC line must be contained in qoutes with no other statements, line %d, Skipping"%_line_num)
			_move_till_next_top()
			return false
		else:
			_current_level = RESPONSE_MARKER
			_on_npc_line = true
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

func validate_response_format(text: String) -> bool:
	var quote_pos = text.find("\"")
	var paren_pos = text.find("(")

	if quote_pos == -1:
		push_error("No opening quote, line %d"%_line_num)
		return false
	if paren_pos == -1 or paren_pos < quote_pos:
		push_error("Metadata parentheses must come after quoted text, line %d"%_line_num)
		return false
	if not text.ends_with(")"):
		push_error("Missing closing parenthesis, line %d"%_line_num)
		return false
	return true

func _move_till_next_top():
	var current = _current_level
	_to_skip = hierarchy[current]

func inline_comments_check(line: String) -> String:
	if line.contains("#"):
		var split = line.split("#")
		line = split[0]
	return line
