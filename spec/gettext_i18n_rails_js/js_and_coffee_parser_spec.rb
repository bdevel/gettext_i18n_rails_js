require "spec_helper"
require "gettext_i18n_rails_js/js_and_coffee_parser"

describe GettextI18nRailsJs::JsAndCoffeeParser do
  let(:parser){ GettextI18nRailsJs::JsAndCoffeeParser }

  describe "#target?" do
    it "targets .js" do
      parser.target?('foo/bar/xxx.js').should == true
    end

    it "targets .coffee" do
      parser.target?('foo/bar/xxx.coffee').should == true
    end

    it "does not target cows" do
      parser.target?('foo/bar/xxx.cows').should == false
    end

    it "targets will match if set by configuration" do
      set_config :js_parser_target_extensions, %w[.tsr]
      parser.target?('foo/bar/xxx.tsr').should == true
    end
    
    it "targets will not match if not in configuration list" do
      set_config :js_parser_target_extensions, %w[.tsr]
      parser.target?('foo/bar/xxx.abc').should == false
    end
    
  end

  describe "#parse" do
    it "finds messages in coffee" do
      with_file 'foo = __("xxxx")' do |path|
        parser.parse(path, []).should == [
          ["xxxx", "#{path}:1"]
        ]
      end
    end

    it "finds plural messages in coffee" do
      with_file 'bla = n__("xxxx", "yyyy", "zzzz", some_count)' do |path|
        parser.parse(path, []).should == [
          ["xxxx\000yyyy\000zzzz", "#{path}:1"]
        ]
      end
    end

    it "finds namespaced messages in coffee" do
      with_file 'bla = __("xxxx", "yyyy")' do |path|
        parser.parse(path, []).should == [
          ["xxxx\004yyyy", "#{path}:1"]
        ]
      end
    end

    it "does not capture a false positive with functions ending like the gettext function" do
      with_file 'bla = this_should_not_be_registered__("xxxx", "yyyy")' do |path|
        parser.parse(path, []).should == []
      end
    end

    it 'Does find messages in interpolated multi-line strings' do
      source = '''
        """ Parser should grab
          #{ __(\'This\') } __(\'known bug\')
        """
      '''
      with_file source do |path|
        parser.parse(path, []).should == [
          ["This", "#{path}:3"],
          ["known bug", "#{path}:3"]
        ]
      end
    end

    it 'finds messages with newlines and tabs in them' do
      with_file 'bla = __("xxxx\n\t")' do |path|
        parser.parse(path, []).should == [
          ['xxxx\n\t', "#{path}:1"]
        ]
      end
    end

    it 'does not find messages that are not strings' do
      with_file 'bla = __(bar)' do |path|
        parser.parse(path, []).should == []
      end
    end

    it 'does not parse internal parentheses ' do
      with_file 'bla = __("some text (which is great) and some parentheses()") + __(\'foobar\')' do |path|
        parser.parse(path, []).should == [
          ['some text (which is great) and some parentheses()', "#{path}:1"],
          ['foobar', "#{path}:1"]
        ]
      end
    end
    it 'does not parse internal called functions' do
      with_file 'bla = n__("items (single)", "items (more)", item.count()) + __(\'foobar\')' do |path|
        parser.parse(path, []).should == [
          ["items (single)\000items (more)", "#{path}:1"],
          ['foobar', "#{path}:1"]
        ]
      end
    end

    it 'finds messages with newlines and tabs in them (single quotes)' do
      with_file "bla = __('xxxx\\n\\t')" do |path|
        parser.parse(path, []).should == [
          ['xxxx\n\t', "#{path}:1"]
        ]
      end
    end
    it 'finds strings that use some templating' do
      with_file '__("hello {yourname}")' do |path|
        parser.parse(path, []).should == [
          ['hello {yourname}', "#{path}:1"]
        ]
      end
    end
    it 'finds strings that use escaped strings' do
      with_file '__("hello \"dude\"") + __(\'how is it \\\'going\\\' \')' do |path|
        parser.parse(path, []).should == [
          ['hello \"dude\"', "#{path}:1"],
          ["how is it \\'going\\' ", "#{path}:1"]
        ]
      end
    end
    it 'accepts changing the function name' do
      GettextI18nRailsJs::JsAndCoffeeParser.js_gettext_function = 'gettext'
      with_file 'gettext("hello {yourname}") + ngettext("item", "items", 44)' do |path|
        parser.parse(path, []).should == [
          ['hello {yourname}', "#{path}:1"],
          ["item\000items", "#{path}:1"],
        ]
      end
      GettextI18nRailsJs::JsAndCoffeeParser.js_gettext_function = '__'
    end
    
    it "uses configured gettext function name" do
      set_config :js_gettext_function, 'XX__'
      with_file 'XX__("Hello World")' do |path|
        parser.parse(path, []).should == [
          ['Hello World', "#{path}:1"]
        ]
      end
    end


  end

  describe 'mixed use tests' do
    it 'parses a full js file' do
      path = File.join(File.dirname(__FILE__), '../fixtures/example.js')
      parser.parse(path, []).should == [
        ['json', "#{path}:2"],
        ["item\000items", "#{path}:3"],
        ['hello {yourname}', "#{path}:6"],
        ['new-trans', "#{path}:9"],
        ["namespaced\004trans", "#{path}:10"],
        ['Hello\nBuddy', "#{path}:11"]
      ]
    end
    it 'parses a full coffee file' do
      path = File.join(File.dirname(__FILE__), '../fixtures/example.coffee')
      parser.parse(path, []).should == [
        ['json', "#{path}:2"],
        ["item\000items", "#{path}:3"],
        ['hello {yourname}', "#{path}:5"],
        ['new-trans', "#{path}:8"],
        ["namespaced\004trans", "#{path}:9"],
        ['Hello\nBuddy', "#{path}:11"],
        ['Multi-line', "#{path}:14"]
      ]
    end
  end
end
