class_name Validator

var line_regex = RegEx.new()
var meta_data_regex = RegEx.new()
var intent_regex = RegEx.new()
var line_format = "\"([^\"]+)\"\\s*(\\([^)]*\\))"
var meta_data_format = "(\\w+):\"([^\"]*)\""
var intent_format = "(\\w+)"
var pool_type
var has_pool_type = false
var in_type = false
var in_vibe = false
var in_mode = false
var in_section = false
var in_npc_line = false
var in_response = false

func token_validation(tokens: Array) -> bool:
	line_regex.compile(line_format)
	meta_data_regex.compile(meta_data_format)
	intent_regex.compile(intent_format)
	var valid
	var checks = []
	
	if tokens.is_empty():
		push_error("No tokens to parse")
		return false
	
	for token in tokens:
		match token.marker:
			Lexer.POOL_MARKER:
				valid = _check_pool(token)
				checks.append(valid)
			Lexer.TYPE_MARKER:
				valid = _check_type(token)
				checks.append(valid)
			Lexer.VIBE_MARKER:
				valid = _check_vibe(token)
				checks.append(valid)
			Lexer.MODE_MARKER:
				valid = _check_mode(token)
				checks.append(valid)
			Lexer.SECTION_MARKER:
				valid = _check_section(token)
				checks.append(valid)
			Lexer.NPC_LINE_MARKER:
				valid = _check_npc_line(token)
				checks.append(valid)
			Lexer.RESPONSE_MARKER:
				valid = _check_response(token)
				checks.append(valid)
			Lexer.INVALID_MARKER:
				push_error("Unrecognized line beginning on line %d"%token.line_num)
				checks.append(false)
	if checks.has(false):
		return false
	return true

func _check_pool(token: Lexer.Token)-> bool:
	if has_pool_type:
		push_error("Pool Type on line %d when pool type already exists"%token.line_num)
		return false
	match token.value:
		"EVENT":
			pool_type = NpcDialogue.PoolType.EVENT
		"NPC":
			pool_type = NpcDialogue.PoolType.NPC
		_:
			push_error("Invalid Pool Type on line %d, should be EVENT or NPC"%token.line_num)
			has_pool_type = false
			return false
	has_pool_type = true
	return true

func _check_type(token: Lexer.Token)-> bool:
	_reset_flags()
	if not has_pool_type:
		push_error("No valid pool type to place type on line %d under"%token.line_num)
		in_type = false
		return false
	match pool_type:
		NpcDialogue.PoolType.EVENT:
			if token.value not in NpcManager._event_types:
				push_error("Invalid Pool type on line %d. see NpcManager.get_event_types() " %token.line_num)
				in_type = false
				return false
		NpcDialogue.PoolType.NPC:
			if token.value  not in NpcManager._relationship_types:
				push_error("Invalid Relationship Type on line %d. see NpcManager.get_event_types() " %token.line_num)
				in_type = false
				return false
	in_type = true
	return true

func _check_vibe(token: Lexer.Token)-> bool:
	if not in_type:
		push_error("No valid type to place Descriptor under on line %d"%token.line_num)
		in_vibe = false
		return false
	if token.value not in NpcDialogue.Vibe.keys():
		print(token.value)
		print( NpcDialogue.Vibe.keys())
		push_error("Invalid Emotional Descriptor on line %d" %token.line_num)
		in_vibe = false
		return false
	in_vibe = true
	return true

func _check_mode(token: Lexer.Token)-> bool:
	if not in_vibe:
		push_error("No valid Emotional Descriptor to place Context under on line %d"%token.line_num)
		in_mode = false
		return false
	if token.value not in NpcDialogue.PoolContext.keys():
		push_error("Invalid Pool Context on line %d" %token.line_num)
		in_mode = false
		return false
	in_mode = true
	return true

func _check_section(token: Lexer.Token)-> bool:
	if not in_mode:
		push_error("No valid Pool Context to place sectiont under on line %d"%token.line_num)
		in_section = false
		return false
	in_section = true
	return true

func _check_npc_line(token: Lexer.Token)-> bool:
	if not in_section:
		push_error("No valid Section to place NPC line under on line %d"%token.line_num)
		in_npc_line = false
		return false
	var line = token.value
	
	var found = line_regex.search(line)
	
	if found == null:
		push_error("Invalid syntax for Npc line on line %d"%token.line_num)
		in_npc_line = false
		return false
		
	var text = found.get_string(1)
	var meta_raw = found.get_string(2)
	
	meta_raw = meta_raw.strip_edges()
	text = text.strip_edges()
	var meta_found = intent_regex.search(meta_raw)

	if meta_found == null and meta_raw != "()":
		push_error("Invalid intent Formating on Line %d"%token.line_num)
		in_npc_line = false
		return false
	
	var meta = ""
	
	if meta_found != null:
		meta = meta_found.get_string(1)
	
	if meta != "" and meta not in NpcDialogue.intent_commands.keys():
		push_error("Unidentified intent on line %d"%token.line_num)
		in_response = false
		return false

	in_npc_line = true
	return true

func _check_response(token: Lexer.Token)-> bool:
	if not in_npc_line:
		push_error("No valid NPC line to place response under, line %d"%token.line_num)
		in_response = false
		return false
	var line = token.value
	var found = line_regex.search(line)
	if found == null:
		push_error("Invalid syntax for response on line %d"%token.line_num)
		in_response = false
		return false
	var text = found.get_string(1)
	var meta_raw = found.get_string(2)
	text = text.strip_edges()
	var meta_found = meta_data_regex.search_all(meta_raw)
	if meta_found.is_empty():
		push_error("Invalid Meta Data Formating on Line %d"%token.line_num)
		in_response = false
		return false
	for meta in meta_found:
		var key = meta.get_string(1)
		if key not in ["condition","condition_type","effect","intent","tag"]:
			push_error("Unidentified meta data on line %d"%token.line_num)
			in_response = false
			return false
		if key == "type":
			var value = meta.get_string(2)
			if value not in ["generic","event","npc"]:
				push_error("Unidentified 'type' on line %d, should be generic,event or npc "%token.line_num)
				in_response = false
				return false
	in_response = true
	return true

func _reset_flags():
	in_type = false
	in_vibe = false
	in_mode = false
	in_section = false
	in_npc_line = false
	in_response = false
