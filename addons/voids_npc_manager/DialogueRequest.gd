@tool
class_name DialogueRequest
## Class for sending Dialogue requesnts to NpcDialogue

## The id of the NPC being spoken to
var npc: String

## Pool type for the conversation see [enum NpcDialogue.PoolType]
var pool_type: int

## The id for the event being talked about
var event_id: String  = "0"

## The id for the NPC being spoken about. [br]
## leave as is if pool_type is set to EVENT
var char_id: String = ""

## Context of the conversation see [enum NpcDialogue.PoolContext]
var context: int

## Section of the script the pool should be taken from
var section: String
