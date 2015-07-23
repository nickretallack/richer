window.last = (list) -> list[list.length-1]

window.overlaysToMarkers = (overlays) ->
	"""Converts overlays of the form {attribute, start, end} into
	markers of the form {attribute, start/end, index}
	so you can sort them"""
	results = []
	for overlay in overlays
		results.push
			index: overlay.start
			attribute: overlay.attribute
			type: 'start'
		results.push
			index: overlay.end
			attribute: overlay.attribute
			type: 'end'
	return results.sort (a,b) ->
		if a.index != b.index
			return a.index - b.index
		if a.type != b.type
			# end tags should come before start tags
			if a.type is 'end'
				return -1
			else
				return 1
		if a.attribute != b.attribute
			# tags should end in the opposite order that they start
			# TODO: test this
			factor1 = if a.type is 'end' then 1 else -1
			factor2 = if a.attribute < b.attribute then 1 else -1
			return factor1 * factor2
		return 0

window.normalizeMarkers = (markers) ->
	"""Adds additional markers so they can be converted to valid HTML.
	For example, if the markers coded for <b>hello<i>awesome</b>world</i>,
	we would change it to <b>hello<i>awesome</i><b><i>world</i>"""
	context = []
	result = []
	for marker in markers
		if marker.type is 'start'
			context.push marker.attribute
			result.push marker
		else if marker.type is 'end'
			unwinding = []
			loop
				attribute = context.pop()
				if attribute is marker.attribute
					break
				unwinding.push attribute
				result.push
					attribute: attribute
					type: 'end'
					index: marker.index
			result.push 
				attribute: marker.attribute
				type: 'end'
				index: marker.index
			loop
				attribute = unwinding.pop()
				unless attribute?
					break
				context.push(attribute)
				result.push
					attribute: attribute
					type: 'start'
					index: marker.index
	result

addSingleText = (parent_tag, full_text, start_index, end_index) ->
	text = full_text[start_index...end_index]
	if text
		parent_tag.children.push {text, start_index, end_index}

addCursor = (parent_tag, cursor_index) ->
	parent_tag.children.push
		attribute: 'cursor'
		start_index: cursor_index
		end_index: cursor_index
		children: []

addCursorText = (parent_tag, full_text, start_index, end_index, cursor_index) ->
	"""The cursor should be placed inside the formatting for the character on its
	left, if possible.  Since the first character in the document has no character to
	its left, we will use the character on its right instead"""
	if cursor_index is 0 and start_index is 0
		addCursor parent_tag, cursor_index
		addSingleText parent_tag, full_text, start_index, end_index
	else if start_index < cursor_index <= end_index
		addSingleText parent_tag, full_text, start_index, cursor_index
		addCursor parent_tag, cursor_index
		addSingleText parent_tag, full_text, cursor_index, end_index
	else
		addSingleText parent_tag, full_text, start_index, end_index


window.markedTextToTree = (markers, full_text, cursor_index) ->
	"""Converts a list of markers into a tree representation that mirrors the
	final HTML, and splits up the text into the resulting elements"""
	current_tag =
		attribute: 'container'
		start_index: 0
		end_index: full_text.length
		children: []
	context = [current_tag]
	last_index = 0
	for marker in markers
		if marker.type is 'start'
			parent_tag = current_tag
			addCursorText parent_tag, full_text, last_index, marker.index, cursor_index
			last_index = marker.index

			# start a tag
			current_tag =
				attribute: marker.attribute
				start_index: marker.index
				children: []

			parent_tag.children.push current_tag
			context.push current_tag

		else if marker.type is 'end'
			addCursorText current_tag, full_text, last_index, marker.index, cursor_index
			last_index = marker.index

			# end the tag
			current_tag.end_index = marker.index

			# go up a level
			context.pop()
			current_tag = last context

	addCursorText current_tag, full_text, last_index, full_text.length, cursor_index

	return current_tag

window.overlayedTextToTree = (overlays, text, cursor) ->
	"""Converts overlays to an html-like tree"""
	markers = overlaysToMarkers overlays
	normalized_markers = normalizeMarkers markers
	tree = markedTextToTree normalized_markers, text, cursor
	return tree
