QUnit.test 'overlays to markers', (assert) ->
	overlays = [
		{attribute:'bold', start:0, end: 5}
		{attribute:'italic', start:6, end: 10}
		{attribute:'strike', start:3, end: 8}
	]
	markers = [
		{attribute:'bold', type:'start', index:0}
		{attribute:'strike', type:'start', index:3}
		{attribute:'bold', type:'end', index:5}
		{attribute:'italic', type:'start', index:6}
		{attribute:'strike', type:'end', index:8}
		{attribute:'italic', type:'end', index:10}
	]
	assert.deepEqual (overlaysToMarkers overlays), markers

QUnit.test 'overlays to markers on overlapping indexes', (assert) ->
	overlays = [
		{attribute:'italic', start:3, end: 6}
		{attribute:'bold', start:6, end: 8}
		{attribute:'strike', start:3, end: 8}
	]
	markers = [
		{attribute:'italic', type:'start', index:3}
		{attribute:'strike', type:'start', index:3}
		{attribute:'italic', type:'end', index:6}
		{attribute:'bold', type:'start', index:6}
		{attribute:'strike', type:'end', index:8}
		{attribute:'bold', type:'end', index:8}
	]
	assert.deepEqual (overlaysToMarkers overlays), markers

QUnit.test 'normalize markers', (assert) ->
	markers = [
		{attribute:'bold', type:'start', index:0}
		{attribute:'strike', type:'start', index:3}
		{attribute:'bold', type:'end', index:5}
		{attribute:'strike', type:'end', index:8}
	]
	normalized_markers = [
		{attribute:'bold', type:'start', index:0}
		{attribute:'strike', type:'start', index:3}
		{attribute:'strike', type:'end', index:5}
		{attribute:'bold', type:'end', index:5}
		{attribute:'strike', type:'start', index:5}
		{attribute:'strike', type:'end', index:8}
	]
	assert.deepEqual (normalizeMarkers markers), normalized_markers

QUnit.test 'normalize multiple markers', (assert) ->
	markers = [
		{attribute:'bold', type:'start', index:1}
		{attribute:'strike', type:'start', index:2}
		{attribute:'italic', type:'start', index:3}
		{attribute:'bold', type:'end', index:4}
		{attribute:'strike', type:'end', index:5}
		{attribute:'italic', type:'end', index:6}
	]
	normalized_markers = [
		{attribute:'bold', type:'start', index:1}
		{attribute:'strike', type:'start', index:2}
		{attribute:'italic', type:'start', index:3}
		{attribute:'italic', type:'end', index:4}
		{attribute:'strike', type:'end', index:4}
		{attribute:'bold', type:'end', index:4}
		{attribute:'strike', type:'start', index:4}
		{attribute:'italic', type:'start', index:4}
		{attribute:'italic', type:'end', index:5}
		{attribute:'strike', type:'end', index:5}
		{attribute:'italic', type:'start', index:5}
		{attribute:'italic', type:'end', index:6}
	]
	assert.deepEqual (normalizeMarkers markers), normalized_markers

QUnit.test 'treeify', (assert) ->
	text = "hello world"
	normalized_markers = [
		{attribute:'bold', type:'start', index:0}
		{attribute:'bold', type:'end', index:5}
		{attribute:'italic', type:'start', index:6}
		{attribute:'italic', type:'end', index:11}
	]
	tree =
		index: 0
		attribute: 'container'
		children: [
			{
				index: 0
				attribute: 'bold'
				children: [
					{
						text: 'hello'
					}
				]
			}
			{
				text: ' '
			}
			{
				index: 6
				attribute: 'italic'
				children: [
					{
						text: 'world'
					}
				]
			}
		]

	assert.deepEqual (markedTextToTree normalized_markers, text), tree

QUnit.test 'treeify nesting', (assert) ->
	text = "helloworld"
	normalized_markers = [
		{attribute:'bold', type:'start', index:3}
		{attribute:'italic', type:'start', index:5}
		{attribute:'italic', type:'end', index:7}
		{attribute:'bold', type:'end', index:8}
	]
	tree =
		index: 0
		attribute: 'container'
		children: [
			{
				text: 'hel'
			}
			{
				index: 3
				attribute: 'bold'
				children: [
					{
						text: 'lo'
					}
					{
						index: 5
						attribute: 'italic'
						children: [
							{
								text: 'wo'
							}
						]
					}
					{
						text: 'r'
					}
				]
			}
			{
				text: 'ld'
			}
		]

	assert.deepEqual (markedTextToTree normalized_markers, text), tree

QUnit.test 'treeify same index', (assert) ->
	text = "1234567"
	normalized_markers = [
		{attribute:'bold', type:'start', index:1}
		{attribute:'strike', type:'start', index:2}
		{attribute:'italic', type:'start', index:3}
		{attribute:'italic', type:'end', index:4}
		{attribute:'strike', type:'end', index:4}
		{attribute:'bold', type:'end', index:4}
		{attribute:'strike', type:'start', index:4}
		{attribute:'italic', type:'start', index:4}
		{attribute:'italic', type:'end', index:5}
		{attribute:'strike', type:'end', index:5}
		{attribute:'italic', type:'start', index:5}
		{attribute:'italic', type:'end', index:6}
	]
	tree =
		index: 0
		attribute: 'container'
		children: [
			{
				text: '1'
			}
			{
				index: 1
				attribute: 'bold'
				children: [
					{
						text: '2'
					}
					{
						index: 2
						attribute: 'strike'
						children: [
							{
								text: '3'
							}
							{
								index: 3
								attribute: 'italic'
								children: [
									{
										text: '4'
									}
								]
							}
						]
					}
				]
			}
			{
				index: 4
				attribute: 'strike'
				children: [
					{
						index: 4
						attribute: 'italic'
						children: [
							{
								text: '5'
							}
						]
					}
				]
			}
			{
				index: 5
				attribute: 'italic'
				children: [
					{
						text: '6'
					}
				]
			}
			{
				text: '7'
			}
		]
	assert.deepEqual (markedTextToTree normalized_markers, text), tree
