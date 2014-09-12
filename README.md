# GettextI18nRailsJs
[![Build Status](https://secure.travis-ci.org/nubis/gettext_i18n_rails_js.png?branch=master)](https://travis-ci.org/nubis/gettext_i18n_rails_js)

GettextI18nRailsJs extends [gettext_i18n_rails](https://github.com/grosser/gettext_i18n_rails) making your .po files available to client side javascript as JSON

It will find translations inside your Handlebars, Javascript and CoffeeScript files, then it will create JSON versions of your .PO files so you can serve them with the rest of your assets, thus letting you access all your translations offline from client side javascript.

## Installation

Requires rails 3.2 or later.

#### Add the following to your gemfile:

    gem 'gettext_i18n_rails_js'

To checkout this forked version add the following to your gemfile:

     gem 'gettext_i18n_rails_js', :github => [GITHUB_USER]/gettext_i18n_rails_js


## To convert your PO files into javascript files you can run:

    rake gettext:po_to_json

This will reconstruct the `locale/<lang>/app.po` structure as javascript files inside `app/assets/javascripts/locale/<lang>/app.js`

## Using translations in your javascript

The gem provides the Jed library to use the generated javascript files. (http://slexaxton.github.com/Jed) 
It also provides a global `__` function that maps to `Jed#gettext`.
The Jed instance used by the client side `__` function is pre-configured with the 'lang' specified in your main html tag.
Before anything, make sure your page's html tag includes a valid 'lang' attribute, for example:

    %html{:manifest => '', :lang => "#{I18n.locale}"}

Once you're sure your page is configured with a locale, then you should add both your javascript locale files and the provided javascripts to your application.js

    //= require_tree ./locale
    //= require gettext/jed
    //= require gettext/helpers
    //= require gettext/ember_helpers

For production environments there are also minified versions of the Javascript via ember_helpers.min.js, helpers.min.js, and jed.min.js

If you are using Ember.js there are some helpers for Handlebars. For Ember templates, any attribute starting with your gettext shorthand function will be captured by gettext. In your template you can access the attribute without the gettext shorthand function prefix (which would just be 'title' in the example below).

```  
  {{__ "This will also be translated"}}
  {{n__ "%s has %d new message" "%s has %d new messages" 3 "User name" }}
  {{my-template __title="This will go into the .po file." }}
```

## Avoiding conflicts with other libraries

The default function name is `window.__` (double underscore), to avoid conflicts with 'underscore.js'. If you want to alias the function to something else you may do so by adding the following code somewhere in your Javascript before including the gettext Javascript libraries:

    window.handlebars_gettext_shorthand = '_';
    window.js_gettext_shorthand = '_';

You should also instruct the gettext parser to look for the new shorthand function:

config/environment.rb:

    GettextI18nRails.configure do |gt|
      gt.js_gettext_function = '_'
      gt.handlebars_gettext_function = '_'
    end


## Configuration

Additional configuration can be done in your config/environment.rb file. You can override options in your config/environments/[ENV].rb files.

    GettextI18nRails.configure do |gt|
      gt.locale_path = File.join(Rails.root, "locale")
    
      gt.files_to_translate = Proc.new do |locale_path|
        Dir.glob("{app,lib,config,#{locale_path}}/**/*.{rb,erb,haml,slim,js,hbs,es6}")
      end
      
      gt.handlebars_parser_target_extensions = %w[.hbs]
      gt.js_parser_target_extensions = %w[.js .es6]
    
      gt.po2json_options = {pretty_js: true}
      
      gt.js_gettext_function = '__'
      gt.handlebars_gettext_function = '__'
    
      # You can change the format of how you specifiy
      # which attributes will be translated in Ember.js
      # template/component calls by setting this regexp.
      # Make sure the first match is the quoted value.
      # Format of template call:
      # {{comment-box __title="Will go in .po file." name="Will not go in .po file" }}
      gt.handlebars_translatable_attribute_regexp = /#{gt.js_gettext_function}[a-zA-Z0-9_-]+="([^"\\]*(?:\\.[^"\\]*)*)"/
      
    end


