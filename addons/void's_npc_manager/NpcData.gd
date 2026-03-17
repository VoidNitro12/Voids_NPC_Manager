@tool
class_name NpcData
extends Resource

var custom_fields = NpcEngine._custom_npc_fields
@export var custom: Dictionary = {}

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var health: float = 100.0
@export var base_friendliness: float = 0.0
@export var base_expressiveness: float = 0.0
@export var base_patience: float = 0.0
@export var base_curiosity: float = 0.0
@export var friendliness: float = 0.0
@export var expressiveness: float = 0.0
@export var patience: float = 0.0
@export var curiosity: float = 0.0
@export var mood: float = 0.0
@export var personality_range: float = 0.0
@export var direct_events: Array = []
@export var indirect_events: Array = []
@export var relationships: Dictionary = {}

func create(npc_info: Dictionary, id: String):
	npc_id = id
	npc_name = npc_info.name
	health = npc_info.health
	base_friendliness = clampf(npc_info.friendliness, 0.0, 1.0)
	base_expressiveness = clampf(npc_info.expressiveness, 0.0, 1.0)
	base_patience = clampf(npc_info.patience, 0.0, 1.0)
	base_curiosity = clampf(npc_info.curiosity, 0.0, 1.0)
	friendliness = base_friendliness
	expressiveness = base_expressiveness
	patience = base_patience
	curiosity = base_curiosity
	mood = clampf(npc_info.mood, -1.0, 1.0)
	personality_range = clampf(npc_info.personality_range, 1.0, 3.0)
	direct_events = npc_info.direct_events
	indirect_events = npc_info.indirect_events
	relationships = {}
	
	for field in custom_fields:
		if npc_info.has(field):
			custom[field] = npc_info[field]
		else:
			push_warning("Custom Field '%s' not included in npc_info " %field)
