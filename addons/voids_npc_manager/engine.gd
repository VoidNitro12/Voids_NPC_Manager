@tool
extends Node
## Void's NPC Manager (WIP)
## Main script for the NPC manager

# Minimum version the plugin accepts for old plugin saves
const _MINIMUM_VERSION = "0.2.3"

## Path where all NPC's will be stored. see [method set_npc_saves] to change it.[br]
## By default it is set to: [code] "res://addons/voids_npc_manager/NPCs/" [/code]
var npc_path = "res://addons/voids_npc_manager/NPCs/"

## Path where all Events's will be stored. see [method set_event_saves] to change it.[br]
## By default it is set to: [code] "res://addons/voids_npc_manager/Events/ [/code]
var event_path = "res://addons/voids_npc_manager/Events/"

## Path where data such as custom fields, player data and time are stored.
## see [method set_data_saves] to change it. [br]
## By default it is set to: [code] "res://addons/voids_npc_manager/plugin_data.tres" [/code]
var plugin_data_path: String = "res://addons/voids_npc_manager/plugin_data.tres"

## Set to [code]false[/code] to disable automatic loading of stored plugindata at runtime (_ready)
var load_pluginData_on_runtime: bool = true

## A map of conditions that will be used for parsing any conditional dialogue choice. see [method register_dialogue_condition] to add
var dialogue_conditions = {}

# format = {"res": target, "path": save_path}
var _save_queue = []

#Events fields that the plugin will utilize
var _event_fields = []

#NPC fields that the plugin will utilize
var _npc_fields = []

# For storing event types 
var _event_types = {
	"default_convo": {},
	"UNAWARE": {}
}

# For storing relationship types 
var _relationship_types = []

# For storing all current npc id's
var _npc_ids = []

# For storing all current event id's
var _event_ids = []

# Keeps track of all npcs ever made for id generation purposes
var _npc_counter = 0

# Keeps track of all event ever made for id generation purposes
var _event_counter = 0

## Time for the NPC manager to utilize. Always in 24hr format.
## [br] see [method set_time_format] to set the format the plugin will export and accept time in
var game_time = {
	"hours": 0,
	"minutes": 0,
	"24hr": true,
	"meridian": 'AM'
	}

## Information about the player
var player_data = {
	"id": "0",
	"player_name" : "Player",
		"direct_events": {},
		"indirect_events": {}
}

func _process(delta: float) -> void:
	_operate_save_queue()

func _ready() -> void:
	if load_pluginData_on_runtime:
		load_plugin_data()
	_register_default_event()

## Set the players name in npc data
func set_player_name(name: String):
	player_data["player_name"] = name

## Update the players events lists
## [code]event_type[/code] should be = "direct_events" or "indirect_events"
func update_player_events(event_type: String, event_id: String):
	assert(event_type == "direct_events" or event_type == "indirect_events", "Invalid event type. Must be 'direct_events' or 'indirect_events'")
	player_data[event_type].append(event_id)

## Returns the number of Events in use. 
func num_events() -> int:
	var num = _event_ids.size()
	return num

## Returns the number of NPCs in use. 
func num_npc() -> int:
	var num = _npc_ids.size()
	return num

## Add a field to be used in events. [code]field[/code] is the name of your entry
## eg making all events's contain an extra field "important"
func add_event_field(field: String):
	_event_fields.append(field)

## Deletes a custom event field. 
func remove_event_field(field: String):
	if _event_fields.has(field):
		_event_fields.erase(field)
	else:
		push_error("Event Field does not exist, see get_event_fields")

## Add a field to be used for NPCs. [code]field[/code] is the name of your entry
## eg making all NPC's contain an extra field "job"
func add_npc_field(field: String):
	_npc_fields.append(field)

## Deletes a custom NPC field. 
func remove_npc_field(field: String):
	if _npc_fields.has(field):
		_npc_fields.erase(field)
	else:
		push_error("NPC Field does not exist, see get_npc_fields")

## Returns a list of all current custom event fields 
func get_event_fields() -> Array:
	return _event_fields

## Returns a list of all current custom NPC fields 
func get_npc_fields() -> Array:
	return _npc_fields

## Returns a list of all current event types 
func get_event_types() -> Array:
	var result = []
	for type in _event_types:
		result.append(type)
	return result

## Adds an event type for use in making and handling events. accepts a string for [code]type[/code]. which is used as the name of the type.
## [code]type_values[/code] accepts a list of values that this type will contain.
## for example say I want to make an event about a fight. i can name [code]type[/code] "fight", and [code]type_values[/code]
## ["fighter1","fighter2","initiator","cause"] things like when and where are already handled by events so no need to add them.
## now in future events I can set type to "fight" and will be given the entries in the list to fill in as well, by default they are "None".
## Do note types can benefit from specifics and naunce. say i wanted a fight but there where three people and not 2. well i can use "3vfight" or "1v2fight"
## the point is to make a system where events are as descriptive as possible
func add_event_type(type: String, type_values: Array):
	var type_val = {}
	for type_value in type_values:
		type_val[type_value] = "None"
	_event_types[type] = type_val

func remove_event_type(type: String):
	if _event_types.has(type):
		_event_types.erase(type)
	else:
		push_error("Event Type does not exist, see get_event_types")

## Add an event to memory. accepts a dictionary.
##[codeblock]
##var event_info = {
##	"name": "An event",
##	"type": "type A",
##	"description": "Example event",
##	"time": "13:00",
##	"date": "13th",
##	"day": "Monday",
##	"where": "city",
##	"direct_witness": ["23","32"],
##	"indirect_witness": ["2","45","56","78"]
##	}
##	add_event(event_info)
##[/codeblock]
## [code]event_type_info[/code] accepts a list. this list should contain info relevant to the type of event. see [method add_event_type]. [br]
## Under witness, its refering to npcs that directly witnessed the even and those that should know of it indirectly, its respective subentries should contain NPC ids.
## If added individual NPC's data will be updated automaticaly.
## Any existing custom fields should be included. [br]
## Set [code]involve_player[/code] to [code]true[/code] to add this events to the players data, set [code]player_type[/code] to "direct_events" or "indirect_events" if so
func add_event(event_info: Dictionary, event_type_info: Array, involve_player : bool = false , player_type : String = "none"):
	
	var num_ids = _event_counter + 1
	var event_id =  str(num_ids)
	
	if involve_player:
		event_info.direct_witness.append(player_data.id)
		update_player_events(player_type, event_id)
	
	var event = EventData.new()
	event.create(event_info,event_id)
	var file_name = "Event_%s.tres" %event_id 
	var save_path = event_path + file_name
	_save_queue.append({"res": event, "path": save_path})
	_event_ids.append(event_id)
	_event_counter += 1

	for witness_id in event_info.direct_witness:
		if get_npc(witness_id) == null:
			push_error("Witness ID %s does not exist, skipping" % witness_id)
			continue
		var npc = get_npc(witness_id)
		var dir = "NPC_%s.tres"%npc.npc_id
		npc.direct_events[event_id] = true
		npc.indirect_events[event_id] = false
		_save_queue.append({"res": npc, "path": dir})
	
	for witness_id in event_info.indirect_witness:
		if get_npc(witness_id) == null:
			push_error("Witness ID %s does not exist, skipping" % witness_id)
			continue
		var npc = get_npc(witness_id)
		var dir = "NPC_%s.tres"%npc.npc_id
		npc.direct_events[event_id] = false
		npc.indirect_events[event_id] = true
		_save_queue.append({"res": npc, "path": dir})

## Adds an NPC to memory. accepts dictionaries.
##[codeblock]
## var new_npc = {
##	"name": "Void",
##	"health": 98.7,
##	"friendliness": 63,
##	"expressiveness": 36,
##	"patience": 70,
##	"curiosity": 30,
##	"mood": 50,
##	"personality_range": 20,
##	"direct_events": [],
##	"indirect_events": [],
##	}
## add_npc(new_npc)
##[/codeblock]
##[code]"friendliness"[/code] is an int of range [code]0[/code] to [code]100[/code] on how nice the NPC is. [br]
##[code]"mood"[/code] is an int of range [code]-15[/code] to [code]15[/code] on the current mood of the NPC that affects all other values. [br]
##[code]"patience"[/code] is an int of range [code]0[/code] to [code]100[/code] on how willing the NPC is to talk and for how long. [br]
##[code]"expressiveness"[/code] is an int of range [code]0[/code] to [code]100[/code] on how much the NPC tells things. [br]
##[code]"curiosity"[/code] is an int of range [code]0[/code] to [code]100[/code] on how much the NPC will inquire about things from others. [br]
##[code]"personality_range"[/code] is an int of range [code]30[/code] to [code]40[/code] on how much the NPCs mood can affect other sliders. [br]
##[br]
## Newly made NPcs by default have no relationships.
## For relationships see [method update_npc_relationship]. which should only be run after the npc has already been made to edit or create relationships with the player or other NPCs
func add_npc(npc_info: Dictionary):
	
	var num_ids = _npc_counter + 1
	var npc_id =  str(num_ids)
	var npc = NpcData.new()
	npc.create(npc_info,npc_id)
	var file_name = "NPC_%s.tres" %npc_id 
	var save_path = npc_path + file_name
	_save_queue.append({"res": npc, "path": save_path})
	_npc_ids.append(npc_id)
	_npc_counter += 1

## Deletes an NPC permanently. [br]
## Note that NPC ids are not reassignable, deleting an NPC with an id "1"
## means no NPC will have the id "1" again to avoid potential conflicts.
func remove_npc(npc_id: String):
	var path = npc_path + "NPC_%s.tres" % npc_id
	if not ResourceLoader.exists(path):
		push_error("NPC not found: %s" % npc_id)
		return
	var to_delete_npc = get_npc(npc_id)
	for npc in to_delete_npc.relationships:
		var target_npc = get_npc(npc)
		if target_npc.relationships.has(npc_id):
			target_npc.relationships.erase(npc_id)
			var save_path = npc_path + "NPC_%s.tres" % npc
			_save_queue.append({"res": target_npc, "path": save_path})
	
	var all_event_ids = to_delete_npc.direct_events + to_delete_npc.indirect_events
	for event in all_event_ids:
		var changed = false
		var target_event = get_event(event)
		if target_event.direct_witness.has(npc_id):
			target_event.direct_witness.erase(npc_id)
			changed = true
		if target_event.indirect_witness.has(npc_id):
			target_event.indirect_witness.erase(npc_id)
			changed = true
		if changed:
			var save_path = event_path + "Event_%s.tres" % event
			_save_queue.append({"res": target_event, "path": save_path})
	DirAccess.remove_absolute(path)
	_npc_ids.erase(npc_id)

## Deletes an Event permanently.[br]
## Note that Event ids are not reassignable, deleting an Event with an id "1"
## means no Event will have the id "1" again to avoid potential conflicts.
func remove_event(event_id: String):
	var path = event_path + "Event_%s.tres" % event_id
	if not ResourceLoader.exists(path):
		push_error("Event not found: %s" % event_id)
		return
	var target_event = get_event(event_id)
	var all_witness_ids = target_event.direct_witness + target_event.indirect_witness
	for npc in all_witness_ids:
		var changed = false
		var target_npc = get_npc(npc)
		if target_npc.direct_events.has(event_id):
			target_npc.direct_events.erase(event_id)
			changed = true
		if target_npc.indirect_events.has(event_id):
			target_npc.indirect_events.erase(event_id)
			changed = true
		if not target_npc.relationships.is_empty():
			for rel in target_npc.relationships:
				if target_npc in rel.memories:
					rel.memories.erase(event_id)
					changed = true
		if changed:
			var save_path = npc_path + "NPC_%s.tres" % npc
			_save_queue.append({"res": target_npc, "path": save_path})
	DirAccess.remove_absolute(path)
	_event_ids.erase(event_id)

## Returns a dictionary with all npcs containing the same name and their ids.
## If looking for a single NPCs id by name. see [method get_npc_by_name]
func get_all_npc_by_name(target: String) -> Dictionary:
	var results = {}
	for id in _npc_ids:
		var file_name = "NPC_%s.tres"%id
		var npc = ResourceLoader.load(npc_path + file_name)
		if npc == null:
			push_warning("Could not load file NPC_%s.tres"%id)
			continue
		if npc.npc_name == target:
			results[npc.npc_id] = npc
	if results.is_empty():
		push_error("No NPC found with the name: %s" %target)
	return results

## returns an NPCs Resource from its name. Returns the first found NPC with said name
## If looking for a dictonary with all NPCs possessing the same name and their respective ids. see [method get_all_npc_by_name]
## If no NPC with this name is found, will return [code]null[/code]
func get_npc_by_name(target: String)  -> Resource: 
	var found_npc
	for id in _npc_ids:
		var file_name = "NPC_%s.tres"%id
		var npc = ResourceLoader.load(npc_path + file_name)
		if npc == null:
			push_warning("Could not load file NPC_%s.tres"%id)
			continue
		if npc.npc_name == target:
			found_npc = npc
			break
	if found_npc == null:
		push_error("No NPC found with the name: %s" % target)
	return found_npc

## Checks if a given input is a valid id or name of an NPC and if true, Returns their id.[br]
## If passing a name checks for the first npc with that name only. Will return [code]null[/code] if the id/name passed is invalid
func _check_for_npc(id) -> Resource:
	var npc
	if _npc_ids.has(id):
		npc = get_npc(id)
	else:
		npc = get_npc_by_name(id)
	if npc == null:
		push_error("No NPC found. must input a valid NPC id or name as a string")
	return npc

## Updates an NPCs relationship data using the desired NPCs name or id, and which NPC to edit their relationship
## [code]npc[/code] is the NPC whos relationship you wish to update, and [code]target[/code] is the NPC
## that you want to change [code]npc[/code]'s relationship with[br]
## [code]value[/code] is the value you want to replace the current relationship value with.
## If you want to edit an NPCs relationship with the player, set [code]target = "player"[/code]. 
## Accepts either id's or names
func update_npc_relationship(npc: String, target: String, value: int, type: String):
	var sel_npc = _check_for_npc(npc)
	var sel_target
	var sel_npc_events = sel_npc.direct_events 
	value = clamp(value, 0, 100)
	
	if type not in _relationship_types:
		push_error("Type: %s is not a valid custom type. see add_relationship_type" %type)
		return
	
	if target != "player":
		sel_target = _check_for_npc(target)
		var target_npc_events = sel_target.direct_events
		var shared_memories = []
		
		for event_id in  sel_npc_events.keys():
			if target_npc_events.has(event_id):
				shared_memories.append(event_id)
		
		var update = {
			"name": sel_npc.npc_name,
			"type": type,
			"value": value,
			"memories": shared_memories
		}
		var target_id = sel_target.npc_id
		sel_npc.relationships[target_id] = update
		
	elif target == "player":
		var player_events = player_data.direct_events
		var shared_memories = []
		
		for event_id in  sel_npc_events.keys():
			if player_events .has(event_id):
				shared_memories.append(event_id)
		
		var update = {
			"name": player_data.player_name,
			"type": type,
			"value": value,
			"memories": shared_memories, 
		}
		
		sel_npc.relationships["player"] = update
	
	var dir_sel = npc_path + "NPC_%s.tres" % sel_npc.npc_id
	_save_queue.append({"res": sel_npc, "path": dir_sel})
	if sel_target != null:
		var dir_target = npc_path + "NPC_%s.tres" % sel_target.npc_id
		_save_queue.append({"res": sel_target, "path": dir_target})

## To add custom relationship types for NPCs. Accepts a string for [code]type[/code]. which is used as the name of the type.
func add_relationship_type(type: String):
	_relationship_types.append(type)

## sets the format used to display time stored. Can be in 24hr or 12hr format. 
## [code]true[/code] for 24hr and [code]false[/code] for 12hr.
## Defaults to 24hr if not set
func set_time_format(use_24hr = true):
	game_time["24hr"] = use_24hr

## Use to let the plugin know the current time of the game as its used in different parts, like events
## and NPC's. [br]
## meridian defaults to "AM" if not set or if invalid
## Make sure to set preffered format with [method set_time_format] else it will use a 24hr format
func update_game_time(hour: int, minute: int, meridian: String = "AM"):
	if game_time["24hr"] == true:
		game_time["hours"] = clamp(hour,0,23)
		game_time["minutes"] = clamp(minute,0,59)
	elif hour > 12 or hour == 0:
		game_time["hours"] = _format_24hr(hour, meridian)
		game_time["minutes"] = clamp(minute,0,59)
		if meridian != "AM" and meridian != "PM":
			meridian = "AM"
		game_time["meridian"] = meridian

# Convert 24hr to 12hr
func _format_12hr(hour: int) -> Array:
	var am_pm = "AM" if hour < 12 else "PM"
	hour = hour % 12
	if hour == 0:
		hour = 12
	return [hour,am_pm]

# Convert 12hr to 24hr
func _format_24hr(hour: int, meridian: String) -> int:
	if meridian.to_lower() == "pm" and hour != 12:
		hour = 12 + hour
	if meridian.to_lower() == "am" and hour == 12:
		hour = 0
	return hour

## gets an NPC's Resource from its id and returns an array of said resource and the NPC's directory.
func get_npc(npc_id: String) -> Resource:
	var target = "NPC_%s.tres" %npc_id
	var dir = npc_path + target
	var npc
	if not ResourceLoader.exists(dir):
		push_warning("NPC file not found")
	else:
		npc = ResourceLoader.load(dir)
	
	return npc

## gets an Events's Resource from its id and returns an array of said resource and the Event's directory.
func get_event(event_id: String) -> Resource:
	var target = "Event_%s.tres" %event_id
	var dir = event_path + target
	if not ResourceLoader.exists(dir) and event_id != "0":
		push_error("Event file not found")
	elif not ResourceLoader.exists(dir) and event_id == "0":
		_register_default_event()
	var event = ResourceLoader.load(dir)
	
	return event

func _load_json(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		push_error("File not found: " + path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null:
		push_error("Failed to parse JSON: " + path)
		return {}
	return parsed

func _load_dgpool_file(path: String) -> String:
	var validator = ParserValidator.new()
	validator.validate_dialogue_file(path)
	return path

## Accepts a .TXT file for dialogue in a specific format to utilize in dialogue.
## will be converted to a custom extention later. [br]
func load_dialogue_pools(event_pool_path: String, character_pool_path: String):
	NpcDialogue._dialogue_pool_event = _load_dgpool_file(event_pool_path)
	NpcDialogue._dialogue_pool_character = _load_dgpool_file(character_pool_path)

## set the file path NPC's data should be stored in. Must be an absolute path
## see [method set_event_saves] to set event save path
func set_npc_saves(path: String):
	if not path.is_absolute_path():
		push_error("path must be an absolute path")
		return
	if event_path == path:
		push_error("Event and NPC save paths cannot be the same")
		return
	if plugin_data_path == path:
		push_error("Cannot be the same with plugin_data_path")
		return
	var dir = DirAccess.open(path)
	if dir == null:
		dir.make_dir_recursive(path)
	npc_path = path

## set the file path Event data should be stored in. Must be an absolute path
## see [method set_npc_saves] to set NPC save path
func set_event_saves(path: String):
	if not path.is_absolute_path():
		push_error("path must be an absolute path")
		return
	if npc_path == path:
		push_error("Event and NPC save paths cannot be the same")
		return
	if plugin_data_path == path:
		push_error("Cannot be the same with plugin_data_path")
		return
	var dir = DirAccess.open(path)
	if dir == null:
		dir.make_dir_recursive(path)
	event_path = path
	
## set the file path general data should be stored in. Include custom fields, player data etc.
## Must be an absolute path. expects a folder path in [code]path[/code] and a file name in [code]file_name[/code]
func set_data_saves(file_name: String,path: String):
	if not file_name.ends_with(".tres"):
		file_name += ".tres"
	if not path.ends_with("/"):
		path += "/"
	var save_path = path + file_name
	if save_path.is_absolute_path() == false :
		push_error("Provided Path must be an absolute path")
		return
	if npc_path == path:
		push_error("Cannot be the same with NPC path")
		return
	if event_path == path:
		push_error("Cannot be the same with Event path")
		return
	var dir = DirAccess.open(path)
	if dir == null:
		dir.make_dir_recursive(path)
	plugin_data_path = save_path
	save_plugin_data()

## saves relevant plugin information to plugin_data_path. see [method set_data_saves] to change the path.
func save_plugin_data():
	var data = PluginData.new()
	var save_data = {
		"game_time": game_time,
		"player_data":player_data,
		"event_fields": _event_fields,
		"event_types": _event_types,
		"npc_fields": _npc_fields,
		"relationship_types": _relationship_types,
		"npc_ids": _npc_ids,
		"event_ids": _event_ids,
		"npc_counter": _npc_counter,
		"event_counter": _event_counter,
		"npc_path": npc_path,
		"event_path": event_path,
		"plugin_data_path": plugin_data_path
	}
	data.store(save_data)
	_save_queue.append({"res": data, "path": plugin_data_path})

## Loads any stored data in [member plugin_data_path].[br]
## merge dictates wether the plugin should simply overwrite current data with the save file or not 
## is automatically called at runtime if [member load_PluginData_on_runtime] is [code]true[/code]. 
func load_plugin_data(merge: bool = false): 
	if not ResourceLoader.exists(plugin_data_path):
		push_warning("No lugin savedata file found at %s, creating file" %plugin_data_path)
		save_plugin_data()
		return
	
	var data = ResourceLoader.load(plugin_data_path)
	if data == null: 
		push_error("Unable to load plugin savedata from: %s" %plugin_data_path)
		return 
	
	if data.get("plugin_version") == null:
		push_error("Pluging savedata version does not exist")
		return
	var current_major = int(_MINIMUM_VERSION.split(".")[0])
	var current_minor = int(_MINIMUM_VERSION.split(".")[1])
	var save_major =  int(data.plugin_version.split(".")[0])
	var save_minor = 	int(data.plugin_version.split(".")[1])
	
	if save_major < current_major:
		push_error("Plugin savedata Outdated, expected at least %s got %s"%[_MINIMUM_VERSION,data.get("plugin_version")])
		return
	elif save_minor < current_minor:
		push_warning("Plugin savedata slightly outdated, Proceeding with load. Plugin Version: %s , Save Version: %s"%[_MINIMUM_VERSION,data.get("plugin_version")])
	elif save_minor > current_minor:
		push_warning("Plugin savedata from newer version. Proceeding with load. Plugin Version: %s , Save Version: %s"%[_MINIMUM_VERSION,data.get("plugin_version")])
		
	var required_fields = ["npc_ids", "event_ids", "npc_counter", "relationship_types", "npc_fields", "event_fields", "npc_path", "event_path"]
	for field in required_fields:
		if not data.has(field):
			push_error("Required Field missing from plugin save_data : %s" %field)
			return
	var new_state = {
	"game_time" = data.game_time,
	"player_data" = data.player_data,
	"_event_fields" = data.event_fields,
	"_event_types" = data.event_types,
	"_npc_fields" = data.npc_fields,
	"_relationship_types" = data.relationship_types,
	"_npc_ids" = data.npc_ids,
	"_event_ids"= data.event_ids,
	"_npc_counter" = data.npc_counter,
	"_event_counter" = data.event_counter,
	"npc_path" = data.npc_path,
	"event_path" = data.event_path,
	"plugin_data_path" = data.plugin_data_path
	}
	
	if not merge:
		game_time = new_state.game_time
		player_data = new_state.player_data
		_event_fields = new_state._event_fields 
		_event_types = new_state._event_types 
		_npc_fields = new_state._npc_fields
		_relationship_types = new_state._relationship_types
		_npc_ids = new_state._npc_ids
		_event_ids = new_state._event_ids
		_npc_counter = new_state._npc_counter
		_event_counter = new_state._event_counter
		npc_path = new_state.npc_path
		event_path = new_state.event_path 
		plugin_data_path = new_state.plugin_data_path 


## Used to add a condition and its respective function to [member dialogue_conditions]
## a funtion needs to exist to run the check, for example
##[codeblock]
##	NpcEngine.register_dialogue_condition("is_friendly", _check_friendly)
##	func _check_friendly(npc):
##		return friendliness > 0.5
##[/codeblock]
## all functions used in this dict should accept an NPC resource argument
func register_dialogue_condition(condition_text: String, callable:  Callable): 
	dialogue_conditions[condition_text] = callable

# Creates a default event to serve in place for generic conversations when theres no event or character as a topic
func _register_default_event(): 
	var type_info = []
	var event_id = "0"
	var event_info ={
	"name": "Starter",
	"type": "default_convo",
	"description": "Just used for non specific conversations",
	"time": "00:00",
	"date": "1st",
	"day": "Sunday",
	"where": "Game",
	"direct_witness": [],
	"indirect_witness": []
	}
	var event = EventData.new()
	event.create(event_info,event_id)
	var file_name = "Event_%s.tres" %event_id 
	var save_path = event_path + file_name
	_save_queue.append({"res": event, "path": save_path})

# Saves all changed files in the plugin that have been stored in a queue, call in delta to save per frame.[br]
# Set min of 0 and max of 50
func _operate_save_queue(per_frame_save: int = 10):
	if Engine.is_editor_hint():
		return
	if _save_queue.is_empty():
		return
	per_frame_save = clamp(per_frame_save,1,50)
	var saved = 0
	while saved < per_frame_save and _save_queue.size() > 0:
		var save = _save_queue.pop_front()
		var error = ResourceSaver.save(save.res, save.path)
		if error != OK:
			push_error("Failed to save: ", save.path)
		saved += 1

## Returns and array 2 dictionaries of the relationship data between 2 NPCs. [br]
## Returns an empty dictionary if one of the npc doesnt have any information on the other. [br]
## #Note: Player not currently included
func get_npc_relationship(npc_1,npc_2) -> Array:
	var npc_1_id = _check_for_npc(npc_1)
	var npc_2_id = _check_for_npc(npc_2)
	var npc1 = get_npc(npc_1_id)
	var npc2 = get_npc(npc_2_id)
	var result1 = {}
	var result2 = {}
	if npc1.relationships.has(npc_2_id):
		result1 = npc1.relationships[npc_2_id]
	if npc2.relationships.has(npc_1_id):
		result2 = npc2.relationships[npc_1_id]
	return [result1,result2]
