class_name ForthImplementationBase
## Base class and utilities for Forth word definition collections
##

extends RefCounted

var forth: AMCForth


# Create with a reference to AMCForth
func _init(_forth: AMCForth):
	forth = _forth
	_scan_definitions()


# Scan source code for Forth word definitions
func _scan_definitions() -> void:
	var src = get_script().source_code
	var regex = RegEx.new()
	# Identify the word set for this file
	var wordset:String = "N/A"
	regex.compile("##\\s+@WORDSET\\s+(.+)\\n?\\r?")
	var res = regex.search_all(src)
	if res.size():
		wordset = res[0].strings[1]
	# make an empty list of words for this wordset
	forth.wordset_words[wordset] = []
	# Compile built-in WORD functions
	regex.compile("[^\"]##\\s+@WORD\\s+([^\\s]+)\\s*(IMMEDIATE)?\\s*\\n?\\r?(\
##[^\\r\\n]*)?\\n?\\r?(##[^\\r\\n]*)?\\n?\\r?(##[^\\r\\n]*)?\\n?\\r?##\\s+\
@STACK\\s+([^\\r\\n]*)?\\n?\\r?func\\s+([^\\s(]+)")
	res = regex.search_all(src)
	for item in res:
		var word:String = item.strings[1]
		# associate word with executable
		forth.built_in_names.append(
			[word, Callable(self, item.strings[7])]
		)
		# identify immediate words
		if item.strings[2] == "IMMEDIATE":
			forth.immediate_names.append(item.strings[1])
		# associate words with their description
		var descr:=""
		for i in [3, 4, 5]:
			var item_str = item.strings[i]
			item_str = item_str.replace("##","").lstrip(" ").rstrip(" ") + " "
			descr = descr + item_str
		descr = descr.rstrip(" ")
		forth.word_description[word] = descr
		# associate words with their word set
		forth.word_wordset[word] = wordset
		# associate words their stack definitions
		forth.word_stackdef[word] = item.strings[6].replace("##","").lstrip(" ").rstrip(" ")
		# associate wordset with this word
		forth.wordset_words[wordset].append(word)
	# sort the wordset list
	forth.wordset_words[wordset].sort()
	# Compile built-in WORDX run-time execution functions
	regex.compile("[^\"]##\\s+@WORDX\\s+([^\\s]+).*\\n?\\r?func\\s+([^\\s(]+)")
	res = regex.search_all(src)
	for item in res:
		forth.built_in_exec_functions.append(
			[item.strings[1], Callable(self, item.strings[2])]
		)
