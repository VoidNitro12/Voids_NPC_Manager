extends Resource
class_name Parser

var result = {}
var current_event = ""
var current_vibe = ""
var current_mode = ""
var current_section = ""
var split
var response_index = 0

func parse_dialogue_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	var lines = file.get_as_text().split("\n")
	file.close()

	for line in lines:
		if line.begins_with("#") or line.is_empty():
			continue
		var bare_line = line.strip_edges()
		
		if bare_line.begins_with("~"):
			handle_event(bare_line)
		elif bare_line.begins_with("/"):
			handle_vibe(bare_line)
		elif bare_line.begins_with("*"):
			handle_mode(bare_line)
		elif bare_line.ends_with(":"):
			handle_section_header(bare_line)
		elif bare_line.begins_with("-"):
			handle_npc_line(bare_line)
		elif bare_line.begins_with(">"):
			handle_response_line(bare_line)
	print(result)

#func get_indent(line: String) -> int:
	#var count = 0
	#for c in line:
		#if c == " " or c == "\t":
			#count += 1
		#else:
			#break
	#return count

func handle_event(line: String):
	var event_name = line.trim_prefix("~").strip_edges()
	result[event_name] = {}
	current_event = event_name
	current_vibe = ""
	current_mode = ""
	current_section = ""

func handle_mode(line: String):
	var name = line.trim_prefix("*").strip_edges()
	current_mode = name
	result[current_event][current_vibe][current_mode] = {}

func handle_vibe(line: String):
	var name = line.trim_prefix("/").strip_edges()
	current_vibe = name
	result[current_event][current_vibe] = {}

func handle_section_header(line: String):
	var text = line.trim_suffix(":").strip_edges()
	current_section = text
	result[current_event][current_vibe][current_mode][current_section] = []

func handle_npc_line(line: String):
	var text = line.trim_prefix("-").strip_edges()
	text = text.trim_prefix("\"")
	text = text.trim_suffix("\"")
	var entry = {"line": text, "responses": []}
	var target = result[current_event][current_vibe][current_mode][current_section]
	target.append(entry)

func handle_response_line(line: String):
	# Parse metadata from parentheses
	var response_data = parse_response_metadata(line)
	var target = result[current_event][current_vibe][current_mode][current_section]
	var last_entry = target[target.size() - 1]
	last_entry["responses"].append(response_data)
	
func parse_response_metadata(line: String) -> Dictionary:
	var text = line.trim_prefix(">").strip_edges()
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
		print(meta)
		var parts = meta.split(",")
		for part in parts:
			var kv = part.split(":")
			var key = kv[0].strip_edges()
			var value = kv[1].strip_edges()
			value = value.trim_prefix("\"")
			value = value.trim_suffix("\"")
			response[key] = value
	return response
