intersperse = (list, sep) ->
  if list.length == 0
    return []
  list.slice(1).reduce (xs, x, i) ->
    xs.concat [sep,x]
  , [ list[0] ]

window.Collaborator = React.createClass
	render: ->
		item = this.props.collaborator
		<div style={background: item.color}>{item.displayName}</div>


window.CollaboratorList = React.createClass
	render: ->
		nodes = for item in this.props.doc.getCollaborators()
			<Collaborator collaborator={item} key={item.sessionId}/>

		<div>{nodes}</div>


window.App = React.createClass
	render: ->
		<div>
			<CollaboratorList doc={this.props.doc}/>
			<Editor doc={this.props.richtext}/>
		</div>


window.Editor = React.createClass
	getInitialState: ->
		# TODO: put the cursor into the collaborative model too and support multiple author cursors
		cursor: @props.doc.getText().length
		selection_end: null

	attributeToTag: (attribute) ->
		simple_elements =
			bold: 'b'
			italic: 'i'
			container: 'div'
			cursor: 'cursor'
		return simple_elements[attribute]

	renderTextNode: (text, index) ->
		React.createElement 'span',
			'data-start-index': index
		, text

	renderTree: (node) ->
		if node.text?
			start_index = node.start_index
			parts = node.text.replace(/ /g, '\u00A0').split '\n'
			elements = []
			elements.push @renderTextNode parts[0], start_index
			start_index += parts[0].length

			for part in parts[1..]
				elements.push React.createElement 'br'
				elements.push @renderTextNode part, start_index
				start_index += part.length

			return elements

		tag = @attributeToTag node.attribute
		React.createElement tag,
			'data-start-index': node.start_index
		, @renderTreeList node.children

	renderTreeList: (nodes) ->
		for node in nodes
			@renderTree node

	getAnchorIndex: (anchor, offset) ->
		if anchor.nodeType is anchor.TEXT_NODE
			(parseInt anchor.parentNode.attributes['data-start-index'].value) + offset
		else
			console.log "TODO: handle non-text clicks"

	onClick: (event) ->
		selection = window.getSelection()
		if selection.isCollapsed
			cursor = @getAnchorIndex selection.anchorNode, selection.anchorOffset
			selection_end = null
		else
			index1 = @getAnchorIndex selection.anchorNode, selection.anchorOffset
			index2 = @getAnchorIndex selection.focusNode, selection.focusOffset
			if index1 < index2
				cursor = index1
				selection_end = index2
			else
				cursor = index2
				selection_end = index1

		# console.log "set selection", cursor, selection_end
		@setState {cursor, selection_end}

	deleteSelection: ->
		@props.doc.deleteText @state.cursor, @state.selection_end - @state.cursor
		@setState selection_end: null

	insertText: (text) ->
		if @state.selection_end
			@deleteSelection()
		@props.doc.insertText @state.cursor, text
		@setState cursor: @state.cursor + text.length
		# console.log "insert", text, @state.cursor, @state.selection_end

	deleteText: ->
		if @state.selection_end
			@deleteSelection()
		else
			@props.doc.deleteText @state.cursor - 1, 1
			@setState cursor: @state.cursor - 1

	getText: ->
		@props.doc.getText()

	onKeypress: (event) ->
		event.preventDefault()
		character = if event.which is KEYCODES.enter
			"\n"
		else
			String.fromCharCode event.which

		@insertText character

	onKeyDown: (event) ->
		if event.keyCode is KEYCODES.backspace
			event.preventDefault()
			@deleteText()
		else if event.keyCode is KEYCODES.left
			if event.shiftKey
				if not @state.selection_end
					@setState selection_end: @state.cursor
				if @state.cursor > 0
					@setState cursor: @state.cursor - 1
			else
				if @state.selection_end
					@setState selection_end: null
				else if @state.cursor > 0
					@setState cursor: @state.cursor - 1
		else if event.keyCode is KEYCODES.right
			if event.shiftKey
				selection_end = @state.selection_end or @state.cursor
				if selection_end < @getText().length
					@setState selection_end: selection_end + 1
			else
				if @state.selection_end
					@setState
						cursor: @state.selection_end
						selection_end: null
				else if @state.cursor < @getText().length
					@setState cursor: @state.cursor + 1
		else if event.keyCode in [KEYCODES.up, KEYCODES.down]
			if event.shiftKey
				console.log "TODO: select up and down"
			else
				if @state.selection_end
					if event.keyCode is KEYCODES.up
						@setState
							selection_end: null
					else if event.keyCode is KEYCODES.down
						@setState
							cursor: @state.selection_end
							selection_end: null
				else
					current_line_start = @findLineStart @state.cursor
					current_line_cursor = @state.cursor - current_line_start

					if event.keyCode is KEYCODES.up
						if current_line_start is -1
							@setState cursor: 0

						previous_line_start = @findLineStart current_line_start
						previous_line_length = current_line_start - previous_line_start
						previous_line_cursor = Math.min current_line_cursor, previous_line_length
						@setState cursor: previous_line_start + previous_line_cursor

					else if event.keyCode is KEYCODES.down
						next_line_start = @findLineEnd @state.cursor
						if next_line_start is -1
							@setState cursor: @getText().length
							return

						next_line_end = @findLineEnd next_line_start+1
						if next_line_end is -1
							next_line_end = @getText().length

						next_line_length = next_line_end - next_line_start
						next_line_cursor = Math.min current_line_cursor, next_line_length
						@setState cursor: next_line_start + next_line_cursor

	findLineStart: (index) ->
		# -1 is a useful return value, since the first line has no newline character in it.
		# This makes the math work out.
		@getText().lastIndexOf "\n", index-1

	findLineEnd: (index) ->
		# The end of one line has the same index as the start of the next.
		@getText().indexOf "\n", index

	onPaste: (event) ->
		data = event.clipboardData
		characters = data.getData data.types[0]
		@insertText characters

	render: ->
		tree = overlayedTextToTree @props.doc.getOverlays(), @props.doc.getText(), @state.cursor
		children = @renderTreeList tree.children
		React.createElement 'div',
			'data-start-index': tree.start_index
			'data-end-index': tree.end_index
			onClick: @onClick
			onKeyPress: @onKeypress
			onKeyDown: @onKeyDown
			onPaste: @onPaste
			tabIndex: 1
		, children

KEYCODES =
	left: 37
	up: 38
	right: 39
	down: 40
	backspace: 8
	enter: 13

top = (stack) -> stack[stack.length-1]

window.gapi.load 'auth:client,drive-realtime,drive-share', ->
	setup_richtext()
	doc = gapi.drive.realtime.newInMemoryDocument()
	model = doc.getModel()
	parent = model.getRoot()
	richtext = model.create(CollaborativeRichText)
	parent.set 'text', richtext
	richtext.insertText 0, "123456789"
	richtext.formatText 1, 6, {bold: true}
	richtext.formatText 5, 3, {italic: true}

	render = ->
		React.render <App richtext={richtext} doc={doc}/>, document.getElementById('main')

	parent.addEventListener gapi.drive.realtime.EventType.OBJECT_CHANGED, render

	render()

