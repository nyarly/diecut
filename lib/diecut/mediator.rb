require 'diecut/configurable'
require 'diecut/errors'

module Diecut
  class UIConfig < Configurable
    class << self
      def options_hash
        @options_hash ||= {}
      end

      def description(name)
        @options_hash.fetch(name).description
      end

      def required?(name)
        field_metadata(name).is?(:required)
      end

      def default_value(name)
        field_metadata(name).default_value
      end
    end

    def initialize
      super
      setup_defaults
    end

    def get_value(name)
      self.class.field_metadata(name).value_on(self)
    end
  end

  class Mediator
    def initialize
      @plugins = []
      @activated = {}
    end

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
      ui_class = Class.new(UIConfig)

      handler = ContextHandler.new
      handler.context_class = Class.new(Configurable)
      handler.ui_class = ui_class
      handler.plugins = @plugins

      handler.backfill_options_to_context
      handler.apply_to_ui

      handler.ui_class
    end

    def build_ui_class(context_class)
      ui_class = Class.new(UIConfig)

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

  class UIApplier
    attr_accessor :plugins, :ui, :context

    # setup default values on ui
    # setup dynamic defaults on context
    # copy ui settings to context
    # resolve context config
    # confirm required
    def apply
      check_ui
      basic_defaults
      dynamic_defaults
      copy_to_context
      resolve_context
      confirm_required
    end

    def check_ui
      ui.check_required
    end

    def basic_defaults
      context.setup_defaults
    end

    def dynamic_defaults
      plugins.each do |plugin|
        plugin.context_defaults.each do |default|
          apply_dynamic_default(default)
        end
      end
    end

    def copy_to_context
      plugins.each do |plugin|
        plugin.options.each do |option|
          copy_option(option)
        end
      end
    end

    def resolve_context
      plugins.each do |plugin|
        unless plugin.resolve_block.nil?
          plugin.apply_resolve(ui, context)
        end
      end
    end

    def confirm_required
      context.check_required
    end

    def apply_dynamic_default(default)
      return if default.simple?

      segment = context.walk_path(default.context_path).last

      segment.value = default.compute_value(context)
    end

    def copy_option(option)
      return unless option.has_context_path?

      segment = context.walk_path(option.context_path).last

      segment.value = ui.get_value(option.name)
    end
  end

  class ContextHandler
    attr_accessor :context_class, :ui_class, :plugins

    def apply_simple_defaults
      plugins.each do |plugin|
        plugin.context_defaults.each do |default|
          next unless default.simple?
          begin
            apply_simple_default(default)
          rescue Error
            raise Error, "Plugin #{plugin.name.inspect} failed"
          end
        end
      end
    end

    def apply_to_ui
      plugins.each do |plugin|
        plugin.options.each do |option|
          apply_option_to_ui(option)
        end
      end
    end

    def backfill_options_to_context
      plugins.each do |plugin|
        plugin.options.each do |option|
          backfill_to_context(option)
        end
      end
    end

    def backfill_to_context(option)
      return unless option.has_context_path?

      segment = context_class.walk_path(option.context_path).last
      if option.has_default?
        segment.klass.setting(segment.name, option.default_value)
      else
        segment.klass.setting(segment.name)
      end
    end

    def apply_simple_default(default)
      target = context_class.walk_path(default.context_path).last
      if target.metadata.nil?
        raise UnusedDefault, "No template uses a value at #{default.context_path.inspect}"
      elsif not target.metadata.default_value.nil?
        raise OverriddenDefault, "default for #{default.context_path.inspect} already set to #{target.metadata.default_value.inspect}"
      else
        target.metadata.default_value = default.value
        target.metadata.is(:defaulting)
      end
    end

    def apply_option_to_ui(option)
      if ui_class.options_hash.key?(option.name)
        existing = ui_class.options_hash[option.name]
        if existing.default_value != option.default_value
          raise OptionClass, "default value for option #{option.name.inspect} changed from #{existing.default_value} to #{option.default_value}"
        end
      end

      ui_class.options_hash[option.name] = option

      if option.has_context_path?
        context_metadata = context_class.walk_path(option.context_path).last.metadata
        if option.has_default?
          if context_metadata.is?(:defaulting) and option.default_value != context_metadata.default_value
            raise OverriddenDefault, "default for option #{option.name.inspect} (#{option.default_value})" +
              "differs from its context target #{option.context_path.inspect} (#{context_metadata.default_value})"
          else
            ui_class.setting(option.name, option.default_value)
          end
        else
          if context_metadata.is?(:defaulting)
            ui_class.setting(option.name, context_metadata.default_value)
          else
            ui_class.setting(option.name)
          end
        end
      else
        if option.has_default?
          ui_class.setting(option.name, option.default_value)
        else
          ui_class.setting(option.name)
        end
      end
    end
  end
end
