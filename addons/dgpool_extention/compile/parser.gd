class_name Parser
var _lines
var _pool_event_locator
var _pool_character_locator
var _pool_event_path
var _pool_character_path
var _pool_event_script
var _pool_character_script
var validator = ParserValidator.new()

func store_pool(file_path: String):
	var script = validator.validate_dialogue_file(file_path)
	var locator = script[0]
	var type = script[1]
	match type:
		NpcDialogue.PoolType.EVENT:
			_pool_event_path = file_path
			_pool_event_locator = locator
		NpcDialogue.PoolType.NPC:
			_pool_character_path = file_path
			_pool_character_locator = locator
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")
			return

## Returns an Array of lines and responses. returns an empty array if any error is found
func pool_request(pool_type: int, field: String, vibe: String, context: String, section: String) -> Array:
	var locator
	var pool_path
	var pool_script
	var field_check_passed = true
	match pool_type:
		NpcDialogue.PoolType.EVENT:
			locator = _pool_event_locator
			pool_path = _pool_event_path
			if _pool_event_script == null :
				_pool_event_script = _load_scripts(_pool_event_path)
				pool_script = _pool_event_script
			else:
				pool_script = _pool_event_script
			field_check_passed = _check_fields(NpcDialogue.PoolType.EVENT,field,vibe)
			if not field_check_passed:
				return []
		NpcDialogue.PoolType.NPC:
			locator = _pool_character_locator
			pool_path = _pool_character_path
			if _pool_character_script == null :
				_pool_character_script = _load_scripts(_pool_character_path)
				pool_script = _pool_character_script
			else:
				pool_script = _pool_character_script
			field_check_passed = _check_fields(NpcDialogue.PoolType.NPC,field,vibe)
			if not field_check_passed:
				return []
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")
			return []
	var result = []
	var current_choice = {"line": "", "responses": []}
	var target_parts = [field,vibe,context,section]
	var target = _make_locator_target(target_parts)
	var has_target = locator["SECTION"].has(target)
	if not has_target :
		push_error("target not found in pool, target: %s"%target)
		return []
	else:
		var target_line = locator["SECTION"][target]
		var not_halt = true
		var idx = target_line 
		var _lines = pool_script
		var current_script_size  = _lines.size()
		while not_halt:
			idx += 1 
			if idx > current_script_size or idx <= 0:
				break
			var line = _lines[idx]
			line = line.strip_edges()
			line = validator.inline_comments_check(line)
			
			if not line.begins_with(ParserValidator.NPC_LINE_MARKER) and not line.begins_with(ParserValidator.RESPONSE_MARKER):
				#if line != "":
					#print("Stopping, begins with %s"%line[0])
				#else:
					#print("Stopping, end of script")
				not_halt = false
				break
			
			if line.begins_with(ParserValidator.NPC_LINE_MARKER):
				if current_choice["line"] != "" or current_choice["responses"].size() > 0:
					result.append(current_choice)
				current_choice = {"line": "", "responses": []}
				var text = line.trim_prefix(ParserValidator.NPC_LINE_MARKER).strip_edges()
				text = text.trim_prefix("\"")
				text = text.trim_suffix("\"")
				current_choice["line"] = text
			
			if line.begins_with(ParserValidator.RESPONSE_MARKER):
				line = line.trim_prefix(ParserValidator.RESPONSE_MARKER).strip_edges()
				var response = {}
				var text
				var meta_raw
				response["condition"] = "None"
				response["condition_type"] = "None"
				response["effect"] = "None"
				response["tag"] = "None"
				response["text"] = "None"
				
				var pattern = "\"([^\"]+)\"\\s*(\\{[^\\}]+\\})"
				var regex = RegEx.new()
				regex.compile(pattern)
				var found = regex.search(line)
				if found:
					text = found.get_string(1)
					meta_raw = found.get_string(2)
				var meta = JSON.parse_string(meta_raw)
				if meta == null:
					push_error("Failed JSON parse")
					return []
				response["text"] = text
				if meta.has("comdition"):
					response["condition"] = meta.condition
				if meta.has("condition_type"):
					response["condition_type"] = meta.condition_type
				if meta.has("effect"):
					response["effect"] = meta.effect
				if meta.has("tag"):
					response["tag"] = meta.tag
				
				current_choice["responses"].append(response)
				
		result.append(current_choice)
	return result

func _check_fields(pool_type: int, field: String,vibe: String) -> bool:
	var matches = {"Field": false, "Vibe": false}
	var mismatches = []
	var check_passed = true
	match pool_type:
		NpcDialogue.PoolType.EVENT:
			if NpcManager._event_types.has(field):
				matches["Field"] = true
			if NpcDialogue.Vibe.keys().has(vibe):
				matches["Vibe"] = true
		NpcDialogue.PoolType.NPC:
			if NpcManager._npc_fields.has(field):
				matches["Field"] = true
			if NpcDialogue.Vibe.keys().has(vibe):
				matches["Vibe"] = true
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")
			return false
		
	if not matches["Field"]:
		check_passed = false
		mismatches.append("Field: " + field)
	if not matches["Vibe"]:
		check_passed = false
		mismatches.append("Vibe: " + vibe)
	if not check_passed:
		mismatches = str(mismatches)
		push_error("Some entries do not match any existing in the NpcManager, Mismatches: %s"%mismatches)
		return false
	return true

func _load_scripts(pool_path: String):
	var pool_script
	var file = FileAccess.open(pool_path, FileAccess.READ)
	if file == null:
		push_error("Could not open file: %s" % pool_path)
	pool_script = file.get_as_text().split("\n")
	file.close()
	return pool_script

func _make_locator_target(parts: Array) -> String:
	var SEPARATOR = validator.SEPARATOR
	return SEPARATOR.join(parts)
