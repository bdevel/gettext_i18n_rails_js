(function(){ 
  
  locale = document.getElementsByTagName('html')[0].lang;
  var gettext_shorthand = (window.js_gettext_shorthand || '__')
  
  if (!window.js_gettext_shorthand) {
    window.js_gettext_shorthand = gettext_shorthand;
  }
  
  if(!locale){
    if (typeof(console) != "undefined"){
      console.warn('No locale found as an html attribute, using default of en.');
    }
    locale = 'en';
  }
  
  var i18n = new Jed(locales[locale] || {});
  window.i18n = i18n;
  
  window.gettext = function(){
    var translation = i18n.gettext.apply(i18n, arguments)
    var args = Array.prototype.slice.apply(arguments); // make into a real array
    if (args.length > 1) {
      // Figure out how many properties they passed in so we can send those to sprintf
      var property_count = args[0].match(/%[sd\d\$]+/g).length;
      var props = args.slice(args.length - property_count);
      props.unshift(translation);
      translation = window.i18n.sprintf.apply(this, props);
    }
    return translation;
  };
  eval('window.' + gettext_shorthand + ' = window.gettext');
  
  window.ngettext = function(){
    var translation = i18n.ngettext.apply(i18n, arguments);
    var args = Array.prototype.slice.apply(arguments);
    var property_count = args[0].match(/%[sd\d\$]+/g).length;
    var props = args.slice(args.length - property_count);
    props.unshift(translation);
    return window.i18n.sprintf.apply(this, props);
  };
  eval('window.n' + gettext_shorthand + ' = window.ngettext');
  
  // adds scoping
  window.sgettext = function(key) {
    return window.gettext(key).split('|').pop();
  }
  eval('window.s' + gettext_shorthand + ' = window.sgettext');
  
})();
