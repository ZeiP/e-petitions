(function ($) {
  'use strict';

  $.fn.languageSelector = function() {
    var $html = this;
    var $languageSelection = $html.find('.language-selector-link');
    
    var appendOrChangeQueryParameter = function(uri, key, value) {
      var i = uri.indexOf('#');
      var hash = i === -1 ? ''  : uri.substr(i);
          uri = i === -1 ? uri : uri.substr(0, i);

      var re = new RegExp("([?&])" + key + "=.*?(&|$)", "i");
      var separator = uri.indexOf('?') !== -1 ? "&" : "?";
      if (uri.match(re)) {
          uri = uri.replace(re, '$1' + key + "=" + value + '$2');
      } else {
          uri = uri + separator + key + "=" + value;
      }
      return uri + hash;
    }
      
    var languageChanged = function(e) {
      e.preventDefault();
  
      var selectedLocale = e.target.getAttribute('data-locale');
      
      var newUrl = appendOrChangeQueryParameter(window.location.href, 'locale', selectedLocale);
      window.location.replace(newUrl);
    }

    $languageSelection.on('click', languageChanged);
  }

  $('#language-selector').languageSelector();
})(jQuery);
