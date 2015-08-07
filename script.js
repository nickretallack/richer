// Generated by CoffeeScript 1.9.2
(function() {
  var KEYCODES, top;

  window.Editor = React.createClass({
    getInitialState: function() {
      return {
        cursor: this.props.doc.getText().length,
        selection_end: null
      };
    },
    attributeToTag: function(attribute) {
      var simple_elements;
      simple_elements = {
        bold: 'b',
        italic: 'i',
        container: 'div',
        cursor: 'cursor'
      };
      return simple_elements[attribute];
    },
    renderTree: function(node) {
      var tag;
      if (node.text != null) {
        return React.createElement('span', {
          'data-start-index': node.start_index,
          'data-end-index': node.end_index
        }, node.text);
      }
      tag = this.attributeToTag(node.attribute);
      return React.createElement(tag, {
        'data-start-index': node.start_index,
        'data-end-index': node.end_index
      }, this.renderTreeList(node.children));
    },
    renderTreeList: function(nodes) {
      var i, len, node, results;
      results = [];
      for (i = 0, len = nodes.length; i < len; i++) {
        node = nodes[i];
        results.push(this.renderTree(node));
      }
      return results;
    },
    getAnchorIndex: function(anchor, offset) {
      if (anchor.nodeType === anchor.TEXT_NODE) {
        return (parseInt(anchor.parentNode.attributes['data-start-index'].value)) + offset;
      } else {
        return console.log("TODO: handle non-text clicks");
      }
    },
    onClick: function(event) {
      var cursor, index1, index2, selection, selection_end;
      selection = window.getSelection();
      if (selection.isCollapsed) {
        cursor = this.getAnchorIndex(selection.anchorNode, selection.anchorOffset);
        selection_end = null;
      } else {
        index1 = this.getAnchorIndex(selection.anchorNode, selection.anchorOffset);
        index2 = this.getAnchorIndex(selection.focusNode, selection.focusOffset);
        if (index1 < index2) {
          cursor = index1;
          selection_end = index2;
        } else {
          cursor = index2;
          selection_end = index1;
        }
      }
      return this.setState({
        cursor: cursor,
        selection_end: selection_end
      });
    },
    deleteSelection: function() {
      this.props.doc.deleteText(this.state.cursor, this.state.selection_end - this.state.cursor);
      return this.setState({
        selection_end: null
      });
    },
    insertText: function(text) {
      if (this.state.selection_end) {
        this.deleteSelection();
      }
      this.props.doc.insertText(this.state.cursor, text);
      return this.setState({
        cursor: this.state.cursor + text.length
      });
    },
    deleteText: function() {
      if (this.state.selection_end) {
        return this.deleteSelection();
      } else {
        this.props.doc.deleteText(this.state.cursor - 1, 1);
        return this.setState({
          cursor: this.state.cursor - 1
        });
      }
    },
    getText: function() {
      return this.props.doc.getText();
    },
    onKeypress: function(event) {
      var character;
      event.preventDefault();
      character = String.fromCharCode(event.which);
      return this.insertText(character);
    },
    onKeyDown: function(event) {
      var selection_end;
      if (event.keyCode === KEYCODES.backspace) {
        event.preventDefault();
        return this.deleteText();
      } else if (event.keyCode === KEYCODES.left) {
        if (event.shiftKey) {
          if (!this.state.selection_end) {
            this.setState({
              selection_end: this.state.cursor
            });
          }
          if (this.state.cursor > 0) {
            return this.setState({
              cursor: this.state.cursor - 1
            });
          }
        } else {
          if (this.state.selection_end) {
            return this.setState({
              selection_end: null
            });
          } else if (this.state.cursor > 0) {
            return this.setState({
              cursor: this.state.cursor - 1
            });
          }
        }
      } else if (event.keyCode === KEYCODES.right) {
        if (event.shiftKey) {
          selection_end = this.state.selection_end || this.state.cursor;
          if (selection_end < this.getText().length) {
            return this.setState({
              selection_end: selection_end + 1
            });
          }
        } else {
          if (this.state.selection_end) {
            return this.setState({
              cursor: this.state.selection_end,
              selection_end: null
            });
          } else if (this.state.cursor < this.getText().length) {
            return this.setState({
              cursor: this.state.cursor + 1
            });
          }
        }
      }
    },
    onPaste: function(event) {
      var characters, data;
      data = event.clipboardData;
      characters = data.getData(data.types[0]);
      return this.insertText(characters);
    },
    render: function() {
      var children, tree;
      tree = overlayedTextToTree(this.props.doc.getOverlays(), this.props.doc.getText(), this.state.cursor);
      children = this.renderTreeList(tree.children);
      return React.createElement('div', {
        'data-start-index': tree.start_index,
        'data-end-index': tree.end_index,
        onClick: this.onClick,
        onKeyPress: this.onKeypress,
        onKeyDown: this.onKeyDown,
        onPaste: this.onPaste,
        tabIndex: 1
      }, children);
    }
  });

  KEYCODES = {
    left: 37,
    up: 38,
    right: 39,
    down: 40,
    backspace: 8
  };

  top = function(stack) {
    return stack[stack.length - 1];
  };

  window.gapi.load('auth:client,drive-realtime,drive-share', function() {
    var doc, model, parent, render, richtext;
    setup_richtext();
    doc = gapi.drive.realtime.newInMemoryDocument();
    model = doc.getModel();
    parent = model.getRoot();
    richtext = model.create(CollaborativeRichText);
    parent.set('text', richtext);
    richtext.insertText(0, "123456789");
    richtext.formatText(1, 6, {
      bold: true
    });
    richtext.formatText(5, 3, {
      italic: true
    });
    render = function() {
      return React.render(React.createElement(Editor, {
        "doc": richtext
      }), document.getElementById('main'));
    };
    parent.addEventListener(gapi.drive.realtime.EventType.OBJECT_CHANGED, render);
    return render();
  });

}).call(this);
