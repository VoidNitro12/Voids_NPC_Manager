@tool
class_name PluginData
extends Resource

@export var npc_path: String = "res://addons/void's_npc_manager/NPCs/"
@export var event_path: String = "res://addons/void's_npc_manager/Events/"
@export var plugin_data_path: String = "res://addons/void's_npc_manager/"
@export var _custom_event_fields: Array = []
@export var _custom_npc_fields: Array = []
@export var _custom_event_types: Dictionary = {}
@export var _custom_relationship_types: Array = []
@export var npc_ids: Array = []
@export var event_ids: Array = []
@export var npc_counter : int = 0
@export var event_counter : int = 0
@export var game_time: Dictionary = {
	"hours": 0,
	"minutes": 0,
	"24hr": true,
	"meridian": 'AM'
	}
@export var player_data: Dictionary = {
	"id": "0",
	"player_name" : "Player",
		"direct_events": [],
		"indirect_events": []
	}
	
func store(info : Dictionary): 
	npc_path  = info.npc_path 
	event_path = info.event_path
	plugin_data_path = info.plugin_data_path
	_custom_event_fields = info._custom_event_fields
	_custom_npc_fields = info._custom_npc_fields
	_custom_event_types = info._custom_event_types
	_custom_relationship_types = info._custom_relationship_types 
	npc_ids = info.npc_ids
	event_ids = info.event_ids
	event_counter = info.event_counter
	npc_counter - info.npc_counter
	game_time = info.game_time
	player_data = info.player_data
