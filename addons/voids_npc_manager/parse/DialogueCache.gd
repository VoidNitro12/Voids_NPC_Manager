@tool
class_name DialogueCache
var _pool_event_locator
var _pool_character_locator
var _lexer = Lexer.new()
var _validator = Validator.new()
var _parser = Parser.new()
var _dialogue_store = ScriptData.new()
var _script_data_path = "res://addons/voids_npc_manager/parse/ScriptData.tres"

func parse_pool(file_path: String):
	var tokens = _lexer.tokenize(file_path)
	var valid = _validator.token_validation(tokens)
	var script 
	if valid:
		script = _parser.parse_tokens(tokens)
	else:
		push_error("Unable to parse script due to errors")
		return
	var locator = script[0]
	var type = script[1]
	match type:
		NpcDialogue.PoolType.EVENT:
			_pool_event_locator = locator
			_dialogue_store.save_lookup(type,locator)
			NpcManager._save_queue.append({"res": _dialogue_store, "path": _script_data_path})
		NpcDialogue.PoolType.NPC:
			_pool_character_locator = locator
			_dialogue_store.save_lookup(type,locator)
			NpcManager._save_queue.append({"res": _dialogue_store, "path": _script_data_path})
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")
			return

## Returns an Array of lines and responses. returns an empty array if any error is found
func pool_request(pool_type: int, field: String, vibe: String, context: String, section: String) -> Array:
	var locator
	var field_check_passed = true
	match pool_type:
		NpcDialogue.PoolType.EVENT:
			locator = _pool_event_locator
			if locator == null:
				_load_pools()
			field_check_passed = _check_fields(NpcDialogue.PoolType.EVENT,field,vibe)
			if not field_check_passed:
				return []
		NpcDialogue.PoolType.NPC:
			locator = _pool_character_locator
			if locator == null:
				_load_pools()
			field_check_passed = _check_fields(NpcDialogue.PoolType.NPC,field,vibe)
			if not field_check_passed:
				return []
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")
			return []
	var result = []
	var target_parts = [field,vibe,context,section]
	var target = _make_locator_target(target_parts)
	if locator == null:
		return []
	var has_target = locator.has(target)
	if not has_target :
		push_error("target not found in pool, target: %s"%target)
		return []
	else:
		result = locator[target]
	return result

func _check_fields(pool_type: int, field: String,vibe: String) -> bool:
	var matches = {"Field": false, "Vibe": false}
	var mismatches = []
	var check_passed = true
	match pool_type:
		NpcDialogue.PoolType.EVENT:
			if NpcManager._event_types.has(field):
				matches["Field"] = true
			if NpcDialogue.Vibe.keys().has(vibe):
				matches["Vibe"] = true
		NpcDialogue.PoolType.NPC:
			if NpcManager._npc_fields.has(field):
				matches["Field"] = true
			if NpcDialogue.Vibe.keys().has(vibe):
				matches["Vibe"] = true
		_:
			push_error("Invalid PoolType see NpcDialogue.PoolType")
			return false
		
	if not matches["Field"]:
		check_passed = false
		mismatches.append("Field: " + field)
	if not matches["Vibe"]:
		check_passed = false
		mismatches.append("Vibe: " + vibe)
	if not check_passed:
		mismatches = str(mismatches)
		push_error("Some entries do not match any existing in the NpcManager, Mismatches: %s"%mismatches)
		return false
	return true

func _make_locator_target(parts: Array) -> String:
	var SEPARATOR = _lexer.SEPARATOR
	return SEPARATOR.join(parts)

func _load_pools():
	if not ResourceLoader.exists(_script_data_path):
		push_warning("No dialogue lookup data found at %s, make sure to call DialogueCache.parse_pool() " %_script_data_path)
		return
	
	var data = ResourceLoader.load(_script_data_path)
	if data == null: 
		push_error("Unable to load dialogue lookup data from: %s" %_script_data_path)
		return 
	
	if data.get("event_dialogue_lookup") == null:
		push_error("No event lookup found")
	else:
		_pool_event_locator = data.event_dialogue_lookup
	
	if data.get("npc_dialogue_lookup") == null:
		push_error("No npc lookup found")
	else:
		_pool_character_locator = data.npc_dialogue_lookup
