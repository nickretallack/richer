run_tests = ->
  doc = gapi.drive.realtime.newInMemoryDocument()
  model = doc.getModel()
  parent = model.getRoot()
  name = 'test'
  richtext = null

  QUnit.assert.overlays = (overlays, message) ->
    @deepEqual(richtext.debug_overlays(), overlays, message)

  QUnit.module 'tests',
    beforeEach: (assert) ->
      parent.clear()
      richtext = new CollaborativeRichText {model, parent, name}
      richtext.insertText 0, "123456789"

  QUnit.test 'extend forward', (assert) ->
    richtext.formatText 3, 1, {bold:true}

    assert.overlays
      bold: [{start:3, end:4}]

    richtext.formatText 4, 1, {bold:true}

    assert.overlays
      bold: [{start:3, end:5}]

  QUnit.test "don't extend forward", (assert) ->
    richtext.formatText 0, 3, {bold:true}

    assert.overlays
      bold: [{start:0, end:3}]

    richtext.formatText 4, 3, {bold:true}

    assert.overlays
      bold: [{start:0, end:3}, {start:4, end:7}]

  QUnit.test 'extend backward', (assert) ->
    richtext.formatText 4, 1, {bold:true}

    assert.overlays
      bold: [{start:4, end:5}]

    richtext.formatText 3, 1, {bold:true}

    assert.overlays
      bold: [{start:3, end:5}]

  QUnit.test "don't extend backward", (assert) ->
    richtext.formatText 4, 1, {bold:true}

    assert.overlays
      bold: [{start:4, end:5}]

    richtext.formatText 2, 1, {bold:true}

    assert.overlays
      bold: [{start:2, end:3}, {start:4, end:5}]

  QUnit.test 'connect two overlays', (assert) ->
    richtext.formatText 2, 1, {bold:true}
    richtext.formatText 4, 1, {bold:true}

    assert.overlays
      bold: [{start:2, end:3}, {start:4, end: 5}]

    richtext.formatText 3, 1, {bold:true}

    assert.overlays
      bold: [{start:2, end: 5}]

  QUnit.test 'remove whole overlay', (assert) ->
    richtext.formatText 2, 3, {bold:true}

    assert.overlays
      bold: [{start:2, end:5}]

    richtext.formatText 2, 3, {bold:null}

    assert.overlays {}

  QUnit.test 'remove beginning', (assert) ->
    richtext.formatText 2, 5, {bold:true}

    assert.overlays
      bold: [{start:2, end:7}]

    richtext.formatText 2, 3, {bold:null}

    assert.overlays
      bold: [{start:5, end:7}]

  QUnit.test 'remove end', (assert) ->
    richtext.formatText 2, 5, {bold:true}

    assert.overlays
      bold: [{start:2, end:7}]

    richtext.formatText 4, 3, {bold:null}

    assert.overlays
      bold: [{start:2, end:4}]

  QUnit.test 'split overlay', (assert) ->
    richtext.formatText 2, 5, {bold:true}

    assert.overlays
      bold: [{start:2, end:7}]

    richtext.formatText 3, 3, {bold:null}

    assert.overlays
      bold: [{start:2, end:3}, {start:6, end:7}]

  QUnit.test 'insert shifts overlay', (assert) ->
    richtext.formatText 2, 3, {bold:true}

    richtext.insertText 1, "hello"

    assert.overlays
      bold: [{start:7, end:10}]

  QUnit.test 'insert inside overlay', (assert) ->
    richtext.formatText 2, 3, {bold:true}

    richtext.insertText 3, "hello"

    assert.overlays
      bold: [{start:2, end:10}]

  QUnit.test 'insert formatted text', (assert) ->
    richtext.insertText 3, "hello", {bold:true}

    assert.overlays
      bold: [{start: 3, end: 8}]

  QUnit.test 'delete formatted text', (assert) ->
    richtext.formatText 2, 3, {bold:true}
    richtext.deleteText 2, 3
    assert.overlays {}

  QUnit.test 'delete beginning of formatted text', (assert) ->
    richtext.formatText 2, 2, {bold:true}

    assert.overlays
      bold: [{start: 2, end: 4}]

    richtext.deleteText 2, 1
    assert.overlays
      bold: [{start: 2, end: 3}]

  QUnit.test 'delete end of formatted text', (assert) ->
    richtext.formatText 2, 2, {bold:true}

    assert.overlays
      bold: [{start: 2, end: 4}]

    richtext.deleteText 3, 1
    assert.overlays
      bold: [{start: 2, end: 3}]

  return

window.gapi.load 'auth:client,drive-realtime,drive-share', run_tests