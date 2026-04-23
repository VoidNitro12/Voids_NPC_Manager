# Voids NPC Manager v0.2.2
- moved `custom_fields` var out of class level assignment inside `create()` in EventData.gd and NpcData.gd
- fixed dictionary look up issue in `_query_char()` in dialogue.gd
- made the ranges definition in `_vibe_band()` a const dictionary in dialogue.gd
- made the vibe maps in `_vibe_map()` a constant array in dialogue.gd and made the selection contain early exits and more readable variables
- changed direct and indirect events in NpcData.gd from Arrays to Dictionaries and removed the ability to edit them from the editor via @export
- changed player_data.direct_events and player_data.indirect_events in engine.gd from Arrays to Dictionaries
- updated `update_npc_relationship()` in engine.gd to use dictionary lookups instead of array looping
- updated `remove_npc()` and `remove_event()` to remove every trace of said event/npc in plugin data. may be slightly expensive
- implemented a save queue that saves any changes to files at a default rate of 10 saves per frame. as opposed to imediately
- fixed `_check_for_npc()` in engine.gd to check if id exists in stored ids as opposed to just checking for a valid int
- updated Dialogue_Syntax.md
- added `get_npc_relationship()` to engine.gd to get relationship data between 2 npcs.

# Dgpool Extension v0.1.2
- fixed scripts not saving to cache after loading in `pool_request()` in parser.gd


# Note
 Extensive testing is not being carried out between minor updates.
