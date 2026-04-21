class_name Parser
var locator
var pool_script 
var pool_path
var lines

func store_pool(file_path: String):
	pool_path = file_path
	var validator = ParserValidator.new()
	locator = validator.validate_dialogue_file(file_path)

func pool_request(event: String,vibe: String,mode: String,section: String):
	var validator = ParserValidator.new()
	var result = []
	var current_choice = {"line": "", "responses": []}
	var target = "%s_%s_%s_%s"%[event,vibe,mode,section]
	var raw_pool = locator["SECTION"].has(target)
	if raw_pool == false:
		push_error("Pool not found")
		return []
	else:
		var target_line = locator["SECTION"][target]
		if pool_script == null :
			var file = FileAccess.open(pool_path, FileAccess.READ)
			if file == null:
				push_error("Could not open file: %s" % pool_path)
			pool_script = file.get_as_text().split("\n")
			file.close()
		var not_halt = true
		var idx = target_line -1 #lines start counting from 0
		var lines = pool_script
		while not_halt:
			idx += 1 
			var line = lines[idx]
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
