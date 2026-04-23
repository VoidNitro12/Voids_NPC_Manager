@tool
class_name NpcData
extends Resource

@export var custom: Dictionary = {}

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var health: float = 100.0
@export var base_friendliness: int = 0
@export var base_expressiveness: int = 0
@export var base_patience: int = 0
@export var base_curiosity: int = 0
@export var friendliness: int = 0
@export var expressiveness: int = 0
@export var patience: int = 0
@export var curiosity: int = 0
@export var mood: int = 0
@export var personality_range: int = 0
var direct_events: Dictionary= {}
var indirect_events: Dictionary= {}
@export var relationships: Dictionary = {}

func create(npc_info: Dictionary, id: String):
	npc_id = id
	npc_name = npc_info.name
	health = npc_info.health
	base_friendliness = clampf(npc_info.friendliness, 0, 100)
	base_expressiveness = clampf(npc_info.expressiveness, 0, 100)
	base_patience = clampf(npc_info.patience, 0, 100)
	base_curiosity = clampf(npc_info.curiosity, 0, 100)
	friendliness = base_friendliness
	expressiveness = base_expressiveness
	patience = base_patience
	curiosity = base_curiosity
	mood = clampf(npc_info.mood, -15, 15)
	personality_range = clampf(npc_info.personality_range, 10, 30)
	direct_events = npc_info.direct_events
	indirect_events = npc_info.indirect_events
	relationships = {}
	
	var custom_fields = NpcManager._npc_fields
	for field in custom_fields:
		if npc_info.has(field):
			custom[field] = npc_info[field]
		else:
			push_warning("Custom Field '%s' not included in npc_info " %field)
