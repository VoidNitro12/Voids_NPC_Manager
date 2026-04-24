# Void's NPC Manager v0.2.3

- Path setters now auto-create directories with `make_dir_recursive()`
- Plugin versioning system with `MINIMUM_VERSION` constant in engine.gd
- `merge` parameter in `load_plugin_data()` (not fully implemented)
- Safety checks and clamps for `update_game_time()` arguments
- RegEx parsing support (experimental)
- `talk_to_npc()` now accepts vibe and context as string names instead of enum keys
- `_operate_save_queue()` only runs outside the editor
- All underscores removed from variable names in PluginData.gd
- `remove_npc()` and `remove_event()` now only scan referenced NPCs/events instead of all
- `store_pool()` no longer requires `pool_type` parameter (auto-detected)
- Response format changed to `> "Hi!" {"condition":"None", "condition_type":"None", "effect":"None", "tag":"None"}`
- Errors are now collected and asserted at the end (not immediate)
- Parser no longer errors on lines beginning with tabs
- `pool_script` null possibility in `pool_request()`
- Out-of-bounds safety in `pool_request()` while loop
- Removed "Skipping line" messages from error output
- Removed `@export` from all fields in PluginData.gd
- `update_npc_relationship()` in engine.gd now saves the both NPC's Resource if not set to "player"


# Dgpool Extension v0.1.3

- Added `const SEPARATOR` in parser_validator.gd (changed from `_` to `^`)
- Made a Single `ParserValidator.new()` instance at class level
- `pool_request()` accepts vibe and context as strings instead of ints
- Pool type auto-detection in `store_pool()`
- Error handling now pushes errors with final assert (not immediate)
- Response format: `> "Hi!" {"condition":"None", ...}`
- Fixed `pool_script` null reference in `pool_request()`
- Fixed Out-of-bounds loop safety in `pool_request()`
- Fixed Tab indentation error in validator

# Documentation
- Updated README.md
- Updated Dialogue_Syntax.md
- Updated script examples

# Note
Extensive testing is not being carried out between minor updates. Though Tests are still carried out
