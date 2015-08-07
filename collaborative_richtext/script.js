// Generated by CoffeeScript 1.9.2
(function() {
  var CollaborativeRichText, Overlay, random_character, random_id;

  random_character = function() {
    var chars;
    chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return chars.charAt(Math.floor(Math.random() * chars.length));
  };

  random_id = function(length) {
    var _;
    return ((function() {
      var i, ref, results;
      results = [];
      for (_ = i = 0, ref = length; 0 <= ref ? i <= ref : i >= ref; _ = 0 <= ref ? ++i : --i) {
        results.push(random_character());
      }
      return results;
    })()).join('');
  };

  Overlay = (function() {
    function Overlay() {}


    /*
    Represents a styled portion of a collaborative string.
    Examples: bold, italic
    
    It tracks the place in the string where it begins and ends.
    
    In Google Drive Realtime API, indexes refer to the positions of actual characters.
    However, I find it more convenient to have indexes refer to the spaces between characters.
    That's why I created the getters and setters on this class, so nobody else has to
    deal with this off-by-one difference.
     */

    Overlay.prototype.__collaborativeInitializerFn__ = function(arg) {
      var attribute, end_index, end_ref, start_index, start_ref;
      this.str = arg.str, start_index = arg.start_index, end_index = arg.end_index, attribute = arg.attribute;
      this.model = gapi.drive.realtime.custom.getModel(this);
      console.log('create overlay:', start_index, end_index, attribute);
      start_ref = this.str.registerReference(start_index, gapi.drive.realtime.IndexReference.DeleteMode.SHIFT_AFTER_DELETE);
      end_ref = this.str.registerReference(end_index - 1, gapi.drive.realtime.IndexReference.DeleteMode.SHIFT_BEFORE_DELETE);
      this.start = start_ref;
      this.end = end_ref;
      this.attribute = attribute;
    };

    Overlay.prototype.collides = function(index, attribute) {
      return attribute === this.attribute && this.get_start() <= index && this.get_end() >= index;
    };

    Overlay.prototype.get_start = function() {
      return this.start.index;
    };

    Overlay.prototype.set_start = function(value) {
      return this.start.index = value;
    };

    Overlay.prototype.get_end = function() {
      return this.end.index + 1;
    };

    Overlay.prototype.set_end = function(value) {
      return this.end.index = value - 1;
    };

    Overlay.prototype.repr = function() {
      return {
        attribute: this.attribute,
        start: this.get_start(),
        end: this.get_end()
      };
    };

    return Overlay;

  })();

  CollaborativeRichText = (function() {
    function CollaborativeRichText() {}

    CollaborativeRichText.prototype.__collaborativeInitializerFn__ = function() {
      this.model = gapi.drive.realtime.custom.getModel(this);
      this.str = this.model.createString();
      return this.overlays = this.model.createList();
    };

    CollaborativeRichText.prototype.debug_overlays = function() {
      var attribute, attributes, i, len, overlay, overlays, ref;
      attributes = {};
      ref = this.overlays.asArray();
      for (i = 0, len = ref.length; i < len; i++) {
        overlay = ref[i];
        attribute = overlay.attribute;
        if (attributes[attribute] == null) {
          attributes[attribute] = [];
        }
        attributes[attribute].push({
          start: overlay.get_start(),
          end: overlay.get_end()
        });
      }
      for (attribute in attributes) {
        overlays = attributes[attribute];
        overlays.sort(function(a, b) {
          var start_comparison;
          start_comparison = a.start - b.start;
          if (start_comparison === 0) {
            return a.end - b.end;
          }
          return start_comparison;
        });
      }
      return attributes;
    };

    CollaborativeRichText.prototype.create_overlay = function(start_index, end_index, attribute) {
      this.overlays.push(this.model.create(Overlay, {
        start_index: start_index,
        end_index: end_index,
        attribute: attribute,
        str: this.str
      }));
    };

    CollaborativeRichText.prototype.remove_overlay = function(overlay) {
      console.log('remove overlay', overlay.repr());
      this.overlays.removeValue(overlay);
    };

    CollaborativeRichText.prototype.find_colliding_overlay = function(attribute, index) {
      var i, len, overlay, ref;
      ref = this.overlays.asArray();
      for (i = 0, len = ref.length; i < len; i++) {
        overlay = ref[i];
        if (overlay.collides(index, attribute)) {
          return overlay;
        }
      }
    };

    CollaborativeRichText.prototype.delete_overlay_range = function(start_index, end_index) {
      var deletable_overlays, i, len, overlay;
      deletable_overlays = this.overlays.asArray().filter(function(overlay) {
        var overlay_end, overlay_start;
        overlay_start = overlay.get_start();
        overlay_end = overlay.get_end();
        return overlay_start >= start_index && overlay_end <= end_index;
      });
      for (i = 0, len = deletable_overlays.length; i < len; i++) {
        overlay = deletable_overlays[i];
        this.remove_overlay(overlay);
      }
    };

    CollaborativeRichText.prototype.split_or_remove_overlay = function(start_index, end_index, attribute) {
      var matches_end, matches_start, overlay, overlay_end, overlay_start;
      overlay = this.find_colliding_overlay(attribute, start_index);
      if (!overlay) {
        console.log('ANOMALY - deleted overlay that wasn\'t found');
        return;
      }
      overlay_start = overlay.start;
      overlay_end = overlay.end;
      matches_start = start_index === overlay.get_start();
      matches_end = end_index === overlay.get_end();
      if (matches_start && matches_end) {
        this.remove_overlay(overlay);
      } else if (matches_start) {
        overlay.set_start(end_index);
      } else if (matches_end) {
        overlay.set_end(start_index);
      } else {
        this.split_overlay(overlay, start_index, end_index, attribute);
      }
    };

    CollaborativeRichText.prototype.split_overlay = function(overlay, start_index, end_index, attribute) {
      var overlay_end;
      overlay_end = overlay.get_end();
      overlay.set_end(start_index);
      this.create_overlay(end_index, overlay_end, attribute);
    };

    CollaborativeRichText.prototype.extend_or_create_overlay = function(start_index, end_index, attribute) {
      var found_end, found_start;
      found_start = this.find_colliding_overlay(attribute, start_index);
      found_end = this.find_colliding_overlay(attribute, end_index);
      if (found_start && found_end) {
        this.connect_two_overlays(found_start, found_end);
      } else if (found_start) {
        found_start.set_end(end_index);
      } else if (found_end) {
        found_end.set_start(start_index);
      } else {
        console.log('create new overlay', attribute);
        this.create_overlay(start_index, end_index, attribute);
      }
    };

    CollaborativeRichText.prototype.connect_two_overlays = function(first_overlay, second_overlay) {
      this.remove_overlay(second_overlay);
      first_overlay.set_end(second_overlay.get_end());
    };

    CollaborativeRichText.prototype.formatText = function(index, length, attributes) {
      var attribute, end_index, value;
      end_index = index + length;
      for (attribute in attributes) {
        value = attributes[attribute];
        if (value) {
          this.extend_or_create_overlay(index, end_index, attribute);
        } else {
          this.split_or_remove_overlay(index, end_index, attribute);
        }
      }
    };

    CollaborativeRichText.prototype.insertText = function(index, text, attributes) {
      this.str.insertString(index, text);
      this.formatText(index, text.length, attributes);
    };

    CollaborativeRichText.prototype.deleteText = function(index, length) {
      var end_index;
      end_index = index + length;
      this.delete_overlay_range(index, end_index);
      this.str.removeRange(index, end_index);
    };

    CollaborativeRichText.prototype.getText = function() {
      return this.str.text;
    };

    CollaborativeRichText.prototype.getOverlays = function() {
      var i, len, overlay, ref, results;
      ref = this.overlays.asArray();
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        overlay = ref[i];
        results.push(overlay.repr());
      }
      return results;
    };

    return CollaborativeRichText;

  })();

  window.CollaborativeRichText = CollaborativeRichText;

  window.setup_richtext = function() {
    gapi.drive.realtime.custom.registerType(CollaborativeRichText, 'CollaborativeRichText');
    return gapi.drive.realtime.custom.registerType(Overlay, 'CollaborativeRichTextOverlay');
  };

}).call(this);
