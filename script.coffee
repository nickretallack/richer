window.Editor = React.createClass
	getInitialState: ->
		text: "hello world"
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

	onClick: (event) ->
		selection = window.getSelection()
		if selection.isCollapsed
			anchor = selection.anchorNode
			index = if anchor.nodeType is anchor.TEXT_NODE
				parent_node = anchor.parentNode.parentNode
				parent_index = parseInt parent_node.attributes['data-start-index'].value
				
				previous_sibling = anchor.parentNode.previousSibling
				previous_sibling_index = if previous_sibling?
					parseInt previous_sibling.attributes['data-end-index'].value
				else 0

				local_index = selection.anchorOffset

				previous_sibling_index + parent_index + local_index
			else
				console.log "TODO: handle non-text clicks"
				debugger

			console.log index
		else
			console.log "TODO: handle selections"
			debugger

	render: ->
		tree = overlayedTextToTree @state.overlays, @state.text
		children = @renderTreeList tree.children
		React.createElement 'div',
			'data-start-index': 0
			'data-end-index': @state.text.length
			onClick: @onClick
		, children
React.render <Editor/>, document.getElementById('main')

top = (stack) -> stack[stack.length-1]
