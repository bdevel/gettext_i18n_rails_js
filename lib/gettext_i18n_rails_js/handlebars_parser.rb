require 'gettext/tools/xgettext'

module GettextI18nRailsJs
  class HandlebarsParser
    
    def self.handlebars_gettext_function
      GettextI18nRails.options.handlebars_gettext_function || '_'
    end

    # Here for backwards compatibility with setting this value in a task file
    def self.handlebars_gettext_function=(function_name)
      GettextI18nRails.options.handlebars_gettext_function = function_name
    end
    
    
    def self.target?(file)
      default_extensions = %w[.hbs .hbs.erb .handlebars .handlebars.erb .mustache]
      extensions = GettextI18nRails.options.handlebars_parser_target_extensions.dup || default_extensions
      
      extensions.map! do |ext|
        Regexp.new "#{ext.gsub('.', '\.')}\\Z" # should look like /\.handlebars\.erb\Z/
      end
      extensions.any? {|regexp| file.match regexp}
    end
    
    # We're lazy and klumsy, so this is a regex based parser that looks for
    # invocations of the various gettext functions. Once captured, we
    # scan them once again to fetch all the function arguments.
    # Invoke regex captures like this:
    # source: "{{ _ "foo"}}"
    # matches:
    # [0]: {{_ "foo"}}
    # [1]: _
    # [2]: "foo"
    #
    # source: "{{_ "foo" "foos" 3}}"
    # matches:
    # [0]: {{_ "foo" "foos" 3}}
    # [1]: _
    # [2]: "foo" "foos" 3'
    # 
    # This method also matches Ember.js compenent/template calls:
    # {{my-template titleTranslation="This will go into the .po file" }}
    #
    # By default it looks for attributes ending in Translation which is default
    # behavior of Ember-i18n gem. This can be overrided by setting the
    # handlebars_translatable_attribute_regexp configuration option
    # to a new regular expression that extracts the quoted string.
    # 
    def self.parse(file, msgids = [])
      cookie = self.handlebars_gettext_function
      file_contents = File.read(file)
      to_return = []
      # Look for {{_ "My string"}} Calls
      invoke_regex = /
        \B[{]{2}(([snN]?#{cookie})      # Matches the function handlebars helper call grouping "{{"
                  \s+                   # and a parenthesis to start the arguments to the function.
                  (".*?"                # Then double quote string
                   .*?                  # remaining arguments
                 )
                )
          [}]{2}                   # function call closing parenthesis
      /x
      
      file_contents.scan(invoke_regex).collect do |whole, function, arguments|
        separator = (function == "n#{cookie}" ? "\000" : "\004")
        
        key = arguments.scan(/('(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")/).
          collect{|match| match.first[1..-2]}.
          join(separator)
        
        next if key == ''
        to_return << key
      end
      
      
      # Find any Ember.js component/template calls that have attributes that need translating.
      # This regex may still needs work... oddly it will match {{my-template attr="foo" bad stuff }}
      # Note, any modification msut support tags spanning multipe lines.
      invoke_regex = /
        [{]{2}\s*[a-zA-Z0-9-]+
        [
          (?:\s+[a-zA-Z0-9_-]+=".*?") |              # attr="some string"
          (?:\s+[a-zA-Z0-9_-]+=[a-zA-Z0-9_]+)        # attr=my_var
        ]+
        [}]{2} # End brackets
      /x
      
      regexp = GettextI18nRails.options.handlebars_translatable_attribute_regexp ||
               /[a-zA-Z0-9_-]+Translation="([^"\\]*(?:\\.[^"\\]*)*)"/ # Default style for Ember-i18n
      
      file_contents.scan(invoke_regex).each do |match|
        # Pull out the values in the attributes with translation calls
        # Match any unescaped quotes
        match.scan(regexp).each do |found|
          to_return << found.first
        end
      end
      
      to_return = to_return.compact.map do |key|
        key.gsub!("\n", '\n')
        key.gsub!("\t", '\t')
        key.gsub!("\0", '\0')
        key.gsub!('\"', '"')
        
        [key, "#{file}:1"]
      end
      
      if !to_return.empty? && GettextI18nRails.options.verbose
        puts "#{file}"
        to_return.each do |m|
          puts "  #{m[0]}"
        end
        puts
      end
      
      return to_return
    end# def parse
    
  end# class
end# module

require 'gettext_i18n_rails/gettext_hooks'
GettextI18nRails::GettextHooks.add_parser(GettextI18nRailsJs::HandlebarsParser)
