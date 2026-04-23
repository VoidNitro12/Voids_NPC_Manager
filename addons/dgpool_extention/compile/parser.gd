class_name Parser
var _lines
var _pool_event_locator
var _pool_character_locator
var _pool_event_path
var _pool_character_path
var _pool_event_script
var _pool_character_script


func store_pool(file_path: String, type: int ):
	var validator = ParserValidator.new()
	match type:
		NpcDialogue.PoolType.EVENT:
			_pool_event_path = file_path
			_pool_event_locator = validator.validate_dialogue_file(file_path)
		NpcDialogue.PoolType.NPC:
			_pool_character_path = file_path
			_pool_character_locator = validator.validate_dialogue_file(file_path)
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")

func pool_request(pool_type: int, field: String,vibe: int,mode: int,section: String):
	var locator
	var pool_path
	var pool_script
	match pool_type:
		NpcDialogue.PoolType.EVENT:
			var sel_script
			locator = _pool_event_locator
			pool_path = _pool_event_path
			if _pool_event_script == null :
				_pool_event_script = _load_scripts(_pool_event_path)
			else:
				sel_script = _pool_event_script
			pool_script = sel_script
			_check_fields(NpcDialogue.PoolType.EVENT,field,vibe)
		NpcDialogue.PoolType.NPC:
			var sel_script
			locator = _pool_character_locator
			pool_path = _pool_character_path
			if _pool_character_script == null :
				_pool_character_script = _load_scripts(_pool_character_path)
			else:
				sel_script = _pool_character_script
			pool_script = sel_script
			_check_fields(NpcDialogue.PoolType.NPC,field,vibe)
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")
	var validator = ParserValidator.new()
	var result = []
	var current_choice = {"line": "", "responses": []}
	mode = NpcDialogue.PoolContext.keys()[mode]
	var target = "%s_%s_%s_%s"%[field,vibe,mode,section]
	var raw_pool = locator["SECTION"].has(target)
	
	if raw_pool == false:
		push_error("Pool not found")
		return []
	else:
		var target_line = locator["SECTION"][target]
		var not_halt = true
		var idx = target_line -1 #_lines start counting from 0
		var _lines = pool_script
		while not_halt:
			idx += 1 
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
				var text = line.trim_prefix(ParserValidator.RESPONSE_MARKER).strip_edges()
				var response = {}
				response["condition"] = "None"
				response["condition_type"] = "None"
				response["effect"] = "None"
				response["tag"] = "None"
				
				var open_paren = text.find("(")
				var close_paren = text.find(")")
				if open_paren != -1 and close_paren != -1:
					var raw  = text.substr(0, open_paren).strip_edges()
					raw = raw.trim_prefix("\"")
					raw = raw.trim_suffix("\"")
					response["text"] = raw
					var meta = text.substr(open_paren + 1)
					meta = meta.trim_suffix(")")
					var parts = meta.split(",")
					for part in parts:
						var kv = part.split(":")
						var key = kv[0].strip_edges()
						var value = kv[1].strip_edges()
						value = value.trim_prefix("\"")
						value = value.trim_suffix("\"")
						response[key] = value
				current_choice["responses"].append(response)
				
		result.append(current_choice)
	return result

func _check_fields(pool_type: int, field: String,vibe: int):
	var matches = {"Field": false, "Vibe": false}
	match pool_type:
		NpcDialogue.PoolType.EVENT:
			if field in NpcManager._event_types:
				matches["Field"] = true
			if vibe in NpcDialogue.descriptor.keys():
				matches["Vibe"] = true
		NpcDialogue.PoolType.NPC:
			if field in NpcManager._npc_fields:
				matches["Field"] = true
				if vibe in NpcDialogue.descriptor.keys():
					matches["Vibe"] = true
		_:
			push_error("Invalid PoolType seeNpcDialogue.PoolType")
	for entry in matches:
		if not matches[entry]:
			var mismatches = str(matches)
			push_error("Some entries do not match any existing in the NpcManager, Mismatches: %s"%mismatches)

func _load_scripts(pool_path: String):
	var pool_script
	var file = FileAccess.open(pool_path, FileAccess.READ)
	if file == null:
		push_error("Could not open file: %s" % pool_path)
	pool_script = file.get_as_text().split("\n")
	file.close()
	return pool_script
