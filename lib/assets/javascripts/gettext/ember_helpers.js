

// Derived from ember-i18n's i18n.js file
(function(window) {
  function eachTranslatedAttribute(object, fn) {
    var isTranslatedAttribute = /(.+)Translation$/;
    var isTranslatedAttributeMatch;
    for (var key in object) {
      isTranslatedAttributeMatch = key.match(isTranslatedAttribute);
      if (isTranslatedAttributeMatch) {
        fn.call(object,
                isTranslatedAttributeMatch[1],
                window.gettext(object[key])
               );
      }
    }
  }
  
  Ember.Gettext = Ember.Evented.apply({
    TranslateableProperties: Em.Mixin.create({
      init: function() {
        var result = this._super.apply(this, arguments);
        eachTranslatedAttribute(this, function(attribute, translation) {
          this.addObserver(attribute + 'Translation', this, function(){
            var value = this.get(attribute + 'Translation');
            Ember.set(this, attribute, window.gettext(value));
          });
          Ember.set(this, attribute, translation);
        });

        return result;
      }
    }),
    
    TranslateableAttributes: Em.Mixin.create({
      didInsertElement: function() {
        var result = this._super.apply(this, arguments);
        
        eachTranslatedAttribute(this, function(attribute, translation) {
           this.$().attr(attribute, translation);
        });
        return result;
      }
    })    
    
  });

  Ember.View.reopen(Em.Gettext.TranslateableAttributes);
  Ember.View.reopen(Em.Gettext.TranslateableProperties);
  
  // ============================================
  
  var shorthand_function = (window.handlebars_gettext_shorthand || '__');
  
  Ember.Handlebars.helper(shorthand_function, function() {
    // take off the context arg
    var args = Array.prototype.slice.apply(arguments, [0, arguments.length-1])
    var translation = window.gettext.apply(this, args);
    var escaped = Handlebars.Utils.escapeExpression(translation);
    return new Handlebars.SafeString(escaped);
  });
  
  Ember.Handlebars.helper('n'+shorthand_function, function() {
    // take off the context arg
    var args = Array.prototype.slice.apply(arguments, [0, arguments.length-1]);
    var translation = window.ngettext.apply(this, args);
    var escaped = Handlebars.Utils.escapeExpression(translation);
    return new Handlebars.SafeString(escaped);
  });
  
}).call(undefined, this);
