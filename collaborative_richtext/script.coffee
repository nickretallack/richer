
random_character = ->
  chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  chars.charAt Math.floor Math.random() * chars.length

random_id = (length) ->
  (random_character() for _ in [0..length]).join('')

class CollaborativeRichText
  constructor: ({@model, parent, name, handlers}) ->
    handlers ?= {}
    @setup_model parent, name
    @setup_events handlers
    @run_initial_events handlers

  setup_model: (parent, name) ->
    @obj = @get_or_create_field @model.createMap, parent, name
    @str = @get_or_create_field @model.createString, @obj, 'text'
    @overlays = @get_or_create_field @model.createList, @obj, 'overlays'

  get_or_create_field: (constructor, parent, name) ->
    # progressively extend it in case they have an incompatible model and we're adding new features
    result = parent.get name
    unless result
      result = constructor.call @model
      parent.set name, result
    return result

  setup_events: (handlers) ->
    @overlays.addEventListener gapi.drive.realtime.EventType.VALUES_ADDED, (event) ->
      if handlers.preview_add_overlay
        event.values.forEach handlers.preview_add_overlay
      if handlers.apply_format and not event.isLocal
        event.values.forEach (item) ->
          handlers.apply_format item, true
      return

    @overlays.addEventListener gapi.drive.realtime.EventType.VALUES_REMOVED, (event) ->
      if handlers.preview_remove_overlay
        event.values.forEach handlers.preview_remove_overlay
      if handlers.apply_format and not event.isLocal
        event.values.forEach (item) ->
          handlers.apply_format item, false
      return

    @str.addEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, (event) ->
      if not event.isLocal
        console.log 'INSERTED', event.index, event.text
        handlers.insert_text? event.index, event.text
      return

    @str.addEventListener gapi.drive.realtime.EventType.TEXT_DELETED, (event) ->
      if not event.isLocal
        console.log 'DELETED', event.index, event.text
        handlers.delete_text? event.index, event.text
      return

  run_initial_events: (handlers) ->
    handlers.insert_text? 0, @str.getText()
    if handlers.preview_add_overlay
      @overlays.asArray().forEach handlers.preview_add_overlay
    if handlers.apply_format
      @overlays.asArray().forEach (item) => handlers.apply_format item, true

  # Overlays

  debug_overlays: ->
    attributes = {}
    for overlay in @overlays.asArray()
      attribute = overlay.get('attribute')
      attributes[attribute] ?= []
      attributes[attribute].push
        start: overlay.get('start').index
        end: overlay.get('end').index + 1

    for attribute, overlays of attributes
      overlays.sort (a,b) ->
        start_comparison = a.start - b.start
        if start_comparison is 0
          return a.end - b.end
        return start_comparison

    return attributes

  create_overlay: (start_index, end_index, attribute) ->
    console.log 'create overlay:', start_index, end_index, attribute
    start_ref = @str.registerReference start_index, gapi.drive.realtime.IndexReference.DeleteMode.SHIFT_AFTER_DELETE
    end_ref = @str.registerReference end_index-1, gapi.drive.realtime.IndexReference.DeleteMode.SHIFT_BEFORE_DELETE
    @overlays.push @model.createMap
      start: start_ref
      end: end_ref
      attribute: attribute
      id: random_id 20
    return

  remove_overlay: (overlay) ->
    console.log 'remove overlay', overlay.get('start').index, overlay.get('end').index+1, overlay.get('attribute')
    @overlays.removeValue overlay
    return

  find_colliding_overlay: (attribute, index) ->
    for overlay in @overlays.asArray()
      if attribute == overlay.get('attribute') and overlay.get('start').index <= index and overlay.get('end').index+1 >= index
        return overlay

  delete_overlay_range: (start_index, end_index) ->
    deletable_overlays = @overlays.asArray().filter (overlay) ->
      overlay_start = overlay.get('start').index
      overlay_end = overlay.get('end').index+1
      overlay_start >= start_index and overlay_end <= end_index
    for overlay in deletable_overlays
      @remove_overlay overlay
    return

  split_or_remove_overlay: (start_index, end_index, attribute) ->
    overlay = @find_colliding_overlay attribute, start_index
    if !overlay
      console.log 'ANOMALY - deleted overlay that wasn\'t found'
      return
    overlay_start = overlay.get('start')
    overlay_end = overlay.get('end')
    matches_start = start_index == overlay_start.index
    matches_end = end_index == overlay_end.index+1

    @remove_overlay overlay
    if matches_start and matches_end
      # remove the whole overlay
      console.log 'remove whole overlay', attribute
    else if matches_start
      # erase the start of this overlay
      console.log 'remove beginning of overlay', attribute
      @create_overlay end_index, overlay_end.index+1, attribute
    else if matches_end
      # erase the end of this overlay
      console.log 'remove end of overlay', attribute
      @create_overlay overlay_start.index, start_index, attribute
    else
      @split_overlay overlay, start_index, end_index, attribute
    return

  split_overlay: (overlay, start_index, end_index, attribute) ->
    console.log 'split overlay', attribute
    @create_overlay overlay.get('start').index, start_index, attribute # first half
    @create_overlay end_index, overlay.get('end').index+1, attribute # second half

  extend_or_create_overlay: (start_index, end_index, attribute) ->
    found_start = @find_colliding_overlay attribute, start_index
    found_end = @find_colliding_overlay attribute, end_index
    if found_start and found_end
      @connect_two_overlays found_start, found_end, attribute
    else if found_start
      @extend_overlay_forward found_start, end_index, attribute
    else if found_end
      @extend_overlay_backward found_end, start_index, attribute
    else
      console.log 'create new overlay', attribute
      @create_overlay start_index, end_index, attribute
    return

  connect_two_overlays: (first_overlay, second_overlay, attribute) ->
    console.log 'connect two overlays', attribute
    @remove_overlay first_overlay
    @remove_overlay second_overlay
    @create_overlay first_overlay.get('start').index, second_overlay.get('end').index+1, attribute    

  extend_overlay_forward: (overlay, end_index, attribute) ->
    console.log 'extend overlay forward', attribute
    @remove_overlay overlay
    @create_overlay overlay.get('start').index, end_index, attribute

  extend_overlay_backward: (overlay, start_index, attribute) ->
    console.log 'extend overlay backward', attribute
    @remove_overlay overlay
    @create_overlay start_index, overlay.get('end').index+1, attribute


  # Public API
  ### A note on indexes:
  In Google Drive Realtime API, indexes refer to the positions of actual characters.
  However, I find it more convenient to have indexes refer to the spaces between characters.
  Therefore, in the actual Model used with Google, I will use character indexes,
  but in my public API functions I will act as if they are the spaces between.


  ###

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
      attribute: overlay.get('attribute')
      start: overlay.get('start').index
      end: overlay.get('end').index + 1

window.CollaborativeRichText = CollaborativeRichText