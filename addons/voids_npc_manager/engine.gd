@tool
extends Node
## Void's NPC Manager (WIP)
## Main script for the NPC manager

## Path where all NPC's will be stored. see [method set_npc_saves] to change it.[br]
## By default it is set to: [code] "res://addons/void's_npc_manager/NPCs/" [/code]
var npc_path = "res://addons/voids_npc_manager/NPCs/"

## Path where all Events's will be stored. see [method set_event_saves] to change it.[br]
## By default it is set to: [code] "res://addons/void's_npc_manager/Events/ [/code]
var event_path = "res://addons/voids_npc_manager/Events/"

## Path where data such as custom fields, player data and time are stored.
## see [method set_data_saves] to change it. [br]
## By default it is set to: [code] "res://addons/void's_npc_manager/plugin_data.tres" [/code]
var plugin_data_path: String = "res://addons/voids_npc_manager/plugin_data.tres"

## Set to [code]false[/code] to disable automatic loading of stored plugindata at runtime (_ready)
var load_PluginData_on_runtime: bool = true

## The number of default templates to serve as a scaffolding for dialogue structures. Will generate none if set to 0, though the manager expects a 
## certain format for pools, so that is unadvised. 
var default_pool_on_generation: int = 1

## During generation of dialogue template jsons. tags are fields where each response leads too. this dictates how many tags should exists
var chat_tag_fields: int = 1

## A map of conditions that will be used for parsing any conditional dialogue choice. see [method register_dialogue_condition] to add
var dialogue_conditions = {}

#Events fields that the plugin will utilize
var _event_fields = []

#NPC fields that the plugin will utilize
var _npc_fields = []

# For storing event types 
var _event_types = {
	"default_convo": {}
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
		"direct_events": [],
		"indirect_events": []
}

func _ready() -> void:
	if load_PluginData_on_runtime:
		load_plugin_data()
	_register_default_event()

## Set the players name in npc data
func set_player_name(name: String):
	player_data["player_name"] = name

## Update the players events lists
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
	_event_fields.erase(field)

## Add a field to be used for NPCs. [code]field[/code] is the name of your entry
## eg making all NPC's contain an extra field "job"
func add_npc_field(field: String):
	_npc_fields.append(field)

## Deletes a custom NPC field. 
func remove_npc_field(field: String):
	_npc_fields.erase(field)

## Returns a list of all current custom event fields 
func see_event_fields() -> Array:
	return _event_fields

## Returns a list of all current custom NPC fields 
func see_npc_fields() -> Array:
	return _npc_fields

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
##	add_event(new_event)
##[/codeblock]
## [code]event_type_info[/code] accepts a list. this list should contain info relevant to the type of event. see [method add_event_type]. [br]
## Under witness, its refering to npcs that directly witnessed the even and those that should know of it indirectly, its respective subentries should contain NPC ids.
## If added individual NPC's data will be updated automaticaly.
## Any existing custom fields should be included. [br]
## Set [code]involve_player[/code] to [code]true[/code] to add this events to the players data, set [code]player_type[/code] to "direct_event" or "event" if so
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
	ResourceSaver.save(event,save_path)
	_event_ids.append(event_id)
	_event_counter += 1
	save_plugin_data()

	for witness in event_info.direct_witness:
		var aquired = get_npc(witness)
		var npc = aquired[0]
		var dir = aquired[1]
		if npc == null:
			push_warning("NPC id %s in direct witness' doesnt exist", witness)
		else:
			npc.direct_events.append(event_id)
			ResourceSaver.save(npc,dir)
	
	for witness in event_info.indirect_witness:
		var aquired = get_npc(witness)
		var npc = aquired[0]
		var dir = aquired[1]
		if npc == null:
			push_warning("NPC id %s in indirect witness' doesnt exist", witness)
		else:
			npc.indirect_events.append(event_id)
			ResourceSaver.save(npc,dir)

## Adds an NPC to memory. accepts dictionaries.
##[codeblock]
## var new_npc = {
##	"name": "Void",
##	"health": 98.7,
##	"friendliness": 1.4,
##	"expressiveness": 0.5,
##	"patience": 0.7,
##	"curiosity": 0.3,
##	"mood": 1.0,
##	"personality_range": 1.8,
##	"direct_events": [],
##	"indirect_events": [],
##	}
##[/codeblock]
##[code]"friendliness"[/code] is a float of range [code]0.0[/code] to [code]1.0[/code] on how nice the NPC is. [br]
##[code]"mood"[/code] is a float of range [code]-1.0[/code] to [code]1.0[/code] on the current mood of the NPC that affects all other values. [br]
##[code]"patience"[/code] is a float of range [code]0.0[/code] to [code]1.0[/code] on how willing the NPC is to talk and for how long. [br]
##[code]"expressiveness"[/code] is a float of range [code]0.0[/code] to [code]1.0[/code] on how much the NPC tells things. [br]
##[code]"curiosity"[/code] is a float of range [code]0.0[/code] to [code]1.0[/code] on how much the NPC will inquire about things from others. [br]
##[code]"personality_range"[/code] is a float of range [code]1.0[/code] to [code]3.0[/code] on how much the NPCs mood can affect other sliders. [br]
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
	ResourceSaver.save(npc,save_path)
	_npc_ids.append(npc_id)
	_npc_counter += 1
	save_plugin_data()

## Deletes an NPC permanently. [br]
## Note that NPC ids are not reassignable, deleting an NPC with an id "1"
## means no NPC will have the id "1" again to avoid potential conflicts.
func remove_npc(npc_id: String):
	var path = npc_path + "NPC_%s.tres" % npc_id
	if ResourceLoader.exists(path):
		DirAccess.remove_absolute(path)
		_npc_ids.erase(npc_id)
		save_plugin_data()
	else:
		push_error("NPC not found: %s" % npc_id)

## Deletes an Event permanently.[br]
## Note that Event ids are not reassignable, deleting an Event with an id "1"
## means no Event will have the id "1" again to avoid potential conflicts.
func remove_event(event_id: String):
	var path = event_path + "Event_%s.tres" % event_id
	if ResourceLoader.exists(path):
		DirAccess.remove_absolute(path)
		_event_ids.erase(event_id)
		save_plugin_data()
	else:
		push_error("Event not found: %s" % event_id)

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

# Checks if a given input is a valid id or name of an NPC and if true, Returns their id
func _check_for_npc(id) -> Resource:
	var npc
	if id.is_valid_int():
		var list = get_npc(id)
		npc = list[0]
	else:
		npc = get_npc_by_name(id)
		assert(npc != null, "No NPC found. must input a valid NPC id or name as a string")
	return npc

## Updates an NPCs relationship data using the desired NPCs name or id, and which NPC to edit their relationship
## [code]npc[/code] is the NPC whos relationship you wish to update, and [code]target[/code] is the NPC
## that you want to change [code]npc[/code]'s relationship with[br]
## If you want to edit an NPCs relationship with the player, set [code]target = "player"[/code]. 
## Accepts either id's or names
func update_npc_relationship(npc: String, target: String, value: float, type: String,):
	var sel_npc = _check_for_npc(npc)
	var sel_target
	var sel_npc_events = sel_npc.direct_events 
	
	if type not in _relationship_types:
		push_error("Type: %s is not a valid custom type. see add_relationship_type" %type)
	
	if target != "player":
		sel_target = _check_for_npc(target)
		var target_npc_events = sel_target.direct_events
		var shared_memories = []
		
		for i in sel_npc_events: 
			for j in target_npc_events: 
				if i == j:
					shared_memories.append(i)
					break
		
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
		
		for i in sel_npc_events: 
			for j in player_events : 
				if i == j:
					shared_memories.append(i)
					break
		
		var update = {
			"name": player_data.player_name,
			"type": type,
			"value": value,
			"memories": shared_memories, 
		}
		
		sel_npc.relationships["player"] = update
	
	var dir = npc_path + "NPC_%s.tres" % sel_npc.npc_id
	ResourceSaver.save(sel_npc, dir)

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
##Make sure to set preffered format with [method set_time_format] else it will use a 24hr format
func update_game_time(hour: int, minute: int, meridian: String = "AM"):
	if game_time["24hr"] == true:
		game_time["hours"] = hour
		game_time["minutes"] = minute
	elif hour > 12 or hour == 0:
		game_time["hours"] = format_24hr(hour, meridian)
		game_time["minutes"] = minute
		game_time["meridian"] = meridian

## Convert 24hr to 12hr
func format_12hr(hour: int) -> Array:
	var am_pm = "AM" if hour < 12 else "PM"
	hour = hour % 12
	if hour == 0:
		hour = 12
	return [hour,am_pm]

## Convert 12hr to 24hr
func format_24hr(hour: int, meridian: String) -> int:
	if meridian.to_lower() == "pm" and hour != 12:
		hour = 12 + hour
	if meridian.to_lower() == "am" and hour == 12:
		hour = 12
	return hour

## gets an NPC's Resource from its id and returns an array of said resource and the NPC's directory.
func get_npc(npc_id: String) -> Array:
	var target = "NPC_%s.tres" %npc_id
	var dir = npc_path + target
	var npc
	if not ResourceLoader.exists(dir):
		push_warning("NPC file not found")
	else:
		npc = ResourceLoader.load(dir)
	
	return [npc,dir]

## gets an Events's Resource from its id and returns an array of said resource and the Event's directory.
func get_event(event_id: String) -> Array:
	var target = "Event_%s.tres" %event_id
	var dir = event_path + target
	if not ResourceLoader.exists(dir) and event_id != "0":
		push_error("Event file not found")
	elif not ResourceLoader.exists(dir) and event_id == "0":
		_register_default_event()
	var event = ResourceLoader.load(dir)
	
	return [event,dir]

## Generates a json file based on all the registered event types for easier dialogue writing.
## Deals with dialogue pertaining to events.
## Expects a folder path in [code]path[/code] and a file name in [code]file_name[/code]
func generate_dialogue_event_template(file_name:String, path: String):
	if path.is_absolute_path() == false :
		push_error("Provided Path must be an absolute path")
		return
	if file_name.ends_with(".json") == false:
		file_name += ".json"
	if not path.ends_with("/"):
		path += "/"
	var save_path = path + file_name
	var template = {}
	var default_style = {"line": "None", "responses": []}
	var response_style = {"text": "None", "condition": "None", "effect": "None", "tag": "None"}
	for type in _event_types:
		template[type] = {"direct":{}, "indirect":{}}
		for descriptor_name in NpcDialogue.descriptor.keys() :
			template[type]["direct"][descriptor_name] = {}
			var direct_target = template[type]["direct"][descriptor_name] 
			
			direct_target["Reactive"] = {"greetings": []}
			direct_target["Proactive"] = {"greetings": []}
			for num in range(default_pool_on_generation):
				var line = default_style.duplicate(true)
				line["responses"] = [response_style.duplicate(true)]
				direct_target["Reactive"]["greetings"].append(line)
				
				var line2 = default_style.duplicate(true)
				line2["responses"] = [response_style.duplicate(true)]
				direct_target["Proactive"]["greetings"].append(line2)
			
			template[type]["indirect"][descriptor_name] = {}
			var indirect_target = template[type]["indirect"][descriptor_name] 
			
			indirect_target["Reactive"] = {"greetings": []}
			indirect_target["Proactive"] = {"greetings": []}
			for num in range(default_pool_on_generation):
				var line = default_style.duplicate(true)
				line["responses"] = [response_style.duplicate(true)]
				indirect_target["Reactive"]["greetings"].append(line)
				
				var line2 = default_style.duplicate(true)
				line2["responses"] = [response_style.duplicate(true)]
				indirect_target["Proactive"]["greetings"].append(line2)
			
	template["UNAWARE"] = {}
	for descriptor_name in NpcDialogue.descriptor.keys() :
		template["UNAWARE"][descriptor_name] = {}
		var unaware = template["UNAWARE"][descriptor_name] 
		
		unaware["Reactive"] = {"greetings": []}
		unaware["Proactive"] = {"greetings": []}
		for num in range(default_pool_on_generation):
				var line = default_style.duplicate(true)
				line["responses"] = [response_style.duplicate(true)]
				unaware["Reactive"]["greetings"].append(line)
				
				var line2 = default_style.duplicate(true)
				line2["responses"] = [response_style.duplicate(true)]
				unaware["Proactive"]["greetings"].append(line2)
		
		template["UNAWARE"][descriptor_name]["Chat"] = {}
		for val in chat_tag_fields:
			var tag = str(val)
			template["UNAWARE"][descriptor_name]["Chat"][tag] = []
			for num in range(default_pool_on_generation):
				template["UNAWARE"][descriptor_name]["Chat"][tag].append(default_style)
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(template, "\t"))
	file.close()
	print("Event dialogue template generated at: ", save_path)
	

## generates a json file based on all the registered event types for easier dialogue writing
## Deals with dialogue pertaining to NPC's or the player.
## Expects a folder path in [code]path[/code] and a file name in [code]file_name[/code]
func generate_dialogue_character_template(file_name:String, path: String):
	# Currently outdated while building
	if path.is_absolute_path() == false :
		push_error("Provided Path must be an absolute path")
		return
	if file_name.ends_with(".json") == false:
		file_name += ".json"
	if not path.ends_with("/"):
		path += "/"
	var save_path = path + file_name
	var template = {}
	var default_style = {"line": "None", "responses": [{"text": "None", "condition": "None", "effect": "None", "tag": "None"}]}
	for type in _relationship_types:
		template[type] = {}
		for descriptor_name in NpcDialogue.descriptor.keys() :
			template[type][descriptor_name] = {}
			template[type][descriptor_name]["Reactive"] = {}
			template[type][descriptor_name]["Reactive"]["greetings"] = []
			for num in default_pool_on_generation:
				template[type][descriptor_name]["Reactive"]["greetings"].append(default_style)
			
			template[type][descriptor_name]["Proactive"] = {}
			template[type][descriptor_name]["Proactive"]["greetings"] = []
			for num in default_pool_on_generation:
				template[type][descriptor_name]["Proactive"]["greetings"].append(default_style)
			
			template[type][descriptor_name]["Chat"] = {}
			for val in chat_tag_fields:
				var tag = str(val)
				template[type][descriptor_name]["Chat"][tag] = []
				for num in default_pool_on_generation:
					template[type][descriptor_name]["Chat"][tag].append(default_style)
			
	template["UNAWARE"] = {}
	for descriptor_name in NpcDialogue.descriptor.keys() :
		template["UNAWARE"][descriptor_name] = {}
		template["UNAWARE"][descriptor_name]["Reactive"] = {}
		template["UNAWARE"][descriptor_name]["Reactive"]["greetings"] = []
		for num in default_pool_on_generation:
			template["UNAWARE"][descriptor_name]["Reactive"]["greetings"].append(default_style)
		
		template["UNAWARE"][descriptor_name]["Proactive"] = {}
		template["UNAWARE"][descriptor_name]["Proactive"]["greetings"] = []
		for num in default_pool_on_generation:
			template["UNAWARE"][descriptor_name]["Proactive"]["greetings"].append(default_style)
		
		template["UNAWARE"][descriptor_name]["Chat"] = {}
		for val in chat_tag_fields:
			var tag = str(val)
			template["UNAWARE"][descriptor_name]["Chat"][tag] = []
			for num in default_pool_on_generation:
				template["UNAWARE"][descriptor_name]["Chat"][tag].append(default_style)
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write file")
		return
	file.store_string(JSON.stringify(template, "\t"))
	file.close()
	print("Character Dialogue template generated at: ", save_path)

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

## Accepts a json file for dialogue in a specific format to utilize in dialogue.
## see [method generate_dialogue_character_template] and [method generate_dialogue_event_template]
## for an automated json file pertaining to dialogue
func load_dialogue_pools(event_pool_path: String, character_pool_path: String):
	NpcDialogue._dialogue_pool_event = _load_json(event_pool_path)
	NpcDialogue._dialogue_pool_character = _load_json(character_pool_path)

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
	if not dir.dir_exists(path):
		DirAccess.make_dir_absolute(path)
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
	if not dir.dir_exists(path):
		DirAccess.make_dir_absolute(path)
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
	plugin_data_path = save_path
	save_plugin_data()

## saves relevant plugin information to plugin_data_path. see [method set_data_saves] to change the path.
## is automatically called after [method add_npc] and [method add_event]. 
## Though it is still advised to call periodically regardless to not lose data
func save_plugin_data():
	var data = PluginData.new()
	var save_data = {
		"game_time": game_time,
		"player_data":player_data,
		"_event_fields": _event_fields,
		"_event_types": _event_types,
		"_npc_fields": _npc_fields,
		"_relationship_types": _relationship_types,
		"npc_ids": _npc_ids,
		"event_ids": _event_ids,
		"npc_counter": _npc_counter,
		"event_counter": _event_counter,
		"npc_path": npc_path,
		"event_path": event_path,
		"plugin_data_path": plugin_data_path
	}
	data.store(save_data)
	ResourceSaver.save(data,plugin_data_path)

## Loads any stored data in [member plugin_data_path].
## is automatically called at runtime if [member load_PluginData_on_runtime] is [code]true[/code]
func load_plugin_data(): 
	if not ResourceLoader.exists(plugin_data_path):
		push_warning("No savedata file found at %s" %plugin_data_path)
		return
	var data = ResourceLoader.load(plugin_data_path)
	game_time = data.game_time
	player_data = data.player_data
	_event_fields = data._event_fields
	_event_types = data._event_types
	_npc_fields = data._npc_fields
	_relationship_types = data._relationship_types
	_npc_ids = data.npc_ids
	_event_ids = data.event_ids
	_npc_counter = data.npc_counter
	_event_counter = data.event_counter
	npc_path = data.npc_path
	event_path = data.event_path
	plugin_data_path = data.plugin_data_path

## Used to add a condition and its respective function to [member dialogue_conditions]
## a funtion needs to exist to run the check, for example
##[codeblock]
##	NpcEngine.register_dialogue_condition("is_friendly", _check_friendly)
##	func _check_friendly(npc):
##		return friendliness > 0.5
##[/codeblock]
## all functions used in this dict should accept an NPC resorce argument
func register_dialogue_condition(condition_text: String, callable:  Callable): 
	dialogue_conditions[condition_text] = callable

## Creates a default event to serve in place for generic conversations when theres no event or character as a topic
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
	ResourceSaver.save(event,save_path)
