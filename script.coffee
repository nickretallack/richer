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

	renderTree: (node) ->
		if node.text?
			return React.createElement 'span', 
				'data-start-index': node.start_index
				'data-end-index': node.end_index
			, node.text
		tag = @attributeToTag node.attribute
		React.createElement tag,
			'data-start-index': node.start_index
			'data-end-index': node.end_index
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
		character = String.fromCharCode event.which
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

top = (stack) -> stack[stack.length-1]

window.gapi.load 'auth:client,drive-realtime,drive-share', ->
	doc = gapi.drive.realtime.newInMemoryDocument()
	model = doc.getModel()
	parent = model.getRoot()
	name = 'text'
	richtext = new CollaborativeRichText {model, parent, name}
	richtext.insertText 0, "123456789"
	richtext.formatText 1, 6, {bold: true}
	richtext.formatText 5, 3, {italic: true}

	render = ->
		React.render <Editor doc={richtext}/>, document.getElementById('main')

	parent.addEventListener gapi.drive.realtime.EventType.OBJECT_CHANGED, render

	render()

