require 'diecut/errors'
require 'diecut/ui-config'
require 'diecut/ui-applier'
require 'diecut/context-handler'

module Diecut
  class Mediator
    def initialize
      @plugins = []
      @activated = {}
    end
    attr_reader :plugins

    def add_plugin(plug)
      @activated[plug.name] = plug.default_activated
      @plugins << plug
    end

    def activated?(plug_name)
      @activated[plug_name]
    end

    def activate(plug_name)
      @activated[plug_name] = true
    end

    def deactivate(plug_name)
      @activated[plug_name] = false
    end

    def activated_plugins
      @plugins.find_all do |plugin|
        @activated[plugin.name]
      end
    end

    # Set up context default settings
    # set up ui settings from context
    #
    # < User gets involved >
    #
    def build_example_ui
      ui_class = UIConfig.build_subclass("Example UI")

      handler = ContextHandler.new
      handler.context_class = Configurable.build_subclass("dummy context")
      handler.ui_class = ui_class
      handler.plugins = @plugins

      handler.backfill_options_to_context
      handler.apply_to_ui

      handler.ui_class
    end

    def build_ui_class(context_class)
      ui_class = UIConfig.build_subclass("User Interface")

      handler = ContextHandler.new
      handler.context_class = context_class
      handler.ui_class = ui_class
      handler.plugins = activated_plugins

      handler.apply_simple_defaults
      handler.apply_to_ui

      handler.ui_class
    end

    def apply_user_input(ui, context_class)
      applier = UIApplier.new
      applier.plugins = activated_plugins
      applier.ui = ui
      applier.context = context_class.new
      applier.apply

    end
  end
end
