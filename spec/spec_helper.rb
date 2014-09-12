require 'rubygems'

$LOAD_PATH << File.expand_path("../lib", File.dirname(__FILE__))

require 'tempfile'
require 'rails'
require 'gettext_i18n_rails_js'

# Reset any configuration options before each test
RSpec.configure do |config|
  config.before(:each) do
    GettextI18nRails.options.to_h.each_key do |key|
      GettextI18nRails.options.delete_field key
    end
  end
end


def with_file(content)
  Tempfile.open('gettext_i18n_rails_specs') do |f|
    f.write(content)
    f.close
    yield f.path
  end
end


def set_config(opt_name, value)
  GettextI18nRails.configure do |gt|
    gt.send("#{opt_name}=", value)
  end
end
