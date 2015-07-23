window.Editor = React.createClass
	getInitialState: ->
		text = "hello world"

		text: text
		cursor: text.length
		overlays: [
			{attribute:'bold', start:0, end: 3}
			{attribute:'italic', start:6, end: 11}
		]

	attributeToTag: (attribute) ->
		simple_elements =
			bold: 'b'
			italic: 'i'
			container: 'div'
		return simple_elements[attribute]

	renderTree: (node) ->
		if node.text?
			return node.text
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
			parent_node = anchor.parentNode.parentNode
			parent_index = parseInt parent_node.attributes['data-start-index'].value
			
			previous_sibling = anchor.parentNode.previousSibling
			previous_sibling_index = if previous_sibling?
				parseInt previous_sibling.attributes['data-end-index'].value
			else 0

			previous_sibling_index + parent_index + offset
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

		console.log "set selection", cursor, selection_end
		@setState {cursor, selection_end}

	onKeypress: (event) ->
		event.preventDefault()
		character = String.fromCharCode event.which
		console.log "insert character", character, @state.cursor, @state.selection_end

	onKeyDown: (event) ->
		if event.keyCode is 8
			event.preventDefault()
			console.log 'backspace', @state.cursor, @state.selection_end

	onPaste: (event) ->
		data = event.clipboardData
		characters = data.getData data.types[0]
		console.log "insert characters", characters, @state.cursor, @state.selection_end

	render: ->
		tree = overlayedTextToTree @state.overlays, @state.text
		children = @renderTreeList tree.children
		React.createElement 'div',
			'data-start-index': 0
			'data-end-index': @state.text.length
			onClick: @onClick
			onKeyPress: @onKeypress
			onKeyDown: @onKeyDown
			onPaste: @onPaste
			tabIndex: 1
		, children
React.render <Editor/>, document.getElementById('main')

top = (stack) -> stack[stack.length-1]

