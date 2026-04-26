@tool
class_name EventData
extends Resource

var custom = {}

@export var event_id: String = ""
@export var event_name: String = ""
@export var type: String = ""
@export var description: String = ""
@export var time: String = ""
@export var date: String = ""
@export var day: String = ""
@export var where: String = ""
@export var direct_witness: Array = []
@export var indirect_witness: Array = []

func create(event_info: Dictionary, id: String, type_data: Array):
	event_id = id
	event_name = event_info.name
	type = event_info.type
	description = event_info.description
	time = event_info.time
	date = event_info.date
	day = event_info.day
	where = event_info.where
	direct_witness = event_info.direct_witness
	indirect_witness = event_info.indirect_witness
	
	var custom_fields = NpcManager._event_fields
	for field in custom_fields:
		if event_info.has(field):
			custom[field] = event_info[field]
		else:
			push_warning("Custom Field '%s' for general Events not included in event_info " %field)
	
	var custom_type_fields = NpcManager._event_types[type]
	for field in custom_type_fields:
		if event_info.has(field):
			custom[field] = event_info[field]
		else:
			push_warning("Custom Field '%s' for Type %s not included in event_info " %[field,type])
