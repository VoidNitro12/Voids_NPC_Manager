# Void's NPC Manager v0.3.0 (alpha1,alpha2)
- removed `load_dialogue_pools()` and `_load_dgpool_file()` from Engine.gd
- changed all instances of `make_dir_recursive() to `make_dir_recursive_absolute()`
- renamed `Dialogue_Syntax.md` -> `DialogueSyntax.md` and added `GettingStarted.md`
- renamed `engine.gd` -> `Engine.gd` and `dialogue.gd` -> `Dialogue.gd`
- removed `merge` argument from `load_plugin_data()` entirely in Engine.gd
- added `get_npc_relationship()` to get relationship data from an npc in Engine.gd
- all functions in Engine.gd now only take npc_ids (not names)
- added `flush_save_queue()` to Engine.gd
- `add_event()` in Engine.gd now makes use of the `event_type_data` parameter (formerly event_type_info)
- `create()` in EventData.gd now validates event type specific fields
- fixed `update_game_time()` in Engine.gd not properly dealing with 12hr time
- removed DialogueConditionType.RELATIONSHIP in Dialogue.gd
- filled in PoolType.NPC section in `talk_to_npc()` in Dialogue.gd
- `_condition_check()` in Dialogue.gd now exits early on DialogueConditionType.CUSTOM
- added validation checks to `_check_str_condition()` in Dialogue.gd


# Dgpool Extension v0.2.0 (alpha1,alpha2)
- renamed `compile/` folder -> to `parse/` folder
- renamed `parser.gd` -> to `DialogueCache.gd` and no longer does runtime parsing and now just does lookups of stored data
- added ScriptData.gd resource class
- renamed `parser_validator.gd` -> to `Parser.gd`
- added const COMMENT_MARKER to Parser.gd and set to "#"
- improved `inline_comments_check()` in Parser.gd to better check for comments and double as a quotation check
