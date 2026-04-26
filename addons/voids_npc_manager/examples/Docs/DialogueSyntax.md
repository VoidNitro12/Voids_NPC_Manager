# Dialogue
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

# Dialogue Script Syntax

## File Structure

```
@Script Type 
~POOL_TYPE or UNAWARE
	/VIBE
		*MODE
			section SECTION_NAME
				- "NPC dialogue line"
					> "Player response" {"condition":"", "condition_type":"", "effect":"", "tag":""}
```

## Core Elements

| Element | Marker | Example |
|---------|--------|---------|
|Script Type| `@`| `NPC`|
| Pool | `~` | `~UNAWARE`, `~FIGHT` |
| Vibe | `/` | `/WARM`, `/COLD`, `/TERSE` |
| Mode | `*` | `*REACTIVE`, `*PROACTIVE`, `*ONGOING` |
| Section | `section` | `section greetings`, `section direct_greetings` |
| NPC Line | `-` | `- "What do you want?"` |
| Player Response | `>` | `> "Just saying hi" {"condition":"None", "condition_type":"None", "effect":"None", "tag":"greeting"}` |
| Comment | `#` | `# This is a comment` |

## Response Metadata

| Field | Purpose | Example |
|-------|---------|---------|
| `condition` | The logical check | `"friendliness > 0.5"` |
| `condition_type` | Which evaluator to use | `"friendliness"`, `"mood"`, `"custom"` |
| `effect` | What happens when chosen | `"relationship += 0.1"` |
| `tag` | Where to go next | `"greeting_response"` |

## Condition Types

| Type | Checks |
|------|--------|
| `"friendliness"` | NPC friendliness value |
| `"mood"` | NPC current mood |
| `"curiosity"` | NPC curiosity value |
| `"patience"` | NPC patience value |
| `"expressiveness"` | NPC expressiveness value |
| `"relationship"` | Relationship with target |
| `"witnessed_direct"` | NPC directly witnessed event |
| `"witnessed_indirect"` | NPC heard about event |
| `"custom"` | Registered custom function |
| `"None"` | Always true |

## Example

```
@NPC
~UNAWARE
/COLD
	*REACTIVE
	section direct_greetings
		- "What do you want?"
			> "Just saying hi" {"condition":"friendliness > 0.5", "condition_type":"friendliness", "effect":"None", "tag":"greeting"}
			> "You look grumpy" {"condition":"mood < -0.3", "condition_type":"mood", effect:"relationship -= 0.1", "tag":"insult"}
			> "Nothing" {"condition":"None", "condition_type":"None", "effect":"None", "tag":"end"}

```

## Placeholders
When writing dialogue, use curly braces {} for dynamic values.

## Event Placeholders
Any field defined in an event type can be used as a placeholder:

```
"They got into a fight just because of {cause}."
"Im pretty sure {victim} is sad about it."
"It happened on {day}, recall?."
```

Player Name

Use {player0} to insert the player's name:

```
"Hello {player0}, good to see you!"
```
