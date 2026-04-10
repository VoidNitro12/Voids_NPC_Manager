# Void's NPC Manager

A simple NPC handler system that stores events and links them to NPCs, with relationship tracking, mood-based dialogue, and dynamic placeholder replacement.

## Features
- NPCs with custom fields and personality traits
- Event tracking with type-specific data
- Relationship system with shared memories
- Mood-based dialogue vibes (WARM, COLD, HOSTILE, etc.)
- JSON dialogue templates with `{placeholder}` replacement
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
    
    # Generate Dialogue Templates
    NpcManager.generate_dialogue_character_template("character_dialogue", "res://Game_manager/")
    NpcManager.generate_dialogue_event_template("event_dialogue", "res://Game_manager/")
```

###Notes

- Save paths are folders (except set_data_saves which takes a folder + filename)
- Folders are not auto-created—ensure they exist or create them in code
- Custom fields become accessible via npc.custom["field_name"]
- Generated JSON templates provide a starting point for dialogue writing



## Dialogue
For dialogue writing, you should write lines as templates. After generating the dialogue JSON files for character and event-related dialogue, use formatted placeholders where possible and the manager should fill in information.

Example with Events

When creating an event, the manager requires an event type and expects certain fields to be provided for that type. For example, an event with type = "fight" might include fields like:

- fighter1
- fighter2
- cause

When writing dialogue for a fight event, you can include a placeholder in your template:

```
"They got into a fight just because of {cause}."
```

When that line is used during actual dialogue, {cause} will be automatically replaced with the actual cause stored in that specific event's resource.

This works for any field in any event type. Simply wrap the field name in curly braces {} and the manager will swap it out with the real value.

Example with Player Name

The same applies to the player's name. Use {player0} anywhere in your dialogue, and it will be replaced with the player's actual name at runtime.
