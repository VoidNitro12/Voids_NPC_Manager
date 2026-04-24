@tool
class_name PluginData
extends Resource

var plugin_version: String
var npc_path: String = "res://addons/voids_npc_manager/NPCs/"
var event_path: String = "res://addons/voids_npc_manager/Events/"
var plugin_data_path: String = "res://addons/voids_npc_manager/"
var event_fields: Array = []
var npc_fields: Array = []
var event_types: Dictionary = {}
var relationship_types: Array = []
var npc_ids: Array = []
var event_ids: Array = []
var npc_counter : int 
var event_counter : int 
var game_time: Dictionary = {
	"hours": 0,
	"minutes": 0,
	"24hr": true,
	"meridian": 'AM'
	}
var player_data: Dictionary = {
	"id": "0",
	"player_name" : "Player",
		"direct_events": [],
		"indirect_events": []
	}
	
func store(info : Dictionary): 
	npc_path  = info.npc_path 
	event_path = info.event_path
	plugin_data_path = info.plugin_data_path
	event_fields = info.event_fields
	npc_fields = info.npc_fields
	event_types = info.event_types
	relationship_types = info.relationship_types 
	npc_ids = info.npc_ids
	event_ids = info.event_ids
	event_counter = info.event_counter
	npc_counter = info.npc_counter
	game_time = info.game_time
	player_data = info.player_data
