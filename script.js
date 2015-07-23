// Generated by CoffeeScript 1.9.2
(function() {
  var top;

  window.Editor = React.createClass({
    getInitialState: function() {
      return {
        text: "hello world",
        overlays: [
          {
            attribute: 'bold',
            start: 0,
            end: 3
          }, {
            attribute: 'italic',
            start: 6,
            end: 11
          }
        ]
      };
    },
    attributeToTag: function(attribute) {
      var simple_elements;
      simple_elements = {
        bold: 'b',
        italic: 'i',
        container: 'div'
      };
      return simple_elements[attribute];
    },
    renderTree: function(node) {
      var tag;
      if (node.text != null) {
        return node.text;
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
    onClick: function(event) {
      var anchor, index, local_index, parent_index, parent_node, previous_sibling, previous_sibling_index, selection;
      selection = window.getSelection();
      if (selection.isCollapsed) {
        anchor = selection.anchorNode;
        index = (function() {
          if (anchor.nodeType === anchor.TEXT_NODE) {
            parent_node = anchor.parentNode.parentNode;
            parent_index = parseInt(parent_node.attributes['data-start-index'].value);
            previous_sibling = anchor.parentNode.previousSibling;
            previous_sibling_index = previous_sibling != null ? parseInt(previous_sibling.attributes['data-end-index'].value) : 0;
            local_index = selection.anchorOffset;
            return previous_sibling_index + parent_index + local_index;
          } else {
            console.log("TODO: handle non-text clicks");
            debugger;
          }
        })();
        return console.log(index);
      } else {
        console.log("TODO: handle selections");
        debugger;
      }
    },
    render: function() {
      var children, tree;
      tree = overlayedTextToTree(this.state.overlays, this.state.text);
      children = this.renderTreeList(tree.children);
      return React.createElement('div', {
        'data-start-index': 0,
        'data-end-index': this.state.text.length,
        onClick: this.onClick
      }, children);
    }
  });

  React.render(React.createElement(Editor, null), document.getElementById('main'));

  top = function(stack) {
    return stack[stack.length - 1];
  };

}).call(this);
