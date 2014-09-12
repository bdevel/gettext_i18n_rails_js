namespace :gettext do
  desc "Convert PO files to js files in app/assets/locales"
  task :po_to_json => :environment do
    require 'po_to_json'
    require 'gettext_i18n_rails_js/js_and_coffee_parser'
    
    # Here for backwards compatibility with setting these methods in a task file
    if defined? js_gettext_function
      GettextI18nRailsJs::JsAndCoffeeParser.js_gettext_function = js_gettext_function
    end
    
    if defined? handlebars_gettext_function
      GettextI18nRailsJs::HandlebarsParser.handlebars_gettext_function = handlebars_gettext_function
    end
    
    po_files = Dir["#{locale_path}/**/*.po"]
    if po_files.empty?
      puts "Could not find any PO files in #{locale_path}. Run 'rake gettext:find' first."
    end
    
    if GettextI18nRails.options.json_output_path
      js_locales = GettextI18nRails.options.json_output_path
    else
      js_locales = File.join(Rails.root, 'app', 'assets', 'javascripts', 'locale')      
    end
    
    FileUtils.makedirs(js_locales)
    
    po_opts = GettextI18nRails.options.po2json_options || {}
    
    po_files.each do |po_file|
      # Language is used for filenames, while language code is used
      # as the in-app language code. So for instance, simplified chinese will
      # live in app/assets/locale/zh_CN/app.js but inside the file the language
      # will be referred to as locales['zh-CN']
      # This is to adapt to the existing gettext_rails convention.
      language = File.basename( File.dirname(po_file) )
      language_code = language.gsub('_','-')
      
      destination = File.join(js_locales, language)
      json_string = PoToJson.new(po_file).generate_for_jed(language_code, po_opts)
      
      FileUtils.makedirs(destination)
      File.open(File.join(destination, 'app.js'), 'w'){ |file| file.write(json_string) }
      
      puts "Created app.js in #{destination}"
    end
    puts
    puts "All files created, make sure they are being added to your assets file."
    puts "If they are not, you can add them with this line:"
    puts "//= require_tree ./locale"
    puts
  end

  def files_to_translate
    if GettextI18nRails.options.files_to_translate.is_a? Proc
      GettextI18nRails.options.files_to_translate.call(locale_path)
      
    elsif GettextI18nRails.options.files_to_translate.is_a? Array
      GettextI18nRails.options.files_to_translate
    else
      Dir.glob("{app,lib,config,#{locale_path}}/**/*.{rb,erb,haml,slim,js,coffee,handlebars,hbs,mustache}")
    end
  end
  
end

