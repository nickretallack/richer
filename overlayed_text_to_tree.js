// Generated by CoffeeScript 1.9.2
(function() {
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

  window.markedTextToTree = function(markers, full_text) {
    "Converts a list of markers into a tree representation that mirrors the\nfinal HTML, and splits up the text into the resulting elements";
    var context, current_tag, i, last_index, len, marker, parent_tag, text;
    current_tag = {
      attribute: 'container',
      index: 0,
      children: []
    };
    context = [current_tag];
    last_index = 0;
    for (i = 0, len = markers.length; i < len; i++) {
      marker = markers[i];
      if (marker.type === 'start') {
        parent_tag = current_tag;
        text = full_text.slice(last_index, marker.index);
        if (text) {
          parent_tag.children.push({
            text: text
          });
        }
        last_index = marker.index;
        current_tag = {
          attribute: marker.attribute,
          index: marker.index,
          children: []
        };
        parent_tag.children.push(current_tag);
        context.push(current_tag);
      } else if (marker.type === 'end') {
        text = full_text.slice(last_index, marker.index);
        if (text) {
          current_tag.children.push({
            text: text
          });
        }
        last_index = marker.index;
        context.pop();
        current_tag = last(context);
      }
    }
    text = full_text.slice(last_index);
    if (text) {
      current_tag.children.push({
        text: text
      });
    }
    return current_tag;
  };

  window.overlayedTextToTree = function(overlays, text) {
    "Converts overlays to an html-like tree";
    var markers, normalized_markers, tree;
    markers = overlaysToMarkers(overlays);
    normalized_markers = normalizeMarkers(markers);
    tree = markedTextToTree(normalized_markers, text);
    return tree;
  };

}).call(this);