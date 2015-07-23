window.Editor = React.createClass
	getInitialState: ->
		text: "hello world"
		overlays: [
			{attribute:'bold', start:0, end: 5}
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
		React.createElement tag, null, @renderTreeList node.children

	renderTreeList: (nodes) ->
		for node in nodes
			@renderTree node

	render: ->
		@renderTree overlayedTextToTree @state.overlays, @state.text

React.render <Editor/>, document.getElementById('main')

top = (stack) -> stack[stack.length-1]
