@tool
extends EditorPlugin

const ENGINE_AUTO = "NpcManager"
const DIALOGUE_AUTO = "NpcDialogue"

func _enable_plugin() -> void:
	add_autoload_singleton(ENGINE_AUTO, "res://addons/voids_npc_manager/Engine.gd")
	add_autoload_singleton(DIALOGUE_AUTO, "res://addons/voids_npc_manager/Dialogue.gd")



func _disable_plugin() -> void:
	remove_autoload_singleton(ENGINE_AUTO)
	remove_autoload_singleton(DIALOGUE_AUTO)


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
