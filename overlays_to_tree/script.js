// Generated by CoffeeScript 1.9.2
(function() {
  var addCursor, addCursorText, addSingleText;

  window.last = function(list) {
    return list[list.length - 1];
  };

  window.overlaysToMarkers = function(overlays) {
    "Converts overlays of the form {attribute, start, end} into\nmarkers of the form {attribute, start/end, index}\nso you can sort them";
    var i, len, overlay, results;
    results = [];
    for (i = 0, len = overlays.length; i < len; i++) {
      overlay = overlays[i];
      results.push({
        index: overlay.start,
        attribute: overlay.attribute,
        type: 'start'
      });
      results.push({
        index: overlay.end,
        attribute: overlay.attribute,
        type: 'end'
      });
    }
    return results.sort(function(a, b) {
      var factor1, factor2;
      if (a.index !== b.index) {
        return a.index - b.index;
      }
      if (a.type !== b.type) {
        if (a.type === 'end') {
          return -1;
        } else {
          return 1;
        }
      }
      if (a.attribute !== b.attribute) {
        factor1 = a.type === 'end' ? 1 : -1;
        factor2 = a.attribute < b.attribute ? 1 : -1;
        return factor1 * factor2;
      }
      return 0;
    });
  };

  window.normalizeMarkers = function(markers) {
    "Adds additional markers so they can be converted to valid HTML.\nFor example, if the markers coded for <b>hello<i>awesome</b>world</i>,\nwe would change it to <b>hello<i>awesome</i><b><i>world</i>";
    var attribute, context, i, len, marker, result, unwinding;
    context = [];
    result = [];
    for (i = 0, len = markers.length; i < len; i++) {
      marker = markers[i];
      if (marker.type === 'start') {
        context.push(marker.attribute);
        result.push(marker);
      } else if (marker.type === 'end') {
        unwinding = [];
        while (true) {
          attribute = context.pop();
          if (attribute === marker.attribute) {
            break;
          }
          unwinding.push(attribute);
          result.push({
            attribute: attribute,
            type: 'end',
            index: marker.index
          });
        }
        result.push({
          attribute: marker.attribute,
          type: 'end',
          index: marker.index
        });
        while (true) {
          attribute = unwinding.pop();
          if (attribute == null) {
            break;
          }
          context.push(attribute);
          result.push({
            attribute: attribute,
            type: 'start',
            index: marker.index
          });
        }
      }
    }
    return result;
  };

  addSingleText = function(parent_tag, full_text, start_index, end_index) {
    var text;
    text = full_text.slice(start_index, end_index);
    if (text) {
      return parent_tag.children.push({
        text: text,
        start_index: start_index,
        end_index: end_index
      });
    }
  };

  addCursor = function(parent_tag, cursor_index) {
    return parent_tag.children.push({
      attribute: 'cursor',
      start_index: cursor_index,
      end_index: cursor_index,
      children: []
    });
  };

  addCursorText = function(parent_tag, full_text, start_index, end_index, cursor_index) {
    "The cursor should be placed inside the formatting for the character on its\nleft, if possible.  Since the first character in the document has no character to\nits left, we will use the character on its right instead";
    if (cursor_index === 0 && start_index === 0) {
      addCursor(parent_tag, cursor_index);
      return addSingleText(parent_tag, full_text, start_index, end_index);
    } else if ((start_index < cursor_index && cursor_index <= end_index)) {
      addSingleText(parent_tag, full_text, start_index, cursor_index);
      addCursor(parent_tag, cursor_index);
      return addSingleText(parent_tag, full_text, cursor_index, end_index);
    } else {
      return addSingleText(parent_tag, full_text, start_index, end_index);
    }
  };

  window.markedTextToTree = function(markers, full_text, cursor_index) {
    "Converts a list of markers into a tree representation that mirrors the\nfinal HTML, and splits up the text into the resulting elements";
    var context, current_tag, i, last_index, len, marker, parent_tag;
    current_tag = {
      attribute: 'container',
      start_index: 0,
      end_index: full_text.length,
      children: []
    };
    context = [current_tag];
    last_index = 0;
    for (i = 0, len = markers.length; i < len; i++) {
      marker = markers[i];
      if (marker.type === 'start') {
        parent_tag = current_tag;
        addCursorText(parent_tag, full_text, last_index, marker.index, cursor_index);
        last_index = marker.index;
        current_tag = {
          attribute: marker.attribute,
          start_index: marker.index,
          children: []
        };
        parent_tag.children.push(current_tag);
        context.push(current_tag);
      } else if (marker.type === 'end') {
        addCursorText(current_tag, full_text, last_index, marker.index, cursor_index);
        last_index = marker.index;
        current_tag.end_index = marker.index;
        context.pop();
        current_tag = last(context);
      }
    }
    addCursorText(current_tag, full_text, last_index, full_text.length, cursor_index);
    return current_tag;
  };

  window.overlayedTextToTree = function(overlays, text, cursor) {
    "Converts overlays to an html-like tree";
    var markers, normalized_markers, tree;
    markers = overlaysToMarkers(overlays);
    normalized_markers = normalizeMarkers(markers);
    tree = markedTextToTree(normalized_markers, text, cursor);
    return tree;
  };

}).call(this);