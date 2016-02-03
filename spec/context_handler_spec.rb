require 'diecut/context-handler'

describe Diecut::ContextHandler do
  let :ui_class do
    Diecut::UIConfig.build_subclass("User Interface")
  end

  let :context_class do
    Diecut::Configurable.build_subclass("TestingCC").tap do |cc|
    end
  end

  let :missing_context_field_plugin do
    Diecut::PluginDescription.new('dummy', 'dummy.rb').tap do |plugin|
      plugin.option('testing') do |opt|
        opt.goes_to('missing', 'field')
      end
    end
  end

  let :activated_plugins do
    [ missing_context_field_plugin ]
  end

  subject :handler do
    Diecut::ContextHandler.new.tap do |handler|
      handler.context_class = context_class
      handler.ui_class = ui_class
      handler.plugins = activated_plugins
    end
  end

  it "should something" do
    handler.apply_simple_defaults
    handler.apply_to_ui
    handler.ui_class
  end
end
