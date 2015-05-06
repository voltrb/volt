/*
 * Watch Event Listener
 *
 * @author Darcy Clarke
 * Modified by Penn Su
 *
 * Copyright (c) 2014 Darcy Clarke
 * Dual licensed under the MIT and GPL licenses.
 *
 * Usage:
 * watch(element, 'width height', function(){
 *   console.log(this.style.width, this.style.height);
 * });
 */

(function (window) {

  var toArray;
  var eqlArrays;

  // http://jsfiddle.net/moagrius/YxzfV/
  Array.prototype.multisplice = function(){
    var args = Array.apply(null, arguments);
    args.sort(function(a,b){
     return a - b;
    });
    for(var i = 0; i < args.length; i++){
      var index = args[i] - i;
      this.splice(index, 1);
    }
  }

  // Object to Array
  toArray = function (obj) {

    var arr = [];

    for (var i = obj.length >>> 0; i--;) {
      arr[i] = obj[i];
    }

    return arr;

  };

  eqlArrays = function (a, b) {
    a.length == b.length && a.every(function (e, i) { e === b[i] });
  }

  var _watch = function (elements, props, options, callback){

    // Setup
    var self = this;
    var check;

    // Check if we should fire callback
    check = function (e) {

      var self = this;

      for (var i = 0; i < self.watching.length; i++) {

        var data = self.watching[i];
        var changed = true;
        var temp;

        // Iterate through properties
        for (var j = 0; j < data.props.length; j++) {
          temp = self.attributes[data.props[j]] || self.style[data.props[j]];
          if (data.vals[j] != temp) {
            data.vals[j] = temp;
            data.changed[j] = true;
          }
        }

        // Check changed attributes
        for (var k = 0; k < data.props.length; k++) {
          if (!data.changed[k]) {
            changed = false;
            break;
          }
        }

        // Run callback if property has changed
        if (changed && data.callback) {
          data.callback.apply(self, e);
        }

      };

    };

    // Elements from node list to array
    elements = toArray(elements);

    // Type check options
    if (typeof(options) == 'function') {
      callback = options;
      options = {};
    }

    // Type check callback
    if (typeof(callback) != 'function') {
      callback = function(){};
    }

    // Set throttle
    options.throttle = options.throttle || 10;

    // Iterate over elements
    for (var i = 0; i < elements.length; i++) {

      var element = elements[i];
      var data = {
        props: props.split(' '),
        vals: [],
        changed: [],
        callback: callback
      };

      // Grab each property's initial value
      for (var j = 0; j < data.props.length; j++) {
        data.vals[j] = element.attributes[data.props[j]] || element.style[data.props[j]];
        data.changed[j] = false;
      }

      // Set watch array
      if (!element.watching) {
        element.watching = [];
      }

      // Store data in watch array
      element.watching.push(data);

      // Create new Mutation Observer
      var observer = new MutationObserver(function (mutations) {
        console.log(mutations);
        for (var k = 0; k < mutations.length; k++) {
          check.call(mutations[k].target, mutations[k]);
        }
      });

      // Set observer array
      if (!element.observers) {
        element.observers = [];
      }

      // Store element observer
      element.observers.push(observer);

      // Start observing
      observer.observe(element, { subtree: false, attributes: true });

    }

    // Return elements to enable chaining
    return self;

  };

  var _unwatch = function (elements, props){

    // Setup
    var self = this;

    // Elements from node list to array
    elements = toArray(elements);

    // Iterate over elements
    for (var i = 0; i < elements.length; i++) {

      var element = elements[i];
      var indexes = []

      if (element.watching) {
        for (var j = 0; j < element.watching.length; j++) {

          var data = element.watching[j];
          if (eqlArrays(data.props, props.split(' '))) {
            indexes.push(j);
          }

        }

        element.watching.multisplice.apply(element.watching, indexes);
      }

    }

    // Return elements to enable chaining
    return self;

  };

  // Expose watch to window
  window.watch = function () {
    return _watch.apply(arguments[0], arguments);
  };

  window.unwatch = function () {
    return _unwatch.apply(arguments[0], arguments);
  };

  // Expose watch to jQuery
  (function ($) {
    $.fn.watch = function () {
      Array.prototype.unshift.call(arguments, this);
      return _watch.apply(this, arguments);
    };

    $.fn.unwatch = function () {
      Array.prototype.unshift.call(arguments, this);
      return _unwatch.apply(this, arguments);
    };
  })(jQuery);

})(window);
