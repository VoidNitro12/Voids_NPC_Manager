# Void's NPC Manager

A simple NPC handler system that stores events and links them to NPCs, with relationship tracking, mood-based dialogue, and dynamic placeholder replacement.

## Features
- NPCs with custom fields and personality traits
- Event tracking with type-specific data
- Relationship system with shared memories
- Mood-based dialogue vibes (WARM, COLD, HOSTILE, etc.)
- Custom dialogue script format with `.TXT` files `#will be changed to custom .dgpool format`
- Persistent save/load using Godot Resources

## Getting Started

To use this plugin, create a setup function to define your custom fields, event types, and save paths **before** loading any NPCs or events.

### Example Setup

```gdscript
func setup_NpcManager():
    # Save Paths (folders must exist or be created)
    NpcManager.set_npc_saves("res://Game_manager/NPCs/")
    NpcManager.set_event_saves("res://Game_manager/Events/")
    NpcManager.set_data_saves("res://Game_manager/", "NpcManager_data.tres")
    
    # Player Data
    NpcManager.set_player_name(player.player_name)
    
    # Custom NPC Fields
    NpcManager.add_npc_field("age")
    NpcManager.add_npc_field("gender")
    NpcManager.add_npc_field("status")
    NpcManager.add_npc_field("class_year")
    NpcManager.add_npc_field("department")
    NpcManager.add_npc_field("location")
    NpcManager.add_npc_field("job")
    NpcManager.add_npc_field("energy")
    NpcManager.add_npc_field("traits")
    NpcManager.add_npc_field("familiarity")
    
    # Event Types and Fields
    NpcManager.add_event_type("fight", ["fighter1", "fighter2", "cause"])
    NpcManager.add_event_type("celebration", ["organizer", "reason"])
    NpcManager.add_event_field("importance")
    
 
```

###Notes

- Save paths are folders (except set_data_saves which takes a folder + filename)
- Folders are not auto-created—ensure they exist or create them in code
- Custom fields become accessible via npc.custom["field_name"]
- Generated JSON templates provide a starting point for dialogue writing

## Documentation
- [Dialogue Syntax and rules](addons/voids_npc_manager/examples/Docs/Dialogue_Syntax.md)
