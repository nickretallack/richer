
random_character = ->
  chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  chars.charAt Math.floor Math.random() * chars.length

random_id = (length) ->
  (random_character() for _ in [0..length]).join('')

class Overlay
  ###
  Represents a styled portion of a collaborative string.
  Examples: bold, italic

  It tracks the place in the string where it begins and ends.

  In Google Drive Realtime API, indexes refer to the positions of actual characters.
  However, I find it more convenient to have indexes refer to the spaces between characters.
  That's why I created the getters and setters on this class, so nobody else has to
  deal with this off-by-one difference.
  ###

  __collaborativeInitializerFn__: ({@str, start_index, end_index, attribute}) ->
    @model = gapi.drive.realtime.custom.getModel @

    start_ref = @str.registerReference start_index, gapi.drive.realtime.IndexReference.DeleteMode.SHIFT_AFTER_DELETE
    end_ref = @str.registerReference end_index-1, gapi.drive.realtime.IndexReference.DeleteMode.SHIFT_BEFORE_DELETE

    @start = start_ref
    @end = end_ref
    @attribute = attribute
    return  

  repr: ->
    {@attribute, start:@get_start(), end:@get_end()}

  get_start: ->
    @start.index

  set_start: (value) ->
    @start.index = value

  get_end: ->
    @end.index+1

  set_end: (value) ->
    @end.index = value-1

  collides: (index) ->
    @get_start() <= index and @get_end() >= index

  collides_attribute: (index, attribute) ->
    attribute == @attribute and @collides index

  is_inside: (start_index, end_index) ->
    @get_start() >= start_index and @get_end() <= end_index


class CollaborativeRichText
  __collaborativeInitializerFn__: ->
    @model = gapi.drive.realtime.custom.getModel @
    @str = @model.createString()
    @overlays = @model.createList()

  # Overlays

  debug_overlays: ->
    attributes = {}
    for overlay in @overlays.asArray()
      attribute = overlay.attribute
      attributes[attribute] ?= []
      attributes[attribute].push
        start: overlay.get_start()
        end: overlay.get_end()

    for attribute, overlays of attributes
      overlays.sort (a,b) ->
        start_comparison = a.start - b.start
        if start_comparison is 0
          return a.end - b.end
        return start_comparison

    return attributes

  create_overlay: (start_index, end_index, attribute) ->
    @overlays.push @model.create Overlay, {start_index, end_index, attribute, @str}
    return

  remove_overlay: (overlay) ->
    @overlays.removeValue overlay
    return

  find_colliding_overlay: (attribute, index) ->
    for overlay in @overlays.asArray()
      if overlay.collides_attribute index, attribute
        return overlay

  delete_overlay_range: (start_index, end_index) ->
    deletable_overlays = @overlays.asArray().filter (overlay) ->
      overlay.is_inside start_index, end_index
    for overlay in deletable_overlays
      @remove_overlay overlay
    return

  split_or_remove_overlay: (start_index, end_index, attribute) ->
    overlay = @find_colliding_overlay attribute, start_index
    if !overlay
      console.log 'ANOMALY - deleted overlay that wasn\'t found'
      return
    overlay_start = overlay.start
    overlay_end = overlay.end
    matches_start = start_index == overlay.get_start()
    matches_end = end_index == overlay.get_end()

    if matches_start and matches_end
      @remove_overlay overlay
    else if matches_start
      overlay.set_start end_index
    else if matches_end
      overlay.set_end start_index
    else
      @split_overlay overlay, start_index, end_index, attribute
    return

  split_overlay: (overlay, start_index, end_index, attribute) ->
    overlay_end = overlay.get_end()
    overlay.set_end start_index # first half
    @create_overlay end_index, overlay_end, attribute # second half
    return

  extend_or_create_overlay: (start_index, end_index, attribute) ->
    found_start = @find_colliding_overlay attribute, start_index
    found_end = @find_colliding_overlay attribute, end_index
    if found_start and found_end
      @connect_two_overlays found_start, found_end
    else if found_start
      found_start.set_end end_index
    else if found_end
      found_end.set_start start_index
    else
      @create_overlay start_index, end_index, attribute
    return

  connect_two_overlays: (first_overlay, second_overlay) ->
    @remove_overlay second_overlay
    first_overlay.set_end second_overlay.get_end()
    return

  # Public API

  formatText: (index, length, attributes) ->
    end_index = index + length
    for attribute, value of attributes
      if value
        @extend_or_create_overlay index, end_index, attribute
      else
        @split_or_remove_overlay index, end_index, attribute
    return

  insertText: (index, text, attributes) ->
    @str.insertString index, text
    @formatText index, text.length, attributes
    return

  deleteText: (index, length) ->
    end_index = index + length
    @delete_overlay_range index, end_index
    @str.removeRange index, end_index
    return

  getText: ->
    @str.text

  getOverlays: ->
    for overlay in @overlays.asArray()
      overlay.repr()

window.CollaborativeRichText = CollaborativeRichText
window.setup_richtext = -> #CollaborativeRichText.setup = ->
  gapi.drive.realtime.custom.registerType CollaborativeRichText, 'CollaborativeRichText'
  gapi.drive.realtime.custom.registerType Overlay, 'CollaborativeRichTextOverlay'
  # gapi.drive.realtime.custom.setInitializer CollaborativeRichText, CollaborativeRichText::setup_model
