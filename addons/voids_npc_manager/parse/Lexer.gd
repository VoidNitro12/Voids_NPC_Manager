class_name Lexer

const POOL_MARKER = "@"
const TYPE_MARKER = "~"
const VIBE_MARKER = "/"
const MODE_MARKER = "*"
const SECTION_MARKER = "section "
const NPC_LINE_MARKER = "-"
const RESPONSE_MARKER = ">"
const SEPARATOR = "^"
const COMMENT_MARKER = "#"
const INVALID_MARKER = "Invalid"

var _line_num: int = 0

class Token:
	var marker: String
	var value: String
	var line_num: int
	func _init(marker: String, value: String, line_num: int):
		self.marker = marker
		self.value = value
		self.line_num = line_num

func tokenize(file_path: String) -> Array:
	_line_num = 0
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Could not open file: %s" % file_path)
		return []
	var lines = file.get_as_text().split("\n")
	file.close()
	
	var tokens = []
	for line in lines:
		_line_num += 1
		var bare_line = line.strip_edges()
		var marker
		var value

		if bare_line.begins_with(COMMENT_MARKER) or bare_line.is_empty():
			continue
		bare_line = bare_line.strip_edges()
		bare_line = inline_comments_check(bare_line)
		if bare_line.begins_with(POOL_MARKER):
			marker = POOL_MARKER
			value = bare_line.trim_prefix(marker)
			tokens.append(Token.new(marker,value,_line_num))
		elif bare_line.begins_with(TYPE_MARKER):
			marker = TYPE_MARKER
			value = bare_line.trim_prefix(marker)
			tokens.append(Token.new(marker,value,_line_num))
		elif bare_line.begins_with(VIBE_MARKER):
			marker = VIBE_MARKER
			value = bare_line.trim_prefix(marker)
			tokens.append(Token.new(marker,value,_line_num))
		elif bare_line.begins_with(MODE_MARKER):
			marker = MODE_MARKER
			value = bare_line.trim_prefix(marker)
			tokens.append(Token.new(marker,value,_line_num))
		elif bare_line.begins_with(SECTION_MARKER):
			marker = SECTION_MARKER
			value = bare_line.trim_prefix(marker)
			tokens.append(Token.new(marker,value,_line_num))
		elif bare_line.begins_with(NPC_LINE_MARKER):
			marker = NPC_LINE_MARKER
			value = bare_line.trim_prefix(marker)
			tokens.append(Token.new(marker,value,_line_num))
		elif bare_line.begins_with(RESPONSE_MARKER):
			marker = RESPONSE_MARKER
			value = bare_line.trim_prefix(marker)
			tokens.append(Token.new(marker,value,_line_num))
		else:
			marker = INVALID_MARKER
			value =  bare_line
			tokens.append(Token.new(marker,value,_line_num))
	return tokens

func inline_comments_check(line: String) -> String:
	var quotes_stack = 0
	var cut_pos = -1
	if line.find(COMMENT_MARKER) != -1:
		for i in range(line.length()):
			if line[i] == '"':
				quotes_stack += 1 
			if quotes_stack == 2:
				quotes_stack = 0
			elif line[i] == COMMENT_MARKER and quotes_stack == 0:
				cut_pos = i
				break
		if cut_pos != -1:
			line = line.substr(0,cut_pos).rstrip(" ")
	return line
